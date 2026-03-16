# Run this in your backend/ folder: python quick_test.py
import traceback
import crop_predictor as cp

predictor = cp.CropPredictor()
predictor.load_model()

print(f"\nmodel.classes_ = {list(predictor.model.classes_)}")
print(f"label_encoder.classes_ = {list(predictor.label_encoder.classes_)}")

test_data = {
    "temperature":  21.4,
    "humidity":     70.9,
    "soilMoisture": 49.7,
    "nitrogen":     93,
    "phosphorus":   47,
    "potassium":    43,
    "soilType":     "Loamy",
    "season":       "Monsoon",
}

print("\nBuilding feature DataFrame...")
try:
    df = predictor._encode_input(test_data)
    print(f"DataFrame:\n{df}")
    print(f"\nRunning predict...")
    pred_enc = predictor.model.predict(df)[0]
    print(f"pred_enc = {pred_enc}  (type: {type(pred_enc).__name__})")
    proba = predictor.model.predict_proba(df)[0]
    print(f"proba max = {proba.max():.3f}")
    crop = predictor.label_encoder.inverse_transform([pred_enc])[0]
    print(f"crop = {crop}")
except Exception as e:
    traceback.print_exc()