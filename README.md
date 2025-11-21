# 🏦 NBFC Voice AI Assistant — Backend

FastAPI + LangChain + PostgreSQL + ElevenLabs (Voice-to-Voice AI)

---

## 🚀 Overview

This backend powers an **NBFC (Non-Banking Financial Company) AI Assistant** that supports:

### ✔ Text Chat (SQL Agent)

* Queries PostgreSQL database
* Analyzes leads, applications, accounts
* Performs tool-calling (e.g., notify sales team)

### ✔ Voice-to-Voice Agent

Upload a voice message →
**STT → AI Reasoning → TTS → Return audio + text metadata**

Works with **ElevenLabs STT & TTS**.

### ✔ Session Memory

Each conversation continues the context across requests.

---

## 🏗️ Tech Stack

| Component     | Technology                    |
| ------------- | ----------------------------- |
| API Framework | **FastAPI**                   |
| AI Reasoning  | **LangChain + OpenAI GPT-4o** |
| DB            | **PostgreSQL + SQLAlchemy**   |
| Voice STT/TTS | **ElevenLabs API**            |
| Agent Tools   | SQL Toolkit + Custom Tools    |
| Deployment    | Uvicorn / Docker              |

---

## 📂 Project Structure

```
project/
│── main.py
│── requirements.txt
│── README.md
│
├── src/
│   ├── agents/
│   │   └── nbfc_agent.py
│   ├── services/
│   │   └── elevenlabs.py
│   ├── routes/
│   │   ├── chat.py
│   │   └── voice.py
│   └── config/
│       └── settings.py
│
└── audio/
    ├── user/
    └── ai/
```

---

## 🔧 Installation

### 1. Clone repo

```sh
git clone https://github.com/whylokesh/nbfc-agent.git
cd nbfc-ai-backend
```

### 2. Create virtual environment

```sh
python -m venv venv
source venv/bin/activate   # Mac/Linux
venv\Scripts\activate      # Windows
```

### 3. Install dependencies

```sh
pip install -r requirements.txt
```

---

## 🔑 Environment Variables

Create **`.env`** file:

```
# PostgreSQL
DB_USER=postgres
DB_PASS=yourpassword
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=nbfc_db

# OpenAI
OPENAI_API_KEY=your_openai_key

# ElevenLabs
ELEVENLABS_API_KEY=your_api_key
ELEVENLABS_STT_MODEL=scribe_v1
ELEVENLABS_TTS_MODEL=eleven_multilingual_v2
ELEVENLABS_VOICE_ID=your_voice_id
```

---

## ▶ Running the server

```
uvicorn main:app --reload
```

Server runs at:

* **API Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)
* **Health Check:** [http://localhost:8000/health](http://localhost:8000/health)

---

# 📌 API Endpoints

---

# 🟦 1. Chat API (Text → AI → Text)

### **POST /chat**

Request:

```json
{
  "message": "Show me leads with low CIBIL score",
  "session_id": null
}
```

Response:

```json
{
  "response": "Here are the top low-CIBIL leads...",
  "session_id": "d9b8df12-..."
}
```

---

# 🟪 2. Voice API (Audio → STT → AI → TTS → Audio Stream)

### **POST /voice**

Returns **raw MP3 stream** (useful for mobile apps, speakers).

```sh
curl -X POST "http://localhost:8000/voice" \
  -F "file=@demo.mp3"
```

Response: **audio/mpeg stream** with headers:

```
X-Session-ID: abc123
X-STT-Text: what is the status of lead 23
X-Agent-Reply: the lead is in DDE stage...
```

---

# 🟩 3. Voice API (Audio → JSON + base64 Audio)

### **POST /voice/main**

This returns **JSON + base64 audio**, perfect for web apps.

```sh
curl -X POST "http://localhost:8000/voice/main" \
  -F "file=@demo.mp3"
```

Response:

```json
{
  "text": "what is the cibil score of lead 103",
  "reply": "Lead 103 has a CIBIL score of 742.",
  "audio_base64": "SUQzBAAAAAA...",
  "session_id": "a13c91ab-..."
}
```

---

# 🟨 4. Test Endpoint (No API usage, returns static MP3)

### **POST /voice/test**

Useful when frontend testing without consuming GPT or ElevenLabs credits.

```json
{
  "text": "Test STT Text",
  "reply": "Test AI Response",
  "audio_base64": "BASE64_DATA",
  "session_id": "test-session-123"
}
```

---

# 🧠 Agent Features

### ✔ SQL Querying

The agent automatically scans the DB schema and writes/executes SQL queries.

### ✔ Tool Calling

Example custom tool:

```python
@tool("ping_sales_team")
def ping_sales_team(lead_id: str, message: str):
    return f"Message sent for Lead {lead_id}: {message}"
```

### ✔ Conversation Memory

Stored in local in-memory dict.
(Production plan: Redis)

---

# 🎤 Voice Pipeline

```
User Audio (mp3/webm)
      ↓
ElevenLabs STT → text
      ↓
NBFC GPT Agent → reply text
      ↓
ElevenLabs TTS → mp3
      ↓
Frontend (Next.js)
```

---

# 🧪 Testing Voice Upload (Postman)

### Request

* Method: **POST**
* URL: `http://localhost:8000/voice/main`
* Body → form-data:

  * **file** → upload `.mp3`
  * **session_id** (optional)

### Response

Base64 audio + texts.

---

# 📦 Build for Production

```
pip install gunicorn uvicorn
gunicorn main:app -k uvicorn.workers.UvicornWorker
```

---

# 💡 Future Enhancements

* Redis for long-term session memory
* Multi-agent (collection officer, credit officer, DSA assistant)
* File upload (bank statements, Aadhaar OCR)
* Realtime streaming audio
* WhatsApp bot integration

---

# ❤️ Author

Built by **Lokesh Jha (LJ)**
NBFC + AI Engineering

---

If you want, I can also generate:

✅ Swagger-styled docs
✅ Mermaid DB diagram
✅ System Architecture diagram
✅ Frontend README (Next.js)

Just tell me!
