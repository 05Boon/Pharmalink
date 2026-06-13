import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function SearchResults() {
  const navigate = useNavigate();

  const results = [
    { name: "City Pharmacy", distance: "1.2 km", stock: "50 units in stock", badge: "Closest", color: "#e1f5ee", textColor: "#085041" },
    { name: "HealthPlus Pharmacy", distance: "4.5 km", stock: "20 units", badge: "Available", color: "#f1efea", textColor: "#444441" },
    { name: "MediCare Store", distance: "8.1 km", stock: "100 units", badge: "Available", color: "#f1efea", textColor: "#444441" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={[{ label: "Search", path: "/search", active: true }]} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Search / <span className="text-[#0f6e56]">Results</span>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-1">Amoxicillin 500mg</h1>
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">3 pharmacies found within 10 km</div>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md h-[72px] flex items-center justify-center mb-2 relative overflow-hidden">
              <div
                className="absolute inset-0 opacity-60"
                style={{
                  backgroundImage:
                    "repeating-linear-gradient(#d3d1c7 0 0.5px, transparent 0.5px 12px), repeating-linear-gradient(90deg, #d3d1c7 0 0.5px, transparent 0.5px 12px)",
                }}
              />
              <div className="w-2.5 h-2.5 bg-[#1d9e75] rounded-full absolute top-9 left-14 border-2 border-[#085041]" />
              <div className="w-2 h-2 bg-[#e1f5ee] rounded-full absolute top-[22px] left-24 border-[1.5px] border-[#1d9e75]" />
              <div className="w-2 h-2 bg-[#e1f5ee] rounded-full absolute top-[46px] left-[138px] border-[1.5px] border-[#1d9e75]" />
              <div className="w-2 h-2 bg-[#e1f5ee] rounded-full absolute top-7 left-44 border-[1.5px] border-[#1d9e75]" />
            </div>

            {results.map((result, i) => (
              <button
                key={i}
                onClick={() => navigate("/search/response")}
                className="w-full flex items-center justify-between py-1.5 border-b border-[#e8e6df] text-left"
              >
                <div>
                  <div className="text-[11px] font-medium text-[#1a1a18]">{result.name}</div>
                  <div className="text-[10px] text-[#5f5e5a]">
                    {result.distance} · {result.stock}
                  </div>
                </div>
                <span
                  className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium"
                  style={{ background: result.color, color: result.textColor }}
                >
                  {result.badge}
                </span>
              </button>
            ))}

            <div className="text-[10px] text-[#888780] mt-2">Tap a result to send a request</div>
          </div>
        </div>
      </div>
    </div>
  );
}
