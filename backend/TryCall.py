import osmnx as ox
from Modules.RouteProcessor import CalculateRoute

G = ox.load_graphml("bhubaneswar_drive.graphml")

desired_route, Missing, all_pois_info = CalculateRoute(
    G,
    "KIIT University, Bhubaneswar",
    "Bhubaneswar Railway Station",
    "I want ATM and a Mall but avoid Highway"
)

print("Route points:", len(desired_route))
print("Missing Locations:", Missing)
print("Pois points:", len(all_pois_info))
