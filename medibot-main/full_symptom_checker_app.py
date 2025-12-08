"""
Full Symptom Checker - Flask Application (Option 3)
====================================================
Features:
✓ Multi-turn symptom collection
✓ Emergency detection
✓ Probability scoring
✓ Differential diagnosis
✓ Treatment recommendations
✓ Age/severity considerations
"""

from flask import Flask, render_template, jsonify, request, session
from flask_cors import CORS
from src.helper import download_hugging_face_embeddings
from langchain_pinecone import PineconeVectorStore
from langchain_openai import ChatOpenAI
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from dotenv import load_dotenv
import os
import json
from datetime import timedelta

# ============================================================================
# CONFIGURATION
# ============================================================================

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'symptom-checker-secret-key')
app.config['SESSION_TYPE'] = 'filesystem'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=2)

CORS(app)

PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
DEEPSEEK_API_KEY = os.getenv('DEEPSEEK_API_KEY')

os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["DEEPSEEK_API_KEY"] = DEEPSEEK_API_KEY

# ============================================================================
# EMERGENCY DETECTION SYSTEM
# ============================================================================

EMERGENCY_SYMPTOMS = {
    "call_911": {
        "keywords": [
            "chest pain", "can't breathe", "difficulty breathing", "cant breathe",
            "unconscious", "passed out", "severe bleeding", "bleeding heavily",
            "seizure", "stroke", "heart attack", "choking", "overdose",
            "suicide", "kill myself", "severe allergic reaction"
        ],
        "message": "🚨 CALL 911 IMMEDIATELY - This could be a medical emergency!"
    },
    "urgent_care": {
        "keywords": [
            "high fever", "severe pain", "persistent vomiting", "vomiting blood",
            "blood in stool", "severe headache", "vision loss", "confused",
            "severe abdominal pain", "deep cut", "broken bone", "can't walk"
        ],
        "message": "⚠️ URGENT: Seek immediate medical care today"
    }
}

def check_emergency(text):
    """Check if symptoms indicate emergency"""
    text_lower = text.lower()
    
    # Check critical emergencies
    for keyword in EMERGENCY_SYMPTOMS["call_911"]["keywords"]:
        if keyword in text_lower:
            return {
                "is_emergency": True,
                "level": "critical",
                "message": EMERGENCY_SYMPTOMS["call_911"]["message"]
            }
    
    # Check urgent situations
    for keyword in EMERGENCY_SYMPTOMS["urgent_care"]["keywords"]:
        if keyword in text_lower:
            return {
                "is_emergency": True,
                "level": "urgent",
                "message": EMERGENCY_SYMPTOMS["urgent_care"]["message"]
            }
    
    return {"is_emergency": False, "level": "routine", "message": None}

# ============================================================================
# Probability Scoring Logic
# ============================================================================

def calculate_probability_weights(symptoms_data):
    """
    Calculate probability weights based on symptom combinations
    """
    weights = {}
    
    # Age factor
    age = int(symptoms_data.get('age', 25))
    if age < 18:
        weights['pediatric'] = 1.5
    elif age > 65:
        weights['geriatric'] = 1.5
    
    # Severity factor
    severity = int(symptoms_data.get('severity', 5))
    if severity >= 8:
        weights['urgent'] = 2.0
    elif severity >= 6:
        weights['moderate'] = 1.3
    
    # Duration factor
    duration = symptoms_data.get('duration', '')
    if 'month' in duration.lower():
        weights['chronic'] = 1.5
    elif 'hour' in duration.lower():
        weights['acute'] = 2.0
    
    return weights

# ============================================================================
# SYMPTOM COLLECTION FRAMEWORK
# ============================================================================

SYMPTOM_QUESTIONS = [
    {
        "id": "main_symptom",
        "question": "What is your main symptom or health concern?",
        "type": "text",
        "required": True
    },
    {
        "id": "duration",
        "question": "When did this symptom start?",
        "type": "choice",
        "options": [
            "Less than 24 hours ago",
            "1-3 days ago",
            "4-7 days ago",
            "1-4 weeks ago",
            "More than a month ago"
        ],
        "required": True
    },
    {
        "id": "severity",
        "question": "How would you rate the severity? (1=mild, 10=severe)",
        "type": "scale",
        "min": 1,
        "max": 10,
        "required": True
    },
    {
        "id": "additional_symptoms",
        "question": "Do you have any of these additional symptoms?",
        "type": "multiselect",
        "options": [
            "Fever", "Fatigue", "Nausea", "Vomiting", "Diarrhea",
            "Headache", "Cough", "Shortness of breath", "Dizziness",
            "Body aches", "Loss of appetite", "None of these"
        ],
        "required": False
    },
    {
        "id": "age",
        "question": "What is your age?",
        "type": "number",
        "required": True
    },
    {
        "id": "chronic_conditions",
        "question": "Do you have any chronic medical conditions? (e.g., diabetes, hypertension)",
        "type": "text",
        "required": False
    },
    {
        "id": "medications",
        "question": "Are you currently taking any medications?",
        "type": "text",
        "required": False
    }
]

# ============================================================================
# INITIALIZE COMPONENTS
# ============================================================================

embeddings = download_hugging_face_embeddings()
index_name = "medical-chatbot"

docsearch = PineconeVectorStore.from_existing_index(
    index_name=index_name,
    embedding=embeddings
)

retriever = docsearch.as_retriever(search_type="similarity", search_kwargs={"k": 8})

chatModel = ChatOpenAI(
    model="deepseek/deepseek-chat",
    openai_api_base="https://openrouter.ai/api/v1",
    openai_api_key=DEEPSEEK_API_KEY,
    temperature=0.3,
)

# ============================================================================
# DIFFERENTIAL DIAGNOSIS SYSTEM
# ============================================================================

def get_differential_diagnosis(symptoms_data):
    """
    Generate differential diagnosis with probabilities

    weights = calculate_probability_weights(symptoms_data)

    Args:
        symptoms_data: Dictionary with collected symptom information
    
    Returns:
        Structured differential diagnosis
    """
    
    # Create comprehensive symptom description
    symptom_description = f"""
Patient presents with:

Main Symptom: {symptoms_data.get('main_symptom', 'Not specified')}
Duration: {symptoms_data.get('duration', 'Not specified')}
Severity: {symptoms_data.get('severity', 'Not specified')}/10
Additional Symptoms: {', '.join(symptoms_data.get('additional_symptoms', []))}
Age: {symptoms_data.get('age', 'Not specified')}
Medical History: {symptoms_data.get('chronic_conditions', 'None reported')}
Current Medications: {symptoms_data.get('medications', 'None reported')}
"""
    
    # Detailed prompt for differential diagnosis
    differential_prompt = f"""
You are a medical information system providing educational differential diagnosis.

IMPORTANT FOR MY PROJECT:
- Consider patient is a young adult if age 18-30
- Emphasize common conditions for college students
- Include stress-related conditions

{symptom_description}

Provide a structured differential diagnosis with:

1. MOST LIKELY CONDITIONS (60-70% probability range):
   - List 2-3 most common conditions that match these symptoms
   - For each condition:
     * Why it matches the symptoms
     * Typical presentation
     * Expected duration
     * Self-care recommendations
     * When to see a doctor

2. POSSIBLE CONDITIONS (20-30% probability range):
   - List 2-3 other conditions to consider
   - Brief explanation for each

3. LESS LIKELY BUT SERIOUS (5-10% probability range):
   - List 1-2 serious conditions that shouldn't be missed
   - Red flags to watch for

4. CLINICAL RECOMMENDATION:
   - Urgency level (routine appointment, urgent care, or emergency)
   - Timeframe for seeking care
   - What diagnostic tests a doctor would likely order

5. WHAT TO MONITOR:
   - Warning signs that indicate worsening
   - When to seek immediate care

CRITICAL RULES:
- This is EDUCATIONAL information, NOT a diagnosis
- Use probability ranges, not exact percentages
- Consider patient age in recommendations
- Always recommend professional medical evaluation
- List conditions in order of likelihood
- Be thorough but concise

Format as structured JSON with clear sections.

CRITICAL OUTPUT RULES:
- Your ENTIRE response must be ONLY valid JSON
- Do NOT include any text before or after the JSON
- Do NOT use markdown code blocks (no ```)
- Do NOT start with "Here is..." or any preamble
- Start directly with {{ and end with }}
- Make sure the JSON is properly formatted

Respond with ONLY the JSON object, nothing else.
"""
    
    # Search relevant medical information
    relevant_docs = retriever.get_relevant_documents(symptom_description)
    context = "\n\n".join([doc.page_content for doc in relevant_docs[:8]])
    
    # Generate differential diagnosis
    full_prompt = f"{differential_prompt}\n\nMedical Context:\n{context}"
    
    response = chatModel.invoke(full_prompt)
    
    return response.content

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

def init_symptom_session():
    """Initialize new symptom collection session"""
    session['symptom_data'] = {}
    session['current_question'] = 0
    session['completed'] = False

def get_current_question():
    """Get current question in the flow"""
    question_index = session.get('current_question', 0)
    if question_index < len(SYMPTOM_QUESTIONS):
        return SYMPTOM_QUESTIONS[question_index]
    return None

def save_answer(question_id, answer):
    """Save answer to session"""
    if 'symptom_data' not in session:
        session['symptom_data'] = {}
    session['symptom_data'][question_id] = answer
    session.modified = True

def advance_question():
    """Move to next question"""
    session['current_question'] = session.get('current_question', 0) + 1
    session.modified = True

def advanced_emergency_check(symptoms_data):
    """
    Context-aware emergency detection
    """
    main_symptom = symptoms_data.get('main_symptom', '').lower()
    severity = int(symptoms_data.get('severity', 0))
    age = int(symptoms_data.get('age', 25))
    
    # High severity + certain symptoms
    if severity >= 9:
        if any(word in main_symptom for word in ['chest', 'breathe', 'dizzy']):
            return {
                'is_emergency': True,
                'level': 'critical',
                'reason': 'High severity with potentially serious symptoms'
            }
    
    # Age-specific emergencies
    if age < 3 and 'fever' in main_symptom:
        if any(word in main_symptom for word in ['high', 'very']):
            return {
                'is_emergency': True,
                'level': 'urgent',
                'reason': 'Infant with high fever'
            }
    
    # Combination warnings
    additional = symptoms_data.get('additional_symptoms', [])
    if 'Fever' in additional and 'Confusion' in additional:
        return {
            'is_emergency': True,
            'level': 'urgent',
            'reason': 'Fever with confusion - possible serious infection'
        }
    
    return {'is_emergency': False}
# ============================================================================
# ROUTES
# ============================================================================

@app.route("/")
def index():
    """Main page"""
    return render_template('symptom_checker.html')

@app.route("/start_assessment", methods=["POST"])
def start_assessment():
    """Start new symptom assessment"""
    init_symptom_session()
    first_question = get_current_question()
    
    return jsonify({
        "status": "started",
        "question": first_question
    })

@app.route("/submit_answer", methods=["POST"])
def submit_answer():
    """Submit answer and get next question"""
    data = request.json
    answer = data.get('answer')
    question_id = data.get('question_id')
    
    # Check for emergency in free text
    if isinstance(answer, str):
        emergency_check = check_emergency(answer)
        if emergency_check['is_emergency']:
            return jsonify({
                "status": "emergency",
                "emergency": emergency_check
            })
    
    # Save answer
    save_answer(question_id, answer)
    
    # Move to next question
    advance_question()
    
    # Check if assessment complete
    next_question = get_current_question()
    
    if next_question is None:
        # All questions answered - generate diagnosis
        session['completed'] = True
        return jsonify({
            "status": "complete",
            "message": "Assessment complete. Generating analysis..."
        })
    else:
        return jsonify({
            "status": "continue",
            "question": next_question
        })

@app.route("/get_diagnosis", methods=["POST"])
def get_diagnosis():
    """Generate differential diagnosis"""
    
    if not session.get('completed'):
        return jsonify({"error": "Assessment not complete"}), 400
    
    symptom_data = session.get('symptom_data', {})
    
    # Check for emergencies one more time
    main_symptom = symptom_data.get('main_symptom', '')
    emergency_check = check_emergency(main_symptom)
    
    if emergency_check['is_emergency']:
        return jsonify({
            "status": "emergency",
            "emergency": emergency_check
        })
    
    # Generate differential diagnosis
    try:
        diagnosis = get_differential_diagnosis(symptom_data)
        
        return jsonify({
            "status": "success",
            "diagnosis": diagnosis,
            "disclaimer": get_medical_disclaimer()
        })
    
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": "Error generating diagnosis. Please try again."
        }), 500

@app.route("/reset", methods=["POST"])
def reset():
    """Reset assessment"""
    init_symptom_session()
    return jsonify({"status": "reset"})

@app.route("/health")
def health():
    """Health check"""
    return jsonify({"status": "healthy", "service": "symptom-checker"})

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def get_medical_disclaimer():
    """Medical disclaimer text"""
    return """
⚕️ MEDICAL DISCLAIMER

This is an EDUCATIONAL tool providing general information only. It does NOT:
• Diagnose medical conditions
• Provide medical advice  
• Replace consultation with healthcare providers
• Handle medical emergencies

FOR EMERGENCIES: Call 911 or go to emergency room

This information is based on general medical knowledge and should not be used 
as a substitute for professional medical evaluation. Always consult a qualified 
healthcare provider for proper diagnosis and treatment.

The probabilities and recommendations provided are estimates based on typical 
presentations and should not be considered definitive.
"""

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
    PORT = int(os.getenv('PORT', 8080))
    
    app.run(
        host="0.0.0.0",
        port=PORT,
        debug=DEBUG
    )