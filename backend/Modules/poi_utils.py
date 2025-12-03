import osmnx as ox
from shapely.geometry import Point
import math
import logging

logger = logging.getLogger("mapout.pathfinder")
logger.setLevel(logging.INFO)

PREFERENCE_TAGS = {
    "atm": {"amenity": "atm"},
    "mall": {"shop": "mall"},
    "hospital": {"amenity": "hospital"},
    "restaurant": {"amenity": "restaurant"},
    "petrol_bunk": {"amenity": "fuel"},
    "fuel": {"amenity": "fuel"},
    "gas_station": {"amenity": "fuel"},
}

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return R * 2 * math.asin(math.sqrt(a))

def fetch_pois(place_name, tags):
    try:
        gdf = ox.features_from_place(place_name, tags)
        return gdf
    except Exception as e:
        logger.warning("OSM fetch failed: %s", e)
        return None

def get_poi_nodes(G, gdf):
    poi_nodes = []
    if gdf is None or gdf.empty:
        return poi_nodes

    for _, row in gdf.iterrows():
        geom = row.geometry
        if isinstance(geom, Point):
            lat = geom.y
            lon = geom.x
        else:
            centroid = geom.centroid
            lat = centroid.y
            lon = centroid.x

        try:
            node = ox.distance.nearest_nodes(G, lon, lat)
            poi_nodes.append((node, lat, lon, row))
        except Exception:
            continue

    return poi_nodes
    
def poi_matches_avoid(row, avoid_list):
    if not avoid_list:
        return False

    for avoid_key in avoid_list:
        avoid_tag = PREFERENCE_TAGS.get(avoid_key)
        if not avoid_tag:
            continue
        for k, v in avoid_tag.items():
            val = row.get(k)
            if val is None:
                row_vals = [str(row.get(c)).lower() for c in row.index if row.get(c) is not None]
                if any(v in rv for rv in row_vals):
                    return True
                continue
            if isinstance(val, str) and v in val:
                return True
            if val == v:
                return True
    return False


def top_k_candidates_by_distance(candidates, src_point, k):
    if not candidates:
        return []
    src_lat, src_lon = src_point
    scored = []
    for node, lat, lon, row in candidates:
        d = haversine_km(src_lat, src_lon, lat, lon)
        scored.append((d, node, lat, lon, row))
    scored.sort(key=lambda x: x[0])
    top = scored[:k]

    return [(node, lat, lon, row) for _, node, lat, lon, row in top]
