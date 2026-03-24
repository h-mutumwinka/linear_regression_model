import io
from pathlib import Path
from typing import List

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.linear_model import LinearRegression


app = FastAPI(
    title="Student Exam Score Regression API",
    description="Predicting exam scores and retraining a linear regression model.",
    version="1.0.0",
)

origins = [
       "https://student-score-hbkk.onrender.com",
       "http://127.0.0.1:8000",
       "http://localhost:8000",
       ]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "best_model.pkl"
FEATURES = [
    "Attendance",
    "Sleep_Hours",
    "Previous_Scores",
    "Tutoring_Sessions",
    "Physical_Activity",
]
TARGET = "Exam_Score"
model = None

 #api codes
class StudentData(BaseModel):
    Attendance: float = Field(..., ge=0, le=100)
    Sleep_Hours: float = Field(..., ge=0, le=24)
    Previous_Scores: float = Field(..., ge=0, le=100)
    Tutoring_Sessions: float = Field(..., ge=0, le=20)
    Physical_Activity: float = Field(..., ge=0, le=10)


class TrainingRecord(StudentData):
    Exam_Score: float = Field(..., ge=0, le=100)


class StreamRetrainRequest(BaseModel):
    records: List[TrainingRecord] = Field(..., min_length=1)


def _load_model_from_disk() -> None:
    global model
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Model file not found at {MODEL_PATH}. Retrain first or add best_model.pkl."
        )
    model = joblib.load(MODEL_PATH)


def _train_and_persist(df: pd.DataFrame) -> int:
    global model
    missing = [column for column in FEATURES + [TARGET] if column not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    training_df = df[FEATURES + [TARGET]].dropna()
    if len(training_df) < 5:
        raise ValueError("At least 5 valid rows are required for retraining.")

    x_train = training_df[FEATURES]
    y_train = training_df[TARGET]

    new_model = LinearRegression()
    new_model.fit(x_train, y_train)

    joblib.dump(new_model, MODEL_PATH)
    model = new_model
    return int(len(training_df))


@app.on_event("startup")
def startup_event() -> None:
    try:
        _load_model_from_disk()
    except FileNotFoundError:
        # The retrain endpoints can initialize the model if the file is absent.
        pass


@app.get("/")
def home() -> dict:
    return {"message": "Student Exam Score API is running"}


@app.post("/predict")# for predicting 
def predict(data: StudentData) -> dict:
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Retrain the model first via /retrain/upload or /retrain/stream.",
        )

    input_data = np.array(
        [[
            data.Attendance,
            data.Sleep_Hours,
            data.Previous_Scores,
            data.Tutoring_Sessions,
            data.Physical_Activity,
        ]]
    )
    prediction = float(model.predict(input_data)[0])

    return {"predicted_exam_score": round(prediction, 4)}


@app.post("/retrain/upload")# for uploading
async def retrain_from_upload(file: UploadFile = File(...)) -> dict:
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are supported.")

    content = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(content))
        rows_used = _train_and_persist(df)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500, detail=f"Retraining failed: {exc}"
        ) from exc

    return {"message": "Model retrained from uploaded CSV.", "rows_used": rows_used}


@app.post("/retrain/stream")
def retrain_from_stream(payload: StreamRetrainRequest) -> dict:
    try:
        df = pd.DataFrame(
            [
                record.model_dump() if hasattr(record, "model_dump") else record.dict()
                for record in payload.records
            ]
        )
        rows_used = _train_and_persist(df)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500, detail=f"Retraining failed: {exc}"
        ) from exc

    return {"message": "Model retrained from streamed data.", "rows_used": rows_used}

