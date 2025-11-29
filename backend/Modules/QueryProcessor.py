PREFERENCE_TAGS = {
    "atm": {"amenity": "atm"},
    "mall": {"shop": "mall"},
    "hospital": {"amenity": "hospital"},
    "restaurant": {"amenity": "restaurant"},
    "petrol_bunk": {"amenity": "fuel"},
    "fuel": {"amenity": "fuel"},
    "gas_station": {"amenity": "fuel"},
}

SYNONYMS = {
    "petrol": "petrol_bunk",
    "petrol bunk": "petrol_bunk",
    "petrolpump": "petrol_bunk",
    "petrol pump": "petrol_bunk",
    "petrolstation": "petrol_bunk",
    "gas": "gas_station",
    "gas station": "gas_station",
    "gasstation": "gas_station",
    "fuel": "fuel",
    "atm": "atm",
    "malls": "mall",
    "mall": "mall",
    "hospital": "hospital",
    "restaurants": "restaurant",
    "restaurant": "restaurant",
}

import re
def parse_preferences(text):
    text = text.lower().strip()

    avoid_split = re.split(r"\b(?:avoid|but avoid|except|without)\b", text, maxsplit=1)
    include_text = avoid_split[0]
    avoid_text = avoid_split[1] if len(avoid_split) > 1 else ""

    def extract_tokens(s):
        s = re.sub(r"[^\w\s]", " ", s)
        parts = re.split(r"\band\b|\b&\b|,|\bplus\b|\bor\b", s)
        tokens = [p.strip() for p in parts if p.strip()]
        return tokens

    include_tokens = extract_tokens(include_text)
    avoid_tokens = extract_tokens(avoid_text)

    includes = []
    avoids = []

    for tok in include_tokens:
        tok = tok.strip()
        if not tok:
            continue
        matched = False
        for syn, canonical in SYNONYMS.items():
            if syn in tok:
                if canonical not in includes:
                    includes.append(canonical)
                matched = True
        if not matched:
            if tok in PREFERENCE_TAGS and tok not in includes:
                includes.append(tok)

    for tok in avoid_tokens:
        tok = tok.strip()
        if not tok:
            continue
        for syn, canonical in SYNONYMS.items():
            if syn in tok:
                if canonical not in avoids:
                    avoids.append(canonical)
        if tok in PREFERENCE_TAGS and tok not in avoids:
            avoids.append(tok)

    return includes, avoids