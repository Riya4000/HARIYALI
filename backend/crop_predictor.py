# ============================================================================
# CROP PREDICTION MODEL
# Uses Random Forest to predict suitable crops based on sensor data
# ============================================================================
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import joblib
import os
# ============================================================================
# CROP DATABASE WITH DETAILED INFORMATION
# ============================================================================

CROP_DATABASE = {
                    'rice': {
                        'name': 'Rice',
                        'description': 'Rice thrives in warm, humid conditions with consistent water supply. Ideal for flooded or irrigated fields.',
                                                              'tips': [
    'Maintain water level at 5-10 cm during growing season',
    'Plant in pH range of 5.5-6.5',
    'Requires high nitrogen (N) levels',
    'Best temperature: 20-30°C',
    'Harvest when grains are golden yellow'
],
'season': 'Monsoon/Summer',
'growth_duration': 120
},
'maize': {
    'name': 'Maize (Corn)',
    'description': 'Maize grows well in warm weather with moderate rainfall. Requires well drained, fertile soil.',
                          'tips': [
    'Plant in well-drained loamy soil',
    'pH range: 5.5-7.0',
    'Needs moderate nitrogen and phosphorus',
    'Optimal temperature: 18-27°C',
    'Space plants 20-30 cm apart'
],
'season': 'Spring/Summer',
'growth_duration': 90
},
'chickpea': {
    'name': 'Chickpea',
    'description': 'Chickpea is a cool-season legume that improves soil nitrogen. Drought tolerant once established.',
                              'tips': [
    'Grows best in cool, dry weather',
    'pH range: 6.0-7.5',
    'Low water requirements',
    'Temperature: 15-25°C',
    'Rotate with cereal crops for better yield'
],
'season': 'Winter',
'growth_duration': 100
},
'kidneybeans': {
    'name': 'Kidney Beans',
    'description': 'Kidney beans prefer warm weather and well-drained soil. Good source of protein and soil nitrogen.',
                              'tips': [
        'Plant after last frost',
        'pH range: 6.0-7.0',
        'Moderate water needs',
        'Temperature: 18-24°C',
        'Provide support for climbing varieties'
    ],
    'season': 'Spring/Summer',
    'growth_duration': 65
},
'pigeonpeas': {
    'name': 'Pigeon Peas',
    'description': 'Pigeon peas are drought-resistant and improve soil fertility. Ideal for tropical and subtropical regions.',
                                     'tips': [
        'Very drought tolerant',
        'pH range: 5.5-7.5',
        'Fixes nitrogen in soil',
        'Temperature: 20-30°C',
        'Can be intercropped with cereals'
    ],
    'season': 'Monsoon',
    'growth_duration': 150
},
'mothbeans': {
    'name': 'Moth Beans',
    'description': 'Moth beans are extremely drought-resistant legumes. Suitable for arid and semi-arid regions.',
                                         'tips': [
    'Requires very little water',
    'pH range: 6.5-8.0',
    'Tolerates poor soil',
    'Temperature: 25-35°C',
    'Good for crop rotation'
],
'season': 'Summer',
'growth_duration': 75
},
'mungbean': {
    'name': 'Mung Bean',
    'description': 'Mung beans are fast-growing legumes rich in protein. Ideal for multiple cropping systems.',
                     'tips': [
        'Short growing season',
        'pH range: 6.2-7.2',
        'Moderate water needs',
        'Temperature: 25-35°C',
        'Harvest when pods turn brown'
    ],
    'season': 'Summer/Monsoon',
    'growth_duration': 60
},
'blackgram': {
    'name': 'Black Gram',
    'description': 'Black gram is a nutritious pulse crop. Grows well in warm, humid conditions.',
               'tips': [
    'Prefers loamy soil',
    'pH range: 6.5-7.5',
    'Needs good drainage',
    'Temperature: 25-30°C',
    'Sensitive to waterlogging'
],
'season': 'Monsoon',
'growth_duration': 70
},
'lentil': {
    'name': 'Lentil',
    'description': 'Lentils are cool-season legumes rich in protein. Drought-tolerant and nitrogen-fixing.',
                    'tips': [
    'Cool weather crop',
    'pH range: 6.0-8.0',
    'Low water requirements',
    'Temperature: 15-25°C',
    'Avoid waterlogged conditions'
],
'season': 'Winter',
'growth_duration': 110
},
'pomegranate': {
    'name': 'Pomegranate',
    'description': 'Pomegranate is a drought-tolerant fruit tree. Thrives in semi-arid climates.',
             'tips': [
    'Requires well-drained soil',
    'pH range: 5.5-7.5',
    'Drought tolerant once established',
    'Temperature: 15-35°C',
    'Prune regularly for better fruiting'
],
'season': 'Year-round (fruit in fall)',
'growth_duration': 180
},
'banana': {
    'name': 'Banana',
    'description': 'Bananas require warm, humid conditions with plenty of water. High nutrient demand.',
                    'tips': [
        'Needs continuous water supply',
        'pH range: 5.5-7.0',
        'High potassium requirement',
        'Temperature: 20-30°C',
        'Protect from strong winds'
    ],
    'season': 'Year-round (tropical)',
    'growth_duration': 270
},
'mango': {
    'name': 'Mango',
    'description': 'Mango is a tropical fruit tree requiring warm temperatures. Drought tolerant once mature.',
                         'tips': [
    'Needs full sunlight',
    'pH range: 5.5-7.5',
    'Deep watering in dry season',
    'Temperature: 24-30°C',
    'Prune after harvest'
],
'season': 'Summer (fruit)',
'growth_duration': 365
},
'grapes': {
    'name': 'Grapes',
    'description': 'Grapes require moderate temperatures and well-drained soil. Need support structures.',
                       'tips': [
        'Provide trellis support',
        'pH range: 5.5-7.0',
        'Moderate water needs',
        'Temperature: 15-25°C',
        'Prune in dormant season'
    ],
    'season': 'Spring/Summer',
    'growth_duration': 150
},
'watermelon': {
    'name': 'Watermelon',
    'description': 'Watermelon needs warm weather and plenty of space. High water requirement during fruiting.',
                                'tips': [
    'Requires warm soil to germinate',
    'pH range: 6.0-7.0',
    'High water needs during fruiting',
    'Temperature: 21-30°C',
    'Mulch to retain moisture'
],
'season': 'Summer',
'growth_duration': 80
},
'muskmelon': {
    'name': 'Muskmelon',
    'description': 'Muskmelon is a warm-season crop requiring full sun. Sweet and aromatic fruit.',
                   'tips': [
        'Plant in full sun',
        'pH range: 6.0-7.5',
        'Regular watering until fruiting',
        'Temperature: 18-30°C',
        'Harvest when fragrant'
    ],
    'season': 'Summer',
    'growth_duration': 75
},
'apple': {
    'name': 'Apple',
    'description': 'Apples need cool winters for dormancy and moderate summers. Requires cross-pollination.',
                               'tips': [
        'Needs chilling hours in winter',
        'pH range: 6.0-7.0',
        'Regular watering',
        'Temperature: 15-25°C (growing)',
        'Thin fruits for better size'
    ],
    'season': 'Fall (harvest)',
    'growth_duration': 200
},
'orange': {
    'name': 'Orange',
    'description': 'Oranges thrive in subtropical climates. Require consistent moisture and nutrients.',
              'tips': [
    'Needs full sunlight',
    'pH range: 6.0-7.5',
    'Regular irrigation',
    'Temperature: 15-30°C',
    'Fertilize regularly'
],
'season': 'Winter (fruit)',
'growth_duration': 270
},
'papaya': {
    'name': 'Papaya',
    'description': 'Papaya is a fast-growing tropical fruit. Requires warm temperatures year round.',
          'tips': [
    'Plant in full sun',
    'pH range: 6.0-7.0',
    'Needs good drainage',
    'Temperature: 21-33°C',
    'Fruits within first year'
],
'season': 'Year-round (tropical)',
'growth_duration': 180
},
'coconut': {
    'name': 'Coconut',
    'description': 'Coconut palms thrive in tropical coastal areas. Salt-tolerant and drought resistant.',
              'tips': [
    'Needs warm, humid climate',
    'pH range: 5.0-8.0',
    'Salt tolerant',
    'Temperature: 27-32°C',
    'Takes 6-10 years to fruit'
],
'season': 'Year-round',
'growth_duration': 365
},
'cotton': {
    'name': 'Cotton',
    'description': 'Cotton requires warm weather and moderate rainfall. Major fiber crop.',
    'tips': [
        'Needs long frost-free period',
        'pH range: 5.5-8.0',
        'Moderate water needs',
        'Temperature: 21-30°C',
        'Harvest when bolls open'
    ],
    'season': 'Summer',
    'growth_duration': 150
},
'jute': {
    'name': 'Jute',
    'description': 'Jute thrives in warm, humid conditions with heavy rainfall. Important fiber crop.',
         'tips': [
    'Needs high humidity',
    'pH range: 6.0-7.5',
    'High water requirement',
    'Temperature: 24-35°C',
    'Harvest before flowering'
],
'season': 'Monsoon',
'growth_duration': 120
},
'coffee': {
    'name': 'Coffee',
    'description': 'Coffee grows in tropical highlands. Requires shade and consistent moisture.',
             'tips': [
    'Grows well in shade',
    'pH range: 6.0-6.5',
    'Regular rainfall needed',
    'Temperature: 15-24°C',
    'Takes 3-4 years to first harvest'
],
'season': 'Year-round',
'growth_duration': 365
}
}
# ============================================================================
# CROP PREDICTOR CLASS
# =========================================================================\===

class CropPredictor:
    def __init__(self, csv_path='crop_recommendation_dataset.csv'):
        """
        Initialize the crop predictor
        Args:
            csv_path: Path to your crop dataset CSV
        """
        self.csv_path = csv_path
        self.model = None
        self.label_encoder = None
        self.feature_columns = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']

        # ========================================================================

    def load_model(self):
        pass

    def predict_crops(self, sensor_data):
        pass


# TRAIN MODEL FROM CSV
# ========================================================================

def train_model(self):
    """
    Train Random Forest model using CSV data
    """
    try:
        print("      Loading dataset from CSV...")

        # Load CSV data
        df = pd.read_csv(self.csv_path)

        print(f"   Dataset loaded: {len(df)} samples")
        print(f"         Columns: {df.columns.tolist()}")
        print(f"     Crops in dataset: {df['label'].unique().tolist()}")

        # Prepare features and labels
        x = df[self.feature_columns]
        y = df['label']

        # Encode labels
        self.label_encoder = LabelEncoder()
        y_encoded = self.label_encoder.fit_transform(y)

        # Split data
        x_train, x_test, y_train, y_test = train_test_split(
            x, y_encoded, test_size=0.2, random_state=42
        )

        print("         Training Random Forest model...")

        # Train Random Forest
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=15,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42
        )

        self.model.fit(x_train, y_train)

        # Calculate accuracy
        accuracy = self.model.score(x_test, y_test)
        print(f"   Model trained! Accuracy: {accuracy * 100:.2f}%")

        # Save model
        self.save_model()

        return True

    except Exception as e:
        print(f"  Error training model: {e}")
        return False

        # ========================================================================
# SAVE MODEL
# ========================================================================

def save_model(self):
    """
    Save trained model to disk
    """
    try:
        os.makedirs('models', exist_ok=True)

        joblib.dump(self.model, 'models/crop_model.pkl')
        joblib.dump(self.label_encoder, 'models/label_encoder.pkl')

        print("       Model saved successfully!")

    except Exception as e:
        print(f"  Error saving model: {e}")

        # ========================================================================
# LOAD MODEL
# ========================================================================

def load_model(self):
    """
    Load trained model from disk
    """
    try:
        if os.path.exists('models/crop_model.pkl'):
            self.model = joblib.load('models/crop_model.pkl')
            self.label_encoder = joblib.load('models/label_encoder.pkl')
            print("   Model loaded successfully!")
            return True
        else:
            print("    No saved model found. Training new model...")
            return self.train_model()

    except Exception as e:
        print(f"  Error loading model: {e}")
        return False

        # ========================================================================
# PREDICT CROPS
# ========================================================================

def predict_crops(self, sensor_data):
    """
    Predict suitable crops based on sensor data
    Args:
        sensor_data: Dictionary with sensor values
    Returns:
        List of crop recommendations
        :param sensor_data: 
        :param self: 
    """
    try:
        # Ensure model is loaded
        if self.model is None:
            self.load_model()

            # Prepare input features
        # Map sensor data to model features
        features = np.array([[
            sensor_data.get('nitrogen', 40),     # N
            sensor_data.get('phosphorus', 35),   # P
            sensor_data.get('potassium', 42),    # K
            sensor_data.get('temperature', 25),  # temperature
            sensor_data.get('humidity', 65),     # humidity
            sensor_data.get('pH', 6.8),          # ph
            50  # rainfall (mock value since not in greenhouse)
        ]])

        print(f"    Input features: {features}")

        # Get prediction probabilities
        probabilities = self.model.predict_proba(features)[0]

        # Get crop names
        crop_names = self.label_encoder.classes_

        # Create list of predictions with confidence
        predictions = []
        for i, prob in enumerate(probabilities):
            crop_name = crop_names[i]

            # Get crop info from database
            crop_key = crop_name.lower()
            crop_info = CROP_DATABASE.get(crop_key, {
                'name': crop_name,
                'description': f'{crop_name} is suitable for your conditions.',
                'tips': ['Water regularly', 'Provide adequate sunlight', 'Monitor for pests'],
                'season': 'Year-round',
                'growth_duration': 90
            })

            predictions.append({
                'crop_name': crop_info['name'],
                'confidence': float(prob),
                'description': crop_info['description'],
                'tips': crop_info['tips'],
                'season': crop_info['season'],
                'growth_duration': crop_info['growth_duration']
            })

            # Sort by confidence (highest first)
        predictions.sort(key=lambda x: x['confidence'], reverse=True)

        # Return top 5
        top_predictions = predictions[:5]

        print(f"   Top predictions:")
        for pred in top_predictions:
            print(f"   - {pred['crop_name']}: {pred['confidence']*100:.1f}%")

        return top_predictions

    except Exception as e:
        print(f"  Error making prediction: {e}")
        return []