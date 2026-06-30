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
* **Modifications:** Refactored [.agents/skills/dart_translator/translate.py](.agents/skills/dart_translator/translate.py) to import the global `Dio` instance from `auth_interceptor.dart` and directly map from `response.data` to skip manual decoding steps.

### Milestone B: Data Validation (Schemas) & Database Access (CRUD)
* **Objective:** Scaffold data validation models and async CRUD operations for `stock_requests` and `alert_notifications`.
* **Modifications in [schemas.py](routing_engine/schemas.py):**
  * Added `StockRequestCreateInput` and `StockRequestResponse` validation schemas.
  * Added `AlertNotificationResponse` validation schemas.
* **Modifications in [crud.py](routing_engine/crud.py):**
  * Built `create_stock_request` to handle request creation.
  * Implemented eager relationship loading via `selectinload(StockRequest.alerts)` when calling `get_stock_request_with_alerts` to resolve associated alert notifications and prevent performance-degrading N+1 queries.
* **Verification:** Verified all Pydantic validations and database insert routines via [test_crud.py](routing_engine/tests/test_crud.py).

### Milestone C: WebSocket Manager & Auth Dependency Override
* **Objective:** Scaffold the main application entry point, manage WebSocket states per logged-in pharmacy, and construct a mock auth provider for local testing.
* **Modifications in [main.py](routing_engine/main.py):**
  * Created a thread-safe `ConnectionManager` that stores mapping of authenticated Supabase UUIDs (`pharmacy_id`) to their active `WebSocket` connections.
  * Implemented connection hooks (`connect`, `disconnect`) and targeted broadcast utilities to send live pings to specific pharmacies without race conditions.
* **Modifications in [dependencies.py](routing_engine/dependencies.py):**
  * Formulated the JWT decoding dependency `get_current_user`.
  * Integrated a local override where authorization headers with `mock-` prefixes skip Supabase network requests and return mock UUIDs instantly, facilitating offline testing.
* **Verification:** Tested client state tracking, ping-pong functionality, and invalid token rejections in [test_websockets.py](routing_engine/tests/test_websockets.py).

### Milestone D: REST API Routers & Geospatial Query Routing
* **Objective:** Expose endpoints for inventory management and requests broadcasting with tenancy verification and spatial query filtering.
* **Modifications in [api.py](routing_engine/routers/api.py):**
  * Registered `/inventory` router (GET, POST, PATCH) with ownership enforcement, checking that a pharmacy node can only update or query its own stock levels.
  * Registered `/broadcasts` router:
    * `POST /broadcasts/request` parses the incoming payload, extracts the requester's coordinates, executes a spatial query using PostGIS `ST_DWithin` to find neighbors within the specified search radius, records the transaction entries in the database, and immediately broadcasts real-time alert payloads to active WebSockets of neighboring pharmacies.
* **Verification:** Built [test_api.py](routing_engine/tests/test_api.py) using `httpx2.AsyncClient` with `ASGITransport` to run full integration tests over routers. Verified tenancy isolation (rejections with `403 Forbidden` on mismatched IDs), WebSocket messaging, and spatial discovery.

### Milestone E: Modernizing Datetime Defaults & Eliminating Deprecations
* **Objective:** Clean deprecated `datetime.datetime.utcnow` usages from tables, which trigger warnings on Python 3.12+.
* **Modifications in [models.py](routing_engine/models.py):**
  * Introduced a timezone-naive UTC helper function `utc_now()` returning a UTC date without offset:
    ```python
    def utc_now():
        return datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    ```
  * Swapped all defaults and `onupdate` directives referencing `datetime.datetime.utcnow` to use `utc_now`.
* **Modifications in [pytest.ini](routing_engine/pytest.ini):**
  * Deleted the `pytest.ini` configuration file since `DeprecationWarning` filters are no longer necessary.

### Milestone F: Workspace Cleanliness & Git Ignore Definitions
* **Objective:** Prevent temporary compilation artifacts, IDE caches, and secret files from being committed.
* **Modifications in [.gitignore](.gitignore):**
  * Created a consolidated, clean `.gitignore` to mask Python pycache directories (`__pycache__/`, `.pytest_cache/`), IDE state directories (`.vscode/`, `.idea/`, `.iml`), system artifacts (`.DS_Store`), and secrets (`.env`, `.env.*`).

### Milestone G: Frontend Code Generation & API Integration
* **Objective:** Bridge the FastAPI backend to the Flutter frontend by translating database schemas to Dart models/services and configuring authentication interceptors.
* **Modifications in [pubspec.yaml](flutter_app/pubspec.yaml):**
  * Added the `dio: ^5.5.0` dependency to support modern HTTP networking in the Flutter application.
* **Executed Python Generation Scripts:**
  * Executed `scaffold.py` to generate the JWT bearer token interceptor.
  * Executed `translate.py` against `StockRequest` and `InventoryItem` schemas.
* **Structured Generated Files:**
  * Created [auth_interceptor.dart](flutter_app/lib/core/network/auth_interceptor.dart) to globally configure `Dio` and attach Supabase Auth tokens to outgoing headers.
  * Created Dart schemas and mapping logics:
    * [alert_notification_model.dart](flutter_app/lib/models/alert_notification_model.dart)
    * [inventory_item_model.dart](flutter_app/lib/models/inventory_item_model.dart)
    * [stock_request_model.dart](flutter_app/lib/models/stock_request_model.dart)
  * Created service connectors targeting backend routes:
    * [inventory_item_service.dart](flutter_app/lib/services/inventory_item_service.dart) (maps GET, POST, PATCH on `/inventory`)
    * [stock_request_service.dart](flutter_app/lib/services/stock_request_service.dart) (maps POST on `/broadcasts/request`)

### Milestone H: Phase 2 Profile Synchronization Endpoint
* **Objective:** Implement the profile synchronization endpoint that receives validated profile data alongside Supabase JWTs, using the verified UUID as primary key to insert pharmacy profile records.
* **Modifications in [schemas.py](routing_engine/schemas.py):**
  * Added `PharmacyProfileSync` (payload schema) and `PharmacyNodeResponse` (response schema) validation layer.
* **Modifications in [crud.py](routing_engine/crud.py):**
  * Implemented database operations: `get_pharmacy_node`, `get_pharmacy_node_by_license`, `get_pharmacy_node_by_email`, and `create_pharmacy_node`.
* **Modifications in [auth.py](routing_engine/routers/auth.py):**
  * Created a dedicated REST router exposing `POST /api/pharmacies/sync-profile` with complete duplicate verification handling (validates unique license number and email, prevents double syncs).
* **Modifications in [main.py](routing_engine/main.py):**
  * Imported and registered `auth_router` in the application instance.
* **Modifications in [test_auth.py](routing_engine/tests/test_auth.py):**
  * Created unit and integration tests to verify successful creations, invalid credentials rejection, and duplicate conflict handling.

### Milestone I: Dashboard Retrieval Endpoints (Eager loading)
* **Objective:** Implement retrieval routes for the pharmacy dashboard to query active requests and unread alerts securely, avoiding N+1 loops.
* **Modifications in [schemas.py](routing_engine/schemas.py):**
  * Added `PharmacyBasicInfo`, `StockRequestDetailResponse`, and `AlertNotificationDetailResponse` schemas to capture nested relations.
* **Modifications in [crud.py](routing_engine/crud.py):**
  * Implemented `get_active_stock_requests` (eagerly loads request alerts).
  * Implemented `get_unread_alerts` (eagerly loads both the stock request and the requesting pharmacy profile).
* **Modifications in [api.py](routing_engine/routers/api.py):**
  * Registered `GET /broadcasts/active-requests` and `GET /broadcasts/alerts/unread`.
* **Modifications in [test_retrieval.py](routing_engine/tests/test_retrieval.py):**
  * Created a test suite confirming correct status filtering, nested relationship loadings, and tenant-to-tenant data isolation.

### Milestone J: Flutter Frontend Authentication & Dashboard Retrieval Service Integration
* **Objective:** Implement complete Flutter frontend authentication flows interacting with Supabase and FastAPI, and build the dashboard retrieval service methods.
* **Modifications in models:**
  * Created [pharmacy_basic_info.dart](flutter_app/lib/models/pharmacy_basic_info.dart) model.
  * Updated [stock_request_model.dart](flutter_app/lib/models/stock_request_model.dart) and [alert_notification_model.dart](flutter_app/lib/models/alert_notification_model.dart) with nested `pharmacy` and `request` structures.
* **Modifications in [main.dart](flutter_app/lib/main.dart):**
  * Added `Supabase.initialize` startup block with fallback settings.
* **Modifications in [auth_service.dart](flutter_app/lib/services/auth_service.dart):**
  * Migrated email/password registration to use Supabase Auth (Phase 1) followed by FastAPI profile synchronization (Phase 2), with automatic user deletion/sign-out rollback if Phase 2 fails.
* **Modifications in [stock_request_service.dart](flutter_app/lib/services/stock_request_service.dart):**
  * Added `fetchMyRequests()` and `fetchMyAlerts()` methods using the interceptor-configured global `dio` instance.

### Milestone K: Backend Containerization & Orchestration
* **Objective:** Containerize the FastAPI application using an optimized multi-stage build, configure the PostGIS database service with healthchecks, and link both services on a custom bridge network via Docker Compose.
* **Modifications in [Dockerfile](routing_engine/Dockerfile):**
  * Created a multi-stage Dockerfile utilizing a compiler builder stage (`python:3.14-slim`) to prepare python wheels and a lightweight runner stage to minimize the target container size.
* **Modifications in [docker-compose.yml](docker-compose.yml):**
  * Added `healthcheck` on the PostGIS database.
  * Added `web` service to build and run the FastAPI container.
  * Added container startup command `sh -c "python create_tables.py && uvicorn main:app ..."` to automatically initialize the PostGIS database tables before booting the server.
  * Defined a custom bridge network `pharmalink-network` for secure, isolated communication between containers.

### Milestone L: Admin Role-Based Access Control & Node Management
* **Objective:** Establish strict role-based access control (RBAC) for system administrators and enable administrators to manage pharmacy node lifecycle status.
* **Modifications in [dependencies.py](routing_engine/dependencies.py):**
  * Implemented `get_current_admin` dependency that extracts the authenticated user UUID from Supabase JWT and asserts its existence in the `SystemAdmin` database table.
* **Modifications in [schemas.py](routing_engine/schemas.py):**
  * Added `PharmacyStatusUpdate` Pydantic validation schema.
* **Modifications in [crud.py](routing_engine/crud.py):**
  * Implemented `update_pharmacy_status` to toggle node account status in database.
* **Modifications in [admin.py](routing_engine/routers/admin.py):**
  * Created a dedicated APIRouter mounting `PATCH /api/admin/pharmacies/{pharmacy_id}/status`.
  * Utilizes `func.ST_X` and `func.ST_Y` to eagerly parse and return longitude/latitude in a validated `PharmacyNodeResponse` after status modification.
* **Modifications in [main.py](routing_engine/main.py):**
  * Registered and mapped the new `admin_router` in the application instance.

### Milestone M: Geospatial Outbreak Detection Analytics
* **Objective:** Build a geospatial analytics engine to aggregate stock requests, allowing system administrators to detect potential medical outbreaks based on recent request spikes and geographic centroids.
* **Modifications in [schemas.py](routing_engine/schemas.py):**
  * Added `OutbreakAnalytic` response schema containing requested drug name, request frequency, and the calculated average latitude and longitude coordinates.
* **Modifications in [crud.py](routing_engine/crud.py):**
  * Implemented `get_outbreaks_analytics` query using PostGIS `ST_Collect` and `ST_Centroid` on the `PharmacyNode.location` column grouped by `StockRequest.requested_drug` over a parameterized timeframe.
* **Modifications in [admin.py](routing_engine/routers/admin.py):**
  * Mounted `GET /api/admin/analytics/outbreaks` in `admin_router` utilizing `get_current_admin` security dependency.
* **Modifications in [test_admin_analytics.py](routing_engine/tests/test_admin_analytics.py):**
  * Created integration test suite verifying timeframe filtering (e.g. 7 days vs 12 days), grouping, average centroid coordinate output, and role-based permissions (403 and 401 rejections).

### Milestone N: Flutter Admin Dashboard & Security Router Guards
* **Objective:** Develop the frontend Admin Portal in Flutter, translate the outbreak analytics payloads to Dart models, and secure admin routes with a GoRouter redirect guard.
* **Modifications in Backend [admin.py](file:///home/yusufsalyani/Projects/Pharmalink/routing_engine/routers/admin.py):**
  * Implemented `GET /api/admin/pharmacies` to support retrieving the list of registered nodes for the frontend table.
* **Modifications in [auth_service.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/services/auth_service.dart):**
  * Added `isAdmin` boolean getter checking Supabase JWT metadata and email attributes.
  * Extracted and saved the authenticated user's role on login.
* **Modifications in [app_router.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/routes/app_router.dart):**
  * Integrated a `redirect` handler checking if unauthenticated users try to access `/admin` (redirects to `/login`), or if authenticated non-admin users try to access it (redirects to `/dashboard`).
  * Linked the `/admin` path to the new `AdminDashboardScreen`.
* **Created [outbreak_analytic_model.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/models/outbreak_analytic_model.dart) & [pharmacy_node_model.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/models/pharmacy_node_model.dart):**
  * Translated and typed the outbreak cluster stats and pharmacy node response structures into Dart models.
* **Created [admin_service.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/services/admin_service.dart):**
  * Built REST integration services utilizing the global Dio instance to fetch pharmacies, toggle node status, and retrieve outbreak reports.
* **Created [admin_dashboard_screen.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/presentation/admin_dashboard_screen.dart):**
  * Created the UI featuring active metrics cards, outbreak location list with frequency count, and registered nodes control panel with interactive Switch toggles.
* **Created [admin_service_test.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/test/admin_service_test.dart):**
  * Wrote Dio-mocked unit tests validating parsing, coordinate mapping, and state-mutation triggers.

### Milestone O: Dual-View Outbreak Analytics Map Dashboard
* **Objective:** Build an interactive Dual-View geospatial outbreak analytics dashboard linking lists and visual map layers.
* **Created [outbreak_map.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/presentation/widgets/outbreak_map.dart):**
  * Built an interactive OpenStreetMap visual display using `flutter_map` showing markers/pins at each outbreak centroid.
  * Tapping a marker centers the map on that centroid and zooms in.
* **Created [outbreak_list.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/presentation/widgets/outbreak_list.dart):**
  * Created a details text list mapping drug name and request count, exposing an `onItemTapped` event callback.
* **Modifications in [admin_dashboard_screen.dart](file:///home/yusufsalyani/Projects/Pharmalink/flutter_app/lib/features/admin/presentation/admin_dashboard_screen.dart):**
  * Instantiated a `MapController` and linked the visual map widget above the text list.
  * Synchronized selections so that clicking an outbreak list item triggers the `MapController` to programmatically pan and zoom to the matching centroid coordinate.

### Milestone P: Database Safety Guards, Test Isolation & Automated Seeding Tool
* **Objective:** Secure credentials and separate the test suite execution database from live databases to prevent accidental metadata deletion, and build an automated seeder to ease local front-end testing.
* **Modifications in [settings.py](routing_engine/settings.py):**
  * Removed all hardcoded Supabase API keys and database fallbacks, migrating them to secure `.env` variables.
  * Added `TEST_DATABASE_URL` pointing tests to local PostgreSQL, and a fast-fail runtime guard preventing production runs without active environment variables.
* **Created [conftest.py](routing_engine/tests/conftest.py):**
  * Centralized pytest fixtures (`test_engine`, `db_session`, and FastAPI dependency overrides) to DRY up tests.
  * Added a session-level autouse safety check raising a `RuntimeError` if tests run against `supabase.co`/`supabase.com` domains or if `APP_ENV` is set to `production`.
* **Refactored Test Suite Files:**
  * Cleaned duplicate fixtures and unused imports from [test_admin_analytics.py](routing_engine/tests/test_admin_analytics.py), [test_admin_auth.py](routing_engine/tests/test_admin_auth.py), [test_api.py](routing_engine/tests/test_api.py), [test_auth.py](routing_engine/tests/test_auth.py), [test_crud.py](routing_engine/tests/test_crud.py), [test_retrieval.py](routing_engine/tests/test_retrieval.py), and [test_spatial.py](routing_engine/tests/test_spatial.py).
  * Swapped legacy `httpx2` imports for standard `httpx` across all test suites.
* **Created [seed_data.py](routing_engine/seed_data.py):**
  * Built an automated Python script utilizing the Supabase GoTrue Admin API to register 6 mock pharmacies and 1 administrator, verify emails, sync their profiles, populate 10 inventory items per node, and seed stock request outbreaks and notifications.

---

## 3. Active Verification Setup

### Python Backend Verification
All modules are verified locally using pytest. The tests are located under [routing_engine/tests/](routing_engine/tests).

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

To run the admin authentication and status toggle test suite:
```bash
PYTHONPATH=routing_engine routing_engine/venv/bin/pytest routing_engine/tests/test_admin_auth.py -v
```

To run the admin outbreak detection analytics test suite:
```bash
PYTHONPATH=routing_engine routing_engine/venv/bin/pytest routing_engine/tests/test_admin_analytics.py -v
```

### Database Seeding Tool
To register mock auth users and seed database profiles, stock inventory records, and outbreaks:
```bash
# From Projects/Pharmalink root directory:
PYTHONPATH=routing_engine routing_engine/venv/bin/python routing_engine/seed_data.py
```

### Backend Container Stack Verification
To build, start, and run the entire backend container stack:
```bash
# Build and boot both database and FastAPI app
sudo docker compose up --build -d

# Stream logs of the web service to verify table initialization and startup
sudo docker compose logs web -f
```

### Flutter Frontend Verification
To verify the generated models and services compile cleanly without syntax or typing issues:
```bash
# From Projects/Pharmalink/flutter_app:
flutter pub get
flutter analyze
```

