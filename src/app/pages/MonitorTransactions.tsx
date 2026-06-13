import Nav from "../components/Nav";

export default function MonitorTransactions() {
  const transactions = [
    { ref: "TXN-00421", drug: "Amoxicillin", status: "Done", date: "Today", color: "#e1f5ee", textColor: "#085041" },
    { ref: "TXN-00420", drug: "Metformin", status: "Pending", date: "Today", color: "#faeeda", textColor: "#633806" },
    { ref: "TXN-00398", drug: "Ibuprofen", status: "Declined", date: "Yesterday", color: "#fcebeb", textColor: "#791f1f" },
    { ref: "TXN-00376", drug: "Atenolol", status: "Done", date: "3 days ago", color: "#e1f5ee", textColor: "#085041" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav
        links={[{ label: "Transactions", path: "/admin/transactions", active: true }]}
        isAdmin
      />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-3xl mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2">
              Admin / <span className="text-[#0f6e56]">Transactions</span>
            </div>

            <div className="flex gap-1.5 mb-2">
              <input
                type="text"
                placeholder="Date range…"
                className="flex-1 bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780]"
              />
              <input
                type="text"
                placeholder="Status…"
                className="flex-1 bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780]"
              />
            </div>

            <div className="grid grid-cols-[1.2fr_1fr_1fr_1fr] text-[10px] font-semibold text-[#5f5e5a] py-1 border-b border-[#d3d1c7] mb-1">
              <span>Ref</span>
              <span>Drug</span>
              <span>Status</span>
              <span>Date</span>
            </div>

            {transactions.map((txn, i) => (
              <div
                key={i}
                className="grid grid-cols-[1.2fr_1fr_1fr_1fr] text-[10px] text-[#1a1a18] py-1.5 border-b border-[#e8e6df]"
              >
                <span>{txn.ref}</span>
                <span>{txn.drug}</span>
                <span>
                  <span
                    className="px-1.5 py-0.5 rounded-[10px] text-[10px] font-medium inline-block"
                    style={{ background: txn.color, color: txn.textColor }}
                  >
                    {txn.status}
                  </span>
                </span>
                <span>{txn.date}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
