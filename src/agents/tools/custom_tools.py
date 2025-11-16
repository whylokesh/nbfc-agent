from langchain.tools import tool

@tool("ping_sales_team", return_direct=True)
def ping_sales_team(lead_id: str, message: str):
    """Send a message to the sales team about a specific lead."""
    return f"TOOL CALLED: 📨 Sales team notified for Lead {lead_id}: {message}"
