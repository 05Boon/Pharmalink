from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import List, Optional

# AlertNotification schemas
class AlertNotificationBase(BaseModel):
    receiving_pharmacy_id: str = Field(..., description="UUID of the receiving pharmacy")
    alert_status: str = Field("UNREAD", description="Status of the alert, e.g., UNREAD, READ, DISMISSED")

class AlertNotificationCreate(AlertNotificationBase):
    request_id: str = Field(..., description="UUID of the associated stock request")

class AlertNotificationResponse(AlertNotificationBase):
    alert_id: str = Field(..., description="UUID of the alert")
    request_id: str = Field(..., description="UUID of the associated stock request")
    delivered_at: datetime = Field(..., description="Timestamp when the alert was delivered")

    model_config = ConfigDict(from_attributes=True)


# StockRequest schemas
class StockRequestBase(BaseModel):
    requested_drug: str = Field(..., min_length=1, description="Name of the requested drug")
    required_quantity: int = Field(..., gt=0, description="Quantity required, must be greater than 0")
    search_radius_meters: int = Field(2000, gt=0, description="Search radius in meters, must be greater than 0")

class StockRequestCreate(StockRequestBase):
    pharmacy_id: str = Field(..., description="UUID of the requesting pharmacy")

class StockRequestResponse(StockRequestBase):
    request_id: str = Field(..., description="UUID of the stock request")
    pharmacy_id: str = Field(..., description="UUID of the requesting pharmacy")
    request_status: str = Field(..., description="Current status of the request (e.g. PENDING, FULFILLED)")
    created_at: datetime = Field(..., description="Timestamp when the request was created")
    alerts: List[AlertNotificationResponse] = Field([], description="List of alert notifications sent to neighbors")

    model_config = ConfigDict(from_attributes=True)
