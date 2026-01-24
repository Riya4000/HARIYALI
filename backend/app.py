from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import os
import pandas as pd   # 👈 Added Pandas import

app = Flask(__name__)
CORS(app)

MODEL_PATH = 'crop_model.pkl'
model = None

def load_model():
    global model
    if os.path.exists(MODEL_PATH):
        print("Loading trained model ...")
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)
        print("Model loaded successfully!")
    else:
        print("Model not found! Please train the model: python train_model.py")
        model = None

load_model()

@app.route('/')
def home():
    return jsonify({
        'message': 'HARIYALI Backend API',
        'version': '2.0.0',
        'model_status': 'loaded' if model else 'not loaded',
        'features': ['N', 'P', 'K', 'Temperature', 'Humidity', 'pH', 'Soil Moisture'],
        'endpoints': {'/health': 'GET', '/predict': 'POST'}
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'model_loaded': model is not None})

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model not loaded. Train the model first.'}), 500

    try:
        data = request.json or {}

        # ✅ Use Pandas DataFrame with feature names
        features = pd.DataFrame([[
            data['nitrogen'],
            data['phosphorus'],
            data['potassium'],
            data['temperature'],
            data['humidity'],
            data['pH'],
            data['soilMoisture']
        ]], columns=['N', 'P', 'K', 'temperature', 'humidity', 'pH', 'soilMoisture'])

        # Predict using model
        pred = model.predict(features)[0]
        probabilities = model.predict_proba(features)[0]
        confidence = float(probabilities.max())

        # Top 3 crops
        top_indices = np.argsort(probabilities)[-3:][::-1]
        top_crops = [{
            'crop': str(model.classes_[i]),
            'confidence': float(probabilities[i])
        } for i in top_indices]

        # Recommendations
        recommendations = get_recommendations(
            pred,
            data['nitrogen'], data['phosphorus'], data['potassium'],
            data['pH'], data['soilMoisture'],
            data['temperature'], data['humidity']
        )

        return jsonify({
            'recommended_crop': pred,
            'confidence': confidence,
            'top_3_crops': top_crops,
            'recommendations': recommendations,
            'status': 'success'
        })

    except KeyError as e:
        return jsonify({
            'error': f'Missing required field: {str(e)}',
            'required_fields': ['nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 'pH', 'soilMoisture'],
            'status': 'error'
        }), 400
    except Exception as e:
        return jsonify({'error': str(e), 'status': 'error'}), 500

# 👇 Add this new GET route
@app.route('/predict', methods=['GET'])
def predict_info():
    return jsonify({
        "message": "Use POST with JSON body to get crop prediction.",
        "example_body": {
            "nitrogen": 80,
            "phosphorus": 40,
            "potassium": 40,
            "temperature": 25,
            "humidity": 70,
            "pH": 6.5,
            "soilMoisture": 60
        }
    })
# ... rest of your get_recommendations() function unchanged ...

def get_recommendations(crop, N, P, K, pH, moisture, temp, humidity):
    rec = {'crop': crop, 'fertilizer': '', 'irrigation': '', 'pH_adjustment': '', 'climate': '', 'notes': ''}

    # Fertilizer
    if N < 40:
        rec['fertilizer'] = 'Add nitrogen-rich fertilizer (Urea or Ammonium Sulfate)'
    elif N > 100:
        rec['fertilizer'] = 'Nitrogen is high. Avoid nitrogen fertilizers'
    elif P < 30:
        rec['fertilizer'] = 'Add phosphorus fertilizer (DAP or TSP)'
    elif K < 30:
        rec['fertilizer'] = 'Add potassium fertilizer (MOP or SOP)'
    else:
        rec['fertilizer'] = 'Soil nutrients are well-balanced'

    # Irrigation
    if moisture < 30:
        rec['irrigation'] = 'Critical: increase watering immediately'
    elif moisture < 50:
        rec['irrigation'] = 'Increase watering frequency'
    elif moisture > 80:
        rec['irrigation'] = 'Reduce watering—soil is waterlogged'
    else:
        rec['irrigation'] = 'Soil moisture is optimal'

    # pH
    if pH < 5.5:
        rec['pH_adjustment'] = 'Add lime (CaCO3) to increase pH'
    elif pH > 8.0:
        rec['pH_adjustment'] = 'Add sulfur or organic matter to decrease pH'
    else:
        rec['pH_adjustment'] = 'pH level is optimal'

    # Climate
    if temp < 15:
        rec['climate'] = 'Temperature is low—consider greenhouse or wait for warmer weather'
    elif temp > 35:
        rec['climate'] = 'Temperature is high—provide shade and increase irrigation'
    elif humidity < 40:
        rec['climate'] = 'Humidity is low—mulching can help retain moisture'
    elif humidity > 90:
        rec['climate'] = 'Humidity is high—ensure ventilation to prevent diseases'
    else:
        rec['climate'] = 'Climate conditions are favorable'

    notes = {
        'rice': 'Main crop in Terai; flooded fields; plant during monsoon; harvest in 120–150 days.',
        'wheat': 'Winter crop; plant Oct–Nov; harvest Mar–Apr; well-drained soil.',
        'maize': 'Hilly regions; plant Feb–Mar or Jun–Jul; ready in 90–120 days.',
        'lentil': 'After rice harvest; cool weather; ready in 120–150 days.',
        'potato': 'Hills; plant Sep–Oct or Feb–Mar; harvest in 90–120 days.',
        'tomato': 'High value; needs support stakes; ready in 60–80 days.',
        'cauliflower': 'Cool season; plant Aug–Sep; protect from heavy rain.',
        'cabbage': 'Consistent moisture; ready in 80–100 days.',
        'onion': 'Plant Nov–Dec; long day length; harvest when tops fall.',
        'garlic': 'Plant Oct–Nov; low water; harvest when leaves yellow.',
        'soybean': 'Monsoon; fixes nitrogen; ready in 90–120 days.',
        'chickpea': 'Post-monsoon; drought tolerant; ready in 120–150 days.',
        'sugarcane': '12-month crop; high water; plant Feb–Mar.',
        'tea': 'Hills; acidic soil; high humidity.',
        'coffee': 'Mid-hills; shade-loving; harvest Nov–Feb.'
    }
    rec['notes'] = notes.get(crop, f'{crop.title()} is suitable for current conditions')
    return rec

if __name__ == '__main__':
    print("\n" + "="*70)
    print("HARIYALI Backend Server Starting ...")
    print("="*70)
    print(f"Model Status: {'Loaded' if model else 'Not Loaded'}")
    print("Features: N, P, K, Temperature, Humidity, pH, Soil Moisture")
    print("\nAPI Endpoints:")
    print(" > http://localhost:5000/ (Home)")
    print(" > http://localhost:5000/health (Health Check)")
    print(" > http://localhost:5000/predict (Crop Prediction)")
    print("="*70 + "\n")
    app.run(debug=True, host='0.0.0.0', port=5000)
