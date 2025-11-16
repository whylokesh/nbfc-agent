from langchain_openai import ChatOpenAI
from langchain_community.utilities.sql_database import SQLDatabase
from langchain_community.agent_toolkits.sql.base import SQLDatabaseToolkit

from src.config.settings import settings

# Initialize DB
db = SQLDatabase.from_uri(settings.DB_URI)

# Initialize LLM
llm = ChatOpenAI(
    model=settings.OPENAI_MODEL,
    temperature=0
)

# Build SQL Toolkit
toolkit = SQLDatabaseToolkit(db=db, llm=llm)
sql_tools = toolkit.get_tools()
