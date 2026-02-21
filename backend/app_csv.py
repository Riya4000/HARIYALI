# ============================================================================
# HARIYALI BACKEND - Flask API
# Connects Firebase + ML Model for crop recommendations
# ============================================================================

from flask import Flask, request, jsonify
from flask_cors import CORS

import crop_predictor
import firebase_config

# Initialize Flask app
app = Flask(__name__)
# Enable CORS for Flutter web
CORS(app, resources={
    r"/*": {
        "origins": ["http://localhost:*", "http://127.0.0.1:*"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})
# Initialize Firebase
firebase_config.initialize_firebase()
# Initialize ML model
predictor = crop_predictor.CropPredictor(csv_path='crop_recommendation_dataset.csv , model_path=crop_model.pkl')
predictor.load_model()  # Load or train model
# ============================================================================
# HOME ROUTE
# ============================================================================

@app.route('/', methods=['GET'])
def home():
    """
    Home endpoint - Check if API is running
    """
    return jsonify({
        'status': 'success',
        'message': 'HARIYALI Backend API is running!   ',
        'endpoints': {
            '/predict': 'POST - Get crop recommendations',
            '/sensor-data': 'GET - Get current sensor data from Firebase',
            '/update-control': 'POST - Update control state (pump/window/light)',
            '/train-model': 'POST - Retrain ML model',
        }
    })

# ============================================================================
# GET SENSOR DATA FROM FIREBASE
# ============================================================================

@app.route('/sensor-data', methods=['GET'])
def get_sensor_data():
    """
    Fetch current sensor data from Firebase
    """
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
    Get crop recommendations based on sensor data
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

        print(f"      Received sensor data: {sensor_data}")

        # Get predictions from ML model
        recommendations = predictor.predict_crops(sensor_data)

        if not recommendations:
            return jsonify({
                'status': 'error',
                'message': 'Could not generate recommendations'
            }), 500

            # Save predictions to Firebase
        firebase_config.save_prediction_to_firebase(recommendations)

        # Return recommendations
        return jsonify({
            'status': 'success',
            'recommendations': recommendations,
            'sensor_data': sensor_data
        })

    except Exception as e:
        print(f"  Error in /predict: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

    # ============================================================================
# UPDATE CONTROLS (Pump, Window, Light)
# ============================================================================

@app.route('/update-control', methods=['POST'])
def update_control():
    """
    Update control state in Firebase
    Body: {
        "control": "pump" | "window" | "light",
        "state": true | false
    }
    """
    try:
        data = request.json
        control_name = data.get('control')
        state = data.get('state')

        if control_name not in ['pump', 'window', 'light']:
            return jsonify({
                'status': 'error',
                'message': 'Invalid control name'
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
    """
    Retrain the ML model with latest CSV data
    """
    try:
        print("         Starting model training...")
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
# AUTO-PREDICT ON SENSOR UPDATES (Optional)
# ============================================================================
def auto_predict_on_update(sensor_data):
    """
    Automatically generate predictions when sensor data updates
    This runs in the background
    """
    print("Sensor data updated! Generating new predictions...")
    recommendations = predictor.predict_crops(sensor_data)
    firebase_config.save_prediction_to_firebase(recommendations)

# Uncomment to enable auto-predictions
# firebase_config.listen_to_sensor_updates(auto_predict_on_update)

# ============================================================================
# RUN SERVER
# ============================================================================
if __name__ == '__main__':
    print(""" 
╔══════════════════════════════════════╗ 
║      
HARIYALI BACKEND STARTED       
║ 
╠══════════════════════════════════════╣ 
║  Server: http://localhost:5000       
║ 
║  Status: Ready to serve predictions! ║ 
╚══════════════════════════════════════╝ 
""")
# Run Flask app
app.run(
    debug=True,
    host='0.0.0.0',  # Allow external connections
    port=5000
)