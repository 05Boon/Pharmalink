# Project Development History: Backend Stack & Spatial Routing Integration

This document logs all architectural decisions, implementations, test suites, and configuration updates completed during this active development session for the decentralized pharmacy network.

---

## 1. Project Tech Stack & Architecture Overview

The backend is built as a REST and Real-Time WebSocket service managing pharmacy node discovery, spatial routing query execution, and secure inventory management.

* **Backend Engine:** FastAPI (Python 3.14.6) with Uvicorn.
* **ORM / Database Driver:** SQLAlchemy (Async) with `asyncpg` interfacing with a PostgreSQL database equipped with the **PostGIS** extension.
* **Geospatial Reference:** Location storage uses geography coordinates cast to WGS 84 (`SRID 4326`) to perform distance calculations in meters via PostGIS.
* **Authentication:** Secured via Supabase Auth JWT bearer tokens, integrated using a local dependency override mechanism.

---

## 2. Completed Milestones & Feature Implementations

### Milestone A: Dart Translator Refactoring
* **Objective:** Align the automated translator script to use `Dio` instead of standard Dart `http` packages.
* **Modifications:** Refactored [translate.py](file:///home/yusufsalyani/Projects/Pharmalink/.agents/skills/dart_translator/translate.py) to import the global `Dio` instance from `auth_interceptor.dart` and directly map from `response.data` to skip manual decoding steps.

### Milestone B: Data Validation (Schemas) & Database Access (CRUD)
* **Objective:** Scaffold data validation models and async CRUD operations for `stock_requests` and `alert_notifications`.
* **Modifications in [schemas.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/schemas.py):**
  * Added `StockRequestCreateInput` and `StockRequestResponse` validation schemas.
  * Added `AlertNotificationResponse` validation schemas.
* **Modifications in [crud.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/crud.py):**
  * Built `create_stock_request` to handle request creation.
  * Implemented eager relationship loading via `selectinload(StockRequest.alerts)` when calling `get_stock_request_with_alerts` to resolve associated alert notifications and prevent performance-degrading N+1 queries.
* **Verification:** Verified all Pydantic validations and database insert routines via [test_crud.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests/test_crud.py).

### Milestone C: WebSocket Manager & Auth Dependency Override
* **Objective:** Scaffold the main application entry point, manage WebSocket states per logged-in pharmacy, and construct a mock auth provider for local testing.
* **Modifications in [main.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/main.py):**
  * Created a thread-safe `ConnectionManager` that stores mapping of authenticated Supabase UUIDs (`pharmacy_id`) to their active `WebSocket` connections.
  * Implemented connection hooks (`connect`, `disconnect`) and targeted broadcast utilities to send live pings to specific pharmacies without race conditions.
* **Modifications in [dependencies.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/dependencies.py):**
  * Formulated the JWT decoding dependency `get_current_user`.
  * Integrated a local override where authorization headers with `mock-` prefixes skip Supabase network requests and return mock UUIDs instantly, facilitating offline testing.
* **Verification:** Tested client state tracking, ping-pong functionality, and invalid token rejections in [test_websockets.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests/test_websockets.py).

### Milestone D: REST API Routers & Geospatial Query Routing
* **Objective:** Expose endpoints for inventory management and requests broadcasting with tenancy verification and spatial query filtering.
* **Modifications in [api.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/routers/api.py):**
  * Registered `/inventory` router (GET, POST, PATCH) with ownership enforcement, checking that a pharmacy node can only update or query its own stock levels.
  * Registered `/broadcasts` router:
    * `POST /broadcasts/request` parses the incoming payload, extracts the requester's coordinates, executes a spatial query using PostGIS `ST_DWithin` to find neighbors within the specified search radius, records the transaction entries in the database, and immediately broadcasts real-time alert payloads to active WebSockets of neighboring pharmacies.
* **Verification:** Built [test_api.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests/test_api.py) using `httpx2.AsyncClient` with `ASGITransport` to run full integration tests over routers. Verified tenancy isolation (rejections with `403 Forbidden` on mismatched IDs), WebSocket messaging, and spatial discovery.

### Milestone E: Modernizing Datetime Defaults & Eliminating Deprecations
* **Objective:** Clean deprecated `datetime.datetime.utcnow` usages from tables, which trigger warnings on Python 3.12+.
* **Modifications in [models.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/models.py):**
  * Introduced a timezone-naive UTC helper function `utc_now()` returning a UTC date without offset:
    ```python
    def utc_now():
        return datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    ```
  * Swapped all defaults and `onupdate` directives referencing `datetime.datetime.utcnow` to use `utc_now`.
* **Modifications in [pytest.ini](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/pytest.ini):**
  * Deleted the `pytest.ini` configuration file since `DeprecationWarning` filters are no longer necessary.

### Milestone F: Workspace Cleanliness & Git Ignore Definitions
* **Objective:** Prevent temporary compilation artifacts, IDE caches, and secret files from being committed.
* **Modifications in [.gitignore](file:///home/yusufsalyani/Projects/Pharmalink/.gitignore):**
  * Created a consolidated, clean `.gitignore` to mask Python pycache directories (`__pycache__/`, `.pytest_cache/`), IDE state directories (`.vscode/`, `.idea/`, `.iml`), system artifacts (`.DS_Store`), and secrets (`.env`, `.env.*`).

### Milestone G: Frontend Code Generation & API Integration
* **Objective:** Bridge the FastAPI backend to the Flutter frontend by translating database schemas to Dart models/services and configuring authentication interceptors.
* **Modifications in [pubspec.yaml](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/pubspec.yaml):**
  * Added the `dio: ^5.5.0` dependency to support modern HTTP networking in the Flutter application.
* **Executed Python Generation Scripts:**
  * Executed `scaffold.py` to generate the JWT bearer token interceptor.
  * Executed `translate.py` against `StockRequest` and `InventoryItem` schemas.
* **Structured Generated Files:**
  * Created [auth_interceptor.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/core/network/auth_interceptor.dart) to globally configure `Dio` and attach Supabase Auth tokens to outgoing headers.
  * Created Dart schemas and mapping logics:
    * [alert_notification_model.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/models/alert_notification_model.dart)
    * [inventory_item_model.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/models/inventory_item_model.dart)
    * [stock_request_model.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/models/stock_request_model.dart)
  * Created service connectors targeting backend routes:
    * [inventory_item_service.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/services/inventory_item_service.dart) (maps GET, POST, PATCH on `/inventory`)
    * [stock_request_service.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/services/stock_request_service.dart) (maps POST on `/broadcasts/request`)

### Milestone H: Phase 2 Profile Synchronization Endpoint
* **Objective:** Implement the profile synchronization endpoint that receives validated profile data alongside Supabase JWTs, using the verified UUID as primary key to insert pharmacy profile records.
* **Modifications in [schemas.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/schemas.py):**
  * Added `PharmacyProfileSync` (payload schema) and `PharmacyNodeResponse` (response schema) validation layer.
* **Modifications in [crud.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/crud.py):**
  * Implemented database operations: `get_pharmacy_node`, `get_pharmacy_node_by_license`, `get_pharmacy_node_by_email`, and `create_pharmacy_node`.
* **Modifications in [auth.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/routers/auth.py):**
  * Created a dedicated REST router exposing `POST /api/pharmacies/sync-profile` with complete duplicate verification handling (validates unique license number and email, prevents double syncs).
* **Modifications in [main.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/main.py):**
  * Imported and registered `auth_router` in the application instance.
* **Modifications in [test_auth.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests/test_auth.py):**
  * Created unit and integration tests to verify successful creations, invalid credentials rejection, and duplicate conflict handling.



### Milestone I: Dashboard Retrieval Endpoints (Eager loading)
* **Objective:** Implement retrieval routes for the pharmacy dashboard to query active requests and unread alerts securely, avoiding N+1 loops.
* **Modifications in [schemas.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/schemas.py):**
  * Added `PharmacyBasicInfo`, `StockRequestDetailResponse`, and `AlertNotificationDetailResponse` schemas to capture nested relations.
* **Modifications in [crud.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/crud.py):**
  * Implemented `get_active_stock_requests` (eagerly loads request alerts).
  * Implemented `get_unread_alerts` (eagerly loads both the stock request and the requesting pharmacy profile).
* **Modifications in [api.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/routers/api.py):**
  * Registered `GET /broadcasts/active-requests` and `GET /broadcasts/alerts/unread`.
* **Modifications in [test_retrieval.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests/test_retrieval.py):**
  * Created a test suite confirming correct status filtering, nested relationship loadings, and tenant-to-tenant data isolation.

---

## 3. Active Verification Setup

### Python Backend Verification
All modules are verified locally using pytest. The tests are located under [routing_engine/tests/](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/tests).

To execute the tests locally:
1. Start your local PostGIS docker database container (`local_pharmacy_db` on port `5432`).
2. Run the tests inside the python virtual environment:
   ```bash
   # From Projects/Pharmalink root directory:
   PYTHONPATH=routing_engine routing_engine/venv/bin/pytest routing_engine/tests -v
   ```

To run the profile synchronization test suite:
```bash
PYTHONPATH=routing_engine routing_engine/venv/bin/pytest routing_engine/tests/test_auth.py -v
```

To run the dashboard retrieval test suite:
```bash
PYTHONPATH=routing_engine routing_engine/venv/bin/pytest routing_engine/tests/test_retrieval.py -v
```

### Flutter Frontend Verification
To verify the generated models and services compile cleanly without syntax or typing issues:
```bash
# From Projects/Pharmalink/flutter_app:
flutter analyze
```


