from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from pydantic import BaseModel

from database import Base


# SQLAlchemy model for the 'aquariums' table
class AquariumDB(Base):
    __tablename__ = "aquariums"
    __table_args__ = {"schema": "aquarium"}

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    name = Column(String, index=True)
    volume_liters = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


# Pydantic model for request body on creation
class AquariumCreate(BaseModel):
    name: str
    volume_liters: float


# Pydantic model for request body on update (all fields optional)
class AquariumUpdate(BaseModel):
    name: str | None = None
    volume_liters: float | None = None


# Pydantic model for response body
class Aquarium(BaseModel):
    id: int
    name: str
    volume_liters: float

    class Config:
        from_attributes = True
