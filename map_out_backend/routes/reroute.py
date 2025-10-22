from flask import Blueprint, request, jsonify
from services.image_processor import process_map_image
from services.nlp_processor import extract_disruption_info
from services.route_planner import reroute_path
import os
import uuid

reroute_bp = Blueprint("reroute", __name__)

@reroute_bp.route("/reroute", methods=["POST"])
def reroute():
    try:
        image_file = request.files['image']
        query = request.form['query']

        filename = f"{uuid.uuid4()}.jpg"
        save_path = os.path.join("static", "outputs", filename)
        image_file.save(save_path)

        map_data = process_map_image(save_path)
        print("Map data extracted")
        disruption = extract_disruption_info(query)
        print("Disruption info extracted")
        new_path_image = reroute_path(map_data, disruption)
        print("Path rerouted")

        new_filename = f"rerouted_{filename}"
        new_image_path = os.path.join("static", "outputs", new_filename)
        new_path_image.save(new_image_path)
        print("New path image saved")

        return jsonify({
            "status": "success",
            "message": "Path rerouted successfully",
            "image_url": f"/static/outputs/{new_filename}"
        })
    
    except Exception as e:
        print(f"Error during reroute: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
