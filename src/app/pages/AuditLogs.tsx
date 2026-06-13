import Nav from "../components/Nav";

export default function AuditLogs() {
  const logs = [
    { user: "j.otieno", action: "Login", time: "09:01" },
    { user: "admin01", action: "Approved pharmacy", time: "09:14" },
    { user: "city.pharm", action: "Submitted query", time: "09:22" },
    { user: "healthplus", action: "Accepted request", time: "09:24" },
    { user: "city.pharm", action: "Viewed response", time: "09:25" },
    { user: "city.pharm", action: "Logout", time: "10:05" },
  ];

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav
        links={[{ label: "Logs", path: "/admin/logs", active: true }]}
        isAdmin
      />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-3xl mx-auto">
          <div className="p-3.5">
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">
              Admin / <span className="text-[#0f6e56]">Audit logs</span>
            </div>

            <input
              type="text"
              placeholder="Search by user or action…"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-2.5"
            />

            <div className="grid grid-cols-[1fr_1.5fr_1fr] text-[10px] font-semibold text-[#5f5e5a] py-1 border-b border-[#d3d1c7] mb-1">
              <span>User</span>
              <span>Action</span>
              <span>Time</span>
            </div>

            {logs.map((log, i) => (
              <div
                key={i}
                className="grid grid-cols-[1fr_1.5fr_1fr] text-[10px] text-[#1a1a18] py-1.5 border-b border-[#e8e6df]"
              >
                <span>{log.user}</span>
                <span>{log.action}</span>
                <span>{log.time}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
