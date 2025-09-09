from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from mangum import Mangum

import models
from database import SessionLocal, engine

app = FastAPI()

# Dependency to get the database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Helper to get user_id from the Cognito authorizer in the API Gateway event
def get_user_id(event):
    return event['requestContext']['authorizer']['claims']['sub']

@app.post("/measurements", response_model=models.Measurement)
def create_measurement(measurement: models.MeasurementCreate, db: Session = Depends(get_db), event: dict = None):
    user_id = get_user_id(event)
    db_measurement = models.MeasurementDB(**measurement.dict(), user_id=user_id)
    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)
    return db_measurement

@app.get("/measurements", response_model=list[models.Measurement])
def read_measurements(aquarium_id: int, db: Session = Depends(get_db), event: dict = None):
    user_id = get_user_id(event)
    measurements = db.query(models.MeasurementDB).filter(
        models.MeasurementDB.aquarium_id == aquarium_id,
        models.MeasurementDB.user_id == user_id
    ).all()
    return measurements


handler = Mangum(app)
