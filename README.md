
## Mission and Problem statement
This project predicts student exam performance from academic and lifestyle factors.  
The goal is to identify patterns affecting exam score outcomes and support early intervention.  
It applies regression modeling, API deployment, and mobile integration for end-to-end prediction.  
The solution includes model training, FastAPI inference/retraining endpoints, and a Flutter client.

## Dataset Source
Kaggle:  
https://www.kaggle.com/code/lalit7881/student-exam-performance-analysis/input

## Project Structure
```text
summative/
├── linear_regression/
│   └── multivariate.ipynb
├── API/
│   ├── prediction.py
│   ├── best_model.pkl
│   └── requirements.txt
└── FlutterApp/
    └── lib/main.dart
```

## Task 1 - Model Development
- Built and compared three models:
  - Linear Regression
  - Decision Tree Regressor
  - Random Forest Regressor
- Selected and saved best-performing model to `best_model.pkl`
- Included data preparation (encoding + standardization) and prediction on a test row in the notebook

## Task 2 - FastAPI Deployment
API code: `summative/API/prediction.py`  
Dependencies: `summative/API/requirements.txt`

### Required Libraries
- fastapi
- pydantic
- uvicorn
- numpy
- pandas
- scikit-learn
- joblib
- python-multipart

### Local Run Instructions (API)
```bash
cd summative/API
pip install -r requirements.txt
uvicorn prediction:app --host 0.0.0.0 --port 8000 --reload
```

### Prediction Endpoint
- `POST /predict`
- Pydantic-enforced data types and ranges:
  - `Attendance`: 0-100
  - `Sleep_Hours`: 0-24
  - `Previous_Scores`: 0-100
  - `Tutoring_Sessions`: 0-20
  - `Physical_Activity`: 0-10

### Model Update Endpoints
- `POST /retrain/upload` for CSV upload retraining
- `POST /retrain/stream` for streamed JSON retraining

### Public API and Swagger UI
- Base URL: https://student-score-hbkk.onrender.com
- Public Swagger UI: https://student-score-hbkk.onrender.com/docs

## Task 3 - Flutter Mobile App
Flutter code: `summative/FlutterApp/lib/main.dart`

### App Features
- One-page prediction screen
- Five input fields (matching model variables)
- Predict button
- Result/error display area
- Input validation for missing values, datatype, and range
- API integration using:
  - Base URL: https://student-score-hbkk.onrender.com
  - Endpoint: `/predict`

Link to the screenshot  of the UI mobile app  
 https://github.com/h-mutumwinka/linear_regression_model/blob/main/summative/FlutterApp/Screenshot%202026-03-24%20173134.png
 
### Local Run Instructions (Flutter)
```bash
cd summative/FlutterApp
flutter pub get
flutter run
```

## Task 4 - Yotube Video Demo Link

https://youtu.be/3xVqcAKHug4



