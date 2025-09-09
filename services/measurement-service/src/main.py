from fastapi import FastAPI, Depends, HTTPException, Request
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

# Dependency to get the current user's ID from the Cognito authorizer context
def get_current_user_id(request: Request) -> str:
    # The user ID (sub) is passed by the API Gateway Cognito Authorizer
    user_id = request.scope.get("aws.event", {}).get("requestContext", {}).get("authorizer", {}).get("claims", {}).get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Could not validate credentials")
    return user_id

@app.post("/measurements", response_model=models.Measurement)
def create_measurement(measurement: models.MeasurementCreate, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    db_measurement = models.MeasurementDB(**measurement.dict(), user_id=user_id)
    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)
    return db_measurement

@app.get("/measurements", response_model=list[models.Measurement])
def read_measurements(aquarium_id: int, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    measurements = db.query(models.MeasurementDB).filter(
        models.MeasurementDB.aquarium_id == aquarium_id,
        models.MeasurementDB.user_id == user_id
    ).all()
    return measurements


handler = Mangum(app)
