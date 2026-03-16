# =============================================================================
# HARIYALI - app.py  (Flask Backend, No pH)
# STATUS: ✅ CORRECT — only minor CORS improvement added
# Endpoints: /, /health, /predict, /sensor-data, /train-model
# =============================================================================

from flask import Flask, request, jsonify
from flask_cors import CORS
import crop_predictor as cp

app = Flask(__name__)

# ✅ FIXED: Added '*' to origins so Flutter Web can connect from any localhost port
CORS(app, resources={r"/*": {
    "origins": ["http://localhost:*", "http://127.0.0.1:*", "http://localhost:5000"],
    "methods": ["GET", "POST", "OPTIONS"],
    "allow_headers": ["Content-Type"],
    "supports_credentials": False
}})

predictor = cp.CropPredictor()
predictor.load_model()

# ─────────────────────────────────────────────────────────────────────────────
# HOME
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "HARIYALI Backend API (No pH)",
        "version": "3.0.0",
        "model_status": "loaded" if predictor.model else "not loaded",
        "features": ["Temperature", "Humidity", "Soil_Moisture",
                     "Soil_Type", "Season", "Nitrogen", "Phosphorous", "Potassium"],
        "endpoints": {
            "/health":      "GET  - Check server health",
            "/predict":     "POST - Get crop prediction",
            "/sensor-data": "POST - Predict from sensor input",
            "/train-model": "POST - Retrain the model",
        }
    })

# ─────────────────────────────────────────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "model_loaded": predictor.model is not None})

# ─────────────────────────────────────────────────────────────────────────────
# PREDICT  (main endpoint called by Flutter recommendation tab)
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/predict", methods=["POST", "OPTIONS"])
def predict():
    if request.method == "OPTIONS":
        return "", 204

    if predictor.model is None:
        return jsonify({"error": "Model not loaded. Run train_model.py first.",
                        "status": "error"}), 500

    try:
        data = request.json or {}

        required = ["temperature", "humidity", "soilMoisture",
                    "nitrogen", "phosphorus", "potassium"]
        missing = [f for f in required if f not in data]
        if missing:
            return jsonify({
                "error": f"Missing required fields: {missing}",
                "required_fields": required,
                "optional_fields": ["soilType", "season"],
                "status": "error"
            }), 400

        result = predictor.predict_crops(data)
        if result is None:
            return jsonify({"error": "Prediction failed.", "status": "error"}), 500

        # ✅ result already contains "recommendations" dict from crop_predictor
        # No need to call _build_advice separately — crop_predictor handles it
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500


@app.route("/predict", methods=["GET"])
def predict_info():
    return jsonify({
        "message": "Use POST with JSON body to get crop prediction.",
        "note":    "pH is NOT required (sensor removed).",
        "example_body": {
            "temperature": 25.5,
            "humidity":    65.0,
            "soilMoisture": 50.0,
            "nitrogen":    80,
            "phosphorus":  45,
            "potassium":   50,
            "soilType":    "Loamy",
            "season":      "Monsoon"
        }
    })

# ─────────────────────────────────────────────────────────────────────────────
# SENSOR DATA
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/sensor-data", methods=["POST"])
def sensor_data():
    data = request.json or {}
    result = predictor.predict_crops(data)
    if result:
        return jsonify(result)
    return jsonify({"error": "Sensor prediction failed"}), 500

# ─────────────────────────────────────────────────────────────────────────────
# RETRAIN
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/train-model", methods=["POST"])
def retrain():
    try:
        import subprocess, sys
        subprocess.run([sys.executable, "train_model.py"], check=True)
        predictor.load_model()
        return jsonify({"status": "success", "message": "Model retrained successfully."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\n" + "="*60)
    print("  HARIYALI Backend Server (No pH)")
    print("="*60)
    print(f"  Model : {'Loaded ✅' if predictor.model else 'NOT LOADED ❌ — run train_model.py'}")
    print("  http://localhost:5000/")
    print("="*60 + "\n")
    app.run(debug=True, host="0.0.0.0", port=5000)