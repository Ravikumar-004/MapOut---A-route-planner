from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import osmnx as ox
from Route_basic import dijkstra_path

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Bhubaneswar road network once
G = ox.load_graphml("backend/bhubaneswar_drive.graphml")

class RouteRequest(BaseModel):
    start_lat: float
    start_lon: float
    end_lat: float
    end_lon: float
    avoid_lat: float | None = None
    avoid_lon: float | None = None

@app.post("/route")
def route(req: RouteRequest):
    # nearest nodes
    orig = ox.distance.nearest_nodes(G, req.start_lon, req.start_lat)
    dest = ox.distance.nearest_nodes(G, req.end_lon, req.end_lat)
    avoid = None
    if req.avoid_lat and req.avoid_lon:
        avoid = ox.distance.nearest_nodes(G, req.avoid_lon, req.avoid_lat)
    
    G2 = G.copy()
    if avoid:
        if avoid in G2.nodes:
            G2.remove_node(avoid)
    
    try:
        # route = nx.shortest_path(G2, orig, dest, weight="length")
        route = dijkstra_path(G2, orig, dest, weight="length")
        coords = [[G2.nodes[n]["y"], G2.nodes[n]["x"]] for n in route]
        print("routes:\n",route)
        print("Coords:\n",coords)
        return {"coords": coords}
    except Exception as e:
        return {"error": str(e), "coords": []}
