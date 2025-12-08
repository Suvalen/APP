"""
Fixed Helper Functions for Medical Chatbot
==========================================
Changes:
✓ Fixed deprecated imports
✓ Improved chunk size (500 → 1000)
✓ Better chunk overlap (20 → 200)
✓ Added error handling
✓ Added logging
✓ Better documentation
"""

from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings  # Fixed: updated import
from typing import List
from langchain.schema import Document
import logging

logger = logging.getLogger(__name__)


def load_pdf_file(data: str) -> List[Document]:
    """
    Extract data from PDF files in a directory
    
    Args:
        data: Path to directory containing PDF files
        
    Returns:
        List of Document objects
        
    Raises:
        FileNotFoundError: If directory doesn't exist
        ValueError: If no PDFs found
    """
    try:
        logger.info(f"Loading PDFs from {data}...")
        
        loader = DirectoryLoader(
            data,
            glob="*.pdf",
            loader_cls=PyPDFLoader,
            show_progress=True,
            use_multithreading=True  # Faster loading
        )
        
        documents = loader.load()
        
        if not documents:
            raise ValueError(f"No PDF files found in {data}")
        
        logger.info(f"✓ Loaded {len(documents)} pages from PDFs")
        return documents
        
    except FileNotFoundError:
        logger.error(f"Directory not found: {data}")
        raise
    except Exception as e:
        logger.error(f"Error loading PDFs: {e}")
        raise


def filter_to_minimal_docs(docs: List[Document]) -> List[Document]:
    """
    Filter documents to keep only source metadata
    
    This reduces memory usage by removing unnecessary metadata fields
    while preserving the source information for attribution.
    
    Args:
        docs: List of Document objects with full metadata
        
    Returns:
        List of Document objects with minimal metadata
    """
    try:
        logger.info("Filtering documents to minimal metadata...")
        
        minimal_docs: List[Document] = []
        for doc in docs:
            src = doc.metadata.get("source", "unknown")
            minimal_docs.append(
                Document(
                    page_content=doc.page_content,
                    metadata={"source": src}
                )
            )
        
        logger.info(f"✓ Filtered {len(minimal_docs)} documents")
        return minimal_docs
        
    except Exception as e:
        logger.error(f"Error filtering documents: {e}")
        raise


def text_split(extracted_data: List[Document]) -> List[Document]:
    """
    Split documents into text chunks for vector embedding
    
    IMPROVED: Larger chunks (1000 vs 500) preserve more medical context
    IMPROVED: Better overlap (200 vs 20) ensures continuity
    
    Args:
        extracted_data: List of Document objects to split
        
    Returns:
        List of Document chunks
    """
    try:
        logger.info("Splitting documents into chunks...")
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,          # IMPROVED: from 500
            chunk_overlap=200,        # IMPROVED: from 20
            separators=["\n\n", "\n", ". ", " ", ""],
            length_function=len
        )
        
        text_chunks = text_splitter.split_documents(extracted_data)
        
        logger.info(f"✓ Created {len(text_chunks)} text chunks")
        return text_chunks
        
    except Exception as e:
        logger.error(f"Error splitting text: {e}")
        raise


def download_hugging_face_embeddings():
    """
    Download and initialize HuggingFace embeddings model
    
    Model: sentence-transformers/all-MiniLM-L6-v2
    - Dimensions: 384
    - Speed: Fast
    - Quality: Good for general purpose
    - Cost: Free
    
    For better medical accuracy, consider:
    - sentence-transformers/all-mpnet-base-v2 (768 dims)
    - emilyalsentzer/Bio_ClinicalBERT (medical-specific)
    
    Returns:
        HuggingFaceEmbeddings object
    """
    try:
        logger.info("Loading HuggingFace embeddings model...")
        
        embeddings = HuggingFaceEmbeddings(
            model_name='sentence-transformers/all-MiniLM-L6-v2',
            model_kwargs={'device': 'cpu'},  # Use 'cuda' if GPU available
            encode_kwargs={'normalize_embeddings': True}
        )
        
        logger.info("✓ Embeddings model loaded successfully")
        return embeddings
        
    except Exception as e:
        logger.error(f"Error loading embeddings: {e}")
        raise


# ============================================================================
# ADDITIONAL HELPER FUNCTIONS
# ============================================================================

def get_embedding_stats(embeddings) -> dict:
    """
    Get statistics about the embedding model
    
    Returns:
        Dictionary with model information
    """
    try:
        # Get model dimension by embedding a test string
        test_embedding = embeddings.embed_query("test")
        
        return {
            "model_name": embeddings.model_name,
            "dimensions": len(test_embedding),
            "device": embeddings.model_kwargs.get('device', 'unknown')
        }
    except Exception as e:
        logger.error(f"Error getting embedding stats: {e}")
        return {}


def validate_documents(docs: List[Document]) -> bool:
    """
    Validate that documents are properly formatted
    
    Args:
        docs: List of documents to validate
        
    Returns:
        True if valid, False otherwise
    """
    if not docs:
        logger.warning("Empty document list")
        return False
    
    for i, doc in enumerate(docs):
        if not doc.page_content or len(doc.page_content.strip()) == 0:
            logger.warning(f"Document {i} has empty content")
            return False
        
        if not isinstance(doc.metadata, dict):
            logger.warning(f"Document {i} has invalid metadata")
            return False
    
    return True


def estimate_token_count(text: str) -> int:
    """
    Rough estimate of token count for cost calculation
    
    Args:
        text: Text to estimate
        
    Returns:
        Estimated token count (rough: 1 token ≈ 4 characters)
    """
    return len(text) // 4


def summarize_documents(docs: List[Document]) -> dict:
    """
    Generate summary statistics for a document list
    
    Returns:
        Dictionary with summary stats
    """
    total_chars = sum(len(doc.page_content) for doc in docs)
    total_tokens = estimate_token_count(''.join(doc.page_content for doc in docs))
    
    return {
        "total_documents": len(docs),
        "total_characters": total_chars,
        "estimated_tokens": total_tokens,
        "avg_chars_per_doc": total_chars // len(docs) if docs else 0,
        "sources": len(set(doc.metadata.get('source', 'unknown') for doc in docs))
    }


# ============================================================================
# USAGE EXAMPLE
# ============================================================================

if __name__ == "__main__":
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    # Load PDFs
    # documents = load_pdf_file("data/")
    
    # Filter metadata
    # filtered = filter_to_minimal_docs(documents)
    
    # Split into chunks
    # chunks = text_split(filtered)
    
    # Get embeddings
    # embeddings = download_hugging_face_embeddings()
    
    # Get stats
    # stats = summarize_documents(chunks)
    # print(stats)
    
    print("Helper functions ready!")