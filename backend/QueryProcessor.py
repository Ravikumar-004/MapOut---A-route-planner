import re

def parse_route_query(query):
    query = query.lower().strip()

    avoid_markers = ["avoid", "without", "no", "exclude", "less"]
    include_markers = ["include", "with", "having", "containing", "along", "through", "want"]
    stop_words = ["but", "and", "then", ".", ";"]

    avoid_list, include_list = [], []

    def extract_phrases(text):
        phrases = []
        parts = re.split(r"\band\b|\bbut\b|,|\.|;", text)
        for part in parts:
            phrase = part.strip()
            if phrase and len(phrase.split()) <= 4:
                phrases.append(phrase)
        return phrases

    for marker in avoid_markers:
        if marker in query:
            after = query.split(marker, 1)[1]
            segment = re.split(r"\bbut\b|\b" + "|".join(include_markers) + r"\b", after)[0]
            avoid_list.extend(extract_phrases(segment))

    for marker in include_markers:
        if marker in query:
            after = query.split(marker, 1)[1]
            segment = re.split(r"\bbut\b|\b" + "|".join(avoid_markers) + r"\b", after)[0]
            include_list.extend(extract_phrases(segment))

    def clean_list(lst):
        cleaned = []
        for item in lst:
            item = re.sub(r"[^\w\s]", "", item).strip()
            if item and item not in cleaned:
                cleaned.append(item)
        return cleaned

    avoid_list = clean_list(avoid_list)
    include_list = clean_list(include_list)

    return {"avoid": avoid_list, "include": include_list}


# # Example
# queries = [
#     "Find me a route that avoids traffic and potholes but includes shopping malls and cafes.",
#     "I want a shortest route that avoids construction and includes restaurants and shopping complexes.",
#     "Avoid jammed roads and heavy traffic, include hospitals and petrol pumps."
# ]

# for q in queries:
#     print(f"\nQuery: {q}")
#     print(parse_route_query(q))
