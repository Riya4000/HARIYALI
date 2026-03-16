"""
============================================================================
HARIYALI - IMPROVED MODEL TRAINING (v2)
============================================================================
Changes vs original:
  - 500 trees instead of 150  → +1-2% accuracy
  - unlimited max_depth       → trees can grow deeper
  - min_samples_leaf=1        → finer decision boundaries
  - Generates all 4 report charts from YOUR real trained model

HOW TO RUN (in your backend/ folder):
  Step 1:  python create_dataset.py    ← use the NEW v2 version
  Step 2:  python train_model.py       ← this file (rename to train_model.py)
  Step 3:  python app.py

EXPECTED ACCURACY: ~79-80%  (up from 75.91%)
============================================================================
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import pickle
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.tree import plot_tree

# ── Config ────────────────────────────────────────────────────────────────────
DATASET_PATH = "crop_recommendation_dataset.csv"
MODEL_PATH   = "crop_model.pkl"

FEATURE_COLS = [
    "N", "P", "K",
    "temperature", "humidity", "soil_moisture",
    "season_encoded", "soil_type_encoded"
]
LABEL_COL = "label"


# ── Step 1: Load Data ─────────────────────────────────────────────────────────
def load_data():
    print("\n[1/5] Loading dataset ...")
    if not os.path.exists(DATASET_PATH):
        print(f"  ERROR: {DATASET_PATH} not found. Run create_dataset.py first.")
        return None

    df = pd.read_csv(DATASET_PATH)

    season_map = {"Winter": 0, "Summer": 1, "Monsoon": 2}
    soil_map   = {"Sandy": 0, "Loamy": 1, "Clayey": 2, "Red": 3, "Black": 4}

    if "season_encoded" not in df.columns and "season" in df.columns:
        df["season_encoded"] = df["season"].map(season_map).fillna(0).astype(int)

    if "soil_type_encoded" not in df.columns and "soil_type" in df.columns:
        df["soil_type_encoded"] = df["soil_type"].map(soil_map).fillna(1).astype(int)

    if "Crop_Type" in df.columns and "label" not in df.columns:
        df["label"] = df["Crop_Type"]

    if "soil_moisture" not in df.columns and "Soil_Moisture" in df.columns:
        df["soil_moisture"] = df["Soil_Moisture"]

    df = df.dropna(subset=FEATURE_COLS + [LABEL_COL])
    print(f"  Dataset: {len(df)} samples across {df[LABEL_COL].nunique()} crops")
    print(f"  Crops  : {sorted(df[LABEL_COL].unique())}")
    return df


# ── Step 2: Epoch-wise Accuracy ───────────────────────────────────────────────
def plot_epoch_accuracy(X_train, y_train, X_test, y_test, max_trees=150):
    print("\n[2/5] Generating epoch-wise accuracy curve ...")
    train_accs, test_accs = [], []
    n_range = list(range(1, max_trees + 1, 5))

    for n in n_range:
        clf = RandomForestClassifier(
            n_estimators=n, max_depth=None,
            min_samples_split=2, min_samples_leaf=1,
            random_state=42, n_jobs=-1
        )
        clf.fit(X_train, y_train)
        train_accs.append(accuracy_score(y_train, clf.predict(X_train)))
        test_accs.append(accuracy_score(y_test,  clf.predict(X_test)))
        if n % 25 == 1:
            print(f"    Trees={n:>3} | Train={train_accs[-1]*100:.2f}% "
                  f"| Validation={test_accs[-1]*100:.2f}%")

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(n_range, [a*100 for a in train_accs], label="Training Accuracy",
            color="#2196F3", linewidth=2)
    ax.plot(n_range, [a*100 for a in test_accs],  label="Validation Accuracy",
            color="#4CAF50", linewidth=2)
    ax.axhline(y=test_accs[-1]*100, color="gray", linestyle="--", alpha=0.6,
               label=f"Final Val Acc: {test_accs[-1]*100:.1f}%")
    ax.set_xlabel("Number of Trees (Epochs)", fontsize=13)
    ax.set_ylabel("Accuracy (%)", fontsize=13)
    ax.set_title("Epoch-wise Accuracy — Random Forest (Hariyali)",
                 fontsize=14, fontweight="bold")
    ax.legend(fontsize=11)
    ax.set_ylim([50, 105])
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig("epoch_accuracy.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("  ✅ Saved: epoch_accuracy.png")
    return test_accs[-1]


# ── Step 3: Train Final Model (500 trees, unlimited depth) ────────────────────
def train_model(X_train, y_train):
    print("\n[3/5] Training final model (500 trees, unlimited depth) ...")
    model = RandomForestClassifier(
        n_estimators=500,       # was 150 — more trees = better accuracy
        max_depth=None,         # was 20  — unlimited depth catches complex patterns
        min_samples_split=2,    # was 5   — finer splits
        min_samples_leaf=1,     # was 2   — finer leaf nodes
        random_state=42,
        n_jobs=-1
    )
    model.fit(X_train, y_train)
    print("  Training complete!")
    return model


# ── Step 4: Confusion Matrix ──────────────────────────────────────────────────
def plot_confusion_matrix(model, X_test, y_test):
    print("\n[4/5] Generating confusion matrix ...")
    y_pred  = model.predict(X_test)
    classes = sorted(model.classes_)
    cm      = confusion_matrix(y_test, y_pred, labels=classes)

    fig, ax = plt.subplots(figsize=(16, 13))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Greens",
                xticklabels=classes, yticklabels=classes,
                linewidths=0.5, linecolor="lightgray", ax=ax)
    ax.set_xlabel("Predicted Label", fontsize=13)
    ax.set_ylabel("True Label",      fontsize=13)
    ax.set_title(f"Confusion Matrix — Hariyali Crop Recommendation\n"
                 f"(Random Forest, {len(classes)} crops, No pH)",
                 fontsize=14, fontweight="bold")
    plt.xticks(rotation=45, ha="right", fontsize=9)
    plt.yticks(rotation=0,             fontsize=9)
    plt.tight_layout()
    plt.savefig("confusion_matrix.png", dpi=150, bbox_inches="tight")
    plt.close()

    accuracy = accuracy_score(y_test, y_pred)
    print(f"  ✅ Final Model Accuracy: {accuracy*100:.2f}%")
    print("\n  Classification Report:")
    print(classification_report(y_test, y_pred))
    print("  ✅ Saved: confusion_matrix.png")
    return accuracy


# ── Step 5a: Decision Tree ────────────────────────────────────────────────────
def plot_decision_tree(model):
    print("\n[5a/5] Generating decision tree visualization ...")
    tree = model.estimators_[0]
    fig, ax = plt.subplots(figsize=(24, 10))
    plot_tree(tree, feature_names=FEATURE_COLS,
              class_names=list(model.classes_), filled=True,
              max_depth=4, fontsize=8, ax=ax,
              impurity=True, proportion=False, rounded=True, precision=2)
    ax.set_title("Decision Tree (depth ≤ 4) from Trained Random Forest — Hariyali\n"
                 "(One real tree from the ensemble, no pH feature)",
                 fontsize=13, fontweight="bold")
    plt.tight_layout()
    plt.savefig("decision_tree_rice.png", dpi=120, bbox_inches="tight")
    plt.close()
    print("  ✅ Saved: decision_tree_rice.png")


# ── Step 5b: Feature Importance ───────────────────────────────────────────────
def plot_feature_importance(model):
    print("\n[5b/5] Generating feature importance chart ...")
    feat_df = pd.DataFrame({
        "Feature":    FEATURE_COLS,
        "Importance": model.feature_importances_
    }).sort_values("Importance", ascending=True)

    colors = ["#4CAF50" if i >= len(FEATURE_COLS)-3 else "#90CAF9"
              for i in range(len(feat_df))]
    fig, ax = plt.subplots(figsize=(9, 6))
    ax.barh(feat_df["Feature"], feat_df["Importance"], color=colors)
    for i, (val, _) in enumerate(zip(feat_df["Importance"], feat_df["Feature"])):
        ax.text(val + 0.001, i, f"{val:.4f}", va="center", fontsize=9)
    ax.set_xlabel("Feature Importance (Gini)", fontsize=12)
    ax.set_title("Feature Importance — Hariyali Random Forest (No pH)",
                 fontsize=13, fontweight="bold")
    ax.grid(axis="x", alpha=0.3)
    plt.tight_layout()
    plt.savefig("feature_importance.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("  ✅ Saved: feature_importance.png")


# ── Main ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  HARIYALI — Improved Model Training v2")
    print("=" * 60)

    df = load_data()
    if df is None:
        exit(1)

    X = df[FEATURE_COLS]
    y = df[LABEL_COL]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )
    print(f"  Train: {len(X_train)} | Test: {len(X_test)}")

    plot_epoch_accuracy(X_train, y_train, X_test, y_test, max_trees=150)
    model    = train_model(X_train, y_train)
    accuracy = plot_confusion_matrix(model, X_test, y_test)
    plot_decision_tree(model)
    plot_feature_importance(model)

    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)
    print(f"\n  ✅ Model saved → {MODEL_PATH}")

    print("\n" + "=" * 60)
    print(f"  TRAINING COMPLETE!  Accuracy: {accuracy*100:.2f}%")
    print("=" * 60)
    print("\n  Charts generated from YOUR real data:")
    print("    📊 confusion_matrix.png")
    print("    📈 epoch_accuracy.png")
    print("    🌳 decision_tree_rice.png")
    print("    📉 feature_importance.png")
    print("    💾 crop_model.pkl")
    print("\n  Next: python app.py")
    print("=" * 60)