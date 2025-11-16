# pip install -U "langchain" "langchain-openai" "langchain-community" "python-dotenv" "psycopg2-binary" "sqlalchemy" "fastapi" "uvicorn[standard]"

import os
import uuid
from urllib.parse import quote_plus
from typing import Optional, Dict, List
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException  # pyright: ignore[reportMissingImports]
from fastapi.middleware.cors import CORSMiddleware  # pyright: ignore[reportMissingImports]
from pydantic import BaseModel


from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langchain_community.utilities.sql_database import SQLDatabase
from langchain_community.agent_toolkits.sql.base import SQLDatabaseToolkit
from langchain.tools import tool

# Load environment variables
load_dotenv()

# PostgreSQL + OpenAI setup
# Prefer environment variables; fall back to your provided local values
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS_RAW = os.getenv("DB_PASS", "@POSTGRES_9")  # contains '@' which must be URL-encoded
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nbfc_db")

# Safely URL-encode password so special characters like '@' don't break the URI
DB_PASS = quote_plus(DB_PASS_RAW)

DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Initialize SQL + LLM
db = SQLDatabase.from_uri(DB_URI)
llm = ChatOpenAI(model="gpt-4o", temperature=0)

# SQL Toolkit   
toolkit = SQLDatabaseToolkit(db=db, llm=llm)
sql_tools = toolkit.get_tools()

# Custom tool
@tool("ping_sales_team", return_direct=True)
def ping_sales_team(lead_id: str, message: str) -> str:
    """Send a message to the sales team about a specific lead."""
    return f"TOOL CALLED: 📨 Sales team notified for Lead {lead_id}: {message}"

# Agent System Prompt
SYSTEM_PROMPT = """
You are NBFC AI Assistant — an intelligent assistant for an NBFC sales and loan team.

You can:
- Query and analyze lead or loan data from the PostgreSQL database.
- Retrieve insights like top leads, rejected applications, or pending approvals.
- Ping the sales team for follow-ups or alerts.

When the user asks:
1. Use SQL tools for any data query.
2. Use 'ping_sales_team' when they ask to alert or message sales.
3. Respond in a business-style, structured tone with clear insights.

Here is the schema of the database (dbdiagram.io syntax):
/////////////////////////////////////////////////////////////
// 🏦 NBFC Loan Origination System (POC)
/////////////////////////////////////////////////////////////

Enum loan_stage_enum {
  KYC
  DDE
  CREDIT
  SANCTION
  DISBURSAL
  POST_DISBURSAL
  CLOSED
}

Enum lead_source_enum {
  DSA
  BRANCH
  REFERRAL
  CHATBOT
  DIGITAL_AD
}

Enum participant_role_enum {
  APPLICANT
  CO_APPLICANT
  GUARANTOR
}

/////////////////////////////////////////////////////////////
// 👤 Customers
/////////////////////////////////////////////////////////////

Table customers {
  id uuid [pk]
  full_name varchar(100)
  mobile_number varchar(15)
  email varchar(100)
  pan_number varchar(10)
  aadhaar_number varchar(12)
  cibil_score int
  monthly_income numeric(12,2)
  created_at timestamp [default: `now()`]
}

/////////////////////////////////////////////////////////////
// 🏦 Customer Banking Details
/////////////////////////////////////////////////////////////

Table customer_bank_details {
  id uuid [pk]
  customer_id uuid [ref: > customers.id]
  bank_name varchar(100)
  account_number varchar(20)
  ifsc_code varchar(11)
  account_type varchar(20) // e.g., SAVINGS, CURRENT
  is_primary boolean [default: true]
  created_at timestamp [default: `now()`]
}

/////////////////////////////////////////////////////////////
// 🧾 Loan Leads
/////////////////////////////////////////////////////////////

Table loan_leads {
  id uuid [pk]
  unique_identifier varchar(100)
  product_type varchar(10) // LAP, HL, PL
  loan_amount_requested numeric(15,2)
  loan_tenure_months int
  loan_purpose_desc text
  lead_source lead_source_enum
  status varchar(20) [default: 'new']
  created_at timestamp [default: `now()`]
}

/////////////////////////////////////////////////////////////
// 🗂️ Loan Applications
/////////////////////////////////////////////////////////////

Table loan_applications {
  id uuid [pk]
  lead_id uuid [ref: > loan_leads.id]
  branch_name varchar(100)
  sanction_amount numeric(15,2)
  stage loan_stage_enum [default: 'KYC']
  status varchar(20) [default: 'in-process']
  disbursal_account_id uuid [ref: > customer_bank_details.id, note: 'Funds credited to this account']
  created_at timestamp [default: `now()`]
  updated_at timestamp [default: `now()`]
}

/////////////////////////////////////////////////////////////
// 👥 Loan Participants
/////////////////////////////////////////////////////////////

Table loan_participants {
  id uuid [pk]
  application_id uuid [ref: > loan_applications.id]
  customer_id uuid [ref: > customers.id]
  role participant_role_enum
}

/////////////////////////////////////////////////////////////
// 📘 Loan Accounts (Post-Disbursal)
/////////////////////////////////////////////////////////////

Table loan_accounts {
  id uuid [pk]
  application_id uuid [ref: > loan_applications.id]
  loan_number varchar(20)
  disbursed_amount numeric(15,2)
  interest_rate numeric(5,2)
  start_date date
  end_date date
  current_balance numeric(15,2)
}

/////////////////////////////////////////////////////////////
// 💸 Loan Repayments
/////////////////////////////////////////////////////////////

Table loan_repayments {
  id uuid [pk]
  account_id uuid [ref: > loan_accounts.id]
  due_date date
  paid_date date
  amount_due numeric(15,2)
  amount_paid numeric(15,2)
  status varchar(20) [default: 'pending']
}

/////////////////////////////////////////////////////////////
// 🧩 Relationships Summary
// customers 1 - * customer_bank_details
// customers 1 - * loan_participants
// loan_leads 1 - * loan_applications
// loan_applications 1 - * loan_participants
// loan_applications 1 - 1 loan_accounts
// loan_applications 1 - 1 disbursal_account_id (customer bank account)
// loan_accounts 1 - * loan_repayments
/////////////////////////////////////////////////////////////
"""

# Create agent
agent = create_agent(
    model="gpt-4o",
    tools=sql_tools + [ping_sales_team],
    system_prompt=SYSTEM_PROMPT.strip(),
)

# FastAPI app
app = FastAPI(
    title="NBFC AI Assistant API",
    description="AI assistant for NBFC sales and loan teams with SQL query capabilities",
    version="1.0.0"
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory session storage (in production, use Redis or a database)
sessions: Dict[str, List[Dict[str, str]]] = {}

# Pydantic models for request/response
class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    session_id: str

class HealthResponse(BaseModel):
    status: str
    message: str

@app.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint with API information."""
    return {
        "status": "ok",
        "message": "NBFC AI Assistant API is running. Use /docs for API documentation."
    }

@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return {
        "status": "ok",
        "message": "Service is healthy"
    }

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Send a message to the AI assistant.
    
    - **message**: The user's message/question
    - **session_id**: Optional session ID to maintain conversation history. 
      If not provided, a new session will be created.
    """
    try:
        # Get or create session
        session_id = request.session_id or str(uuid.uuid4())
        
        # Initialize chat history for new sessions
        if session_id not in sessions:
            sessions[session_id] = [{"role": "system", "content": SYSTEM_PROMPT.strip()}]
        
        chat_history = sessions[session_id]
        
        # Add user message to history
        chat_history.append({"role": "user", "content": request.message})
        
        # Invoke agent
        response = agent.invoke({"messages": chat_history})
        output = response["messages"][-1].content
        
        # Add assistant response to history
        chat_history.append({"role": "assistant", "content": output})
        
        # Update session
        sessions[session_id] = chat_history
        
        return ChatResponse(response=output, session_id=session_id)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}")

@app.delete("/chat/{session_id}")
async def clear_session(session_id: str):
    """Clear chat history for a specific session."""
    if session_id in sessions:
        del sessions[session_id]
        return {"status": "ok", "message": f"Session {session_id} cleared"}
    else:
        raise HTTPException(status_code=404, detail="Session not found")

if __name__ == "__main__":
    import uvicorn
    
    # Get port from environment variable or default to 8000
    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    
    print(f"\n🚀 Starting NBFC AI Assistant API server...")
    print(f"📍 Server running on http://127.0.0.1:{port} (localhost)")
    print(f"📚 API Documentation: http://127.0.0.1:{port}/docs")
    print(f"🔍 Alternative Docs: http://127.0.0.1:{port}/redoc")
    print(f"❤️  Health Check: http://127.0.0.1:{port}/health\n")
    
    uvicorn.run(app, host=host, port=port)

