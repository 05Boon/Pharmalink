import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function ApproveOnboarding() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav
        links={[{ label: "Pharmacies", path: "/admin/pharmacies", active: true }]}
        isAdmin
      />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Pharmacies / <span className="text-[#0f6e56]">Review application</span>
            </div>

            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-1">Green Leaf Pharmacy</h1>
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">Application received 2 days ago</div>

            <div className="bg-[#f1efea] border border-[#d3d1c7] rounded-md p-2.5 mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Owner</span>
                <span className="text-[10px] text-[#1a1a18]">James Otieno</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Email</span>
                <span className="text-[10px] text-[#1a1a18]">j.otieno@greenleaf.com</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Location</span>
                <span className="text-[10px] text-[#1a1a18]">Nairobi, CBD</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">License no.</span>
                <span className="text-[10px] text-[#1a1a18]">PPB-2024-00421</span>
              </div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-[#5f5e5a]">Documents</span>
                <span className="text-[10px] text-[#0f6e56]">2 uploaded ↗</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-[#5f5e5a]">Status</span>
                <span className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium bg-[#faeeda] text-[#633806]">
                  Pending review
                </span>
              </div>
            </div>

            <div className="flex gap-1.5 mt-2">
              <button
                onClick={() => navigate("/admin/pharmacies")}
                className="flex-1 bg-[#1d9e75] border border-[#0f6e56] rounded-md py-1.5 text-[10px] font-medium text-[#04342c] text-center"
              >
                Approve
              </button>
              <button
                onClick={() => navigate("/admin/pharmacies")}
                className="flex-1 bg-[#fcebeb] border border-[#e24b4a] rounded-md py-1.5 text-[10px] font-medium text-[#791f1f] text-center"
              >
                Reject
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
