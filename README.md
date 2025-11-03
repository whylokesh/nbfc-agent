# NBFC AI Assistant

An interactive command-line AI agent for NBFC (Non-Banking Financial Company) sales and loan teams. The assistant can:

- Query and analyze lead/loan data from a PostgreSQL database via SQL tools
- Provide structured, business-style insights
- Notify the sales team with a custom tool (`ping_sales_team`)

The agent is built with LangChain and OpenAI and runs locally as a simple REPL.

## Features
- Uses LangChain SQL toolkit to translate questions into SQL over your Postgres DB
- Custom tool `ping_sales_team` to simulate notifying sales for a given lead
- Conversation history preserved within the session for more contextual answers

## Project Structure
- `main.py`: Entry point; config, agent setup, REPL loop
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

5) Run the assistant
```bash
python main.py
```
You should see:
```
🤖 NBFC AI Assistant Ready!
Type 'exit' to quit.
```

Ask questions like:
- "Show top 5 leads by score this week"
- "List applications rejected last month and reasons"
- "Ping the sales team for lead 123 with an urgent follow-up"

Type `exit` to quit.

## How It Works (High Level)
- Builds a Postgres URI from environment variables and initializes `SQLDatabase`
- Instantiates an OpenAI chat model (`gpt-4o`) via `langchain-openai`
- Creates a LangChain SQL toolkit and adds a custom tool `ping_sales_team`
- Runs a REPL that maintains `chat_history` and streams responses

## Configuration Details
- Model: `gpt-4o`, temperature 0
- Connection string template: `postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}`
- Password is URL-encoded automatically with `urllib.parse.quote_plus`

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

## Security Notes
- Do not commit `.env` files or secrets
- Use least-privilege DB credentials for analytics

## References
- `refrences/NBFC Lead schema & sample data.sql`: Example schema and seed snippets
- `refrences/res.json`: Example data payload

## License
This project is provided as-is without warranty. Add your preferred license here.

