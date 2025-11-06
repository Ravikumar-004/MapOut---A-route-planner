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