# =============================================================================
# HARIYALI - crop_predictor.py (Fixed for dict encoders + correct column names)
#
# WHAT WAS WRONG:
#   1. soil_encoder.pkl and season_encoder.pkl are plain dicts  e.g. {"Loamy": 1}
#      but the old code called .transform([[value]]) on them → AttributeError
#   2. Feature columns saved in feature_columns.pkl are:
#        ['N', 'P', 'K', 'temperature', 'humidity', 'soil_moisture',
#         'season_encoded', 'soil_type_encoded']
#      but the old _encode_input() built keys like:
#        'Temperature', 'Soil_Moisture', 'Phosphorous', 'Soil_Type_enc'  → KeyError
#
# FIXES:
#   - Dict encoders: use  soil_enc[soil_raw]  instead of  .transform(...)
#   - Column names now exactly match feature_columns.pkl
# =============================================================================

import os
import pickle
import numpy as np
import pandas as pd

# ── Crop database (tips shown in frontend) ────────────────────────────────────
CROP_DATABASE = {
    "Rice":        {"season": "Monsoon",       "duration": 120, "notes": "Main cereal in Terai; needs flooded fields and high humidity."},
    "Paddy":       {"season": "Monsoon",       "duration": 120, "notes": "Paddy thrives in warm, flooded Terai conditions."},
    "Wheat":       {"season": "Winter",        "duration": 110, "notes": "Plant Oct-Nov; harvest Mar-Apr in well-drained soil."},
    "Maize":       {"season": "Summer/Monsoon","duration": 90,  "notes": "Suitable for hilly regions; plant Feb-Mar or Jun-Jul."},
    "Barley":      {"season": "Winter",        "duration": 100, "notes": "Hardy crop; tolerates low temperatures and dry conditions."},
    "Millets":     {"season": "Summer",        "duration": 75,  "notes": "Drought tolerant; grows in sandy soil with low rainfall."},
    "Sugarcane":   {"season": "Summer",        "duration": 365, "notes": "12-month crop; high water and nutrient demand."},
    "Lentil":      {"season": "Winter",        "duration": 110, "notes": "After rice harvest; cool weather; nitrogen-fixing legume."},
    "Chickpea":    {"season": "Winter",        "duration": 100, "notes": "Drought tolerant once established; improves soil fertility."},
    "Soybean":     {"season": "Monsoon",       "duration": 90,  "notes": "Fixes nitrogen; plant during monsoon in loamy soil."},
    "Pulses":      {"season": "Winter",        "duration": 110, "notes": "Protein-rich; grows in cool, dry post-monsoon season."},
    "Potato":      {"season": "Winter",        "duration": 90,  "notes": "High value; plant Sep-Oct or Feb-Mar in hilly areas."},
    "Tomato":      {"season": "Winter/Summer", "duration": 70,  "notes": "High value vegetable; needs support stakes; ready in 60-80 days."},
    "Onion":       {"season": "Winter",        "duration": 120, "notes": "Plant Nov-Dec; harvest when tops fall over."},
    "Garlic":      {"season": "Winter",        "duration": 120, "notes": "Plant Oct-Nov; harvest when leaves turn yellow."},
    "Ginger":      {"season": "Monsoon",       "duration": 240, "notes": "Plant Mar-Apr; prefers warm humid conditions with shade."},
    "Turmeric":    {"season": "Monsoon",       "duration": 270, "notes": "Plant Apr-May; ready in 8-9 months; high humidity needed."},
    "Ground Nuts": {"season": "Summer",        "duration": 120, "notes": "Drought tolerant; sandy loam soil; harvest 120 days after planting."},
    "Mustard":     {"season": "Winter",        "duration": 90,  "notes": "Plant Oct-Nov; major oil seed crop; harvest Mar."},
    "Sunflower":   {"season": "Summer",        "duration": 90,  "notes": "Grows fast; faces the sun; oil and seed crop."},
    "Oil Seeds":   {"season": "Winter",        "duration": 100, "notes": "Post-monsoon oil crop; low water needs."},
    "Cotton":      {"season": "Summer",        "duration": 150, "notes": "Warm-season fiber crop; long frost-free period needed."},
    "Tobacco":     {"season": "Summer",        "duration": 120, "notes": "Well-drained sandy soil; moderate water and nutrients."},
    "Tea":         {"season": "Monsoon",       "duration": 365, "notes": "Hill crop; acidic-friendly soil; high humidity needed."},
    "Coffee":      {"season": "Monsoon",       "duration": 365, "notes": "Mid-hills; shade-loving; harvest Nov-Feb."},
}

# ── Fallback dicts if pkl encoders are plain dicts ────────────────────────────
DEFAULT_SOIL_MAP   = {"Sandy": 0, "Loamy": 1, "Clayey": 2, "Red": 3, "Black": 4}
DEFAULT_SEASON_MAP = {"Winter": 0, "Summer": 1, "Monsoon": 2}


class CropPredictor:
    """
    Loads the trained Random Forest model and predicts crop from sensor data.
    Handles both sklearn OrdinalEncoder objects AND plain dict encoders.

    Sensor data dict keys expected:
        temperature, humidity, soilMoisture, nitrogen, phosphorus, potassium,
        soilType (string, optional), season (string, optional)
    pH is NOT used.
    """

    MODEL_DIR = "."

    def __init__(self):
        self.model         = None
        self.label_encoder = None
        self.soil_encoder  = None
        self.season_encoder= None
        self.feature_cols  = None

    # ── Load model ────────────────────────────────────────────────────────────
    def load_model(self):
        """Load model and encoders from disk. Returns True on success."""
        try:
            mp = self.MODEL_DIR
            with open(os.path.join(mp, "crop_model.pkl"),      "rb") as f: self.model          = pickle.load(f)
            with open(os.path.join(mp, "soil_encoder.pkl"),    "rb") as f: self.soil_encoder   = pickle.load(f)
            with open(os.path.join(mp, "season_encoder.pkl"),  "rb") as f: self.season_encoder = pickle.load(f)
            with open(os.path.join(mp, "feature_columns.pkl"), "rb") as f: self.feature_cols   = pickle.load(f)

            # ✅ FIX: label_encoder.pkl classes don't match the model's actual
            # class indices — causes "unseen labels" error for Turmeric, Sugarcane etc.
            # Solution: rebuild a correct LabelEncoder directly from model.classes_
            # which is always in sync with the trained model. The pkl is ignored.
            from sklearn.preprocessing import LabelEncoder
            self.label_encoder = LabelEncoder()
            self.label_encoder.classes_ = self.model.classes_
            print(f"  [CropPredictor] Model loaded  | features: {list(self.feature_cols)}")
            print(f"  [CropPredictor] Label classes | {list(self.label_encoder.classes_)}")
            print(f"  [CropPredictor] Soil encoder  | type: {type(self.soil_encoder).__name__}")
            print(f"  [CropPredictor] Season encoder| type: {type(self.season_encoder).__name__}")
            return True
        except FileNotFoundError:
            print("  [CropPredictor] ❌ Model files not found. Run train_model.py first.")
            return False
        except Exception as e:
            print(f"  [CropPredictor] ❌ Error loading model: {e}")
            return False

    # ── Encode a single value using either a dict or OrdinalEncoder ──────────
    def _encode_value(self, encoder, value, fallback_map, fallback_default=0):
        """
        Works with both:
          - plain dict  e.g. {"Loamy": 1, "Sandy": 0}
          - sklearn OrdinalEncoder  (has .transform method)
        Returns an integer encoding.
        """
        if isinstance(encoder, dict):
            # Plain dict encoder saved by train_model.py
            result = encoder.get(value)
            if result is None:
                # Try case-insensitive match
                for k, v in encoder.items():
                    if k.lower() == value.lower():
                        return v
                # Not found — use fallback map
                print(f"  [CropPredictor] ⚠️  '{value}' not in encoder dict {list(encoder.keys())} — using fallback")
                return fallback_map.get(value, fallback_default)
            return result
        else:
            # sklearn OrdinalEncoder or LabelEncoder
            try:
                return encoder.transform([[value]])[0][0]
            except Exception:
                return fallback_map.get(value, fallback_default)

    # ── Build feature DataFrame ───────────────────────────────────────────────
    def _encode_input(self, sensor_data: dict) -> pd.DataFrame:
        """
        Convert raw sensor dict into a feature DataFrame that matches
        the exact column names saved in feature_columns.pkl.

        feature_columns.pkl contains:
            ['N', 'P', 'K', 'temperature', 'humidity', 'soil_moisture',
             'season_encoded', 'soil_type_encoded']
        """
        soil_raw   = sensor_data.get("soilType", "Loamy")
        season_raw = sensor_data.get("season",   "Summer")

        soil_enc_val   = self._encode_value(self.soil_encoder,   soil_raw,   DEFAULT_SOIL_MAP,   1)
        season_enc_val = self._encode_value(self.season_encoder, season_raw, DEFAULT_SEASON_MAP, 1)

        # ✅ KEY FIX: column names must exactly match feature_columns.pkl
        # Your pkl has: ['N', 'P', 'K', 'temperature', 'humidity',
        #                'soil_moisture', 'season_encoded', 'soil_type_encoded']
        row = {
            "N":                float(sensor_data.get("nitrogen",     60)),
            "P":                float(sensor_data.get("phosphorus",   40)),
            "K":                float(sensor_data.get("potassium",    40)),
            "temperature":      float(sensor_data.get("temperature",  25.0)),
            "humidity":         float(sensor_data.get("humidity",     60.0)),
            "soil_moisture":    float(sensor_data.get("soilMoisture", 50.0)),
            "season_encoded":   float(season_enc_val),
            "soil_type_encoded":float(soil_enc_val),
        }

        df = pd.DataFrame([row])

        # Reorder to exactly match training order
        try:
            return df[list(self.feature_cols)]
        except KeyError as e:
            print(f"  [CropPredictor] ❌ Column mismatch: {e}")
            print(f"      Built columns   : {list(df.columns)}")
            print(f"      Expected columns: {list(self.feature_cols)}")
            raise

    # ── Predict ───────────────────────────────────────────────────────────────
    def predict_crops(self, sensor_data: dict) -> dict | None:
        """
        Predict crop and return recommendation dict.
        Returns None on failure.
        """
        try:
            if self.model is None:
                if not self.load_model():
                    return None

            features   = self._encode_input(sensor_data)
            pred_enc   = self.model.predict(features)[0]
            proba      = self.model.predict_proba(features)[0]
            confidence = float(proba.max())

            # ✅ FIX: model.predict() already returns the crop name as a string
            # (model was trained with string labels directly).
            # inverse_transform() is NOT needed and crashes when given a string.
            crop = str(pred_enc)

            top3_idx = np.argsort(proba)[-3:][::-1]
            top3 = [
                {"crop": str(self.model.classes_[i]), "confidence": float(proba[i])}
                for i in top3_idx
            ]

            recommendations = self._get_recommendations(
                crop     = crop,
                N        = sensor_data.get("nitrogen",     60),
                P        = sensor_data.get("phosphorus",   40),
                K        = sensor_data.get("potassium",    40),
                moisture = sensor_data.get("soilMoisture", 50),
                temp     = sensor_data.get("temperature",  25),
                humidity = sensor_data.get("humidity",     60),
            )

            return {
                "recommended_crop": crop,
                "confidence":       confidence,
                "top_3_crops":      top3,
                "recommendations":  recommendations,
                "status":           "success",
            }

        except Exception as e:
            print(f"  [CropPredictor] ❌ Prediction error: {e}")
            import traceback
            traceback.print_exc()
            return None

    # ── Build agronomic advice ────────────────────────────────────────────────
    def _get_recommendations(self, crop, N, P, K, moisture, temp, humidity) -> dict:
        """Generate actionable recommendations. pH section removed."""
        rec = {"crop": crop, "fertilizer": "", "irrigation": "", "climate": "", "notes": ""}

        # Fertilizer
        if N < 40:
            rec["fertilizer"] = "Low nitrogen: add Urea or Ammonium Sulfate fertilizer."
        elif N > 110:
            rec["fertilizer"] = "High nitrogen: avoid additional nitrogen fertilizers."
        elif P < 30:
            rec["fertilizer"] = "Low phosphorus: apply DAP or TSP fertilizer."
        elif K < 30:
            rec["fertilizer"] = "Low potassium: apply MOP or SOP fertilizer."
        else:
            rec["fertilizer"] = "Soil nutrients N, P, K are well-balanced."

        # Irrigation
        if moisture < 30:
            rec["irrigation"] = "Critical: increase watering immediately."
        elif moisture < 50:
            rec["irrigation"] = "Increase watering frequency."
        elif moisture > 80:
            rec["irrigation"] = "Reduce watering — soil is near waterlogged."
        else:
            rec["irrigation"] = "Soil moisture is optimal."

        # Climate
        if temp < 15:
            rec["climate"] = "Low temperature — consider greenhouse covering or wait for warmer weather."
        elif temp > 35:
            rec["climate"] = "High temperature — provide shade and increase irrigation."
        elif humidity < 40:
            rec["climate"] = "Low humidity — mulching can help retain soil moisture."
        elif humidity > 90:
            rec["climate"] = "Very high humidity — ensure ventilation to prevent fungal diseases."
        else:
            rec["climate"] = "Climate conditions are favorable."

        # Notes from crop database
        info          = CROP_DATABASE.get(crop, {})
        rec["notes"]  = info.get("notes",    f"{crop} is suitable for current conditions.")
        rec["season"] = info.get("season",   "")
        rec["duration"] = info.get("duration", "")

        return rec