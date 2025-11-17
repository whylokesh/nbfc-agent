import os
from dotenv import load_dotenv
from urllib.parse import quote_plus

load_dotenv()


class Settings:

    # Database Configuration
    DB_USER: str = os.getenv("DB_USER", "postgres")
    DB_PASS_RAW: str = os.getenv("DB_PASS", "@POSTGRES_9")
    DB_HOST: str = os.getenv("DB_HOST", "127.0.0.1")
    DB_PORT: str = os.getenv("DB_PORT", "5432")
    DB_NAME: str = os.getenv("DB_NAME", "nbfc_db")

    # URL-safe encode password
    DB_PASS: str = quote_plus(DB_PASS_RAW)

    DB_URI: str = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASS}" f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    # LLM Configuration
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o")

    # ElevenLabs Configuration
    ELEVENLABS_API_KEY: str = os.getenv("ELEVENLABS_API_KEY", "")

    # speech → text model
    ELEVENLABS_STT_MODEL: str = os.getenv("ELEVENLABS_STT_MODEL", "scribe_v1")

    # text → speech model
    ELEVENLABS_TTS_MODEL: str = os.getenv( "ELEVENLABS_TTS_MODEL", "eleven_multilingual_v2")

    # voice id
    ELEVENLABS_VOICE_ID: str = os.getenv("ELEVENLABS_VOICE_ID", "JBFqnCBsd6RMkjVDRZzb")


settings = Settings()
