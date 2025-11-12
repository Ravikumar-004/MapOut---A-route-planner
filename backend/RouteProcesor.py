from geocode import get_geocode_dual
from QueryProcessor import parse_route_query
import osmnx as ox

def dijkstra_path(G, source, target, weight="length"):
    import heapq

    queue = [(0, source, [])]
    seen = set()

    while queue:
        (cost, node, path) = heapq.heappop(queue)
        if node in seen:
            continue
        seen.add(node)
        path = path + [node]

        if node == target:
            return path

        for neighbor, edge_data in G[node].items():
            w = edge_data[0].get(weight, 1)
            if neighbor not in seen:
                heapq.heappush(queue, (cost + w, neighbor, path))
    return []

def remove_avoid_nodes(G, avoid_list): # TODO: improve this function
    if not avoid_list:
        return G, []

    remove_nodes = set()
    for node, data in G.nodes(data=True):
        tags = " ".join(str(v).lower() for v in data.values())
        if any(avoid.lower() in tags for avoid in avoid_list):
            remove_nodes.add(node)

    G_new = G.copy()
    G_new.remove_nodes_from(remove_nodes)
    return G_new, remove_nodes


def add_query_weights(G, include_list): # TODO: improve this function
    if not include_list:
        return G

    for u, v, key, data in G.edges(keys=True, data=True):
        tags = " ".join(str(v).lower() for v in data.values())
        if any(word.lower() in tags for word in include_list):
            data["length"] *= 0.5  # encourage route
    return G


def CalculateRoute(G, source, target, query, weight="length"):

    start_lat, start_lon = get_geocode_dual(source) # get_geocode_tomtom(req.start)
    print("Start location:", start_lat, start_lon)
    if start_lon and start_lat:
        orig = ox.distance.nearest_nodes(G, start_lon, start_lat)
    else:
        return {"error": "Start location not found.", "coords": []}
    
    end_lat, end_lon = get_geocode_dual(target) # get_geocode_tomtom(req.end)
    print("Start location:", end_lat, end_lon)
    if end_lon and end_lat:
        dest = ox.distance.nearest_nodes(G, end_lon, end_lat)
    else:
        return {"error": "End location not found.", "coords": []}

    query_lists = parse_route_query(query) if query else {"avoid": [], "include": []}
    print("Query lists:", query_lists)

    G2, remove_nodes = remove_avoid_nodes(G, query_lists.get("avoid", []))
    print("Removed nodes:", remove_nodes)

    route = dijkstra_path(G2, orig, dest, weight)
    coords = [[G2.nodes[n]["y"], G2.nodes[n]["x"]] for n in route]
    return coords