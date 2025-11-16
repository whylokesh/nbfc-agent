from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.routes import chat_router, voice_router

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
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
