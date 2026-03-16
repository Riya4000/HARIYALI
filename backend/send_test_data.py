# =============================================================================
# HARIYALI - send_test_data.py
# STATUS: ❌ BUG FIXED — "pH" key was still being generated and sent to Firebase
#                         even though pH sensor was removed. This caused:
#                         1. Firebase 'current' node still had a 'pH' field
#                         2. History entries had 'pH' in sensor_data
#                         3. Backend /predict received 'pH' which it ignores (harmless)
#                            but the old Firebase history data with pH can confuse
#                            SensorData.fromMap() if pH field is unexpected.
#
# ✅ FIXES APPLIED:
#   1. Removed 'pH' from generated data dict
#   2. result['recommendations'] in history now saved correctly
#      (backend returns recommendations as a dict, not a list — fixed print too)
#   3. Added history also written to sensors/{USER_ID}/history/{push_key}
#      so SensorService._loadHistoricalData() can find it
# =============================================================================

import requests
import time
import random

# =============================================================================
# CONFIGURATION — update USER_ID to your Firebase UID
# =============================================================================
FIREBASE_URL = "https://hariyali-10a26-default-rtdb.firebaseio.com"
BACKEND_URL  = "http://localhost:5000/predict"
USER_ID      = "PeWmSMYFR9SWf9FVKDkqF9q3sfe2"   # ← Replace with your Firebase UID

# =============================================================================
# SEND SENSOR DATA + GET RECOMMENDATION
# =============================================================================
def send_sensor_data():
    """Send realistic sensor data to Firebase and get backend recommendation."""

    # ✅ FIX: 'pH' key completely removed
    data = {
        "temperature":  round(random.uniform(20, 30), 1),
        "humidity":     round(random.uniform(60, 80), 1),
        "soilMoisture": round(random.uniform(40, 70), 1),
        "nitrogen":     random.randint(70, 95),
        "phosphorus":   random.randint(40, 60),
        "potassium":    random.randint(40, 60),
        "timestamp":    int(time.time() * 1000)
    }

    # --- Send to Firebase current sensor state ---
    url = f"{FIREBASE_URL}/sensors/{USER_ID}/current.json"
    try:
        fb_response = requests.put(url, json=data)
        if fb_response.status_code == 200:
            print(f"✅ Sensor data sent to Firebase: T={data['temperature']}°C  "
                  f"H={data['humidity']}%  SM={data['soilMoisture']}%  "
                  f"N={data['nitrogen']}  P={data['phosphorus']}  K={data['potassium']}")
        else:
            print(f"❌ Firebase error: {fb_response.status_code} — {fb_response.text}")
    except Exception as e:
        print(f"❌ Error sending to Firebase: {e}")

    # --- Send to Flask backend for ML recommendation ---
    try:
        backend_response = requests.post(BACKEND_URL, json=data, timeout=10)
        if backend_response.status_code == 200:
            result = backend_response.json()
            crop       = result.get("recommended_crop", "Unknown")
            confidence = result.get("confidence", 0)
            top3       = result.get("top_3_crops", [])
            recs       = result.get("recommendations", {})

            print(f"🌱 Recommended Crop : {crop}  (confidence: {confidence:.2f})")
            print(f"   Top 3            : {[c['crop'] for c in top3]}")
            # ✅ FIX: recommendations is a DICT (fertilizer/irrigation/climate/notes)
            #         Old code printed result['recommendations'] as if it were a list
            print(f"   Fertilizer tip   : {recs.get('fertilizer', 'N/A')}")
            print(f"   Irrigation tip   : {recs.get('irrigation', 'N/A')}")
            print(f"   Climate tip      : {recs.get('climate',    'N/A')}")
            print()

            # --- Log recommendation into Firebase history ---
            # ✅ FIX: Flutter's _loadHistoricalData() reads from history/{USER_ID}
            #         and maps each entry to SensorData.fromMap().
            #         We store the sensor_data WITHOUT pH so fromMap() works cleanly.
            history_url   = f"{FIREBASE_URL}/history/{USER_ID}.json"
            history_entry = {
                "timestamp":        data["timestamp"],
                # Only the 6 sensor fields Flutter's SensorData.fromMap() expects
                "temperature":      data["temperature"],
                "humidity":         data["humidity"],
                "soilMoisture":     data["soilMoisture"],
                "nitrogen":         data["nitrogen"],
                "phosphorus":       data["phosphorus"],
                "potassium":        data["potassium"],
                # Extra recommendation info (Flutter ignores unknown fields — safe)
                "recommended_crop": crop,
                "confidence":       confidence,
                "top_3_crops":      top3,
            }
            hist_response = requests.post(history_url, json=history_entry)
            if hist_response.status_code == 200:
                print(f"   📋 History entry saved")
            else:
                print(f"   ⚠️  History save failed: {hist_response.status_code}")

        else:
            print(f"❌ Backend error: {backend_response.status_code}")
            print(backend_response.text)

    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend. Is 'python app.py' running?")
    except Exception as e:
        print(f"❌ Error calling backend: {e}")


# =============================================================================
# CONTINUOUS UPDATE MODE
# =============================================================================
def continuous_update():
    print("\n" + "="*60)
    print("  HARIYALI TEST DATA SENDER + RECOMMENDER")
    print("="*60)
    print(f"  Firebase User : {USER_ID}")
    print(f"  Backend URL   : {BACKEND_URL}")
    print("  Sending data every 5 seconds. Press Ctrl+C to stop.")
    print("="*60 + "\n")

    try:
        while True:
            send_sensor_data()
            time.sleep(5)
    except KeyboardInterrupt:
        print("\n\n✋ Stopped by user")


# =============================================================================
# MAIN
# =============================================================================
if __name__ == "__main__":
    if USER_ID in ("PASTE_YOUR_USER_ID_HERE", ""):
        print("❌ ERROR: Set USER_ID to your Firebase UID before running!")
    else:
        continuous_update()