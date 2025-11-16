from fastapi import APIRouter, File, UploadFile, HTTPException
from pydantic import BaseModel

from agents.nbfc_agent import process_message

router = APIRouter()

class VoiceResponse(BaseModel):
    text: str
    reply: str
    session_id: str


@router.post("/", response_model=VoiceResponse)
async def voice_endpoint(file: UploadFile = File(...), session_id: str | None = None):
    try:
        # TODO: Replace this with Whisper or your STT model
        text = "Dummy transcription: Implement STT here"

        reply, new_session_id = process_message(text, session_id)

        return VoiceResponse(
            text=text,
            reply=reply,
            session_id=new_session_id
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
