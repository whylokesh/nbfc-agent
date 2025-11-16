import os
from dotenv import load_dotenv
from urllib.parse import quote_plus

load_dotenv()

class Settings:
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASS_RAW = os.getenv("DB_PASS", "@POSTGRES_9")
    DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "nbfc_db")

    DB_PASS = quote_plus(DB_PASS_RAW)
    DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

    OPENAI_MODEL = "gpt-4o"

settings = Settings()
