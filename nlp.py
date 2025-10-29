import spacy
import re

nlp = spacy.load("en_core_web_sm")

def parse_route_query(query):
    """
    NLP-based route query parser.
    Extracts 'avoid' and 'include' lists with proper compound phrases.
    Example:
        "avoid traffic and potholes but include shopping malls and cafes"
        ➜ {'avoid': ['traffic', 'potholes'], 'include': ['shopping malls', 'cafes']}
    """

    query = query.lower().strip()
    doc = nlp(query)

    # Define trigger words
    avoid_markers = ["avoid", "without", "no", "exclude", "less"]
    include_markers = ["include", "with", "having", "containing", "along", "through","want"]

    avoid_list, include_list = [], []

    # Helper: extract noun phrases after a trigger
    def extract_phrases(start_index):
        phrases = []
        current_phrase = []
        for token in doc[start_index:]:
            # Stop collecting when encountering "but", punctuation, or another trigger
            if token.text in ["but", ".", ";"] or token.lemma_ in avoid_markers + include_markers:
                break

            # Collect compound phrases (adjectives + nouns)
            if token.pos_ in ["ADJ", "NOUN", "PROPN"]:
                current_phrase.append(token.text)
                # If next token is not also part of the phrase, finalize it
                next_token = doc[token.i + 1] if token.i + 1 < len(doc) else None
                if not next_token or next_token.pos_ not in ["ADJ", "NOUN", "PROPN"]:
                    phrases.append(" ".join(current_phrase).strip())
                    current_phrase = []
        return phrases

    # Go through all tokens and detect where avoid/include markers appear
    for i, token in enumerate(doc):
        if token.lemma_ in avoid_markers:
            avoid_list.extend(extract_phrases(i + 1))
        elif token.lemma_ in include_markers:
            include_list.extend(extract_phrases(i + 1))

    # Cleanup
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


# -------------------------
# ✅ Test Cases
# -------------------------
queries = [
    "Find me a route that avoids traffic and potholes but includes shopping malls and cafes.",
    "I want a shortest route that avoids construction and includes restaurants and shopping complexes.",
    "Avoid jammed roads and heavy traffic, include hospitals and petrol pumps."
]

for q in queries:
    print(f"\nQuery: {q}")
    print(parse_route_query(q))
