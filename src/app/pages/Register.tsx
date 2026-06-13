import { useNavigate } from "react-router";
import Nav from "../components/Nav";

export default function Register() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#f5f5f2]">
      <Nav links={[{ label: "Login", path: "/login" }]} />
      <div className="p-3.5">
        <div className="bg-white border border-[#b4b2a9] rounded-[10px] overflow-hidden max-w-md mx-auto">
          <div className="p-3.5">
            <h1 className="text-[13px] font-semibold text-[#1a1a18] mb-1">Create account</h1>
            <div className="text-[10px] text-[#5f5e5a] mb-2.5">Register your pharmacy</div>

            <input
              type="text"
              placeholder="Full name"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="email"
              placeholder="Email address"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="password"
              placeholder="Password"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="text"
              placeholder="Pharmacy name"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />
            <input
              type="text"
              placeholder="Location / address"
              className="w-full bg-[#f1efea] border border-[#d3d1c7] rounded-md px-2 py-1.5 text-[10px] text-[#888780] mb-1.5"
            />

            <button
              onClick={() => navigate("/dashboard")}
              className="w-full bg-[#1d9e75] rounded-md py-1.5 text-[11px] font-semibold text-[#04342c] text-center mt-1"
            >
              Register
            </button>

            <button
              onClick={() => navigate("/login")}
              className="text-[10px] text-[#0f6e56] text-center block w-full mt-2"
            >
              Already registered? Login
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
