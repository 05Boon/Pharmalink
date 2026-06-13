import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function ReceiveAlert() {
  const navigate = useNavigate();

  const navLinks = [
    { label: "Dashboard", path: "/dashboard" },
    { label: "Requests", path: "/requests", active: true },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={navLinks} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Requests / <span className="text-[#0f6e56]">New alert</span>
            </div>

            <div className="bg-[#faeeda] border border-[#ef9f27] rounded-md p-2 mb-2">
              <div className="text-[11px] font-semibold text-[#633806] mb-0.5">New stock request</div>
              <div className="text-[10px] text-[#854f0b]">City Pharmacy requesting Amoxicillin 500mg</div>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-2">Review request</h1>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md p-2.5 mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Drug</span>
                <span className="text-[10px] text-[#1a1a18]">Amoxicillin 500mg</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Quantity needed</span>
                <span className="text-[10px] text-[#1a1a18]">30 units</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Requested by</span>
                <span className="text-[10px] text-[#1a1a18]">City Pharmacy</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Distance</span>
                <span className="text-[10px] text-[#1a1a18]">1.2 km</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-[#5f5e5a]">Your stock</span>
                <span className="text-[10px] text-[#085041]">50 units available</span>
              </div>
            </div>

            <div className="flex gap-1.5 mt-2">
              <button
                onClick={() => navigate("/requests/accepted")}
                className="flex-1 bg-[#1d9e75] border border-[#0f6e56] rounded-md py-1.5 text-[10px] font-medium text-[#04342c] text-center"
              >
                Accept
              </button>
              <button
                onClick={() => navigate("/dashboard")}
                className="flex-1 bg-[#fcebeb] border border-[#e24b4a] rounded-md py-1.5 text-[10px] font-medium text-[#791f1f] text-center"
              >
                Decline
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
