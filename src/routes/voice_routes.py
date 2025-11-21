import time
from pathlib import Path
import base64
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel

from src.agents.nbfc_agent import process_message
from src.services.elevenlabs import speech_to_text, text_to_speech

router = APIRouter()

# Directory Setup
ROOT_DIR = Path(__file__).resolve().parent.parent.parent

AUDIO_DIR = ROOT_DIR / "audio"
USER_AUDIO_DIR = AUDIO_DIR / "user"
AI_AUDIO_DIR = AUDIO_DIR / "ai"

USER_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
AI_AUDIO_DIR.mkdir(parents=True, exist_ok=True)

# RESPONSE MODELS
class VoiceResponse(BaseModel):
    text: str
    reply: str
    session_id: str


class VoiceJSONResponse(BaseModel):
    text: str
    reply: str
    audio_base64: str
    session_id: str


@router.post("/", response_model=VoiceResponse)
async def voice_endpoint(file: UploadFile = File(...), session_id: str | None = None):
    """
    Accept user audio → STT → Agent → TTS → Return MP3 audio + STT & reply text
    """

    try:
        # 1️⃣ Read uploaded audio bytes
        audio_bytes = await file.read()

        # Save user audio (optional but good for logs)
        timestamp = int(time.time())
        user_audio_path = USER_AUDIO_DIR / f"user_{timestamp}.mp3"
        with open(user_audio_path, "wb") as f:
            f.write(audio_bytes)

        # 2️⃣ STT
        try:
            text = speech_to_text(audio_bytes)
        except Exception as stt_err:
            raise HTTPException(500, f"STT failed: {stt_err}")

        # 3️⃣ Agent
        try:
            reply, new_session_id = process_message(text, session_id)
        except Exception as agent_err:
            raise HTTPException(500, f"Agent failed: {agent_err}")

        # 4️⃣ TTS
        try:
            reply_audio_bytes = text_to_speech(reply)
        except Exception as tts_err:
            raise HTTPException(500, f"TTS failed: {tts_err}")

        # 5️⃣ Save AI audio for auditing
        ai_audio_path = AI_AUDIO_DIR / f"ai_{timestamp}.mp3"
        with open(ai_audio_path, "wb") as f:
            f.write(reply_audio_bytes)

        # 6️⃣ Return JSON + audio stream
        headers = {
            "X-Session-ID": new_session_id,
            "X-STT-Text": text,
            "X-Agent-Reply": reply,
        }

        return StreamingResponse(
            content=iter([reply_audio_bytes]), media_type="audio/mpeg", headers=headers
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice endpoint failed: {str(e)}")


# ======================================================
# 1️⃣ /main — returns JSON with BASE64 audio (Option A)
# ======================================================
@router.post("/main", response_model=VoiceJSONResponse)
async def voice_json_endpoint(
    file: UploadFile = File(...), session_id: str | None = None
):
    """
    Accept user audio → STT → Agent → TTS → return JSON + Base64 audio
    """

    try:
        # 1️⃣ Read uploaded audio
        audio_bytes = await file.read()

        timestamp = int(time.time())
        user_audio_path = USER_AUDIO_DIR / f"user_{timestamp}.mp3"

        with open(user_audio_path, "wb") as f:
            f.write(audio_bytes)

        # 2️⃣ STT
        try:
            text = speech_to_text(audio_bytes)
        except Exception as stt_err:
            raise HTTPException(500, f"STT failed: {stt_err}")

        # 3️⃣ Agent
        try:
            reply, new_session_id = process_message(text, session_id)
        except Exception as agent_err:
            raise HTTPException(500, f"Agent failed: {agent_err}")

        # 4️⃣ TTS
        try:
            reply_audio = text_to_speech(reply)
        except Exception as tts_err:
            raise HTTPException(500, f"TTS failed: {tts_err}")

        # Save AI audio
        ai_audio_path = AI_AUDIO_DIR / f"ai_{timestamp}.mp3"
        with open(ai_audio_path, "wb") as f:
            f.write(reply_audio)

        # 5️⃣ Convert MP3 → Base64
        audio_base64 = base64.b64encode(reply_audio).decode()

        # 6️⃣ Return JSON
        return VoiceJSONResponse(
            text=text, reply=reply, audio_base64=audio_base64, session_id=new_session_id
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"/main failed: {str(e)}")


# ======================================================
# 2️⃣ /test — return static MP3 as JSON Base64
# ======================================================
@router.post("/test", response_model=VoiceJSONResponse)
async def voice_test_endpoint():
    """
    Returns a static audio file in the same structural format as /main.
    Used to test frontend without consuming API credits.
    """

    try:
        test_file = AI_AUDIO_DIR / "ai_1763399836.mp3"

        if not test_file.exists():
            raise HTTPException(404, "Test audio file not found")

        with open(test_file, "rb") as f:
            audio_bytes = f.read()

        audio_base64 = base64.b64encode(audio_bytes).decode()

        # Fixed dummy values
        return VoiceJSONResponse(
            text="Test STT Text",
            reply="Test AI Response",
            audio_base64=audio_base64,
            session_id="test-session-123",
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"/test failed: {str(e)}")
