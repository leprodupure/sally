from fastapi import FastAPI, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from mangum import Mangum

import crud, models, database

app = FastAPI(title="Aquarium Service")


# Dependency to get the database session
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Dependency to get the current user's ID from the Cognito authorizer context
def get_current_user_id(request: Request) -> str:
    # The user ID (sub) is passed by the API Gateway Cognito Authorizer
    # For HTTP API (v2) JWT authorizers, claims are nested under 'jwt'
    user_id = request.scope.get("aws.event", {}).get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {}).get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Could not validate credentials")
    return user_id


@app.post("/aquariums", response_model=models.Aquarium)
def create_aquarium(
    aquarium: models.AquariumCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    # Pass the Pydantic model directly to the CRUD layer
    return crud.create_aquarium(db=db, aquarium=aquarium, user_id=user_id)


@app.get("/aquariums", response_model=list[models.Aquarium])
def read_aquariums(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    print("start GET /aquariums")
    aquariums = crud.get_aquariums_by_user(db, user_id=user_id, skip=skip, limit=limit)
    print(f"GET /aquariums result: {aquariums}")
    return aquariums


@app.get("/aquariums/{aquarium_id}", response_model=models.Aquarium)
def read_aquarium(
    aquarium_id: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    db_aquarium = crud.get_aquarium(db, aquarium_id=aquarium_id, user_id=user_id)
    if db_aquarium is None:
        raise HTTPException(status_code=404, detail="Aquarium not found")
    return db_aquarium


@app.put("/aquariums/{aquarium_id}", response_model=models.Aquarium)
def update_aquarium(
    aquarium_id: int,
    aquarium: models.AquariumUpdate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    db_aquarium = crud.update_aquarium(db, aquarium_id=aquarium_id, user_id=user_id, aquarium=aquarium)
    if db_aquarium is None:
        raise HTTPException(status_code=404, detail="Aquarium not found")
    return db_aquarium


@app.delete("/aquariums/{aquarium_id}", status_code=204)
def delete_aquarium(
    aquarium_id: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    success = crud.delete_aquarium(db, aquarium_id=aquarium_id, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Aquarium not found")
    return {"ok": True}


# Mangum adapter to make FastAPI work with AWS Lambda
handler = Mangum(app)