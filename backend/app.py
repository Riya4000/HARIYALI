# ============================================================================
# HARIYALI BACKEND - Flask API (app.py)
# Connects Firebase + ML Model for crop recommendations
# NOTE: Light/LED control removed — no physical LED hardware in the system.
#       /update-control now only accepts "pump" and "window".
# ============================================================================

from flask import Flask, request, jsonify
from flask_cors import CORS

import crop_predictor
import firebase_config

# Initialize Flask app
app = Flask(__name__)

# Enable CORS for Flutter web
# ✅ FIX: Use "*" to allow ALL origins — Flask-CORS does NOT support
# wildcard ports like "http://localhost:*". Flutter Web runs on a random
# port (e.g. localhost:53419) which never matched the old pattern,
# causing the browser to block every request even though the server runs.
CORS(app, resources={r"/*": {"origins": "*"}})

# Initialize Firebase
firebase_config.initialize_firebase()

# Initialize ML model
predictor = crop_predictor.CropPredictor()
predictor.load_model()

# ============================================================================
# HOME ROUTE
# ============================================================================

@app.route('/', methods=['GET'])
def home():
    """Home endpoint - Check if API is running"""
    return jsonify({
        'status': 'success',
        'message': 'HARIYALI Backend API is running!',
        'endpoints': {
            '/predict':        'POST - Get crop recommendations',
            '/sensor-data':    'GET  - Get current sensor data from Firebase',
            '/update-control': 'POST - Update control state (pump/window)',
            '/train-model':    'POST - Retrain ML model',
        }
    })

# ============================================================================
# HEALTH CHECK — called by Flutter ml_service.dart checkHealth()
# This route was missing, causing checkHealth() to always return false
# and the frontend to always show "Backend offline"
# ============================================================================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Flutter frontend"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': predictor.model is not None
    })

# ============================================================================
# GET SENSOR DATA FROM FIREBASE
# ============================================================================

@app.route('/sensor-data', methods=['GET'])
def get_sensor_data():
    """Fetch current sensor data from Firebase"""
    try:
        data = firebase_config.get_sensor_data()

        if data:
            return jsonify({
                'status': 'success',
                'data': data
            })
        else:
            return jsonify({
                'status': 'error',
                'message': 'No sensor data available'
            }), 404

    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

# ============================================================================
# PREDICT CROPS (Main Feature!)
# ============================================================================

@app.route('/predict', methods=['POST', 'OPTIONS'])
def predict():
    """
    Get crop recommendations based on sensor data.
    Accepts either:
    1. Sensor data in request body
    2. No data (fetches from Firebase automatically)
    """
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return '', 204

    try:
        # Get sensor data from request or Firebase
        sensor_data = request.json if request.json else firebase_config.get_sensor_data()

        if not sensor_data:
            return jsonify({
                'status': 'error',
                'message': 'No sensor data available'
            }), 400

        print(f"  Received sensor data: {sensor_data}")

        # Get predictions from ML model
        result = predictor.predict_crops(sensor_data)

        if not result:
            return jsonify({
                'status': 'error',
                'message': 'Could not generate recommendations'
            }), 500

        # Save predictions to Firebase
        firebase_config.save_prediction_to_firebase(result)

        # Return result directly (already has correct structure from CropPredictor)
        return jsonify(result)

    except Exception as e:
        print(f"  Error in /predict: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


@app.route('/predict', methods=['GET'])
def predict_info():
    return jsonify({
        "message": "Use POST with JSON body to get crop prediction.",
        "note": "pH is NOT required (sensor removed).",
        "example_body": {
            "temperature": 25.5,
            "humidity": 65.0,
            "soilMoisture": 50.0,
            "nitrogen": 80,
            "phosphorus": 45,
            "potassium": 50,
            "soilType": "Loamy",
            "season": "Monsoon"
        }
    })

# ============================================================================
# UPDATE CONTROLS (Pump, Window only — Light removed)
# ============================================================================

@app.route('/update-control', methods=['POST'])
def update_control():
    """
    Update control state in Firebase.
    Body: {
        "control": "pump" | "window",
        "state": true | false
    }
    Note: "light" removed — no physical LED hardware.
    """
    try:
        data = request.json
        control_name = data.get('control')
        state = data.get('state')

        # "light" removed from valid controls
        if control_name not in ['pump', 'window']:
            return jsonify({
                'status': 'error',
                'message': 'Invalid control name. Valid options: pump, window'
            }), 400

        success = firebase_config.update_control(control_name, state)

        if success:
            return jsonify({
                'status': 'success',
                'message': f'{control_name} updated to {state}'
            })
        else:
            return jsonify({
                'status': 'error',
                'message': 'Failed to update control'
            }), 500

    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

# ============================================================================
# RETRAIN MODEL
# ============================================================================

@app.route('/train-model', methods=['POST'])
def train_model():
    """Retrain the ML model with latest CSV data"""
    try:
        print("  Starting model training...")
        success = predictor.train_model()

        if success:
            return jsonify({
                'status': 'success',
                'message': 'Model trained successfully!'
            })
        else:
            return jsonify({
                'status': 'error',
                'message': 'Model training failed'
            }), 500
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

# ============================================================================
if __name__ == '__main__':
    print("\n" + "=" * 60)
    print("  HARIYALI Backend Server")
    print("=" * 60)
    print(f"  Model : {'Loaded ✅' if predictor.model else 'NOT LOADED ❌ — run train_model.py'}")
    print("  http://localhost:5000/")
    print("=" * 60 + "\n")
    app.run(debug=True, host='0.0.0.0', port=5000)