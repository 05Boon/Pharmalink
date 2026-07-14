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


# Lightweight pharmacy summary, reused wherever a request/alert needs to show
# who the requesting pharmacy is without pulling in the full profile payload.
class PharmacyBasicInfo(BaseModel):
    pharmacy_id: str
    business_name: str
    email: str
    phone_number: str

    model_config = ConfigDict(from_attributes=True)


# StockRequest schemas
class StockRequestBase(BaseModel):
    requested_drug: str = Field(..., min_length=1, description="Name of the requested drug")
    required_quantity: int = Field(..., gt=0, description="Quantity required, must be greater than 0")
    search_radius_meters: int = Field(2000, gt=0, description="Search radius in meters, must be greater than 0")
    therapeutic_class: Optional[str] = Field(None, description="Therapeutic class of the requested drug")
    shortage_reason: Optional[str] = Field(None, description="Reason for the drug shortage")

class StockRequestCreate(StockRequestBase):
    pharmacy_id: str = Field(..., description="UUID of the requesting pharmacy")

class StockRequestResponse(StockRequestBase):
    request_id: str = Field(..., description="UUID of the stock request")
    pharmacy_id: str = Field(..., description="UUID of the requesting pharmacy")
    request_status: str = Field(..., description="Current status of the request (e.g. PENDING, FULFILLED)")
    created_at: datetime = Field(..., description="Timestamp when the request was created")
    alerts: List[AlertNotificationResponse] = Field([], description="List of alert notifications sent to neighbors")
    pharmacy: Optional[PharmacyBasicInfo] = Field(
        None, description="Summary of the requesting pharmacy (name/contact info)"
    )
    accepted_by_pharmacy: Optional[PharmacyBasicInfo] = Field(
        None, description="Summary of the pharmacy that accepted the request"
    )
    accepted_at: Optional[datetime] = Field(
        None, description="Timestamp when the request was accepted"
    )

    model_config = ConfigDict(from_attributes=True)


# Client stock request input (omits pharmacy_id which is auto-injected from auth)
class StockRequestCreateInput(BaseModel):
    requested_drug: str = Field(..., min_length=1, description="Name of the requested drug")
    required_quantity: int = Field(..., gt=0, description="Quantity required, must be greater than 0")
    search_radius_meters: Optional[int] = Field(2000, gt=0, description="Search radius in meters, must be greater than 0")
    therapeutic_class: Optional[str] = Field(None, description="Therapeutic class of the requested drug")
    shortage_reason: Optional[str] = Field(None, description="Reason for the drug shortage")


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


class PharmacyProfileSync(BaseModel):
    business_name: str = Field(..., min_length=1, description="Registered name of the pharmacy")
    license_number: str = Field(..., min_length=1, description="Unique license number issued by the PPB")
    email: str = Field(..., description="Registered email address")
    phone_number: str = Field(..., min_length=1, description="Primary contact phone number")
    latitude: float = Field(..., ge=-90, le=90, description="GPS latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="GPS longitude coordinate")


class PharmacyProfileUpdate(BaseModel):
    business_name: Optional[str] = Field(None, min_length=1, description="Registered name of the pharmacy")
    phone_number: Optional[str] = Field(None, min_length=1, description="Primary contact phone number")
    general_location: Optional[str] = Field(None, description="General locality (e.g., City, Region)")

class PharmacyNodeResponse(BaseModel):
    pharmacy_id: str
    business_name: str
    license_number: str
    email: str
    phone_number: str
    latitude: float
    longitude: float
    general_location: Optional[str] = None
    account_status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class StockRequestDetailResponse(StockRequestBase):
    request_id: str = Field(..., description="UUID of the stock request")
    pharmacy_id: str = Field(..., description="UUID of the requesting pharmacy")
    request_status: str = Field(..., description="Current status of the request (e.g. PENDING, FULFILLED)")
    created_at: datetime = Field(..., description="Timestamp when the request was created")
    pharmacy: PharmacyBasicInfo

    model_config = ConfigDict(from_attributes=True)



class AlertNotificationDetailResponse(BaseModel):
    alert_id: str
    request_id: str
    receiving_pharmacy_id: str
    alert_status: str
    delivered_at: datetime
    request: StockRequestDetailResponse

    model_config = ConfigDict(from_attributes=True)


class PharmacyStatusUpdate(BaseModel):
    account_status: str = Field(..., description="Target status, e.g., ACTIVE, SUSPENDED")


class OutbreakAnalytic(BaseModel):
    requested_drug: str
    request_frequency: int
    centroid_latitude: float
    centroid_longitude: float
    region_name: str

    model_config = ConfigDict(from_attributes=True)


class OutbreakAlert(BaseModel):
    location: str
    drug_category: str
    shortage_reason: str
    incident_count: int

    model_config = ConfigDict(from_attributes=True)


class PharmacyProfileUpdate(BaseModel):
    business_name: Optional[str] = Field(None, min_length=1, description="Registered name of the pharmacy")
    phone_number: Optional[str] = Field(None, min_length=1, description="Primary contact phone number")
    latitude: Optional[float] = Field(None, ge=-90, le=90, description="GPS latitude coordinate")
    longitude: Optional[float] = Field(None, ge=-180, le=180, description="GPS longitude coordinate")


class RequestResponseInput(BaseModel):
    status: str = Field(..., description="ACCEPTED or DECLINED")


class DashboardStats(BaseModel):
    active_queries: int
    requests_received: int
    completed: int


class RecentRequestItem(BaseModel):
    drug_name: str
    source: str
    created_at: datetime
    status: str


class ActiveQueryItem(BaseModel):
    drug_name: str
    meta: str
    status: str


class DashboardResponse(BaseModel):
    stats: DashboardStats
    recent_requests: List[RecentRequestItem]
    active_queries: List[ActiveQueryItem]
    low_stock_items: List[InventoryItemResponse]


class OnboardingReviewInput(BaseModel):
    approved: bool
    status: Optional[str] = None
    decision: Optional[str] = None


class AdminTransactionResponse(BaseModel):
    id: str = Field(..., alias="id")
    sender: str = Field(..., alias="from")
    receiver: str = Field(..., alias="to")
    drug: str = Field(..., alias="drug")
    quantity: int = Field(..., alias="quantity")
    status: str
    time: datetime = Field(..., alias="time")

    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


class AdminAuditLogResponse(BaseModel):
    action: str
    user: str
    created_at: datetime = Field(..., alias="time")

    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


# Compact card item used for dashboard report tiles.
class AdminReportCard(BaseModel):
    title: str
    description: str
    icon: str


# Ranked drug-demand row for the generated report details.
class AdminTopDrugReportItem(BaseModel):
    drug_name: str
    request_count: int


class AdminAreaTopDrugReportItem(BaseModel):
    area_label: str
    top_drug: str
    request_count: int
    total_requests_in_area: int
    percentage: float


# Full report envelope returned by the generate-report endpoint.
class AdminGeneratedReport(BaseModel):
    generated_at: datetime
    timeframe_days: int
    fulfillment_rate: float
    average_resolution_time_mins: int
    cards: List[AdminReportCard]
    top_requested_drugs: List[AdminTopDrugReportItem]
    top_requested_drugs_by_area: List[AdminAreaTopDrugReportItem]