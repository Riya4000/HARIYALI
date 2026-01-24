# ==========================================================================
# HARIYALI TEST DATA SENDER + BACKEND RECOMMENDATIONS
# ==========================================================================
import requests
import time
import random

# ==========================================================================
# CONFIGURATION
# ==========================================================================
FIREBASE_URL = "https://hariyali-10a26-default-rtdb.firebaseio.com"
BACKEND_URL = "http://localhost:5000/predict"   # Flask backend
USER_ID = "PeWmSMYFR9SWf9FVKDkqF9q3sfe2"        # Replace with your Firebase UID

# ==========================================================================
# SEND SENSOR DATA + GET RECOMMENDATION
# ==========================================================================
def send_sensor_data():
    """Send realistic sensor data to Firebase and get backend recommendation"""

    # Generate realistic sensor values
    data = {
        "temperature": round(random.uniform(20, 30), 1),
        "humidity": round(random.uniform(60, 80), 1),
        "soilMoisture": round(random.uniform(40, 70), 1),
        "pH": round(random.uniform(6.0, 7.5), 1),
        "nitrogen": random.randint(70, 95),
        "phosphorus": random.randint(40, 60),
        "potassium": random.randint(40, 60),
        "timestamp": int(time.time() * 1000)
    }

    # --- Send to Firebase (current sensor state) ---
    url = f"{FIREBASE_URL}/sensors/{USER_ID}/current.json"
    try:
        fb_response = requests.put(url, json=data)
        if fb_response.status_code == 200:
            print(f"✅ Sensor data sent: {data}")
        else:
            print(f"❌ Firebase error: {fb_response.status_code}")
    except Exception as e:
        print(f"❌ Error sending to Firebase: {e}")

    # --- Send to backend for recommendation ---
    try:
        backend_response = requests.post(BACKEND_URL, json=data)
        if backend_response.status_code == 200:
            result = backend_response.json()
            print(f"🌱 Recommended Crop: {result['recommended_crop']} "
                  f"(Confidence: {result['confidence']:.2f})")
            print(f"   Top 3: {result['top_3_crops']}")
            print(f"   Advice: {result['recommendations']}\n")

            # --- Log recommendation into Firebase history ---
            history_url = f"{FIREBASE_URL}/history/{USER_ID}.json"
            history_entry = {
                "timestamp": data["timestamp"],
                "sensor_data": data,
                "recommended_crop": result["recommended_crop"],
                "confidence": result["confidence"],
                "top_3_crops": result["top_3_crops"],
                "recommendations": result["recommendations"]
            }
            requests.post(history_url, json=history_entry)

        else:
            print(f"❌ Backend error: {backend_response.status_code}")
            print(backend_response.text)
    except Exception as e:
        print(f"❌ Error calling backend: {e}")

# ==========================================================================
# CONTINUOUS UPDATE MODE
# ==========================================================================
def continuous_update():
    print("\n" + "="*60)
    print("   HARIYALI TEST DATA SENDER + RECOMMENDER")
    print("="*60)
    print("Simulating ESP32 → Firebase + Backend Recommendations")
    print("Press Ctrl+C to stop")
    print("="*60 + "\n")

    try:
        while True:
            send_sensor_data()
            time.sleep(5)
    except KeyboardInterrupt:
        print("\n\n          Stopped by user")

# ==========================================================================
# MAIN
# ==========================================================================
if __name__ == "__main__":
    if USER_ID == "PASTE_YOUR_USER_ID_HERE":
        print("❌ ERROR: USER ID NOT SET! Please replace USER_ID with your Firebase UID.")
    else:
        continuous_update()