import osmnx as ox

place = "Odisha, India"

G = ox.graph_from_place(place, network_type="drive", simplify=True) # 36 seconds
ox.save_graphml(G, "odisha_drive.graphml") # 6 seconds


# ox.save_graph_geopackage(G, "bhubaneswar_drive.gpkg")
# nodes, edges = ox.graph_to_gdfs(G)
# nodes.to_file("bhubaneswar_nodes.geojson", driver="GeoJSON")
# edges.to_file("bhubaneswar_edges.geojson", driver="GeoJSON")
