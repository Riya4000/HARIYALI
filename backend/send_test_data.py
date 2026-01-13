# ==========================================================================
# SEND TEST DATA TO FIREBASE - For Testing Your App
# ==========================================================================

import requests
import json
import time
import random
from datetime import datetime

# ==========================================================================
# FIREBASE CONFIGURATION
# ==========================================================================

# Your Firebase Realtime Database URL
FIREBASE_URL = "https://hariyali-10a26-default-rtdb.firebaseio.com"

# REPLACE THIS WITH YOUR ACTUAL USER ID FROM FIREBASE AUTHENTICATION
# Go to: Firebase Console → Authentication → Click your user → Copy UID
USER_ID = "PeWmSMYFR9SWf9FVKDkqF9q3sfe2"

# ==========================================================================
# SEND SENSOR DATA
# ==========================================================================

def send_sensor_data():
    """Send realistic sensor data to Firebase"""

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

    # Send to Firebase
    url = f"{FIREBASE_URL}/sensors/{USER_ID}/current.json"

    try:
        response = requests.put(url, json=data)

        if response.status_code == 200:
            print(f"   Sensor data sent successfully!")
            print(f"   Temp: {data['temperature']}°C")
            print(f"   Humidity: {data['humidity']}%")
            print(f"   Soil Moisture: {data['soilMoisture']}%")
            print(f"   pH: {data['pH']}")
            print(f"   NPK: {data['nitrogen']}/{data['phosphorus']}/{data['potassium']}")
        else:
            print(f"  Error: {response.status_code}")
            print(response.text)

    except Exception as e:
        print(f"  Error sending data: {e}")

# ==========================================================================
# SEND CONTROL STATES
# ==========================================================================

def send_control_states():
    """Initialize control states"""

    controls = {
        "pump": False,
        "window": False,
        "light": False
    }

    url = f"{FIREBASE_URL}/controls/{USER_ID}.json"

    try:
        response = requests.put(url, json=controls)

        if response.status_code == 200:
            print(f"   Control states initialized!")
        else:
            print(f"  Error: {response.status_code}")

    except Exception as e:
        print(f"  Error: {e}")

# ==========================================================================
# CONTINUOUS UPDATE MODE
# ==========================================================================

def continuous_update():
    """Send sensor data every 5 seconds (simulates ESP32)"""

    print("\n" + "="*60)
    print("   HARIYALI TEST DATA SENDER")
    print("="*60)
    print("This simulates your ESP32 sending data to Firebase")
    print("Press Ctrl+C to stop")
    print("="*60 + "\n")

    # Initialize controls
    send_control_states()

    try:
        while True:
            send_sensor_data()
            print(f"       Waiting 5 seconds...\n")
            time.sleep(5)

    except KeyboardInterrupt:
        print("\n\n          Stopped by user")

# ==========================================================================
# MAIN
# ==========================================================================

if __name__ == '__main__':

    # Check if user ID is set
    if USER_ID == "PASTE_YOUR_USER_ID_HERE":
        print("\n" + "="*60)
        print("     ERROR: USER ID NOT SET!")
        print("="*60)
        print("\n          How to fix:")
        print("1. Go to: https://console.firebase.google.com/")
        print("2. Select project: hariyali-app-47d1f")
        print("3. Click 'Authentication' in left sidebar")
        print("4. Click on your user (Riya)")
        print("5. Copy the 'User UID'")
        print("6. Open this file and replace USER_ID with your UID")
        print("\nExample:")
        print('USER_ID = "abc123xyz456..."')
        print("="*60 + "\n")
    else:
        # Start sending data
        continuous_update()