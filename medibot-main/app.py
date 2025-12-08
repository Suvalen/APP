"""
Combined Medical Chatbot + Symptom Checker
==========================================
Features:
- Chat with AI (Option 1): /get, /clear
- Symptom Checker (Option 3): /start_assessment, /submit_answer, /get_diagnosis
- Shared knowledge base (60,000+ medical chunks)
- Single Flask app on port 8080
"""

from flask import Flask, render_template, jsonify, request, session
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from src.helper import download_hugging_face_embeddings
from langchain_pinecone import PineconeVectorStore
from langchain_openai import ChatOpenAI
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains.history_aware_retriever import create_history_aware_retriever
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
from dotenv import load_dotenv
from src.prompt import system_prompt, contextualize_q_system_prompt
import os
import logging
from datetime import timedelta
import json

# ============================================================================
# CONFIGURATION
# ============================================================================

load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================================
# FLASK APP INITIALIZATION
# ============================================================================

app = Flask(__name__)

# Security configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-change-this')
app.config['SESSION_TYPE'] = 'filesystem'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=24)

# CORS - Allow Flutter to connect
CORS(app, resources={r"/*": {"origins": "*"}})

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    return response

# Rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://"
)

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
DEEPSEEK_API_KEY = os.getenv('DEEPSEEK_API_KEY')

if not PINECONE_API_KEY:
    logger.error("PINECONE_API_KEY not found!")
    raise ValueError("Missing PINECONE_API_KEY")

if not DEEPSEEK_API_KEY:
    logger.error("DEEPSEEK_API_KEY not found!")
    raise ValueError("Missing DEEPSEEK_API_KEY")

os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["DEEPSEEK_API_KEY"] = DEEPSEEK_API_KEY

# ============================================================================
# INITIALIZE SHARED COMPONENTS
# ============================================================================

try:
    logger.info("Loading embeddings...")
    embeddings = download_hugging_face_embeddings()
    
    logger.info("Connecting to Pinecone...")
    index_name = "medical-chatbot"
    docsearch = PineconeVectorStore.from_existing_index(
        index_name=index_name,
        embedding=embeddings
    )
    
    logger.info("Setting up retriever...")
    retriever = docsearch.as_retriever(
        search_type="similarity", 
        search_kwargs={"k": 5}
    )
    
    logger.info("Initializing LLM...")
    chatModel = ChatOpenAI(
        model="deepseek/deepseek-chat",
        openai_api_base="https://openrouter.ai/api/v1",
        openai_api_key=DEEPSEEK_API_KEY,
        temperature=0.4,
    )
    
    # ============================================================================
    # CHAT CONVERSATION MEMORY SETUP (Option 1)
    # ============================================================================
    
    logger.info("Setting up chat conversation memory...")
    
    contextualize_q_prompt = ChatPromptTemplate.from_messages([
        ("system", contextualize_q_system_prompt),
        MessagesPlaceholder("chat_history"),
        ("human", "{input}"),
    ])
    
    history_aware_retriever = create_history_aware_retriever(
        chatModel, retriever, contextualize_q_prompt
    )
    
    qa_prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        MessagesPlaceholder("chat_history"),
        ("human", "{input}"),
    ])
    
    question_answer_chain = create_stuff_documents_chain(chatModel, qa_prompt)
    rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)
    
    logger.info("✓ All components initialized successfully!")
    
except Exception as e:
    logger.error(f"Failed to initialize components: {e}")
    raise

# ============================================================================
# SYMPTOM CHECKER CONFIGURATION (Option 3)
# ============================================================================

ASSESSMENT_QUESTIONS = [
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
        "question": "On a scale of 1-10, how severe is this symptom?",
        "type": "scale",
        "min": 1,
        "max": 10,
        "required": True
    },
    {
        "id": "additional_symptoms",
        "question": "Are you experiencing any of these additional symptoms?",
        "type": "multiselect",
        "options": [
            "Fever",
            "Fatigue",
            "Nausea",
            "Vomiting",
            "Diarrhea",
            "Headache",
            "Cough",
            "Shortness of breath",
            "Dizziness",
            "Body aches",
            "Loss of appetite"
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
        "question": "Do you have any chronic medical conditions?",
        "type": "text",
        "placeholder": "e.g., diabetes, hypertension, asthma (or 'None')",
        "required": False
    },
    {
        "id": "medications",
        "question": "Are you currently taking any medications?",
        "type": "text",
        "placeholder": "e.g., aspirin, blood pressure medication (or 'None')",
        "required": False
    }
]

EMERGENCY_KEYWORDS = [
    "chest pain", "heart attack", "stroke", "can't breathe", "cannot breathe",
    "difficulty breathing", "severe bleeding", "unconscious", "seizure",
    "suicidal", "suicide", "want to die", "overdose", "poisoning",
    "severe allergic", "anaphylaxis", "choking", "drowning",
    "severe head injury", "loss of consciousness", "paralysis",
    "coughing blood", "vomiting blood", "severe abdominal pain"
]

SYMPTOM_CHECKER_PROMPT = """You are a medical symptom analysis assistant. Based on the patient information provided, generate a differential diagnosis.

IMPORTANT RULES:
1. This is for EDUCATIONAL purposes only
2. Always recommend consulting a healthcare professional
3. Never diagnose definitively - only suggest possibilities
4. Flag any emergency symptoms immediately

Patient Information:
{patient_info}

Relevant Medical Knowledge:
{context}

Please provide your analysis in the following JSON format:
{{
  "differential_diagnosis": {{
    "most_likely_conditions": [
      {{
        "condition": "Name of condition",
        "why_it_matches": "Brief explanation of matching symptoms",
        "typical_presentation": "How this condition typically presents",
        "expected_duration": "Typical duration",
        "self_care": "Self-care recommendations",
        "when_to_see_doctor": "When to seek medical attention"
      }}
    ],
    "possible_conditions": [
      {{
        "condition": "Name",
        "explanation": "Why it's possible"
      }}
    ],
    "less_likely_but_serious": [
      {{
        "condition": "Name",
        "red_flags": "Warning signs to watch for"
      }}
    ],
    "clinical_recommendation": {{
      "urgency_level": "Routine/Urgent/Emergency",
      "timeframe": "When to seek care",
      "diagnostic_tests": ["List of likely tests"]
    }},
    "what_to_monitor": {{
      "warning_signs": ["Signs that need immediate attention"],
      "when_to_seek_immediate_care": "Specific guidance"
    }}
  }}
}}

Provide 2-3 conditions in each category based on the symptoms."""

# ============================================================================
# HELPER FUNCTIONS - CHAT (Option 1)
# ============================================================================

def get_chat_history():
    """Get chat history from session"""
    if 'messages' not in session:
        session['messages'] = []
    
    chat_history = []
    for msg in session['messages']:
        if msg['role'] == 'user':
            chat_history.append(HumanMessage(content=msg['content']))
        else:
            chat_history.append(AIMessage(content=msg['content']))
    
    return chat_history

def update_chat_history(user_message, bot_message):
    """Update chat history in session"""
    if 'messages' not in session:
        session['messages'] = []
    
    session['messages'].append({'role': 'user', 'content': user_message})
    session['messages'].append({'role': 'assistant', 'content': bot_message})
    session['messages'] = session['messages'][-20:]
    session.modified = True

def validate_message(msg):
    """Validate user input"""
    if not msg:
        return False, "Message cannot be empty"
    if len(msg) > 1000:
        return False, "Message too long (max 1000 characters)"
    if len(msg.strip()) < 2:
        return False, "Message too short"
    return True, None

# ============================================================================
# HELPER FUNCTIONS - SYMPTOM CHECKER (Option 3)
# ============================================================================

def check_emergency(text):
    """Check for emergency symptoms"""
    text_lower = text.lower()
    for keyword in EMERGENCY_KEYWORDS:
        if keyword in text_lower:
            return True, keyword
    return False, None

def format_patient_info(answers):
    """Format patient answers for the LLM"""
    info_parts = []
    
    if 'age' in answers:
        info_parts.append(f"Age: {answers['age']}")
    
    if 'main_symptom' in answers:
        info_parts.append(f"Main Symptom: {answers['main_symptom']}")
    
    if 'duration' in answers:
        info_parts.append(f"Duration: {answers['duration']}")
    
    if 'severity' in answers:
        info_parts.append(f"Severity: {answers['severity']}/10")
    
    if 'additional_symptoms' in answers and answers['additional_symptoms']:
        symptoms = answers['additional_symptoms']
        if isinstance(symptoms, list):
            info_parts.append(f"Additional Symptoms: {', '.join(symptoms)}")
        else:
            info_parts.append(f"Additional Symptoms: {symptoms}")
    
    if 'chronic_conditions' in answers and answers['chronic_conditions']:
        info_parts.append(f"Chronic Conditions: {answers['chronic_conditions']}")
    
    if 'medications' in answers and answers['medications']:
        info_parts.append(f"Current Medications: {answers['medications']}")
    
    return "\n".join(info_parts)

# ============================================================================
# ROUTES - GENERAL
# ============================================================================

@app.route("/")
def index():
    """Render main page"""
    try:
        return render_template('chat.html')
    except Exception as e:
        logger.error(f"Error rendering template: {e}")
        return jsonify({"error": "Template not found"}), 500

@app.route("/health")
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "services": ["chat", "symptom-checker"],
        "version": "2.0.0"
    })

# ============================================================================
# ROUTES - CHAT (Option 1)
# ============================================================================

@app.route("/get", methods=["POST"])
@limiter.limit("30 per minute")
def chat():
    """Handle chat requests with conversation memory"""
    try:
        msg = request.form.get("msg", "").strip()
        
        is_valid, error_msg = validate_message(msg)
        if not is_valid:
            logger.warning(f"Invalid message: {error_msg}")
            return jsonify({"error": error_msg}), 400
        
        logger.info(f"Chat received: {msg[:50]}...")
        
        chat_history = get_chat_history()
        
        response = rag_chain.invoke({
            "input": msg,
            "chat_history": chat_history
        })
        
        answer = response["answer"]
        
        disclaimer = "\n\n⚕️ Disclaimer: This is AI-generated information. Always consult a qualified healthcare professional for medical advice."
        full_answer = answer + disclaimer
        
        update_chat_history(msg, answer)
        
        logger.info(f"Chat response: {answer[:50]}...")
        
        return jsonify({
            "answer": full_answer,
            "conversation_length": len(session.get('messages', []))
        })
        
    except Exception as e:
        logger.error(f"Chat error: {e}", exc_info=True)
        return jsonify({"error": "An error occurred processing your request"}), 500

@app.route("/clear", methods=["POST"])
def clear_conversation():
    """Clear chat conversation history"""
    try:
        session['messages'] = []
        logger.info("Chat conversation cleared")
        return jsonify({"status": "success", "message": "Conversation cleared"})
    except Exception as e:
        logger.error(f"Error clearing conversation: {e}")
        return jsonify({"error": "Failed to clear conversation"}), 500

# ============================================================================
# ROUTES - SYMPTOM CHECKER (Option 3)
# ============================================================================

@app.route("/symptom-checker")
def symptom_checker():
    """Render symptom checker page"""
    try:
        return render_template('symptom_checker.html')
    except Exception as e:
        logger.error(f"Error rendering symptom checker: {e}")
        return jsonify({"error": "Template not found"}), 500

@app.route("/start_assessment", methods=["POST"])
def start_assessment():
    """Start a new symptom assessment"""
    try:
        # Initialize assessment session
        session['assessment'] = {
            'answers': {},
            'current_question': 0,
            'started': True
        }
        session.modified = True
        
        logger.info("Symptom assessment started")
        
        return jsonify({
            "status": "started",
            "message": "Assessment started",
            "question": ASSESSMENT_QUESTIONS[0],
            "total_questions": len(ASSESSMENT_QUESTIONS)
        })
        
    except Exception as e:
        logger.error(f"Error starting assessment: {e}")
        return jsonify({"error": "Failed to start assessment"}), 500

@app.route("/submit_answer", methods=["POST"])
def submit_answer():
    """Submit an answer to the current question"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        question_id = data.get('question_id')
        answer = data.get('answer')
        
        if not question_id:
            return jsonify({"error": "Missing question_id"}), 400
        
        # Initialize assessment if needed
        if 'assessment' not in session:
            session['assessment'] = {
                'answers': {},
                'current_question': 0,
                'started': True
            }
        
        # Check for emergency (on main symptom)
        if question_id == 'main_symptom' and answer:
            is_emergency, keyword = check_emergency(str(answer))
            if is_emergency:
                logger.warning(f"Emergency detected: {keyword}")
                return jsonify({
                    "status": "emergency",
                    "emergency": {
                        "detected": True,
                        "keyword": keyword,
                        "message": f"⚠️ EMERGENCY: Your symptom '{keyword}' may require immediate medical attention. Please call emergency services (911) or go to the nearest emergency room immediately.",
                        "action": "CALL 911 OR GO TO ER"
                    }
                })
        
        # Store the answer
        session['assessment']['answers'][question_id] = answer
        session['assessment']['current_question'] += 1
        session.modified = True
        
        current_idx = session['assessment']['current_question']
        
        # Check if assessment is complete
        if current_idx >= len(ASSESSMENT_QUESTIONS):
            return jsonify({
                "status": "complete",
                "message": "All questions answered",
                "answers": session['assessment']['answers']
            })
        
        # Return next question
        return jsonify({
            "status": "continue",
            "question": ASSESSMENT_QUESTIONS[current_idx],
            "progress": current_idx / len(ASSESSMENT_QUESTIONS),
            "current": current_idx + 1,
            "total": len(ASSESSMENT_QUESTIONS)
        })
        
    except Exception as e:
        logger.error(f"Error submitting answer: {e}", exc_info=True)
        return jsonify({"error": "Failed to submit answer"}), 500

@app.route("/get_diagnosis", methods=["POST"])
def get_diagnosis():
    """Generate differential diagnosis based on collected symptoms"""
    try:
        # Try to get answers from request body first (Flutter)
        data = request.get_json()
        
        if data and 'answers' in data:
            answers = data['answers']
        elif 'assessment' in session and session['assessment'].get('answers'):
            # Fallback to session (web version)
            answers = session['assessment']['answers']
        else:
            return jsonify({"error": "No assessment data found. Please provide answers."}), 400
        
        logger.info(f"Generating diagnosis for: {answers}")
        
        # Format patient information
        patient_info = format_patient_info(answers)
        
        # Get relevant medical context from RAG
        main_symptom = answers.get('main_symptom', '')
        additional = answers.get('additional_symptoms', [])
        
        search_query = f"{main_symptom} {' '.join(additional) if isinstance(additional, list) else additional}"
        
        docs = retriever.invoke(search_query)
        context = "\n\n".join([doc.page_content for doc in docs])
        
        # Generate diagnosis using LLM
        diagnosis_prompt = SYMPTOM_CHECKER_PROMPT.format(
            patient_info=patient_info,
            context=context
        )
        
        response = chatModel.invoke(diagnosis_prompt)
        diagnosis = response.content
        
        # Add disclaimer
        disclaimer = """

⚕️ MEDICAL DISCLAIMER

This is an EDUCATIONAL tool only and does NOT provide medical diagnoses.

- This assessment is NOT a substitute for professional medical advice
- Always consult a qualified healthcare provider for medical concerns
- If experiencing severe symptoms, seek emergency care immediately
- The information provided is based on general medical knowledge
- Individual cases may vary significantly

Please consult a healthcare professional for proper evaluation."""
        
        logger.info("Diagnosis generated successfully")
        
        # Clear assessment session if exists
        session.pop('assessment', None)
        session.modified = True
        
        return jsonify({
            "status": "success",
            "diagnosis": diagnosis,
            "disclaimer": disclaimer,
            "patient_summary": patient_info
        })
        
    except Exception as e:
        logger.error(f"Error generating diagnosis: {e}", exc_info=True)
        return jsonify({"error": "Failed to generate diagnosis"}), 500

@app.route("/get_questions", methods=["GET"])
def get_questions():
    """Get all assessment questions (for Flutter)"""
    return jsonify({
        "questions": ASSESSMENT_QUESTIONS,
        "total": len(ASSESSMENT_QUESTIONS)
    })

# ============================================================================
# API ROUTES (For mobile app - JSON format)
# ============================================================================

@app.route("/api/chat", methods=["POST"])
@limiter.limit("30 per minute")
def api_chat():
    """API endpoint for chat (JSON request/response)"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "Invalid JSON"}), 400
        
        msg = data.get("message", "").strip()
        
        is_valid, error_msg = validate_message(msg)
        if not is_valid:
            return jsonify({"error": error_msg}), 400
        
        chat_history = get_chat_history()
        
        response = rag_chain.invoke({
            "input": msg,
            "chat_history": chat_history
        })
        
        answer = response["answer"]
        update_chat_history(msg, answer)
        
        return jsonify({
            "answer": answer,
            "disclaimer": "This is AI-generated information. Always consult a qualified healthcare professional.",
            "conversation_length": len(session.get('messages', []))
        })
        
    except Exception as e:
        logger.error(f"API chat error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(429)
def ratelimit_handler(e):
    """Handle rate limit exceeded"""
    logger.warning(f"Rate limit exceeded: {request.remote_addr}")
    return jsonify({
        "error": "Rate limit exceeded. Please try again later."
    }), 429

@app.errorhandler(500)
def internal_error(e):
    """Handle internal server errors"""
    logger.error(f"Internal server error: {e}")
    return jsonify({
        "error": "Internal server error. Please try again later."
    }), 500

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 8080))
    
    logger.info("=" * 50)
    logger.info("COMBINED MEDICAL ASSISTANT")
    logger.info("=" * 50)
    logger.info(f"Chat Endpoint: POST /get")
    logger.info(f"Symptom Checker: POST /start_assessment, /submit_answer, /get_diagnosis")
    logger.info(f"Health Check: GET /health")
    logger.info("=" * 50)
    logger.info(f"Starting server on {HOST}:{PORT}")
    
    app.run(
        host=HOST,
        port=PORT,
        debug=DEBUG
    )