from sqlalchemy.orm import Session

import models


def get_aquarium(db: Session, aquarium_id: int, user_id: str):
    return db.query(models.AquariumDB).filter(models.AquariumDB.id == aquarium_id, models.AquariumDB.user_id == user_id).first()


def get_aquariums_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.AquariumDB).filter(models.AquariumDB.user_id == user_id).offset(skip).limit(limit).all()


def create_aquarium(db: Session, aquarium: models.AquariumCreate, user_id: str):
    # Convert the Pydantic model to a dictionary and unpack it into the SQLAlchemy model
    db_aquarium = models.AquariumDB(**aquarium.model_dump(), user_id=user_id)
    db.add(db_aquarium)
    db.commit()
    db.refresh(db_aquarium)
    return db_aquarium


def update_aquarium(db: Session, aquarium_id: int, user_id: str, aquarium: models.AquariumUpdate):
    db_aquarium = get_aquarium(db, aquarium_id, user_id)
    if not db_aquarium:
        return None

    update_data = aquarium.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_aquarium, key, value)

    db.add(db_aquarium)
    db.commit()
    db.refresh(db_aquarium)
    return db_aquarium


def delete_aquarium(db: Session, aquarium_id: int, user_id: str):
    db_aquarium = get_aquarium(db, aquarium_id, user_id)
    if not db_aquarium:
        return False
    db.delete(db_aquarium)
    db.commit()
    return True
