# NBFC AI Assistant

A FastAPI-based AI agent for NBFC (Non-Banking Financial Company) sales and loan teams. The assistant can:

- Query and analyze lead/loan data from a PostgreSQL database via SQL tools
- Provide structured, business-style insights
- Notify the sales team with a custom tool (`ping_sales_team`)

The agent is built with LangChain, OpenAI, and FastAPI, providing a RESTful API for integration with web applications or other services.

## Features
- Uses LangChain SQL toolkit to translate questions into SQL over your Postgres DB
- Custom tool `ping_sales_team` to simulate notifying sales for a given lead
- Conversation history preserved within sessions for more contextual answers
- RESTful API with automatic OpenAPI documentation
- Session management for multi-user support
- CORS enabled for frontend integration

## Project Structure
- `main.py`: FastAPI server with agent setup and API endpoints
- `requirements.txt`: Python dependencies
- `refrences/`: Example schema/data references (not executed by the app)

## Prerequisites
- Python 3.11+ (recommended to match the provided `venv`)
- A running PostgreSQL instance accessible from this machine
- An OpenAI API key with access to the `gpt-4o` model

## Quickstart

1) Clone and enter the project directory
```bash
cd nbfc-agent
```

2) (Optional) Create and activate a virtual environment
```bash
python -m venv venv
# Windows (PowerShell)
./venv/Scripts/Activate.ps1
# Windows (cmd)
venv\Scripts\activate.bat
# Windows (Git Bash)
source venv/Scripts/activate
```

3) Install dependencies
```bash
pip install -r requirements.txt
```

4) Create a `.env` file
```bash
# Required
OPENAI_API_KEY=sk-your-openai-key

# Optional (defaults shown from main.py)
DB_USER=postgres
DB_PASS=@POSTGRES_9
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=nbfc_db
```
Notes:
- `main.py` automatically URL-encodes `DB_PASS` (so special characters like `@` are OK).
- You may override any DB_* value via environment variables.

5) Run the FastAPI server
```bash
python main.py
```
Or using uvicorn directly:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

6) Access the API
- **API Documentation (Swagger UI)**: http://localhost:8000/docs
- **Alternative API Docs (ReDoc)**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## API Usage

### Chat Endpoint
Send a POST request to `/chat`:

```bash
curl -X POST "http://localhost:8000/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show top 5 leads by score this week",
    "session_id": null
  }'
```

Response:
```json
{
  "response": "Based on the query...",
  "session_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Session Management**: 
- Omit `session_id` in the first request to create a new session
- Include the returned `session_id` in subsequent requests to maintain conversation history
- Use `DELETE /chat/{session_id}` to clear a session's history

### Example Questions
- "Show top 5 leads by score this week"
- "List applications rejected last month and reasons"
- "Ping the sales team for lead 123 with an urgent follow-up"

## How It Works (High Level)
- Builds a Postgres URI from environment variables and initializes `SQLDatabase`
- Instantiates an OpenAI chat model (`gpt-4o`) via `langchain-openai`
- Creates a LangChain SQL toolkit and adds a custom tool `ping_sales_team`
- FastAPI server exposes REST endpoints for chat interactions
- Session-based chat history management (in-memory, can be upgraded to Redis/DB)

## Configuration Details
- Model: `gpt-4o`, temperature 0
- Connection string template: `postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}`
- Password is URL-encoded automatically with `urllib.parse.quote_plus`
- Server runs on `0.0.0.0:8000` by default (configurable via uvicorn)
- CORS is enabled for all origins (restrict in production)

## Troubleshooting
- **Connection errors to Postgres**
  - Ensure the DB is running and credentials in `.env` are correct
  - Verify network/firewall rules allow access to `{DB_HOST}:{DB_PORT}`
- **OpenAI authentication**
  - Ensure `OPENAI_API_KEY` is set and has access to `gpt-4o`
- **Missing packages or import errors**
  - Re-run `pip install -r requirements.txt`
- **SQL permissions**
  - The configured DB user needs read access to relevant schemas/tables
- **NumPy/PyTorch incompatibility (NumPy 2.x)**
  - If you see an error like: "A module compiled using NumPy 1.x cannot be run in NumPy 2.x" (often triggered via `transformers`/`torch` imported by LangChain internals), install with pinned NumPy:
    ```bash
    pip install --upgrade "numpy<2"
    ```
  - This repo’s `requirements.txt` already pins `numpy<2` to avoid this.

## Security Notes
- Do not commit `.env` files or secrets
- Use least-privilege DB credentials for analytics

## Database Schema
The agent expects a Postgres table like `nbfc_loan_leads`:

```sql
CREATE TABLE nbfc_loan_leads (
    -- Primary Identification
    lead_id TEXT PRIMARY KEY,                       -- Corresponds to requestReferenceNumber
    unique_identifier TEXT NOT NULL,                -- Unique technical ID
    
    -- Loan Details
    product_type VARCHAR(10) NOT NULL,              -- e.g., LAP, HL, PL
    loan_amount_requested NUMERIC(15, 2) NOT NULL,  -- Loan requested in INR
    loan_tenure_months INTEGER NOT NULL,            -- Tenure in months
    loan_purpose_desc TEXT,                         -- Descriptive purpose of the loan
    sourcing_channel VARCHAR(50),                   -- e.g., DIRECT, DSA
    
    -- Applicant Details (Main Applicant / Hirer)
    applicant_name VARCHAR(100),
    applicant_monthly_income NUMERIC(12, 2),        -- Monthly income
    applicant_cibil_score VARCHAR(10),              -- The string '000-1' means no history
    
    -- Collateral Details (for LAP/HL)
    collateral_type VARCHAR(50),                    -- e.g., Property, Gold
    property_market_value NUMERIC(15, 2),           -- FMV of the asset
    property_pincode VARCHAR(10),
    
    -- Risk & Status
    next_followup_date DATE,                        -- Next planned action/contact
    has_co_applicant BOOLEAN DEFAULT FALSE
);
```

Sample seed data is provided in `refrences/NBFC Lead schema & sample data.sql`.

## References
- `refrences/NBFC Lead schema & sample data.sql`: Example schema and seed snippets
- `refrences/res.json`: Example data payload

## License
This project is provided as-is without warranty. Add your preferred license here.

