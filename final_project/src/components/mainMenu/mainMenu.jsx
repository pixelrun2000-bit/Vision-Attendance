// src/components/mainMenu/mainMenu.jsx
// ─── Role-Aware Sidebar ────────────────────────────────────────────────────────
// Admin   → sees all items
// Manager → sees Dashboard + People Management only
// ─────────────────────────────────────────────────────────────────────────────
import { Link, useLocation, useNavigate } from "react-router-dom";
import { getUser, getUserRole, ROLE_PERMISSIONS } from "../../utils/auth";

// ── All nav items (filtered per role) ─────────────────────────────────────────
const ALL_NAV = [
  {
    label: "Dashboard",
    path: "/",
    roles: ["admin", "manager"],
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <rect x="3" y="3" width="7" height="7" rx="1" strokeWidth="2" />
        <rect x="14" y="3" width="7" height="7" rx="1" strokeWidth="2" />
        <rect x="3" y="14" width="7" height="7" rx="1" strokeWidth="2" />
        <rect x="14" y="14" width="7" height="7" rx="1" strokeWidth="2" />
      </svg>
    ),
  },
  {
    label: "Room Management",
    path: "/rooms",
    roles: ["admin"],
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeWidth="2" d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
        <polyline strokeWidth="2" points="9 22 9 12 15 12 15 22" />
      </svg>
    ),
  },
  {
    label: "Attendance",
    path: "/attendance",
    roles: ["admin"],
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        <path strokeWidth="2" d="M9 12l2 2 4-4" />
      </svg>
    ),
  },
  {
    label: "People",
    path: "/add-person",
    roles: ["admin", "manager"],
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeWidth="2" d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2" />
        <circle cx="9" cy="7" r="4" strokeWidth="2" />
        <line x1="19" y1="8" x2="19" y2="14" strokeWidth="2" />
        <line x1="16" y1="11" x2="22" y2="11" strokeWidth="2" />
      </svg>
    ),
  },
  {
    label: "Settings",
    path: "/settings",
    roles: ["admin"],
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="3" strokeWidth="2" />
        <path strokeWidth="2" d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
      </svg>
    ),
  },
];

// Role badge colors
const ROLE_BADGE = {
  admin:   "bg-gray-900 text-white",
  manager: "bg-blue-600 text-white",
};

export default function MainMenu() {
  const location  = useLocation();
  const navigate  = useNavigate();
  const role      = getUserRole();
  const user      = getUser();

  // Filter nav items the current role can see
  const navItems = ALL_NAV.filter(item => item.roles.includes(role));

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    navigate("/login");
  };

  return (
    <aside className="relative bottom-0 top-0 w-52 flex flex-col shrink-0">
      <div className="fixed bottom-0 top-0 w-52 bg-white border-r border-gray-100 py-5 px-3 flex flex-col shadow-sm">

        {/* ── Logo ── */}
        <div className="px-3 mb-6">
          <span className="text-base font-bold text-gray-900 tracking-tight">
            Vision Attendance
          </span>
          <p className="text-xs text-gray-400 mt-0.5">Admin Panel</p>
        </div>

        {/* ── User card ── */}
        {user && (
          <div className="mb-6 mx-1 px-3 py-3 bg-gray-50 rounded-xl border border-gray-100">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-600 shrink-0">
                {(user.full_name_en || user.username || "?")[0].toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="text-xs font-semibold text-gray-800 truncate">
                  {user.full_name_en || user.username}
                </p>
                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full ${ROLE_BADGE[role] || "bg-gray-200 text-gray-600"}`}>
                  {role?.toUpperCase()}
                </span>
              </div>
            </div>
          </div>
        )}

        {/* ── Nav items ── */}
        <nav className="flex flex-col gap-1 flex-1">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.label}
                to={item.path}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150
                  ${isActive
                    ? "bg-gray-900 text-white shadow-sm"
                    : "text-gray-500 hover:bg-gray-50 hover:text-gray-700"
                  }`}
              >
                {item.icon}
                {item.label}
              </Link>
            );
          })}

          {/* Manager: show read-only indicator for locked pages */}
          {role === "manager" && (
            <div className="mt-4 mx-1 px-3 py-3 bg-blue-50 border border-blue-100 rounded-xl">
              <p className="text-xs font-semibold text-blue-700 mb-1">Manager Access</p>
              <p className="text-xs text-blue-500 leading-relaxed">
                You can view Dashboard and manage People. Rooms, Attendance records, and Settings are admin-only.
              </p>
            </div>
          )}
        </nav>

        {/* ── Logout ── */}
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-400 hover:bg-red-50 hover:text-red-500 transition-all mt-2 w-full"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          Sign Out
        </button>

      </div>
    </aside>
  );
}