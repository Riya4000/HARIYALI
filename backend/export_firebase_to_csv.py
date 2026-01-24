import firebase_admin
from firebase_admin import credentials, db
import csv

# -------------------------------------------------------------------
# Firebase Setup
# -------------------------------------------------------------------
cred = credentials.Certificate("serviceAccountKey.json")

firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://hariyali-10a26-default-rtdb.firebaseio.com'
})

USER_ID = "PeWmSMYFR9SWf9FVKDkqF9q3sfe2"

# -------------------------------------------------------------------
# Export Sensor Data
# -------------------------------------------------------------------
def export_sensor_data():
    ref = db.reference(f"sensors/{USER_ID}/current")
    data = ref.get()

    if data:
        with open("sensor_data.csv", "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=data.keys())
            writer.writeheader()
            writer.writerow(data)
        print("✅ Sensor data exported to sensor_data.csv")
    else:
        print("❌ No sensor data found")

# -------------------------------------------------------------------
# Export History Data
# -------------------------------------------------------------------
def export_history_data():
    ref = db.reference(f"history/{USER_ID}")
    history = ref.get()

    if history:
        # Flatten history entries
        with open("history_data.csv", "w", newline="") as f:
            fieldnames = ["timestamp", "recommended_crop", "confidence", "sensor_data", "top_3_crops", "recommendations"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for key, entry in history.items():
                writer.writerow({
                    "timestamp": entry.get("timestamp"),
                    "recommended_crop": entry.get("recommended_crop"),
                    "confidence": entry.get("confidence"),
                    "sensor_data": entry.get("sensor_data"),
                    "top_3_crops": entry.get("top_3_crops"),
                    "recommendations": entry.get("recommendations")
                })
        print("✅ History data exported to history_data.csv")
    else:
        print("❌ No history data found")

# -------------------------------------------------------------------
# MAIN
# -------------------------------------------------------------------
if __name__ == "__main__":
    export_sensor_data()
    export_history_data()