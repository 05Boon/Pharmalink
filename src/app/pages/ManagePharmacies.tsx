import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function ManagePharmacies() {
  const navigate = useNavigate();

  const pharmacies = [
    { name: "City Pharmacy", status: "Active", color: "#e1f5ee", textColor: "#085041", action: "Edit" },
    { name: "Green Leaf", status: "Pending", color: "#faeeda", textColor: "#633806", action: "Approve", id: "1" },
    { name: "SunCare Chemist", status: "Pending", color: "#faeeda", textColor: "#633806", action: "Approve", id: "2" },
    { name: "HealthPlus", status: "Active", color: "#e1f5ee", textColor: "#085041", action: "Edit" },
    { name: "MediCare", status: "Active", color: "#e1f5ee", textColor: "#085041", action: "Edit" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav
        links={[{ label: "Pharmacies", path: "/admin/pharmacies", active: true }]}
        isAdmin
      />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-3xl mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">
              Admin / <span className="text-[#0f6e56]">Pharmacies</span>
            </div>

            <div className="flex gap-1.5 mb-2.5 items-center">
              <input
                type="text"
                placeholder="Search pharmacies…"
                className="flex-1 bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780]"
              />
              <button className="bg-[#1d9e75] rounded-md px-3 py-1.5 text-[11px] font-semibold text-[#04342c] whitespace-nowrap">
                + Register
              </button>
            </div>

            <div className="grid grid-cols-[2fr_1fr_1fr] text-[10px] font-semibold text-[#5f5e5a] py-1 border-b border-[#d3d1c7] mb-1">
              <span>Pharmacy</span>
              <span>Status</span>
              <span>Action</span>
            </div>

            {pharmacies.map((pharmacy, i) => (
              <div
                key={i}
                className="grid grid-cols-[2fr_1fr_1fr] text-[10px] text-[#1a1a18] py-1.5 border-b border-[#e8e6df]"
              >
                <span>{pharmacy.name}</span>
                <span>
                  <span
                    className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium inline-block"
                    style={{ background: pharmacy.color, color: pharmacy.textColor }}
                  >
                    {pharmacy.status}
                  </span>
                </span>
                <button
                  onClick={() =>
                    pharmacy.id
                      ? navigate(`/admin/pharmacies/approve/${pharmacy.id}`)
                      : undefined
                  }
                  className="text-[#0f6e56] text-left"
                >
                  {pharmacy.action}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
