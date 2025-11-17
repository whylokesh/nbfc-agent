# 🏦 NBFC AI Assistant — Backend

### FastAPI • LangChain • PostgreSQL • GPT-4o • ElevenLabs Voice-to-Voice AI

This repository powers a **Voice + Text NBFC AI Assistant**, capable of:

* SQL‑aware GPT‑4o agent (auto-detects DB schema)
* Multi-turn conversation memory
* Voice-to-voice interaction (STT → LLM → TTS)
* Modular and production-ready FastAPI backend
* Built for NBFC Loan Origination System (LOS) workflows

---

## 🚀 Features

### 🤖 AI Agent (LangChain + GPT‑4o)

* Fully SQL-aware using `SQLDatabaseToolkit`
* Agent automatically reads your **database schema**
* Executes safe SQL queries
* Custom tools (e.g., `ping_sales_team`)
* Designed for NBFC workflows: leads, applications, repayments, disbursal

### 🎤 Voice-to-Voice AI

* Accepts audio input (MP3/WAV)
* Converts audio → text (ElevenLabs STT)
* Sends text to NBFC Agent
* Converts reply text → audio (ElevenLabs TTS)
* Returns JSON + Base64 audio OR audio stream

### 📡 FastAPI API Server

* `/chat` → text chat API
* `/voice` → voice-to-voice API
* `/voice/main` → JSON + Base64 audio
* `/voice/test` → static test MP3
* CORS enabled for frontend integrations

### 🧠 Session Memory

* Conversation memory stored per-session
* Sessions handled in `session_manager.py`

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone <repo-url>
cd nbfc-agent
```

### 2. Create Virtual Environment

```bash
python -m venv venv
source venv/bin/activate   # macOS/Linux
venv\Scripts\activate      # Windows
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## 🔐 Environment Variables (`.env`)

Create a `.env` file in the project root:

```env
OPENAI_API_KEY=YOUR_OPENAI_KEY
ELEVENLABS_API_KEY=YOUR_11LABS_KEY

DB_USER=postgres
DB_PASS=@POSTGRES_9
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=nbfc_db
```

---

## ▶️ Running the Server

```bash
python main.py
```

The server runs at:

```
http://localhost:8000
```

API Docs:

```
http://localhost:8000/docs
```

---

# 🗂️ Folder Structure

```
nbfc-agent/
│
├── main.py
├── .env
├── requirements.txt
│
├── src/
│   ├── agents/
│   │   └── nbfc_agent.py
│   │
│   ├── services/
│   │   └── elevenlabs.py
│   │
│   ├── routes/
│   │   ├── chat.py
│   │   └── voice.py
│   │
│   └── utils/
│       └── session_manager.py
│
└── audio/
    ├── user/
    └── ai/
```

---

# 🔊 API Endpoints

## 1️⃣ **Text Chat Endpoint**

### `POST /chat`

**Request:**

```json
{
  "message": "Show me leads with low CIBIL score",
  "session_id": "optional"
}
```

**Response:**

```json
{
  "response": "Formatted business answer",
  "session_id": "abcd-1234"
}
```

---

## 2️⃣ **Voice-to-Voice Endpoint**

### `POST /voice`

**Form-Data:**

```
file: <audio.mp3>
session_id: optional
```

**Returns:**

* Streaming MP3 audio
* Text via response headers

---

## 3️⃣ **Primary Voice API (JSON + Base64)**

### `POST /voice/main`

**Returns:**

```json
{
  "text": "User said...",
  "reply": "AI reply...",
  "session_id": "1234",
  "audio_base64": "..."
}
```

---

## 4️⃣ **Test Endpoint (Static file)**

### `GET /voice/test`

Useful for frontend integration without burning API credits.

Returns a static MP3 in the same structure as `/main`.

---

# 🛠️ Tech Stack

| Component          | Technology                |
| ------------------ | ------------------------- |
| LLM                | GPT‑4o (OpenAI)           |
| STT                | ElevenLabs Speech-to-Text |
| TTS                | ElevenLabs Voice API      |
| AI Agent           | LangChain `create_agent`  |
| Database           | PostgreSQL + SQLAlchemy   |
| Backend            | FastAPI                   |
| Frontend (planned) | Next.js Voice UI          |

---

# 🧪 Testing (Postman)

### Upload audio:

* Method: `POST`
* URL: `http://localhost:8000/voice`
* Body → Form-Data

  * `file`: Upload MP3/WAV
  * `session_id`: optional

---

# 📌 Notes

* Interactive memory is session-based
* Audio outputs saved under `/audio/ai`
* User uploads saved under `/audio/user`

---

# 💬 Support

For issues or feature requests, open an issue in the repository.

---

# 🟢 License

MIT License

---

Enjoy building your NBFC Voice AI 🚀
