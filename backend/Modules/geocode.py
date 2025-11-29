import requests
import urllib.parse
import logging
from typing import Tuple
import osmnx as ox

logger = logging.getLogger("mapout.geocode")

# Note: you already had API keys in the original. Keep them secure in env vars in real deployments.
TOMTOM_KEY = "IkDngm6JSCPd3o9jMYUB6Wm9htAtSarI"
POSITIONSTACK_KEY = "4c406b30ee98858e2d99582a612fae9f"

def _safe_get(url: str, params: dict, timeout: int = 5) -> dict | None:
    try:
        r = requests.get(url, params=params, timeout=timeout)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        logger.warning("Geocode request failed: %s %s", url, str(e))
        return None

def get_geocode_tomtom(place_name: str) -> Tuple[float | None, float | None]:
    if not place_name:
        return None, None
    url = f"https://api.tomtom.com/search/2/geocode/{urllib.parse.quote(place_name)}.json"
    params = {"key": TOMTOM_KEY, "limit": 1}
    data = _safe_get(url, params)
    if data and data.get("results"):
        p = data["results"][0].get("position")
        if p:
            return float(p["lat"]), float(p["lon"])
    return None, None

def get_geocode_positionstack(place_name: str) -> Tuple[float | None, float | None]:
    if not place_name:
        return None, None
    url = "http://api.positionstack.com/v1/forward"
    params = {"access_key": POSITIONSTACK_KEY, "query": place_name, "limit": 1}
    data = _safe_get(url, params)
    if data and data.get("data"):
        d = data["data"][0]
        return float(d["latitude"]), float(d["longitude"])
    return None, None

def get_geocode(location: str) -> Tuple[float | None, float | None]:
    """
    Try TomTom first, then PositionStack. Returns (lat, lon) or (None, None)
    """
    lat, lon = get_geocode_tomtom(location)
    if lat is None or lon is None:
        lat, lon = get_geocode_positionstack(location)
    if lat is None or lon is None:
        lat, lon = ox.geocode(location)
    if lat is None or lon is None:
        logger.warning("Geocode failed for location: %s", location)
    return lat, lon
