import osmnx as ox
from RouteProcesor import CalculateRoute

G = ox.load_graphml("bhubaneswar_drive.graphml")

route_data = CalculateRoute(
    G,
    "KIIT University, Bhubaneswar",
    "Bhubaneswar Railway Station",
    "avoid Janpath Road"
)

print(route_data)
