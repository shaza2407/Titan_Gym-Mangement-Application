import joblib ##Add joblib and sklearn to requi.txt
import numpy as np
from pathlib import Path

BASE_DIR = Path(__file__).parent
model = joblib.load(BASE_DIR / "churn_model.pkl")
le = joblib.load(BASE_DIR / "label_encoder.pkl")
FEATURES = joblib.load(BASE_DIR / "features.pkl")


def predict(payload: dict) -> str:
    weeks = [payload[f"w{i}"] for i in range(12)]

    weeks_arr = np.array(weeks)

    weighted_score = int(sum(weeks_arr * np.array(range(1, 13))))
    recent_score = int(sum(weeks_arr[8:] * np.array(range(9, 13))))
    old_score = int(sum(weeks_arr[:8] * np.array(range(1, 9))))
    recent_vs_old = round(recent_score / (old_score + 1), 4)
    is_inactive = 1 if all(v == 0 for v in weeks_arr[8:]) else 0

    features = weeks + [
        weighted_score,
        recent_score,
        old_score,
        recent_vs_old,
        is_inactive,
        payload["days_since_last_visit"],
        payload["days_until_expiry"],
    ]

    features_arr = np.array(features).reshape(1, -1)
    prediction = model.predict(features_arr)[0]
    return le.inverse_transform([prediction])[0]
