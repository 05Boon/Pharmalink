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


# Client stock request input (omits pharmacy_id which is auto-injected from auth)
class StockRequestCreateInput(BaseModel):
    requested_drug: str = Field(..., min_length=1, description="Name of the requested drug")
    required_quantity: int = Field(..., gt=0, description="Quantity required, must be greater than 0")
    search_radius_meters: Optional[int] = Field(2000, gt=0, description="Search radius in meters, must be greater than 0")


# InventoryItem schemas
class InventoryItemCreate(BaseModel):
    drug_name: str = Field(..., min_length=1, description="Name of the drug")
    drug_category: Optional[str] = Field(None, description="Category of the drug")
    stock_quantity: int = Field(0, ge=0, description="Current stock level, must be greater than or equal to 0")

class InventoryItemUpdate(BaseModel):
    stock_quantity: int = Field(..., ge=0, description="New stock level, must be greater than or equal to 0")

class InventoryItemResponse(BaseModel):
    item_id: str = Field(..., description="UUID of the inventory item")
    pharmacy_id: str = Field(..., description="UUID of the associated pharmacy")
    drug_name: str = Field(..., description="Name of the drug")
    drug_category: Optional[str] = Field(None, description="Category of the drug")
    stock_quantity: int = Field(..., description="Current stock level")
    last_updated: datetime = Field(..., description="Timestamp when the stock level was last updated")

    model_config = ConfigDict(from_attributes=True)
