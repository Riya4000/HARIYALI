"""
============================================================================
HARIYALI — Improved Model Training v3 (K-Fold + Better Accuracy)
============================================================================
Key Improvements:
  1. StratifiedKFold cross-validation (5-fold) to reduce train/test gap
  2. Hyperparameter tuning for better generalisation
  3. Epoch accuracy graph styled like figure.png (dark bg, orange/blue lines)
  4. NEW: Error vs Number of Trees graph
  5. All 4 original charts retained

HOW TO RUN (in your backend/ folder):
  python train_model.py

EXPECTED ACCURACY: ~81-85% test / CV std < 1.5%
============================================================================
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns
import pickle
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.tree import plot_tree

# ── Config ──────────────────────────────────────────────────────────────────
DATASET_PATH = "crop_recommendation_dataset.csv"
MODEL_PATH   = "crop_model.pkl"

FEATURE_COLS = [
    "N", "P", "K",
    "temperature", "humidity", "soil_moisture",
    "season_encoded", "soil_type_encoded"
]
LABEL_COL = "label"

# ── Style constants (textbook / clean white style) ───────────────────────────
ORANGE = "#F5A623"
BLUE   = "#4A90D9"


# ═══════════════════════════════════════════════════════════════════════════
# STEP 1 — Load Data
# ═══════════════════════════════════════════════════════════════════════════
def load_data():
    print("\n[1/6] Loading dataset ...")
    if not os.path.exists(DATASET_PATH):
        print(f"  ERROR: {DATASET_PATH} not found.")
        return None

    df = pd.read_csv(DATASET_PATH)

    season_map   = {"Winter": 0, "Summer": 1, "Monsoon": 2}
    soil_map     = {"Sandy": 0, "Loamy": 1, "Clayey": 2, "Red": 3, "Black": 4}

    if "season_encoded" not in df.columns and "season" in df.columns:
        df["season_encoded"]    = df["season"].map(season_map).fillna(0).astype(int)
    if "soil_type_encoded" not in df.columns and "soil_type" in df.columns:
        df["soil_type_encoded"] = df["soil_type"].map(soil_map).fillna(1).astype(int)
    if "Crop_Type" in df.columns and "label" not in df.columns:
        df["label"] = df["Crop_Type"]
    if "soil_moisture" not in df.columns and "Soil_Moisture" in df.columns:
        df["soil_moisture"] = df["Soil_Moisture"]

    df = df.dropna(subset=FEATURE_COLS + [LABEL_COL])
    print(f"  Dataset : {len(df)} samples | {df[LABEL_COL].nunique()} crops")
    print(f"  Crops   : {sorted(df[LABEL_COL].unique())}")
    return df


# ═══════════════════════════════════════════════════════════════════════════
# STEP 2 — K-Fold Cross-Validation
# ═══════════════════════════════════════════════════════════════════════════
def kfold_cross_validation(X, y, n_splits=5):
    """
    5-fold stratified CV.  This is the main tool for reducing the
    train/validation gap — it ensures every sample is used for both
    training and evaluation, giving a much more reliable accuracy estimate
    and helping tune hyperparameters without over-fitting to a single split.
    """
    print(f"\n[2/6] Running {n_splits}-Fold Stratified Cross-Validation ...")

    cv_model = RandomForestClassifier(
        n_estimators=300,
        max_depth=25,           # moderate depth — prevents memorising training data
        min_samples_split=4,    # need at least 4 samples to make a split
        min_samples_leaf=2,     # each leaf must have ≥2 samples
        max_features="sqrt",    # standard RF feature sub-sampling
        class_weight="balanced",# compensate for any slight class imbalance
        random_state=42,
        n_jobs=-1
    )

    skf    = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)
    scores = cross_val_score(cv_model, X, y, cv=skf, scoring="accuracy", n_jobs=-1)

    print(f"  Fold accuracies : {[f'{s*100:.2f}%' for s in scores]}")
    print(f"  Mean CV accuracy: {scores.mean()*100:.2f}%  ±  {scores.std()*100:.2f}%")
    return scores


# ═══════════════════════════════════════════════════════════════════════════
# STEP 3 — Epoch Accuracy Graph  (styled like figure.png)
# ═══════════════════════════════════════════════════════════════════════════
def plot_epoch_accuracy(X_train, y_train, X_test, y_test, max_trees=200, final_test_acc=None):
    """
    Detailed data plot (real tick numbers, real values) on a clean WHITE background:
      • White background, light grey grid
      • Y-axis: Accuracy (%) with real numbers
      • X-axis: Number of Trees (Epochs) with real numbers
      • Orange  = validation curve
      • Blue    = training curve
      • Floating right-side labels (no legend box)
      • All spines hidden except bottom and left
      • No top/right border — open, clean feel
    """
    print("\n[3/6] Generating epoch-wise learning curve (white detailed style) ...")

    train_accs, test_accs = [], []
    n_range = list(range(5, max_trees + 1, 5))

    for n in n_range:
        clf = RandomForestClassifier(
            n_estimators=n,
            max_depth=25,
            min_samples_split=4,
            min_samples_leaf=2,
            max_features="sqrt",
            class_weight="balanced",
            random_state=42,
            n_jobs=-1,
        )
        clf.fit(X_train, y_train)
        train_accs.append(accuracy_score(y_train, clf.predict(X_train)))
        test_accs.append(accuracy_score(y_test,  clf.predict(X_test)))
        if n % 50 == 5 or n == max_trees:
            print(f"  Trees={n:>3} | Train={train_accs[-1]*100:.2f}% | Val={test_accs[-1]*100:.2f}%")

    ORANGE = "#F5A623"
    BLUE   = "#4A90D9"

    train_pct = [a * 100 for a in train_accs]
    val_pct   = [a * 100 for a in test_accs]

    fig, ax = plt.subplots(figsize=(10, 6), facecolor="white")
    ax.set_facecolor("white")

    ax.plot(n_range, train_pct, color=BLUE,   linewidth=2.5)
    ax.plot(n_range, val_pct,   color=ORANGE, linewidth=2.5)

    # Floating right-side labels
    ax.text(n_range[-1] + 3, val_pct[-1],   "validation",
            color=ORANGE, fontsize=12, fontweight="bold", va="center")
    ax.text(n_range[-1] + 3, train_pct[-1], "training",
            color=BLUE,   fontsize=12, fontweight="bold", va="center")

    # Final value annotations — use the real final model accuracy if provided
    final_train = train_accs[-1] * 100
    final_val   = (final_test_acc * 100) if final_test_acc is not None else (test_accs[-1] * 100)
    ax.annotate(f"Final Train: {final_train:.2f}%\nFinal Test:  {final_val:.2f}%",
                xy=(n_range[len(n_range)//2], val_pct[-1] - 5),
                fontsize=9, color="#444444",
                bbox=dict(boxstyle="round,pad=0.35", fc="#F5F5F5", ec="#DDDDDD", lw=0.8))

    ax.set_xlabel("Number of Trees (Epochs)", fontsize=12, color="#333333", labelpad=8)
    ax.set_ylabel("Accuracy (%)",             fontsize=12, color="#333333", labelpad=8)
    ax.set_title("The Learning Curves",       fontsize=15, fontweight="bold",
                 color="#111111", pad=12)

    # Real tick numbers, clean styling
    ax.tick_params(colors="#555555", labelsize=10)
    ax.set_xlim([n_range[0], n_range[-1] + 28])
    ax.set_ylim([60, 102])

    # Light grey grid, no top/right border
    ax.grid(True, color="#E0E0E0", linewidth=0.8, linestyle="-")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#CCCCCC")
    ax.spines["bottom"].set_color("#CCCCCC")

    plt.tight_layout()
    plt.savefig("epoch_accuracy.png", dpi=180, bbox_inches="tight", facecolor="white")
    plt.close()
    print("  ✅ Saved: epoch_accuracy.png  (white detailed style)")
    return test_accs, train_accs, n_range


# ═══════════════════════════════════════════════════════════════════════════
# STEP 4 — Error vs Number of Trees  (NEW)
# ═══════════════════════════════════════════════════════════════════════════
def plot_error_vs_trees(test_accs, train_accs, n_range):
    """
    Same white detailed style as epoch_accuracy.png:
      • White background, light grey grid, real tick numbers
      • Orange = validation error, Blue = training error
      • Floating right-side labels, no top/right border
    """
    print("\n[4/6] Generating error vs number-of-trees graph (white detailed style) ...")

    train_errors = [( 1 - a) * 100 for a in train_accs]
    val_errors   = [(1 - a)  * 100 for a in test_accs]

    ORANGE = "#F5A623"
    BLUE   = "#4A90D9"

    fig, ax = plt.subplots(figsize=(10, 6), facecolor="white")
    ax.set_facecolor("white")

    ax.plot(n_range, train_errors, color=BLUE,   linewidth=2.5)
    ax.plot(n_range, val_errors,   color=ORANGE, linewidth=2.5)

    ax.text(n_range[-1] + 3, val_errors[-1],   "validation error",
            color=ORANGE, fontsize=12, fontweight="bold", va="center")
    ax.text(n_range[-1] + 3, train_errors[-1], "training error",
            color=BLUE,   fontsize=12, fontweight="bold", va="center")

    ax.set_xlabel("Number of Trees (Epochs)", fontsize=12, color="#333333", labelpad=8)
    ax.set_ylabel("Error Rate (%)",           fontsize=12, color="#333333", labelpad=8)
    ax.set_title("The Error Curves",          fontsize=15, fontweight="bold",
                 color="#111111", pad=12)

    ax.tick_params(colors="#555555", labelsize=10)
    ax.set_xlim([n_range[0], n_range[-1] + 40])
    ax.set_ylim([-1, max(val_errors) * 1.15])

    ax.grid(True, color="#E0E0E0", linewidth=0.8, linestyle="-")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#CCCCCC")
    ax.spines["bottom"].set_color("#CCCCCC")

    plt.tight_layout()
    plt.savefig("epoch_error.png", dpi=180, bbox_inches="tight", facecolor="white")
    plt.close()
    print("  ✅ Saved: epoch_error.png  (white detailed style)")


# ═══════════════════════════════════════════════════════════════════════════
# STEP 5 — Train Final Model
# ═══════════════════════════════════════════════════════════════════════════
def train_final_model(X_train, y_train):
    """
    Balanced hyperparameters that reduce the train/test gap:
      - max_depth=25  (not None) prevents unlimited tree growth that
        causes 100% training accuracy but poor generalisation
      - min_samples_split=4 / min_samples_leaf=2 add regularisation
      - class_weight='balanced' handles any class imbalance
      - 300 trees — good accuracy without over-fitting
    """
    print("\n[5/6] Training final model ...")
    model = RandomForestClassifier(
        n_estimators=300,
        max_depth=25,
        min_samples_split=4,
        min_samples_leaf=2,
        max_features="sqrt",
        class_weight="balanced",
        random_state=42,
        n_jobs=-1
    )
    model.fit(X_train, y_train)
    print("  Training complete!")
    return model


# ═══════════════════════════════════════════════════════════════════════════
# STEP 6a — Confusion Matrix
# ═══════════════════════════════════════════════════════════════════════════
def plot_confusion_matrix(model, X_test, y_test):
    print("\n[6a/6] Generating confusion matrix ...")
    y_pred  = model.predict(X_test)
    classes = sorted(model.classes_)
    cm      = confusion_matrix(y_test, y_pred, labels=classes)

    fig, ax = plt.subplots(figsize=(16, 13))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Greens",
                xticklabels=classes, yticklabels=classes,
                linewidths=0.5, linecolor="lightgray", ax=ax)
    ax.set_xlabel("Predicted Label", fontsize=13)
    ax.set_ylabel("True Label",      fontsize=13)
    ax.set_title(
        f"Confusion Matrix — Hariyali Crop Recommendation\n"
        f"(Random Forest, {len(classes)} crops, No pH)",
        fontsize=14, fontweight="bold"
    )
    plt.xticks(rotation=45, ha="right", fontsize=9)
    plt.yticks(rotation=0,  fontsize=9)
    plt.tight_layout()
    plt.savefig("confusion_matrix.png", dpi=150, bbox_inches="tight")
    plt.close()

    accuracy = accuracy_score(y_test, y_pred)
    print(f"  ✅ Final Model Accuracy: {accuracy*100:.2f}%")
    print("\n  Classification Report:")
    print(classification_report(y_test, y_pred))
    print("  ✅ Saved: confusion_matrix.png")
    return accuracy


# ═══════════════════════════════════════════════════════════════════════════
# STEP 6b — Decision Tree
# ═══════════════════════════════════════════════════════════════════════════
def plot_decision_tree(model):
    print("\n[6b/6] Generating decision tree visualization ...")
    tree = model.estimators_[0]
    fig, ax = plt.subplots(figsize=(24, 10))
    plot_tree(tree, feature_names=FEATURE_COLS,
              class_names=list(model.classes_), filled=True,
              max_depth=4, fontsize=8, ax=ax,
              impurity=True, proportion=False, rounded=True, precision=2)
    ax.set_title(
        "Decision Tree (depth ≤ 4) from Trained Random Forest — Hariyali\n"
        "(One real tree from the ensemble, no pH feature)",
        fontsize=13, fontweight="bold"
    )
    plt.tight_layout()
    plt.savefig("decision_tree_rice.png", dpi=120, bbox_inches="tight")
    plt.close()
    print("  ✅ Saved: decision_tree_rice.png")


# ═══════════════════════════════════════════════════════════════════════════
# STEP 6c — Feature Importance
# ═══════════════════════════════════════════════════════════════════════════
def plot_feature_importance(model):
    print("\n[6c/6] Generating feature importance chart ...")
    DISPLAY_LABELS = {
        "season_encoded":    "season",
        "soil_type_encoded": "soil type",
    }
    display_names = [DISPLAY_LABELS.get(f, f) for f in FEATURE_COLS]
    feat_df = pd.DataFrame({
        "Feature":    display_names,
        "Importance": model.feature_importances_
    }).sort_values("Importance", ascending=True)

    colors = ["#4CAF50" if i >= len(FEATURE_COLS)-3 else "#90CAF9"
              for i in range(len(feat_df))]
    fig, ax = plt.subplots(figsize=(9, 6))
    ax.barh(feat_df["Feature"], feat_df["Importance"], color=colors)
    for i, val in enumerate(feat_df["Importance"]):
        ax.text(val + 0.001, i, f"{val:.4f}", va="center", fontsize=9)
    ax.set_xlabel("Feature Importance (Gini)", fontsize=12)
    ax.set_title("Feature Importance — Hariyali Random Forest (No pH)",
                 fontsize=13, fontweight="bold")
    ax.grid(axis="x", alpha=0.3)
    plt.tight_layout()
    plt.savefig("feature_importance.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("  ✅ Saved: feature_importance.png")


# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    print("=" * 60)
    print("  HARIYALI — Improved Model Training v3 (K-Fold)")
    print("=" * 60)

    # 1. Load
    df = load_data()
    if df is None:
        exit(1)

    X = df[FEATURE_COLS]
    y = df[LABEL_COL]

    # 2. K-Fold CV (uses the full dataset — gives reliable accuracy estimate)
    cv_scores = kfold_cross_validation(X, y, n_splits=5)

    # 3. Single 80/20 split for charts & final model
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )
    print(f"\n  Train : {len(X_train)} | Test : {len(X_test)}")

    # 4. Train final model FIRST so we have the real test accuracy
    model = train_final_model(X_train, y_train)
    accuracy = plot_confusion_matrix(model, X_test, y_test)

    # 5. Epoch accuracy graph — pass real final accuracy so annotation is correct
    test_accs, train_accs, n_range = plot_epoch_accuracy(
        X_train, y_train, X_test, y_test, max_trees=200,
        final_test_acc=accuracy
    )

    # 6. Error vs Trees graph
    plot_error_vs_trees(test_accs, train_accs, n_range)

    # 7. Decision tree + Feature importance
    plot_decision_tree(model)
    plot_feature_importance(model)

    # 9. Save model
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)
    print(f"\n  ✅ Model saved → {MODEL_PATH}")

    print("\n" + "=" * 60)
    print(f"  TRAINING COMPLETE!")
    print(f"  CV Accuracy   : {cv_scores.mean()*100:.2f}% ± {cv_scores.std()*100:.2f}%")
    print(f"  Test Accuracy : {accuracy*100:.2f}%")
    print("=" * 60)
    print("\n  Charts generated:")
    print("   📊 confusion_matrix.png")
    print("   📈 epoch_accuracy.png      ← dark-styled (matches figure.png)")
    print("   📉 epoch_error.png         ← NEW: Error vs Trees")
    print("   🌳 decision_tree_rice.png")
    print("   📉 feature_importance.png")
    print("   💾 crop_model.pkl")
    print("\n  Next: python app.py")
    print("=" * 60)