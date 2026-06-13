import { createBrowserRouter } from "react-router";
import Register from "./pages/Register";
import Login from "./pages/Login";
import OwnerDashboard from "./pages/OwnerDashboard";
import DrugQuery from "./pages/DrugQuery";
import SearchResults from "./pages/SearchResults";
import ReceiveAlert from "./pages/ReceiveAlert";
import AcceptShare from "./pages/AcceptShare";
import ViewResponse from "./pages/ViewResponse";
import TransactionHistory from "./pages/TransactionHistory";
import AdminDashboard from "./pages/AdminDashboard";
import ManagePharmacies from "./pages/ManagePharmacies";
import ApproveOnboarding from "./pages/ApproveOnboarding";
import MonitorTransactions from "./pages/MonitorTransactions";
import Reports from "./pages/Reports";
import AuditLogs from "./pages/AuditLogs";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Login,
  },
  {
    path: "/register",
    Component: Register,
  },
  {
    path: "/login",
    Component: Login,
  },
  {
    path: "/dashboard",
    Component: OwnerDashboard,
  },
  {
    path: "/search",
    Component: DrugQuery,
  },
  {
    path: "/search/results",
    Component: SearchResults,
  },
  {
    path: "/requests",
    Component: ReceiveAlert,
  },
  {
    path: "/requests/accepted",
    Component: AcceptShare,
  },
  {
    path: "/search/response",
    Component: ViewResponse,
  },
  {
    path: "/history",
    Component: TransactionHistory,
  },
  {
    path: "/admin",
    Component: AdminDashboard,
  },
  {
    path: "/admin/pharmacies",
    Component: ManagePharmacies,
  },
  {
    path: "/admin/pharmacies/approve/:id",
    Component: ApproveOnboarding,
  },
  {
    path: "/admin/transactions",
    Component: MonitorTransactions,
  },
  {
    path: "/admin/reports",
    Component: Reports,
  },
  {
    path: "/admin/logs",
    Component: AuditLogs,
  },
]);
