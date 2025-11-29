import heapq
import math

def heuristic(G, a, b):
    ax, ay = G.nodes[a]["x"], G.nodes[a]["y"]
    bx, by = G.nodes[b]["x"], G.nodes[b]["y"]
    return math.sqrt((ax - bx)**2 + (ay - by)**2)

def astar_path(G, start, goal):
    pq = [(0, start)]
    g = {start: 0}
    parent = {start: None}
    while pq:
        f, current = heapq.heappop(pq)
        if current == goal:
            path = []
            while current is not None:
                path.append(current)
                current = parent[current]
            return path[::-1]
        for nbr in G.neighbors(current):
            weight = G[current][nbr][0].get("length", 1)
            tentative_g = g[current] + weight
            if nbr not in g or tentative_g < g[nbr]:
                g[nbr] = tentative_g
                f_score = tentative_g + heuristic(G, nbr, goal)
                parent[nbr] = current
                heapq.heappush(pq, (f_score, nbr))
    return None

def astar_length(G, start, goal):
    pq = [(0, start)]
    g = {start: 0}
    while pq:
        f, current = heapq.heappop(pq)
        if current == goal:
            return g[current]
        for nbr in G.neighbors(current):
            weight = G[current][nbr][0].get("length", 1)
            tentative_g = g[current] + weight
            if nbr not in g or tentative_g < g[nbr]:
                g[nbr] = tentative_g
                f_score = tentative_g + heuristic(G, nbr, goal)
                heapq.heappush(pq, (f_score, nbr))
    return float("inf")

    
def compute_route_and_length(G, src_node, dst_node, waypoints):
    total_length = 0.0
    full_nodes = []
    cur = src_node
    try:
        for wp in waypoints:
            path = astar_path(G, cur, wp)
            if path is None:
                return float("inf"), []
            length = astar_length(G, cur, wp)
            total_length += length
            if full_nodes:
                full_nodes.extend(path[1:])
            else:
                full_nodes.extend(path)
            cur = wp
        path = astar_path(G, cur, dst_node)
        if path is None:
            return float("inf"), []
        length = astar_length(G, cur, dst_node)
        total_length += length
        if full_nodes:
            full_nodes.extend(path[1:])
        else:
            full_nodes.extend(path)
        return total_length, full_nodes
    except Exception:
        return float("inf"), []
