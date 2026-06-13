import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function AcceptShare() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={[{ label: "Requests", path: "/requests", active: true }]} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Requests / <span className="text-[#0f6e56]">Accepted</span>
            </div>

            <div className="bg-[#e1f5ee] border border-[#5dcaa5] rounded-md p-2 mb-2.5">
              <div className="text-[11px] font-semibold text-[#085041] mb-0.5">✓ Request accepted</div>
              <div className="text-[10px] text-[#0f6e56]">Details shared with City Pharmacy</div>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-2">Shared details</h1>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md p-2.5 mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Your pharmacy</span>
                <span className="text-[10px] text-[#1a1a18]">HealthPlus</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Address</span>
                <span className="text-[10px] text-[#1a1a18]">14 Market St</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Contact</span>
                <span className="text-[10px] text-[#1a1a18]">+254 700 000 000</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Drug ready</span>
                <span className="text-[10px] text-[#085041]">Yes</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-[#5f5e5a]">Transaction ref</span>
                <span className="text-[10px] text-[#1a1a18]">TXN-00421</span>
              </div>
            </div>

            <button
              onClick={() => navigate("/requests")}
              className="w-full bg-[#f1efea] border border-[#b4b2a9] rounded-md py-1.5 text-[11px] text-[#1a1a18] text-center"
            >
              Back to requests
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
