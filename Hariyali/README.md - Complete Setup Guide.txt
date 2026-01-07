README.md - Complete Setup Guide
🌱 HARIYALI - Smart Greenhouse System
Complete setup guide for beginners with ZERO prior knowledge.
________________________________________
📋 What You'll Build
1.	Mobile App (Android/iOS) - Monitor greenhouse from phone
2.	Web App (Browser) - Access from computer
3.	Python Backend - AI crop recommendations
4.	Firebase - Real-time data sync with ESP32
________________________________________
🛠️ Prerequisites (Install These First)
1. Install Flutter
Windows:
# Download Flutter SDK
https://docs.flutter.dev/get-started/install/windows

# Extract to C:\flutter
# Add to PATH: C:\flutter\bin
Mac:
brew install flutter
Verify installation:
flutter doctor
2. Install Python 3.10+
Download: https://www.python.org/downloads/
☑️ IMPORTANT: Check "Add Python to PATH" during installation
3. Install VS Code
Download: https://code.visualstudio.com/
Install Extensions:
•	Flutter
•	Dart
•	Python
4. Install Node.js (for Firebase)
Download: https://nodejs.org/
________________________________________
🚀 Step-by-Step Setup
STEP 1: Create Firebase Project
1.	Go to https://console.firebase.google.com/
2.	Click "Add Project"
3.	Name it "hariyali-app"
4.	Enable Google Analytics ✅
5.	Click "Create Project"
Enable Services:
•	Authentication → Email/Password ✅
•	Realtime Database → Create Database → Start in test mode
•	Hosting → Get Started
STEP 2: Get Firebase Config
1.	In Firebase Console → ⚙️ Project Settings
2.	Scroll to "Your apps"
3.	Click Web icon </>
4.	Register app as "hariyali-web"
5.	Copy the config values
STEP 3: Create Flutter Project
# Create project
flutter create hariyali
cd hariyali

# Install dependencies
flutter pub add firebase_core firebase_auth firebase_database
flutter pub add provider google_fonts
flutter pub add speech_to_text permission_handler flutter_tts
flutter pub add http webview_flutter fl_chart intl shared_preferences
STEP 4: Configure Firebase
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init

# Select:
# - Realtime Database
# - Hosting
# - Use existing project: hariyali-app

# Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
STEP 5: Project Structure
Create this folder structure:
hariyali/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/
│   │   └── sensor_data.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── sensor_service.dart
│   │   └── voice_service.dart
│   └── screens/
│       ├── splash_screen.dart
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── signup_screen.dart
│       └── home/
│           ├── home_screen.dart
│           ├── dashboard_tab.dart
│           ├── sensors_tab.dart
│           ├── controls_tab.dart
│           └── voice_tab.dart
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── crop_model.pkl
└── web/
    └── index.html
STEP 6: Copy All Code Files
Copy all the code I provided into the correct files:
1.	lib/main.dart → Main app file
2.	lib/firebase_options.dart → Firebase config
3.	lib/models/sensor_data.dart → Data model
4.	lib/services/auth_service.dart → Authentication
5.	lib/services/sensor_service.dart → Sensor data
6.	lib/services/voice_service.dart → Voice assistant
7.	lib/screens/... → All screen files
8.	backend/app.py → Python API
9.	backend/requirements.txt → Python packages
10.	web/index.html → Web page
STEP 7: Update Firebase Config
In lib/firebase_options.dart, replace with YOUR values:
static const FirebaseOptions web = FirebaseOptions(
  apiKey: "YOUR_API_KEY",           // ← From Firebase Console
  authDomain: "YOUR_AUTH_DOMAIN",   // ← From Firebase Console
  projectId: "YOUR_PROJECT_ID",     // ← From Firebase Console
  storageBucket: "YOUR_BUCKET",     // ← From Firebase Console
  messagingSenderId: "YOUR_ID",     // ← From Firebase Console
  appId: "YOUR_APP_ID",             // ← From Firebase Console
  measurementId: "YOUR_MEASURE_ID", // ← From Firebase Console
);
STEP 8: Setup Python Backend
# Navigate to backend folder
cd backend

# Create virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Run server
python app.py
Backend should start at: http://localhost:5000
STEP 9: Run Flutter App
For Web:
flutter run -d chrome
For Mobile (with device connected):
flutter run
For Android APK:
flutter build apk
# APK location: build/app/outputs/flutter-apk/app-release.apk
________________________________________
