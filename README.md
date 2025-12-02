# MAP OUT – Intelligent Route Planner

MAP OUT is a smart route-planning system that finds the best route between two locations
while satisfying user-defined preferences such as visiting malls, hospitals, ATMs,
restaurants, fuel stations, and more.

The system consists of:
- A **Flutter frontend** for user interaction, map display, and visualization.
- A **FastAPI backend** for geocoding, POI fetching, and route optimization.


The app processes natural language queries, fetches POI data from OpenStreetMap,
and computes the optimal path through selected POIs.

------------------------------------------------------------------------------

 Features

- Natural language query parsing
- Automatic detection of required and avoided POIs
- OSNmx-based POI extraction from OpenStreetMap
- A* search for route computation with multiple stops
- Best combination of POIs with minimum detour
- Flutter UI with map view and interactive results
- JSON API communication between Flutter and FastAPI

------------------------------------------------------------------------------

 Project Structure

MAP OUT consists of two main components: Backend + Frontend

```
.
├── backend/
│   ├── main.py               # FastAPI entry point
│   ├── Modules
│   │    ├── RouteProcessor.py     # Core route computation
│   │    ├── QueryProcessor.py     # Natural language preference parsing
│   │    ├── geocode.py            # Geocode like latitude and longitude
│   │    ├── poi_utils.py          # Fetching and filtering POIs
│   │    ├── route_utils.py        # A* pathfinding utilities
│   │    └── Modules/geocode.py    # Geocoding helper
│   └── bhubaneswar_drive.graphml  # Cached OSM graph
│
└── frontend/
    ├── lib/
    │   ├── main.dart         # Flutter app entry point
    └── pubspec.yaml          # Flutter dependencies


```

# Frontend

## About the Flutter App

The Flutter frontend is responsible for:
- Taking user input for start, end, and query
- Calling the FastAPI backend
- Displaying results on a map (Google Maps / Flutter Map)
- Showing selected POIs and route details

This enables a fully interactive, mobile-friendly experience.

# Running the Flutter App

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Make sure the backend (FastAPI) is running and accessible.

------------------------------------------------------------------------------


# Running the backend

Install dependencies:

```bash
pip install -r requirements.txt
```

Start server:

```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```


# API Endpoint

POST: `/route`

Request:
```json
{
  "start": "Location A",
  "end": "Location B",
  "query": "I need a restaurant and mall but avoid fuel"
}
```

Response:
```json
{
  "route": [],
  "missing_locs": [],
  "selected_pois": [
    { "name": "XYZ Mall", "lat": , "lon": , "pref_type": "mall" }
  ],
  "all_pois": [...]
}
```

------------------------------------------------------------------------------

 How Routing Works

# 1. Query Parsing

Extracts:
- included POIs (e.g., restaurant, mall)
- avoided POIs (e.g., petrol bunk)

# 2. POI Fetching

The backend fetches POIs using:
- OpenStreetMap (via OSMnx)
- Filtering based on preference and avoid rules

# 3. Route Optimization

The system:
- Computes the direct route
- Finds candidate POIs for each preference
- Generates combinations & permutations
- Uses A* to compute path length
- Selects the best minimal-detour route

# 4. Response sent back to Flutter

Flutter then visualizes:
- The route
- Selected POIs
- Missing POI types
- Additional POI information

------------------------------------------------------------------------------

 Requirements

# Backend Requirements
- Python 3.10+
- FastAPI
- uvicorn
- OSMnx
- NetworkX
- Shapely
- Geopy

# Flutter Requirements
- Flutter SDK
- Dart 3+
- Internet permission (Android/iOS)
- Maps plugin (Google Maps or Flutter Map)

------------------------------------------------------------------------------

 Customization


  Add more POI types in:
  - QueryProcessor.py → synonym mapping
  - RouteProcessor.py → PREFERENCE_TAGS
  - poi_utils.py → OSM tag mapping

Update Flutter UI/logic easily by modifying:
- screens/
- services/api_service.dart
- widgets/

------------------------------------------------------------------------------

 Future Enhancements

- Multiple-language query support
- Traffic-aware routing
- Offline routing capability
- Better POI ranking logic
- Real-time location tracking
- Saved routes & user profiles

------------------------------------------------------------------------------

 License

This project is open for personal and academic use.
Modify and extend as you wish.

