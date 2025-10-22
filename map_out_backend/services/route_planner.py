import cv2
import numpy as np
import networkx as nx
from PIL import Image

def reroute_path(map_data, disruption):
    image = map_data["image"]
    height, width = image.shape[:2]

    G = nx.grid_2d_graph(width//10, height//10)

    blocked = (width//20, height//20)
    if disruption["type"] == "blockage":
        if G.has_node(blocked):
            G.remove_node(blocked)

    src, dst = (1, 1), (width//10 - 2, height//10 - 2)
    path = nx.shortest_path(G, src, dst)

    for (x, y) in path:
        cv2.circle(image, (x*10, y*10), 2, (0, 0, 255), -1)

    output_path = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    return output_path
