import logging
import itertools
import osmnx as ox
from shapely.geometry import Point
from Modules.geocode import get_geocode
from Modules.route_utils import compute_route_and_length
from Modules.QueryProcessor import parse_preferences
from Modules.poi_utils import fetch_pois, poi_matches_avoid, top_k_candidates_by_distance
from Modules.route_utils import astar_path, astar_length

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

PLACE_NAME = "Bhubaneswar, India"   
CANDIDATES_PER_PREF = 10          

def CalculateRoute(G, source_name, dest_name, user_text, place_name=PLACE_NAME, top_k=CANDIDATES_PER_PREF):
    included_names = []
    Missing = []
    selected_pois_info = []
    all_poi_info = []

    includes, avoids = parse_preferences(user_text)
    logger.info("Parsed includes=%s avoids=%s", includes, avoids)

    if not includes:
        logger.info("No includes detected in user_text; returning direct route.")
    try:
        src_point = get_geocode(source_name) 
        dst_point = get_geocode(dest_name)
        src_node = ox.distance.nearest_nodes(G, src_point[1], src_point[0])
        dst_node = ox.distance.nearest_nodes(G, dst_point[1], dst_point[0])
    except Exception as e:
        logger.warning("Geocoding failed: %s", e)
        return [], ["Geocoding failed"], []

    try:
        direct_route = astar_path(G, src_node, dst_node, weight="length")
        direct_length = astar_length(G, direct_route, weight="length")
    except Exception as e:
        logger.warning("Direct route failed: %s", e)
        return [], ["Route failed"], []

    pref_candidates = {} 
    for pref in includes:
        pref_tag = PREFERENCE_TAGS.get(pref)
        if not pref_tag:
            Missing.append(pref)
            continue

        gdf = fetch_pois(place_name, pref_tag)
        if gdf is None or gdf.empty:
            Missing.append(pref)
            continue

        filtered_rows = []
        for _, row in gdf.iterrows():
            if poi_matches_avoid(row, avoids):
                continue
            filtered_rows.append(row)

        if not filtered_rows:
            Missing.append(pref)
            continue

        raw_candidates = []
        for row in filtered_rows:
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
                raw_candidates.append((node, lat, lon, row))
            except Exception:
                continue

        if not raw_candidates:
            Missing.append(pref)
            continue

        top_candidates = top_k_candidates_by_distance(raw_candidates, src_point, k=top_k)
        pref_candidates[pref] = top_candidates

        for node, lat, lon, row in raw_candidates:
            name = row.get("name") if ("name" in row and isinstance(row.get("name"), str)) else pref
            all_poi_info.append({"name": name, "lat": lat, "lon": lon, "pref_type": pref, "node": node})

        included_names.append(pref)

    if not pref_candidates:
        coord_route = [(G.nodes[n]['y'], G.nodes[n]['x']) for n in direct_route]
        return coord_route, Missing, all_poi_info

    pref_keys = list(pref_candidates.keys())
    candidate_lists = [pref_candidates[k] for k in pref_keys]

    max_combinations = 2000
    total_combinations = 1
    for l in candidate_lists:
        total_combinations *= max(1, len(l))
    if total_combinations > max_combinations:
        reduce_k = max(1, int((max_combinations) ** (1.0 / len(candidate_lists))))
        logger.info("Trimming candidates per pref to %d to limit combos (was %d combinations)", reduce_k, total_combinations)
        candidate_lists = [lst[:reduce_k] for lst in candidate_lists]

    best_combo = None
    best_combo_length = float("inf")
    best_combo_nodes_seq = []

    for combo in itertools.product(*candidate_lists):
        nodes = [c[0] for c in combo]

        for perm in itertools.permutations(range(len(nodes))):
            ordered_nodes = [nodes[i] for i in perm]
            total_len, final_nodes = compute_route_and_length(G, src_node, dst_node, ordered_nodes)
            if total_len < best_combo_length:
                best_combo_length = total_len
                best_combo = combo
                best_combo_nodes_seq = final_nodes

    if best_combo is None or best_combo_length == float("inf"):
        coord_route = [(G.nodes[n]['y'], G.nodes[n]['x']) for n in direct_route]
        return coord_route, Missing, all_poi_info

    detour = best_combo_length - direct_length
    logger.info("Best combo length=%.1f direct=%.1f detour=%.1f meters", best_combo_length, direct_length, detour)

    selected_pois_info = []
    for idx, (node, lat, lon, row) in enumerate(best_combo):
        pref_type = pref_keys[idx]
        name = row.get("name") if ("name" in row and isinstance(row.get("name"), str)) else pref_type
        selected_pois_info.append({"name": name, "lat": lat, "lon": lon, "node": node, "pref_type": pref_type})

    final_nodes = best_combo_nodes_seq
    coord_route = [(G.nodes[n]['y'], G.nodes[n]['x']) for n in final_nodes]

    return coord_route,  Missing, selected_pois_info

