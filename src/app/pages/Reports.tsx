import Nav from "../components/Nav";

export default function Reports() {
  const topDrugs = [
    { name: "Amoxicillin 500mg", count: "42 queries" },
    { name: "Metformin 1g", count: "31 queries" },
    { name: "Ibuprofen 400mg", count: "28 queries" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav
        links={[{ label: "Reports", path: "/admin/reports", active: true }]}
        isAdmin
      />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-2xl mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">
              Admin / <span className="text-[#0f6e56]">Reports</span>
            </div>

            <div className="flex gap-1.5 mb-2.5">
              <input
                type="text"
                placeholder="Date range"
                className="flex-1 bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780]"
              />
              <button className="bg-[#1d9e75] rounded-md px-3 py-1.5 text-[11px] font-semibold text-[#04342c]">
                Generate
              </button>
            </div>

            <div className="grid grid-cols-2 gap-1.5 mb-2">
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">89%</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Match rate</div>
              </div>
              <div className="bg-[#f1efea] rounded-md p-2 text-center">
                <div className="text-base font-semibold text-[#1a1a18]">4.2 min</div>
                <div className="text-[10px] text-[#5f5e5a] mt-0.5">Avg response</div>
              </div>
            </div>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md p-2.5 mb-2">
              <div className="text-[11px] font-medium text-[#1a1a18] mb-1.5">Top requested drugs</div>
              {topDrugs.map((drug, i) => (
                <div key={i} className="flex items-center justify-between py-1.5 border-b border-[#e8e6df] last:border-0">
                  <span className="text-[11px] font-medium text-[#1a1a18]">{drug.name}</span>
                  <span className="text-[10px] text-[#1a1a18]">{drug.count}</span>
                </div>
              ))}
            </div>

            <button className="w-full bg-[#f1efea] border border-[#b4b2a9] rounded-md py-1.5 text-[11px] text-[#1a1a18] text-center">
              Export as PDF
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
