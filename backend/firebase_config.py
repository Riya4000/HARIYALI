# ============================================================================
# FIREBASE CONFIGURATION
# Connects Python backend to Firebase Realtime Database
# ============================================================================
import firebase_admin
from firebase_admin import credentials, db
import os

# ============================================================================
# INITIALIZE FIREBASE
# ============================================================================

# firebase_config.py
import firebase_admin
from firebase_admin import credentials, db

def initialize_firebase():
    """
    Initialize Firebase Admin SDK
    This allows Python to read/write to Firebase Realtime Database
    """
    try:
        # Check if Firebase is already initialized
        if not firebase_admin._apps:
            # Load service account credentials
            cred = credentials.Certificate(r"C:\Projects\hariyali_app\backend\serviceAccountKey.json.json")

            # Initialize Firebase with your database URL
            # REPLACE THIS with your actual Firebase Database URL
            # Find it in Firebase Console → Realtime Database → Data tab (top)
            firebase_admin.initialize_app(cred, {
                'databaseURL': 'https://hariyali-10a26-default-rtdb.firebaseio.com/'
                #     CHANGE THIS to your database URL!
            })

            print("   Firebase initialized successfully!")
            return True
        else:
            print("   Firebase already initialized")
            return True

    except Exception as e:
        print(f"  Error initializing Firebase: {e}")
        return False

    # ============================================================================
# GET SENSOR DATA FROM FIREBASE
# ============================================================================

def get_sensor_data():
    """
    Fetch current sensor data from Firebase
    Returns: Dictionary with sensor values
    """
    try:
        # Reference to sensors/current node
        ref = db.reference('sensors/current')

        # Get the data
        data = ref.get()

        if data:
            print(f"   Fetched sensor data: {data}")
            return data
        else:
            print("    No sensor data found in Firebase")
            return None

    except Exception as e:
        print(f"  Error fetching sensor data: {e}")
        return None

    # ===========================================================================
# SAVE PREDICTION TO FIREBASE
# ============================================================================

def save_prediction_to_firebase(predictions):
    """
    Save crop predictions to Firebase
    Args:
        predictions: List of crop recommendations
    """
    try:
        # Reference to predictions node
        ref = db.reference('predictions')

        # Save with timestamp
        from datetime import datetime
        timestamp = datetime.now().isoformat()

        ref.child('latest').set({
            'predictions': predictions,
            'timestamp': timestamp
        })

        print("   Predictions saved to Firebase")
        return True

    except Exception as e:
        print(f"  Error saving predictions: {e}")
        return False

    # ============================================================================
# LISTEN TO SENSOR UPDATES (Real-time)
# ============================================================================

def listen_to_sensor_updates(callback):
    """
    Listen for real-time sensor data updates
    Args:
        callback: Function to call when data changes
    """
    try:
        ref = db.reference('sensors/current')

        # Set up listener
        def listener(event):
            print(f"    Sensor data updated: {event.data}")
            callback(event.data)

        ref.listen(listener)
        print("   Listening for sensor updates...")

    except Exception as e:
        print(f"  Error setting up listener: {e}")

    # ==========================================================================
# UPDATE CONTROL STATE IN FIREBASE
# ===========================================================================

def update_control(control_name, state):
    """
    Update control state in Firebase (pump, window, light)
    Args:
        control_name: 'pump', 'window', or 'light'
        state: True/False
    """
    try:
        ref = db.reference('controls')

        from datetime import datetime
        ref.update({
            control_name: state,
            'timestamp': datetime.now().isoformat()
        })

        print(f"   Updated {control_name} to {state}")
        return True
    except Exception as e:
        print(f"  Error updating control: {e}")
        return False