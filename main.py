# pip install -U "langchain" "langchain-openai" "langchain-community" "python-dotenv" "psycopg2-binary" "sqlalchemy"

import os
from urllib.parse import quote_plus
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from langchain_community.utilities.sql_database import SQLDatabase
from langchain_community.agent_toolkits.sql.base import SQLDatabaseToolkit
from langchain.tools import tool

# Load environment variables
load_dotenv()

# PostgreSQL + OpenAI setup
# Prefer environment variables; fall back to your provided local values
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS_RAW = os.getenv("DB_PASS", "@POSTGRES_9")  # contains '@' which must be URL-encoded
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nbfc_db")

# Safely URL-encode password so special characters like '@' don't break the URI
DB_PASS = quote_plus(DB_PASS_RAW)

DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Initialize SQL + LLM
db = SQLDatabase.from_uri(DB_URI)
llm = ChatOpenAI(model="gpt-4o", temperature=0)

# SQL Toolkit   
toolkit = SQLDatabaseToolkit(db=db, llm=llm)
sql_tools = toolkit.get_tools()

# Custom tool
# def ping_sales_team(lead_id: str, message: str) -> str:
#     """Send a message to the sales team."""
#     return f"📨 Sales team notified for Lead {lead_id}: {message}"
@tool("ping_sales_team", return_direct=True)
def ping_sales_team(lead_id: str, message: str) -> str:
    """Send a message to the sales team about a specific lead."""
    return f"📨 Sales team notified for Lead {lead_id}: {message}"

# Agent System Prompt
SYSTEM_PROMPT = """
You are NBFC AI Assistant — an intelligent assistant for an NBFC sales and loan team.

You can:
- Query and analyze lead or loan data from the PostgreSQL database.
- Retrieve insights like top leads, rejected applications, or pending approvals.
- Ping the sales team for follow-ups or alerts.

When the user asks:
1. Use SQL tools for any data query.
2. Use 'ping_sales_team' when they ask to alert or message sales.
3. Respond in a business-style, structured tone with clear insights.
"""

# Create agent
agent = create_agent(
    model="gpt-4o",
    tools=sql_tools + [ping_sales_team],
    system_prompt=SYSTEM_PROMPT.strip(),
)

# Run the agent
print("\n🤖 NBFC AI Assistant Ready!")
print("Type 'exit' to quit.\n")

chat_history = [{"role": "system", "content": SYSTEM_PROMPT.strip()}]

while True:
    user_input = input("You: ").strip()
    if user_input.lower() in ["exit", "quit"]:
        print("👋 Goodbye!")
        break

    chat_history.append({"role": "user", "content": user_input})

    try:
        response = agent.invoke({"messages": chat_history})
        output = response["messages"][-1].content
        print("\nAssistant:", output, "\n")

        # Append assistant message back to history
        chat_history.append({"role": "assistant", "content": output})

    except Exception as e:
        print("⚠️ Error:", e)

