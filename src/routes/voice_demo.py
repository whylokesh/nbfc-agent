import time
from pathlib import Path
from fastapi import HTTPException

from src.agents.nbfc_agent import process_message
from src.services.elevenlabs import speech_to_text, text_to_speech


# ---------------------------------------------
# Compute project root reliably
# This file: project/src/routes/voice_demo.py
# parent.parent.parent → project/
# ---------------------------------------------
ROOT_DIR = Path(__file__).resolve().parent.parent.parent

# Global path for demo audio
DEMO_AUDIO_PATH = ROOT_DIR / "audio" / "demo.mp3"


def run_voice_demo(session_id: str | None = None) -> dict:
    """
    Runs the local demo:
    - Loads audio/demo.mp3
    - STT (ElevenLabs)
    - Agent reply
    - TTS (ElevenLabs)
    - Saves output audio
    - Returns dict with results
    """

    try:
        # 1️⃣ Load demo audio file
        if not DEMO_AUDIO_PATH.exists():
            raise HTTPException(status_code=500, detail="demo.mp3 not found in /audio")

        with open(DEMO_AUDIO_PATH, "rb") as f:
            audio_bytes = f.read()

        # 2️⃣ STT → Convert audio to text (FIXED)
        try:
            text = speech_to_text(audio_bytes)
        except Exception as stt_err:
            raise Exception(f"STT failed: {str(stt_err)}")

        # 3️⃣ Process message with agent
        try:
            reply, new_session_id = process_message(text, session_id)
        except Exception as agent_err:
            raise Exception(f"Agent failed: {str(agent_err)}")

        # 4️⃣ TTS → Convert reply text back to audio
        try:
            reply_audio_bytes = text_to_speech(reply)
        except Exception as tts_err:
            raise Exception(f"TTS failed: {str(tts_err)}")

        # 5️⃣ Save output audio with timestamp
        timestamp = int(time.time())
        output_file = ROOT_DIR / "audio" / f"output_{timestamp}.mp3"

        with open(output_file, "wb") as f:
            f.write(reply_audio_bytes)

        # 6️⃣ Return results
        return {
            "text": text,
            "reply": reply,
            "saved_file": str(output_file),
            "session_id": new_session_id,
        }

    except Exception as e:
        raise Exception(f"Demo function failed: {str(e)}")
