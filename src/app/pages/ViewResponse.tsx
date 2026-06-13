import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function ViewResponse() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={[{ label: "Search", path: "/search", active: true }]} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Search / <span className="text-[#0f6e56]">Response received</span>
            </div>

            <div className="bg-[#e1f5ee] border border-[#5dcaa5] rounded-md p-2 mb-2.5">
              <div className="text-[11px] font-semibold text-[#085041] mb-0.5">Stock confirmed</div>
              <div className="text-[10px] text-[#0f6e56]">HealthPlus Pharmacy accepted your request</div>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-2">Pharmacy details</h1>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md p-2.5 mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Pharmacy</span>
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
                <span className="text-[10px] text-[#5f5e5a]">Drug</span>
                <span className="text-[10px] text-[#1a1a18]">Amoxicillin 500mg × 30</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-[#5f5e5a]">Distance</span>
                <span className="text-[10px] text-[#1a1a18]">4.5 km</span>
              </div>
            </div>

            <button
              onClick={() => navigate("/dashboard")}
              className="w-full bg-[#1d9e75] rounded-md py-1.5 text-[11px] font-semibold text-[#04342c] text-center"
            >
              View on map
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
