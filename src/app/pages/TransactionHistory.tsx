import { useState } from "react";
import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function TransactionHistory() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("All");

  const navLinks = [
    { label: "Dashboard", path: "/dashboard" },
    { label: "History", path: "/history", active: true },
  ];

  const transactions = [
    { ref: "TXN-00421", drug: "Amoxicillin", meta: "Sent to HealthPlus · Today 09:14", status: "Completed", color: "#e1f5ee", textColor: "#085041" },
    { ref: "TXN-00398", drug: "Metformin", meta: "Received from City · Yesterday", status: "Completed", color: "#e1f5ee", textColor: "#085041" },
    { ref: "TXN-00376", drug: "Ibuprofen", meta: "Sent to MediCare · 3 days ago", status: "Declined", color: "#fcebeb", textColor: "#791f1f" },
    { ref: "TXN-00351", drug: "Atenolol", meta: "Sent to PharmCity · 5 days ago", status: "Completed", color: "#e1f5ee", textColor: "#085041" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={navLinks} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-2xl mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">Transaction history</div>

            <div className="flex border-b border-[#d3d1c7] mb-2">
              {["All", "Sent", "Received"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`text-[10px] px-2.5 py-1 border-b-2 ${
                    activeTab === tab
                      ? "text-[#0f6e56] border-[#1d9e75] font-medium"
                      : "text-[#5f5e5a] border-transparent"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            {transactions.map((txn, i) => (
              <div
                key={i}
                className="flex items-center justify-between py-1.5 border-b border-[#e8e6df]"
              >
                <div>
                  <div className="text-[11px] font-medium text-[#1a1a18]">
                    {txn.ref} · {txn.drug}
                  </div>
                  <div className="text-[10px] text-[#5f5e5a]">{txn.meta}</div>
                </div>
                <span
                  className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium"
                  style={{ background: txn.color, color: txn.textColor }}
                >
                  {txn.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
