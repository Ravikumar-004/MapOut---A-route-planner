from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import osmnx as ox
from RouteProcesor import CalculateRoute

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

G = ox.load_graphml("bhubaneswar_drive.graphml")

class RouteRequest(BaseModel):
    start: str
    end: str
    query: str | None = None

@app.post("/route")
def route(req: RouteRequest):
    print("Received route request, ", req)
    try:
        coords = CalculateRoute(G, req.start, req.end, req.query, weight="length")
        print("Coords Length:\n",len(coords))
        return {"coords": coords}
    except Exception as e:
        print("Error calculating route:", str(e))
        return {"error": str(e), "coords": []}
