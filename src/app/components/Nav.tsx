import { useNavigate } from "react-router";

interface NavProps {
  brand?: string;
  links?: Array<{ label: string; path: string; active?: boolean }>;
  isAdmin?: boolean;
}

export default function Nav({ brand = "PharmPool", links = [], isAdmin = false }: NavProps) {
  const navigate = useNavigate();

  return (
    <div className="bg-[#f1efea] border-b border-[#d3d1c7] px-3 py-1.5 flex items-center justify-between">
      <span className="text-[11px] font-semibold text-[#1a1a18]">
        {isAdmin ? "PharmPool Admin" : brand}
      </span>
      <div className="flex gap-2.5">
        {links.map((link, i) => (
          <button
            key={i}
            onClick={() => navigate(link.path)}
            className={`text-[10px] ${
              link.active
                ? "text-[#0f6e56] font-medium"
                : "text-[#5f5e5a]"
            }`}
          >
            {link.label}
          </button>
        ))}
      </div>
    </div>
  );
}
