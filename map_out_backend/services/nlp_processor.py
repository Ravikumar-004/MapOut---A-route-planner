import re

def extract_disruption_info(query: str):
    query = query.lower()
    location = None
    disruption_type = None

    if "at" in query:
        parts = query.split("at")
        location = parts[-1].strip()
    if "block" in query:
        disruption_type = "blockage"
    elif "traffic" in query:
        disruption_type = "traffic"
    else:
        disruption_type = "unknown"

    return {"location": location, "type": disruption_type}
