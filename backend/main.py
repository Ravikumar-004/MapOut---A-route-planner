from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import osmnx as ox
import logging
from Modules.RouteProcessor import CalculateRoute


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mapout")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# load graph once (assumes file exists)
G = ox.load_graphml("bhubaneswar_drive.graphml")
logger.info("Graph loaded: nodes=%d, edges=%d", len(G.nodes), len(G.edges))

class RouteRequest(BaseModel):
    start: str
    end: str
    query: str | None = None

@app.post("/route")
def route(req: RouteRequest):
    logger.info("Received route request: start=%s end=%s query=%s", req.start, req.end, req.query)
    try:
        desired_route, Missing, all_pois_info = CalculateRoute(G, req.start, req.end, req.query)
        logger.info("Route computed: points=%d, missing=%s, poi points=%s", 
                    len(desired_route), Missing, len(all_pois_info))
        return {"route": desired_route, "missing_locs": Missing, "all_pois": all_pois_info}
    except Exception as e:
        logger.exception("Error calculating route")
        return {"error": str(e), "coords": []}
