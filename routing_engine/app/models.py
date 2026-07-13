import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
import datetime
from geoalchemy2 import Geometry

Base = declarative_base()

def generate_uuid():
    return str(uuid.uuid4())

def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)

class SystemAdmin(Base):
    __tablename__ = "system_admins"

    admin_id = Column(String, primary_key=True, default=generate_uuid)
    email = Column(String, nullable=False, unique=True)
    role_level = Column(Integer, default=1)
    created_at = Column(DateTime, default=utc_now)

class PharmacyNode(Base):
    __tablename__ = "pharmacy_nodes"

    # This UUID will be injected directly from Supabase Auth upon signup
    pharmacy_id = Column(String, primary_key=True) 
    
    business_name = Column(String, nullable=False)
    license_number = Column(String, nullable=False, unique=True)
    email = Column(String, nullable=False, unique=True)
    phone_number = Column(String, nullable=False)
    
    # Geographic coordinates (WGS 84)
    location = Column(Geometry(geometry_type="POINT", srid=4326), nullable=False)
    
    account_status = Column(String, default="PENDING") 
    created_at = Column(DateTime, default=utc_now)

    # Relationships
    inventory = relationship("InventoryItem", back_populates="pharmacy")
    requests = relationship("StockRequest", back_populates="pharmacy")

class InventoryItem(Base):
    __tablename__ = "inventory_items"

    item_id = Column(String, primary_key=True, default=generate_uuid)
    
    # B-Tree Index applied here for ultra-fast dashboard queries
    pharmacy_id = Column(String, ForeignKey("pharmacy_nodes.pharmacy_id", ondelete="CASCADE"), nullable=False, index=True)
    
    drug_name = Column(String, nullable=False)
    drug_category = Column(String, nullable=True)
    stock_quantity = Column(Integer, default=0)
    last_updated = Column(DateTime, default=utc_now, onupdate=utc_now)

    # Relationships
    pharmacy = relationship("PharmacyNode", back_populates="inventory")

class StockRequest(Base):
    __tablename__ = "stock_requests"

    request_id = Column(String, primary_key=True, default=generate_uuid)
    pharmacy_id = Column(String, ForeignKey("pharmacy_nodes.pharmacy_id", ondelete="CASCADE"), nullable=False, index=True)
    
    requested_drug = Column(String, nullable=False)
    drug_category = Column(String, nullable=True)
    required_quantity = Column(Integer, nullable=False)
    search_radius_meters = Column(Integer, default=2000)
    therapeutic_class = Column(String, nullable=True)
    shortage_reason = Column(String, nullable=True)
    request_status = Column(String, default="PENDING")
    created_at = Column(DateTime, default=utc_now)

    # Relationships
    pharmacy = relationship("PharmacyNode", back_populates="requests")
    logs = relationship("TransactionLog", back_populates="request")
    alerts = relationship("AlertNotification", back_populates="request")

class TransactionLog(Base):
    __tablename__ = "transaction_logs"

    log_id = Column(String, primary_key=True, default=generate_uuid)
    request_id = Column(String, ForeignKey("stock_requests.request_id", ondelete="SET NULL"), nullable=True, index=True)
    
    drug_category = Column(String, nullable=True)
    general_location = Column(String, nullable=True)
    final_outcome = Column(String, nullable=False) # e.g., "FULFILLED_BY_NEIGHBOR", "EXPIRED"
    resolved_at = Column(DateTime, default=utc_now)

    # Relationships
    request = relationship("StockRequest", back_populates="logs")

class AlertNotification(Base):
    __tablename__ = "alert_notifications"

    alert_id = Column(String, primary_key=True, default=generate_uuid)
    request_id = Column(String, ForeignKey("stock_requests.request_id", ondelete="CASCADE"), nullable=False, index=True)
    
    # The neighbor receiving the ping
    receiving_pharmacy_id = Column(String, ForeignKey("pharmacy_nodes.pharmacy_id", ondelete="CASCADE"), nullable=False, index=True)
    
    alert_status = Column(String, default="UNREAD")
    delivered_at = Column(DateTime, default=utc_now)

    # Relationships
    request = relationship("StockRequest", back_populates="alerts")