from io import BytesIO
from elevenlabs.client import ElevenLabs
from src.config.settings import settings

client = ElevenLabs(api_key=settings.ELEVENLABS_API_KEY)


# -------------------------
# Speech → Text (STT)
# -------------------------
def speech_to_text(audio_bytes: bytes) -> str:
    audio_file = BytesIO(audio_bytes)

    result = client.speech_to_text.convert(
        file=audio_file,
        model_id=settings.ELEVENLABS_STT_MODEL,  # "scribe_v1"
        tag_audio_events=False,
        language_code="eng",
        diarize=False,
    )

    return result.text


# -------------------------
# Text → Speech (TTS)
# -------------------------
def text_to_speech(text: str) -> bytes:
    """
    Handles all ElevenLabs TTS return formats:
    - bytes
    - bytearray
    - generator of audio chunks
    """

    result = client.text_to_speech.convert(
        text=text,
        voice_id=settings.ELEVENLABS_VOICE_ID,
        model_id=settings.ELEVENLABS_TTS_MODEL,
        output_format="mp3_44100_128",
    )

    # CASE 1: raw bytes
    if isinstance(result, (bytes, bytearray)):
        return result

    # CASE 2: generator that yields bytes
    try:
        return b"".join(chunk for chunk in result)
    except Exception:
        raise TypeError(
            f"Unexpected TTS response type: {type(result)}. "
            f"Expected bytes or generator."
        )
