import requests

def get_geocode_tomtom(place_name):
    url = f"https://api.tomtom.com/search/2/geocode/{place_name}.json"
    params = {
        "key": "IkDngm6JSCPd3o9jMYUB6Wm9htAtSarI",
        "limit": 1
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data["results"]:
            lat = data["results"][0]["position"]["lat"]
            lon = data["results"][0]["position"]["lon"]
            return lat, lon
        else:
            print("No results found.")
    else:
        print("Error:", response.status_code, response.text)
    return None, None



def get_geocode_positionstack(place_name):
    url = "http://api.positionstack.com/v1/forward"
    params = {
        "access_key": "4c406b30ee98858e2d99582a612fae9f",
        "query": place_name,
        "limit": 1
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data.get("data"):
            lat = data["data"][0]["latitude"]
            lon = data["data"][0]["longitude"]
            return lat, lon
        else:
            print("No results found.")
    else:
        print("Error:", response.status_code, response.text)
    return None, None

def get_geocode_dual(location):
    lat, lon = get_geocode_tomtom(location)
    if not lat or not lon:
        lat, lon = get_geocode_positionstack(location)
    return lat, lon