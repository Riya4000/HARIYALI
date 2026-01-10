import pandas as pd
import pickle
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

def load_data():
    print("\nLoading dataset ...")
    try:
        df = pd.read_csv('crop_recommendation_dataset.csv')
        print(f"Dataset loaded: {len(df)} samples")
        return df
    except FileNotFoundError:
        print("Dataset not found! Run create_dataset.py first.")
        return None

def train_model(df):
    print("\nTraining Random Forest model ...")

    X = df[['N', 'P', 'K', 'temperature', 'humidity', 'pH', 'soilMoisture']]
    y = df['label']

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=20,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1
    )

    model.fit(X_train, y_train)
    print("Training completed!")

    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model Accuracy: {accuracy * 100:.2f}%")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred))

    feature_importance = pd.DataFrame({
        'feature': X.columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    print("\nFeature Importance:")
    print(feature_importance)

    with open('crop_model.pkl', 'wb') as f:
        pickle.dump(model, f)
    print("Model saved as: crop_model.pkl")

    return model

def test_model(model):
    print("\n" + "="*60)
    print("TESTING MODEL WITH SAMPLE DATA")
    print("="*60)

    samples = [
        ([90, 45, 50, 25, 80, 6.5, 75], "Rice conditions"),
        ([60, 50, 50, 18, 60, 6.8, 50], "Wheat conditions"),
        ([90, 60, 70, 17, 75, 5.5, 60], "Potato conditions"),
        ([60, 70, 60, 24, 70, 6.5, 60], "Tomato conditions"),
    ]
    for vec, label in samples:
        pred = model.predict([vec])[0]
        proba = model.predict_proba([vec])[0].max()
        print(f"- {label}: predicted={pred}, confidence={proba*100:.2f}%")

if __name__ == '__main__':
    df = load_data()
    if df is not None:
        model = train_model(df)
        test_model(model)
        print("\nMODEL TRAINING COMPLETED!")
        print("Next steps:")
        print("1) Run: python app.py")
        print("2) Use endpoints: /, /health, /predict")
    else:
        print("Training failed. Please create the dataset first: python create_dataset.py")