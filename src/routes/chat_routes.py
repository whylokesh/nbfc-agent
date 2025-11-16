from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from src.agents.nbfc_agent import process_message, clear_session

router = APIRouter()

# --- Pydantic Models ---
class ChatRequest(BaseModel):
    message: str
    session_id: str | None = None

class ChatResponse(BaseModel):
    response: str
    session_id: str


# --- Routes ---
@router.post("/", response_model=ChatResponse)
async def chat(req: ChatRequest):
    try:
        output, session_id = process_message(req.message, req.session_id)
        return ChatResponse(response=output, session_id=session_id)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{session_id}")
async def delete_session(session_id: str):
    if clear_session(session_id):
        return {"status": "ok", "message": f"Session {session_id} cleared"}

    raise HTTPException(status_code=404, detail="Session not found")
