import { useState } from "react";
import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function DrugQuery() {
  const navigate = useNavigate();
  const [selectedRadius, setSelectedRadius] = useState(10);

  const navLinks = [
    { label: "Dashboard", path: "/dashboard" },
    { label: "Search", path: "/search", active: true },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={navLinks} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Dashboard / <span className="text-[#0f6e56]">New query</span>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-1">Drug query</h1>
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">Find nearby stock</div>

            <input
              type="text"
              placeholder="Drug name / generic name"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="text"
              placeholder="Quantity needed"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="text"
              placeholder="Dosage / form (optional)"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />

            <div className="mb-2">
              <div className="text-[10px] text-[#5f5e5a] mb-1">Search radius</div>
              <div className="flex gap-1">
                <button
                  onClick={() => setSelectedRadius(5)}
                  className={`flex-1 border rounded-md py-1.5 text-[10px] ${
                    selectedRadius === 5
                      ? "bg-[#e1f5ee] text-[#085041] border-[#5dcaa5]"
                      : "bg-[#f1efea] text-[#888780] border-[#d3d1c7]"
                  }`}
                >
                  5 km {selectedRadius === 5 && "✓"}
                </button>
                <button
                  onClick={() => setSelectedRadius(10)}
                  className={`flex-1 border rounded-md py-1.5 text-[10px] ${
                    selectedRadius === 10
                      ? "bg-[#e1f5ee] text-[#085041] border-[#5dcaa5]"
                      : "bg-[#f1efea] text-[#888780] border-[#d3d1c7]"
                  }`}
                >
                  10 km {selectedRadius === 10 && "✓"}
                </button>
                <button
                  onClick={() => setSelectedRadius(20)}
                  className={`flex-1 border rounded-md py-1.5 text-[10px] ${
                    selectedRadius === 20
                      ? "bg-[#e1f5ee] text-[#085041] border-[#5dcaa5]"
                      : "bg-[#f1efea] text-[#888780] border-[#d3d1c7]"
                  }`}
                >
                  20 km {selectedRadius === 20 && "✓"}
                </button>
              </div>
            </div>

            <input
              type="text"
              placeholder="Your location (auto-detected)"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />

            <button
              onClick={() => navigate("/search/results")}
              className="w-full bg-[#1d9e75] rounded-md py-1.5 text-[11px] font-semibold text-[#04342c] text-center mt-1"
            >
              Search now
            </button>

            <button
              onClick={() => navigate("/dashboard")}
              className="w-full bg-[#f1efea] border border-[#b4b2a9] rounded-md py-1.5 text-[11px] text-[#1a1a18] text-center mt-1.5"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
