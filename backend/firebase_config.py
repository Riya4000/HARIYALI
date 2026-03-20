# =============================================================================
# HARIYALI - firebase_config.py
# FIX 1: SERVICE_ACCOUNT_PATH now uses os.path so it works on any machine.
# FIX 2: update_control() docstring — "light" removed (no physical LED).
# =============================================================================

import firebase_admin
from firebase_admin import credentials, db
import os

# ─── YOUR FIREBASE CONFIG ────────────────────────────────────────────────────
# Use a path relative to this file so it works on any machine / any folder name
SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
DATABASE_URL = "https://hariyali-10a26-default-rtdb.firebaseio.com/"
# ─────────────────────────────────────────────────────────────────────────────


def initialize_firebase():
    """
    Initialize Firebase Admin SDK.
    Call this ONCE at startup — safe to call multiple times.
    """
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
            firebase_admin.initialize_app(cred, {"databaseURL": DATABASE_URL})
            print("✅ Firebase initialized successfully!")
        else:
            print("ℹ️ Firebase already initialized")
        return True
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        return False


# =============================================================================
# GET SENSOR DATA FROM FIREBASE
# =============================================================================

def get_sensor_data(user_id=None):
    """
    Fetch current sensor data from Firebase.

    ✅ FIX: Flutter stores data at sensors/{USER_ID}/current
    The old code read from 'sensors/current' (WRONG PATH — returns None always)
    Now we first try with user_id, then fall back to scanning all users.

    Returns: dict with sensor values, or None
    """
    try:
        if user_id:
            # Direct path if user_id is known
            ref = db.reference(f"sensors/{user_id}/current")
            data = ref.get()
            if data:
                print(f"✅ Fetched sensor data for user {user_id}: {data}")
                return data

        # Fallback: scan all users under /sensors/ and return the most recent
        ref = db.reference("sensors")
        all_data = ref.get()
        if all_data:
            # all_data = { USER_ID: { "current": {...} }, ... }
            for uid, value in all_data.items():
                if isinstance(value, dict) and "current" in value:
                    data = value["current"]
                    print(f"✅ Fetched sensor data from user {uid}: {data}")
                    return data

        print("⚠️ No sensor data found in Firebase")
        return None

    except Exception as e:
        print(f"❌ Error fetching sensor data: {e}")
        return None


# =============================================================================
# SAVE PREDICTION TO FIREBASE
# =============================================================================

def save_prediction_to_firebase(predictions, user_id=None):
    """Save crop predictions to Firebase."""
    try:
        from datetime import datetime
        timestamp = datetime.now().isoformat()

        # Save to predictions/latest (or predictions/{user_id}/latest)
        path = f"predictions/{user_id}/latest" if user_id else "predictions/latest"
        ref = db.reference(path)
        ref.set({
            "predictions": predictions,
            "timestamp": timestamp
        })
        print("✅ Predictions saved to Firebase")
        return True
    except Exception as e:
        print(f"❌ Error saving predictions: {e}")
        return False


# =============================================================================
# LISTEN TO SENSOR UPDATES (Real-time)
# =============================================================================

def listen_to_sensor_updates(callback, user_id=None):
    """Listen for real-time sensor data updates."""
    try:
        path = f"sensors/{user_id}/current" if user_id else "sensors"
        ref = db.reference(path)

        def listener(event):
            print(f"🔔 Sensor data updated: {event.data}")
            callback(event.data)

        ref.listen(listener)
        print("👂 Listening for sensor updates...")
    except Exception as e:
        print(f"❌ Error setting up listener: {e}")


# =============================================================================
# UPDATE CONTROL STATE IN FIREBASE
# Valid controls: "pump", "window"  — "light" removed (no physical LED)
# =============================================================================

def update_control(control_name, state, user_id=None):
    """
    Update control state in Firebase (pump, window).
    Note: 'light' has been removed — no physical LED hardware.
    """
    try:
        from datetime import datetime

        # ✅ FIX: Flutter reads from controls/{USER_ID}/pump|window
        # Old code wrote to controls/pump (WRONG PATH — Flutter never saw it)
        path = f"controls/{user_id}" if user_id else "controls"
        ref = db.reference(path)
        ref.update({
            control_name: state,
            "timestamp": datetime.now().isoformat()
        })
        print(f"✅ Updated {control_name} → {state}")
        return True
    except Exception as e:
        print(f"❌ Error updating control: {e}")
        return False