import pandas as pd
import numpy as np

def create_hariyali_dataset():
    print("\nCreating HARIYALI Dataset (without rainfall) ... ")

    data = []

    # Rice
    for _ in range(150):
        data.append({
            'N': np.random.randint(80, 100),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(40, 60),
            'temperature': np.random.uniform(20, 27),
            'humidity': np.random.uniform(75, 90),
            'pH': np.random.uniform(5.5, 7.0),
            'soilMoisture': np.random.uniform(60, 90),
            'label': 'rice'
        })

    # Wheat
    for _ in range(150):
        data.append({
            'N': np.random.randint(50, 70),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(40, 60),
            'temperature': np.random.uniform(12, 25),
            'humidity': np.random.uniform(50, 70),
            'pH': np.random.uniform(6.0, 7.5),
            'soilMoisture': np.random.uniform(40, 60),
            'label': 'wheat'
        })

    # Maize
    for _ in range(150):
        data.append({
            'N': np.random.randint(60, 80),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(30, 50),
            'temperature': np.random.uniform(18, 27),
            'humidity': np.random.uniform(55, 75),
            'pH': np.random.uniform(5.5, 7.0),
            'soilMoisture': np.random.uniform(45, 65),
            'label': 'maize'
        })

    # Lentil
    for _ in range(100):
        data.append({
            'N': np.random.randint(20, 40),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(20, 40),
            'temperature': np.random.uniform(15, 25),
            'humidity': np.random.uniform(50, 70),
            'pH': np.random.uniform(6.0, 7.5),
            'soilMoisture': np.random.uniform(35, 55),
            'label': 'lentil'
        })

    # Potato
    for _ in range(100):
        data.append({
            'N': np.random.randint(80, 100),
            'P': np.random.randint(50, 70),
            'K': np.random.randint(60, 80),
            'temperature': np.random.uniform(15, 20),
            'humidity': np.random.uniform(70, 85),
            'pH': np.random.uniform(5.0, 6.5),
            'soilMoisture': np.random.uniform(50, 70),
            'label': 'potato'
        })

    # Tomato
    for _ in range(100):
        data.append({
            'N': np.random.randint(50, 70),
            'P': np.random.randint(60, 80),
            'K': np.random.randint(50, 70),
            'temperature': np.random.uniform(20, 27),
            'humidity': np.random.uniform(60, 80),
            'pH': np.random.uniform(6.0, 7.0),
            'soilMoisture': np.random.uniform(50, 70),
            'label': 'tomato'
        })

    # Cauliflower
    for _ in range(80):
        data.append({
            'N': np.random.randint(60, 80),
            'P': np.random.randint(50, 70),
            'K': np.random.randint(50, 70),
            'temperature': np.random.uniform(15, 22),
            'humidity': np.random.uniform(65, 80),
            'pH': np.random.uniform(6.0, 7.0),
            'soilMoisture': np.random.uniform(50, 70),
            'label': 'cauliflower'
        })

    # Cabbage
    for _ in range(80):
        data.append({
            'N': np.random.randint(60, 80),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(50, 70),
            'temperature': np.random.uniform(15, 22),
            'humidity': np.random.uniform(60, 75),
            'pH': np.random.uniform(6.0, 7.0),
            'soilMoisture': np.random.uniform(50, 70),
            'label': 'cabbage'
        })

    # Onion
    for _ in range(80):
        data.append({
            'N': np.random.randint(40, 60),
            'P': np.random.randint(50, 70),
            'K': np.random.randint(40, 60),
            'temperature': np.random.uniform(18, 25),
            'humidity': np.random.uniform(60, 75),
            'pH': np.random.uniform(6.0, 7.0),
            'soilMoisture': np.random.uniform(45, 65),
            'label': 'onion'
        })

    # Garlic
    for _ in range(80):
        data.append({
            'N': np.random.randint(40, 60),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(40, 60),
            'temperature': np.random.uniform(12, 20),
            'humidity': np.random.uniform(50, 70),
            'pH': np.random.uniform(6.0, 7.0),
            'soilMoisture': np.random.uniform(40, 60),
            'label': 'garlic'
        })

    # Soybean
    for _ in range(80):
        data.append({
            'N': np.random.randint(20, 40),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(30, 50),
            'temperature': np.random.uniform(20, 30),
            'humidity': np.random.uniform(60, 80),
            'pH': np.random.uniform(6.0, 7.5),
            'soilMoisture': np.random.uniform(45, 65),
            'label': 'soybean'
        })

    # Chickpea
    for _ in range(80):
        data.append({
            'N': np.random.randint(20, 40),
            'P': np.random.randint(40, 60),
            'K': np.random.randint(30, 50),
            'temperature': np.random.uniform(18, 27),
            'humidity': np.random.uniform(50, 70),
            'pH': np.random.uniform(6.0, 7.5),
            'soilMoisture': np.random.uniform(35, 55),
            'label': 'chickpea'
        })

    # Sugarcane
    for _ in range(100):
        data.append({
            'N': np.random.randint(90, 120),
            'P': np.random.randint(50, 70),
            'K': np.random.randint(50, 70),
            'temperature': np.random.uniform(25, 35),
            'humidity': np.random.uniform(70, 90),
            'pH': np.random.uniform(6.0, 7.5),
            'soilMoisture': np.random.uniform(60, 80),
            'label': 'sugarcane'
        })

    # Tea
    for _ in range(80):
        data.append({
            'N': np.random.randint(70, 90),
            'P': np.random.randint(30, 50),
            'K': np.random.randint(30, 50),
            'temperature': np.random.uniform(18, 25),
            'humidity': np.random.uniform(75, 90),
            'pH': np.random.uniform(4.5, 6.0),
            'soilMoisture': np.random.uniform(60, 80),
            'label': 'tea'
        })

    # Coffee
    for _ in range(80):
        data.append({
            'N': np.random.randint(60, 80),
            'P': np.random.randint(30, 50),
            'K': np.random.randint(40, 60),
            'temperature': np.random.uniform(15, 24),
            'humidity': np.random.uniform(70, 85),
            'pH': np.random.uniform(5.5, 6.5),
            'soilMoisture': np.random.uniform(55, 75),
            'label': 'coffee'
        })

    df = pd.DataFrame(data).sample(frac=1).reset_index(drop=True)
    df.to_csv(path_or_buf='crop_recommendation_dataset.csv', index=False)

    print("Dataset created successfully!")
    print(f"Total samples: {len(df)}")
    print(f"Crops included: {df['label'].nunique()}")
    print("Crop distribution:")
    print(df['label'].value_counts())
    print("Saved as: crop_recommendation_dataset.csv")
    return df

if __name__ == '__main__':
    df = create_hariyali_dataset()
    print("\nSample data (first 5 rows):")
    print(df.head())
    print("\nDataset statistics:")
    print(df.describe())