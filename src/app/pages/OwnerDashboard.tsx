import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function OwnerDashboard() {
  const navigate = useNavigate();

  const navLinks = [
    { label: "Dashboard", path: "/dashboard", active: true },
    { label: "Search", path: "/search" },
    { label: "Requests", path: "/requests" },
    { label: "History", path: "/history" },
    { label: "Logout", path: "/" },
  ];

  const recentRequests = [
    { drug: "Amoxicillin 500mg", from: "City Pharmacy", time: "2 min ago", status: "Pending", color: "#faeeda", textColor: "#633806" },
    { drug: "Metformin 1g", from: "HealthPlus", time: "1 hr ago", status: "Accepted", color: "#e1f5ee", textColor: "#085041" },
    { drug: "Ibuprofen 400mg", from: "MediCare", time: "3 hr ago", status: "Declined", color: "#fcebeb", textColor: "#791f1f" },
  ];

  const activeQueries = [
    { drug: "Ciprofloxacin 250mg", meta: "Searching nearby…", status: "Searching", color: "#faeeda", textColor: "#633806" },
    { drug: "Atenolol 50mg", meta: "Match found", status: "Matched", color: "#e1f5ee", textColor: "#085041" },
    { drug: "Paracetamol 500mg", meta: "No match found", status: "Unmatched", color: "#fcebeb", textColor: "#791f1f" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={navLinks} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">Dashboard</div>

            <div className="grid grid-cols-3 gap-1.5 mb-3">
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">3</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Active queries</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">12</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Requests received</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">8</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Completed</div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 mb-3">
              <div>
                <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">Recent requests</div>
                {recentRequests.map((req, i) => (
                  <div key={i} className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                    <div>
                      <div className="text-[11px] font-medium text-[#1a1a18]">{req.drug}</div>
                      <div className="text-[10px] text-[#5f5e5a]">{req.from} · {req.time}</div>
                    </div>
                    <span
                      className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium"
                      style={{ background: req.color, color: req.textColor }}
                    >
                      {req.status}
                    </span>
                  </div>
                ))}
              </div>

              <div>
                <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">My active queries</div>
                {activeQueries.map((query, i) => (
                  <div key={i} className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                    <div>
                      <div className="text-[11px] font-medium text-[#1a1a18]">{query.drug}</div>
                      <div className="text-[10px] text-[#5f5e5a]">{query.meta}</div>
                    </div>
                    <span
                      className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium"
                      style={{ background: query.color, color: query.textColor }}
                    >
                      {query.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            <button
              onClick={() => navigate("/search")}
              className="bg-[#1d9e75] rounded-md py-1.5 px-4 text-[11px] font-semibold text-[#04342c] max-w-[180px]"
            >
              + New drug query
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
