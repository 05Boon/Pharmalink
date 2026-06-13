import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function AdminDashboard() {
  const navigate = useNavigate();

  const navLinks = [
    { label: "Overview", path: "/admin", active: true },
    { label: "Pharmacies", path: "/admin/pharmacies" },
    { label: "Transactions", path: "/admin/transactions" },
    { label: "Reports", path: "/admin/reports" },
    { label: "Logs", path: "/admin/logs" },
    { label: "Logout", path: "/" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={navLinks} isAdmin />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden">
          <div className="p-3.5">
            <div className="grid grid-cols-4 gap-1.5 mb-3">
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">47</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Pharmacies</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">132</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Queries today</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">89</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Completed</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">5</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Pending approvals</div>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-3">
              <div>
                <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">Recent transactions</div>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <div>
                    <div className="text-[11px] font-medium text-[#1a1a18]">TXN-00421</div>
                    <div className="text-[10px] text-[#5f5e5a]">City → HealthPlus</div>
                  </div>
                  <span className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium bg-[#e1f5ee] text-[#085041]">
                    Done
                  </span>
                </div>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <div>
                    <div className="text-[11px] font-medium text-[#1a1a18]">TXN-00420</div>
                    <div className="text-[10px] text-[#5f5e5a]">MediCare → PharmCity</div>
                  </div>
                  <span className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium bg-[#faeeda] text-[#633806]">
                    Pending
                  </span>
                </div>
              </div>

              <div>
                <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">Pending approvals</div>
                <button
                  onClick={() => navigate("/admin/pharmacies/approve/1")}
                  className="w-full flex items-center justify-between py-1.5 border-b border-[#e8e6df] text-left"
                >
                  <div>
                    <div className="text-[11px] font-medium text-[#1a1a18]">Green Leaf</div>
                    <div className="text-[10px] text-[#5f5e5a]">Applied 2 days ago</div>
                  </div>
                  <span className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium bg-[#faeeda] text-[#633806]">
                    Review
                  </span>
                </button>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <div>
                    <div className="text-[11px] font-medium text-[#1a1a18]">SunCare Chemist</div>
                    <div className="text-[10px] text-[#5f5e5a]">Applied today</div>
                  </div>
                  <span className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium bg-[#faeeda] text-[#633806]">
                    Review
                  </span>
                </div>
              </div>

              <div>
                <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">System health</div>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <span className="text-[10px] text-[#5f5e5a]">Uptime</span>
                  <span className="text-[10px] text-[#085041]">99.8%</span>
                </div>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <span className="text-[10px] text-[#5f5e5a]">Avg response</span>
                  <span className="text-[10px] text-[#1a1a18]">4.2 min</span>
                </div>
                <div className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]">
                  <span className="text-[10px] text-[#5f5e5a]">Match rate</span>
                  <span className="text-[10px] text-[#085041]">89%</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
