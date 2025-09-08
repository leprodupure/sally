from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from pydantic import BaseModel
from datetime import datetime

from database import Base


# SQLAlchemy model for the 'measurements' table
class MeasurementDB(Base):
    __tablename__ = "measurements"
    __table_args__ = {"schema": "measurement"}

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    aquarium_id = Column(Integer, index=True, nullable=False)
    parameter_type = Column(String, index=True)
    value = Column(Float)
    timestamp = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


# Pydantic model for request body on creation
class MeasurementCreate(BaseModel):
    aquarium_id: int
    parameter_type: str
    value: float
    timestamp: datetime


# Pydantic model for response body
class Measurement(BaseModel):
    id: int
    aquarium_id: int
    parameter_type: str
    value: float
    timestamp: datetime

    class Config:
        from_attributes = True
