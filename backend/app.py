# ============================================================================
# HARIYALI BACKEND - Simple Version for Beginners
# ============================================================================
# Save this file as: backend/app.py

from flask import Flask, request, jsonify
from flask_cors import CORS

# Create Flask app
app = Flask(__name__)
CORS(app)  # Allow Flutter app to connect

# ============================================================================
# HOME PAGE - Test if server is running
# ============================================================================
@app.route('/')
def home():
    """
    Visit http://localhost:5000/ to see this
    """
    return jsonify({
        'message': 'HARIYALI Backend is running!',
        'status': 'OK',
        'version': '1.0'
    })

# ============================================================================
# HEALTH CHECK - Check if API is working
# ============================================================================
@app.route('/health')
def health():
    """
    Visit http://localhost:5000/health to test
    """
    return jsonify({
        'status': 'healthy',
        'server': 'running'
    })

# ============================================================================
# CROP RECOMMENDATION - Main AI feature
# ============================================================================
@app.route('/predict', methods=['POST'])
def predict():
    """
    This receives sensor data from Flutter app
    and returns crop recommendation
    
    Flutter sends JSON like:
    {
        "nitrogen": 90,
        "phosphorus": 42,
        "temperature": 25.5,
        ...
    }
    """
    try:
        # Get data from Flutter app
        data = request.json
        
        # Extract sensor values
        nitrogen = data.get('nitrogen', 0)
        phosphorus = data.get('phosphorus', 0)
        potassium = data.get('potassium', 0)
        temperature = data.get('temperature', 0)
        humidity = data.get('humidity', 0)
        pH = data.get('pH', 7.0)
        soilMoisture = data.get('soilMoisture', 0)
        
        # ====================================================================
        # SIMPLE CROP RECOMMENDATION LOGIC
        # (Later replace with Machine Learning model)
        # ====================================================================
        
        recommended_crop = "rice"  # Default
        
        # Simple rules based on conditions
        if temperature > 30 and humidity > 70:
            recommended_crop = "rice"
        elif temperature < 25 and soilMoisture < 50:
            recommended_crop = "wheat"
        elif pH > 7.0 and nitrogen > 50:
            recommended_crop = "cotton"
        elif temperature > 25 and temperature < 30:
            recommended_crop = "maize"
        
        # Generate recommendations
        recommendations = {
            'fertilizer': get_fertilizer_recommendation(nitrogen, phosphorus, potassium),
            'irrigation': get_irrigation_recommendation(soilMoisture),
            'pH_adjustment': get_pH_recommendation(pH),
            'notes': f'{recommended_crop} is suitable for your current conditions'
        }
        
        # Send response back to Flutter app
        return jsonify({
            'recommended_crop': recommended_crop,
            'confidence': 0.85,  # Fake confidence for now
            'recommendations': recommendations,
            'status': 'success'
        })
        
    except Exception as e:
        # If something goes wrong, send error message
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 400

# ============================================================================
# HELPER FUNCTIONS - Give specific advice
# ============================================================================

def get_fertilizer_recommendation(N, P, K):
    """Recommend fertilizer based on NPK levels"""
    if N < 40:
        return "Add nitrogen-rich fertilizer (Urea)"
    elif P < 30:
        return "Add phosphorus fertilizer (DAP)"
    elif K < 30:
        return "Add potassium fertilizer (MOP)"
    else:
        return "Soil nutrients are balanced ✓"

def get_irrigation_recommendation(moisture):
    """Recommend watering based on moisture"""
    if moisture < 40:
        return "Increase watering - soil is DRY"
    elif moisture > 80:
        return "Reduce watering - soil is TOO WET"
    else:
        return "Moisture level is optimal ✓"

def get_pH_recommendation(pH):
    """Recommend pH adjustment"""
    if pH < 6.0:
        return "Add lime to increase pH (soil is acidic)"
    elif pH > 7.5:
        return "Add sulfur to decrease pH (soil is alkaline)"
    else:
        return "pH level is optimal ✓"

# ============================================================================
# START SERVER
# ============================================================================
if __name__ == '__main__':
    print("\n" + "="*60)
    print("🌱 HARIYALI Backend Server")
    print("="*60)
    print("Server running at: http://localhost:5000")
    print("\nAvailable endpoints:")
    print("  → http://localhost:5000/          (Home)")
    print("  → http://localhost:5000/health    (Health Check)")
    print("  → http://localhost:5000/predict   (Crop Prediction)")
    print("="*60 + "\n")
    
    # Start Flask server
    app.run(debug=True, host='0.0.0.0', port=5000)