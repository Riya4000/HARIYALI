# HARIYALI

HARIYALI (High-tech Agriculture Resource Integration for Yield and Land Improvement) is our final year project — a smart greenhouse system built on an ESP32 microcontroller that reads live sensor data, syncs everything to Firebase Realtime Database, and serves crop recommendations through a Random Forest ML model via a Flask API. The frontend is a Flutter web app.

## Project structure

```
HARIYALI/
├── frontend/                        # Flutter web app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── sensors_screen.dart
│   │   │   ├── controls_screen.dart
│   │   │   ├── voice_assistant_screen.dart
│   │   │   └── crop_recommendation_screen.dart
│   │   └── firebase_options.dart    # DO NOT COMMIT — in .gitignore
│   ├── pubspec.yaml
│   └── android/
│       └── app/
│           └── google-services.json # DO NOT COMMIT — in .gitignore
│
├── backend/                         # Python Flask ML API
│   ├── app.py                       # Flask server, /predict endpoint
│   ├── train_model.py               # trains the model, generates charts
│   ├── crop_model.pkl               # NOT in repo — run train_model.py
│   ├── crop_recommendation_dataset.csv  # NOT in repo — download from Kaggle
│   └── requirements.txt
│
└── firmware/                        # ESP32 Arduino code
    └── hariyali_firmware/
        └── hariyali_firmware.ino
```

## Hardware

ESP32 microcontroller, DHT22 (temperature and humidity), soil moisture sensor, NPK sensor over RS-485 via MAX485, relay module, servo motor, DC water pump, Li-ion battery. pH sensor was removed from the final design.

## Running the backend

You need Python 3.8+ and the dataset from Kaggle — search "Crop Recommendation Dataset" by Priya 2023 and place it as `backend/crop_recommendation_dataset.csv`.

```bash
cd backend
pip install -r requirements.txt
python train_model.py
python app.py
```

`train_model.py` does 5-fold stratified cross-validation first, then trains the final Random Forest model (300 trees, max_depth=25) and saves it as `crop_model.pkl`. It also generates `confusion_matrix.png`, `epoch_accuracy.png`, `epoch_error.png`, `decision_tree_rice.png`, and `feature_importance.png` — all excluded from the repo since they're generated output.

The Flask API runs on port 5000. The crop recommendation screen in the app sends a POST to `/predict` with N, P, K, temperature, humidity, soil_moisture, season_encoded, and soil_type_encoded, and gets back the top 3 crops with confidence percentages.

Current model performance: CV accuracy 76.53% ± 0.31%, test accuracy 76.97% across 25 crop classes (26,050 samples). Training accuracy is ~98.9%. The gap exists because pH was removed — crops like Chickpea, Lentil, Mustard, and Pulses are very similar without it.

Season encoding: Winter=0, Summer=1, Monsoon=2
Soil type encoding: Sandy=0, Loamy=1, Clayey=2, Red=3, Black=4

## Running the frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

The app connects to Firebase using the config in `firebase_options.dart`. You'll need to set this up yourself — see the Firebase setup section below.

## Firebase setup

The Realtime Database structure the app expects:

```
hariyali-10a26-default-rtdb/
├── sensors/{userId}/current/
│   ├── temperature
│   ├── humidity
│   ├── nitrogen
│   ├── phosphorus
│   ├── potassium
│   ├── soilMoisture
│   └── timestamp
├── history/{userId}/{recordId}/
│   └── (same fields as current)
└── controls/{userId}/
    ├── light     (true/false)
    ├── pump      (true/false)
    └── window    (true/false)
```

Enable Email/Password authentication and Realtime Database in your Firebase console, then run `flutterfire configure` in the `frontend/` folder to generate `firebase_options.dart`. Never commit this file.

## Firmware

Open `firmware/hariyali_firmware/hariyali_firmware.ino` in Arduino IDE. The ESP32 reads sensors every 5 seconds and writes to Firebase. It also listens to the `controls/{userId}` node and drives the relay and servo accordingly. Install the FirebaseESP32 library and ArduinoJson before flashing.

## Team

Rashmi Khadka (79028), Riya Shakya (79032), Sujal Khanal (79044), Sumit Thapa (79045)

Supervisor: Assoc. Prof. Er. Sujan Shrestha
Kathmandu Engineering College, IOE, Tribhuvan University — 2026
