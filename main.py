from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from src.routes import chat_router, voice_router, run_voice_demo

app = FastAPI(
    title="NBFC AI Assistant API",
    version="1.0.0"
)               

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True
)

# ROUTES
app.include_router(chat_router, prefix="/chat")
app.include_router(voice_router, prefix="/voice")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

    # result = run_voice_demo(session_id=None)

    # print("User said:", result["text"])
    # print("Agent replied:", result["reply"])
    # print("Output audio saved at:", result["saved_file"])
