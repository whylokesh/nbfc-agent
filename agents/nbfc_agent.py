import uuid
from typing import Dict, List

from langchain.agents import create_agent

from .tools.sql_tools import sql_tools
from .tools.custom_tools import ping_sales_team
from core.config import settings
from agents.prompt import NBFC_SYSTEM_PROMPT


# CREATE AGENT
agent = create_agent(
    model=settings.OPENAI_MODEL,
    tools=sql_tools + [ping_sales_team],
    system_prompt=NBFC_SYSTEM_PROMPT.strip(),
)

# SIMPLE IN-MEMORY SESSION STORE
sessions: Dict[str, List[Dict[str, str]]] = {}

# PROCESS MESSAGE
def process_message(message: str, session_id: str | None = None):
    session_id = session_id or str(uuid.uuid4())

    if session_id not in sessions:
        sessions[session_id] = [
            {"role": "system", "content": NBFC_SYSTEM_PROMPT.strip()}
        ]

    chat_history = sessions[session_id]
    chat_history.append({"role": "user", "content": message})

    response = agent.invoke({"messages": chat_history})
    output = response["messages"][-1].content

    chat_history.append({"role": "assistant", "content": output})

    sessions[session_id] = chat_history

    return output, session_id

# CLEAR SESSION
def clear_session(session_id: str):
    if session_id in sessions:
        del sessions[session_id]
        return True
    return False
