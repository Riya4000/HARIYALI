# =============================================================================
# HARIYALI - diagnose.py
# Run this in your backend/ folder to find the exact prediction error.
# Usage: python diagnose.py
# =============================================================================

import os, pickle, traceback

print("\n" + "="*60)
print("  HARIYALI BACKEND DIAGNOSTICS")
print("="*60)

# ── Step 1: Check which .pkl files exist ──────────────────────────────────────
print("\n[1] Checking model files in current directory...")
required_files = [
    "crop_model.pkl",
    "label_encoder.pkl",
    "soil_encoder.pkl",
    "season_encoder.pkl",
    "feature_columns.pkl",
    "crop_recommendation_dataset.csv",
]
all_ok = True
for f in required_files:
    exists = os.path.exists(f)
    status = "✅ Found" if exists else "❌ MISSING"
    print(f"   {status}: {f}")
    if not exists:
        all_ok = False

if not all_ok:
    print("\n❌ MISSING FILES — run: python train_model.py")
    print("   (or python create_dataset.py first if the CSV is also missing)")
    exit(1)

# ── Step 2: Load each pickle ───────────────────────────────────────────────────
print("\n[2] Loading pickle files...")
try:
    with open("crop_model.pkl", "rb") as f:
        model = pickle.load(f)
    print(f"   ✅ crop_model.pkl loaded  — type: {type(model).__name__}")
    print(f"       n_estimators: {model.n_estimators}  |  classes: {len(model.classes_)}")
except Exception as e:
    print(f"   ❌ crop_model.pkl FAILED: {e}")
    exit(1)

try:
    with open("label_encoder.pkl", "rb") as f:
        le = pickle.load(f)
    print(f"   ✅ label_encoder.pkl     — classes: {list(le.classes_)}")
except Exception as e:
    print(f"   ❌ label_encoder.pkl FAILED: {e}")
    exit(1)

try:
    with open("soil_encoder.pkl", "rb") as f:
        soil_enc = pickle.load(f)
    print(f"   ✅ soil_encoder.pkl      — type: {type(soil_enc).__name__}")
except Exception as e:
    print(f"   ❌ soil_encoder.pkl FAILED: {e}")
    exit(1)

try:
    with open("season_encoder.pkl", "rb") as f:
        season_enc = pickle.load(f)
    print(f"   ✅ season_encoder.pkl    — type: {type(season_enc).__name__}")
except Exception as e:
    print(f"   ❌ season_encoder.pkl FAILED: {e}")
    exit(1)

try:
    with open("feature_columns.pkl", "rb") as f:
        feature_cols = pickle.load(f)
    print(f"   ✅ feature_columns.pkl   — columns: {list(feature_cols)}")
except Exception as e:
    print(f"   ❌ feature_columns.pkl FAILED: {e}")
    exit(1)

# ── Step 3: Test encoding ──────────────────────────────────────────────────────
print("\n[3] Testing encoder transforms...")
import pandas as pd
import numpy as np

test_data = {
    "temperature":  29.8,
    "humidity":     69.7,
    "soilMoisture": 47.4,
    "nitrogen":     73,
    "phosphorus":   55,
    "potassium":    52,
    "soilType":     "Loamy",
    "season":       "Monsoon",
}

try:
    soil_raw   = test_data.get("soilType", "Loamy")
    season_raw = test_data.get("season",   "Summer")

    # Try soil encoder
    try:
        soil_val = soil_enc.transform([[soil_raw]])[0][0]
        print(f"   ✅ soil_encoder.transform(['{soil_raw}'])  → {soil_val}")
    except Exception as e:
        print(f"   ❌ soil_encoder FAILED on '{soil_raw}': {e}")
        print(f"      Valid categories: {soil_enc.categories_}")
        exit(1)

    # Try season encoder
    try:
        season_val = season_enc.transform([[season_raw]])[0][0]
        print(f"   ✅ season_encoder.transform(['{season_raw}']) → {season_val}")
    except Exception as e:
        print(f"   ❌ season_encoder FAILED on '{season_raw}': {e}")
        print(f"      Valid categories: {season_enc.categories_}")
        exit(1)

except Exception as e:
    print(f"   ❌ Encoding step failed: {e}")
    traceback.print_exc()
    exit(1)

# ── Step 4: Build feature row ──────────────────────────────────────────────────
print("\n[4] Building feature DataFrame...")
try:
    row = {
        "Temperature":    test_data["temperature"],
        "Humidity":       test_data["humidity"],
        "Soil_Moisture":  test_data["soilMoisture"],
        "Soil_Type_enc":  soil_val,
        "Season_enc":     season_val,
        "Nitrogen":       test_data["nitrogen"],
        "Phosphorous":    test_data["phosphorus"],
        "Potassium":      test_data["potassium"],
    }
    print(f"   Row dict: {row}")
    df = pd.DataFrame([row])
    print(f"   DataFrame columns: {list(df.columns)}")
    print(f"   Feature cols expected: {list(feature_cols)}")

    # Check all expected columns are present
    missing = [c for c in feature_cols if c not in df.columns]
    if missing:
        print(f"   ❌ MISSING columns in DataFrame: {missing}")
        exit(1)

    df_ordered = df[feature_cols]
    print(f"   ✅ Feature DataFrame built successfully: shape {df_ordered.shape}")

except Exception as e:
    print(f"   ❌ Feature building FAILED: {e}")
    traceback.print_exc()
    exit(1)

# ── Step 5: Run prediction ─────────────────────────────────────────────────────
print("\n[5] Running model.predict()...")
try:
    pred_enc   = model.predict(df_ordered)[0]
    proba      = model.predict_proba(df_ordered)[0]
    confidence = float(proba.max())
    crop       = le.inverse_transform([pred_enc])[0]
    top3_idx   = np.argsort(proba)[-3:][::-1]
    top3       = [{"crop": str(le.classes_[i]), "confidence": float(proba[i])}
                  for i in top3_idx]

    print(f"   ✅ Prediction successful!")
    print(f"       Recommended crop : {crop}")
    print(f"       Confidence       : {confidence:.3f}")
    print(f"       Top 3            : {[c['crop'] for c in top3]}")

except Exception as e:
    print(f"   ❌ Prediction FAILED: {e}")
    traceback.print_exc()
    exit(1)

print("\n" + "="*60)
print("  ✅ ALL CHECKS PASSED — crop_predictor should work fine")
print("  If you still see 500 errors, restart app.py and try again.")
print("="*60 + "\n")