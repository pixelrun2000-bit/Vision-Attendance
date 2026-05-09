// src/components/addPerson/addPerson.jsx
// ─── Add Person — Admin Page ───────────────────────────────────────────────
// • Loads ALL registered users from API (real data)
// • Shows who registered from mobile (has account) vs admin-added
// • Search, filter by role
// • Click a person → slide-in panel with full attendance history & stats
// • Admin can also create new users directly from here
// • Real-time: Socket.IO pushes "users:update" when a new user registers
// ──────────────────────────────────────────────────────────────────────────
import { useState, useEffect, useCallback, useRef } from "react";
import { io } from "socket.io-client";
import MainMenu from "../mainMenu/mainMenu";
import * as XLSX from "xlsx";
import PricingPlans from "../subscriptions/PricingPlans";

const API_BASE = import.meta.env.VITE_API_URL || "";
const WS_URL   = import.meta.env.VITE_WS_URL  || window.location.origin;
const token    = () => localStorage.getItem("token") || "";

async function apiFetch(path, opts = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json", ...opts.headers },
    ...opts,
  });
  if (res.status === 401) throw new Error("AUTH_REQUIRED");
  return res.json();
}

/* ─── helpers ─────────────────────────────────────────────────────────────── */
const roleBadge = (role) => {
  const map = {
    employee: "bg-blue-50 text-blue-600 border-blue-200",
    student:  "bg-violet-50 text-violet-600 border-violet-200",
    manager:  "bg-amber-50 text-amber-600 border-amber-200",
    admin:    "bg-red-50 text-red-600 border-red-200",
  };
  return `text-xs font-medium border px-2.5 py-0.5 rounded-full ${map[role?.toLowerCase()] || "bg-gray-50 text-gray-500 border-gray-200"}`;
};

const statusColor = (s) => ({
  present: "text-emerald-600 bg-emerald-50",
  late:    "text-amber-600 bg-amber-50",
  absent:  "text-red-500 bg-red-50",
}[s] || "text-gray-400 bg-gray-50");

function Avatar({ name, photo, size = 8 }) {
  const initials = (name || "?").split(" ").slice(0, 2).map(w => w[0]).join("").toUpperCase();
  const photoSrc = photo && photo.startsWith("/uploads") ? `${API_BASE}${photo}` : photo;
  return photoSrc
    ? <img src={photoSrc} alt={name} className={`w-${size} h-${size} rounded-full object-cover`} />
    : (
      <div className={`w-${size} h-${size} rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-500`}>
        {initials}
      </div>
    );
}

/* ─── Person Detail Slide-in Panel ─────────────────────────────────────────── */
function PersonDetailPanel({ person, onClose }) {
  const [detail,  setDetail]  = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    apiFetch(`/api/dashboard/person/${person.id}`)
      .then(data => { if (data.success) setDetail(data); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [person.id]);

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      {/* backdrop */}
      <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" onClick={onClose} />

      {/* panel */}
      <div className="relative bg-white w-full max-w-md h-full shadow-2xl flex flex-col overflow-hidden animate-slideIn">
        {/* header */}
        <div className="px-6 py-5 border-b border-gray-100 flex items-center gap-4">
          <Avatar name={person.full_name_en} photo={person.photo_url} size={12} />
          <div className="flex-1 min-w-0">
            <h2 className="text-sm font-bold text-gray-900 truncate">{person.full_name_en}</h2>
            <p className="text-xs text-gray-400 truncate">{person.email}</p>
            <div className="flex gap-2 mt-1.5">
              <span className={roleBadge(person.role)}>{person.role}</span>
              {person.is_face_enrolled
                ? <span className="text-xs text-emerald-600 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">Face enrolled ✓</span>
                : <span className="text-xs text-gray-400 bg-gray-50 border border-gray-200 px-2 py-0.5 rounded-full">No face data</span>
              }
            </div>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 transition-colors">
            <i className="fa-solid fa-xmark text-xl" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
            </div>
          ) : !detail ? (
            <div className="py-16 text-center text-sm text-gray-400">Could not load data</div>
          ) : (
            <>
              {/* info grid */}
              <div className="px-6 py-4 grid grid-cols-2 gap-3 border-b border-gray-100">
                {[
                  ["Department",  person.department || "—"],
                  ["Username",    `@${person.username}`],
                  ["Phone",       person.phone || "—"],
                  ["Employee ID", person.employee_id || "—"],
                  ["Registered",  new Date(person.created_at).toLocaleDateString()],
                  ["Source",      person.is_face_enrolled ? "Mobile App" : "Admin Added"],
                ].map(([k, v]) => (
                  <div key={k}>
                    <p className="text-xs text-gray-400">{k}</p>
                    <p className="text-sm font-medium text-gray-700 truncate">{v}</p>
                  </div>
                ))}
              </div>

              {/* stats */}
              <div className="px-6 py-4 border-b border-gray-100">
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
                  Attendance Summary — {detail.month}
                </p>
                <div className="grid grid-cols-4 gap-2">
                  {[
                    ["Total",   detail.summary.total_sessions, "text-gray-800"],
                    ["Present", detail.summary.present,        "text-emerald-600"],
                    ["Late",    detail.summary.late,            "text-amber-600"],
                    ["All-time",detail.summary.all_time_total, "text-blue-600"],
                  ].map(([l, v, c]) => (
                    <div key={l} className="bg-gray-50 rounded-xl p-3 text-center border border-gray-100">
                      <p className={`text-xl font-bold ${c}`}>{v ?? 0}</p>
                      <p className="text-xs text-gray-400 mt-0.5">{l}</p>
                    </div>
                  ))}
                </div>
                {detail.summary.avg_confidence > 0 && (
                  <div className="mt-3 flex items-center gap-2">
                    <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-500 rounded-full"
                        style={{ width: `${Math.round(detail.summary.avg_confidence * 100)}%` }}
                      />
                    </div>
                    <span className="text-xs text-gray-500 shrink-0">
                      {Math.round(detail.summary.avg_confidence * 100)}% AI confidence
                    </span>
                  </div>
                )}
              </div>

              {/* recent attendance */}
              <div className="px-6 py-4">
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
                  Recent Attendance
                </p>
                {detail.records.length === 0 ? (
                  <div className="py-8 text-center text-sm text-gray-400">
                    <i className="fa-solid fa-calendar-xmark text-2xl mb-2 block" />
                    No attendance records yet
                  </div>
                ) : (
                  <ul className="space-y-2">
                    {detail.records.map(r => (
                      <li key={r.id}
                        className="flex items-center gap-3 bg-gray-50 rounded-xl px-4 py-3 border border-gray-100">
                        <span className={`text-xs font-medium px-2 py-1 rounded-lg ${statusColor(r.status)}`}>
                          {r.status}
                        </span>
                        <div className="flex-1 min-w-0">
                          <p className="text-xs text-gray-700 font-medium">
                            {new Date(r.checkin_time).toLocaleDateString()}
                          </p>
                          <p className="text-xs text-gray-400">
                            {new Date(r.checkin_time).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                            {r.room_name ? ` · ${r.room_name}` : ""}
                          </p>
                        </div>
                        <span className="text-xs text-gray-300 shrink-0 capitalize">{r.method}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

/* ─── Add Person Form ─────────────────────────────────────────────────────── */
function AddPersonForm({ onAdded, onClose }) {
  const [form, setForm] = useState({
    full_name_en: "", username: "", email: "", phone: "", employee_id: "",
    department: "", role: "employee", password: "",
  });
  const [saving, setSaving] = useState(false);
  const [error,  setError]  = useState("");

  // ── auto-generate username from name + 4-digit suffix ──────────────────────
  const autoUsername = (name) =>
    name.toLowerCase().replace(/\s+/g, '.').replace(/[^a-z0-9.]/g, '') +
    '.' + Math.floor(1000 + Math.random() * 9000);

  const f = (k) => (e) => {
    setForm(p => ({ ...p, [k]: e.target.value }));
    if (k === 'full_name_en' && !p.username) {
      setForm(prev => ({ ...prev, [k]: e.target.value,
        username: autoUsername(e.target.value) }));
    }
  };

  const handleSave = async () => {
    if (!form.full_name_en || !form.email) {
      setError("Name and email are required.");
      return;
    }
    const username = form.username.trim() ||
      form.full_name_en.toLowerCase().replace(/\s+/g, '.') + '.' + Date.now().toString().slice(-4);
    const password = form.password.trim() || "changeme123";
    setSaving(true);
    setError("");
    try {
      const data = await apiFetch("/api/users", {
        method: "POST",
        body: JSON.stringify({
          full_name_en: form.full_name_en.trim(),
          full_name_ar: form.full_name_en.trim(),
          username,
          email:        form.email.trim(),
          phone:        form.phone.trim(),
          employee_id:  form.employee_id.trim(),
          department:   form.department,
          role:         form.role,
          password,
        }),
      });
      if (data.success) {
        onAdded(data.user);   // triggers fetchUsers() in parent
        onClose();
      } else {
        setError(data.message || "Failed to add person.");
      }
    } catch (err) {
      setError(err.message === "AUTH_REQUIRED"
        ? "You must be logged in as admin."
        : "Server error. Please try again.");
    } finally {
      setSaving(false);
    }
  };

  const inp = "w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors";

  return (
    <div className="bg-white border border-gray-200 rounded-xl p-6 mb-5 shadow-sm">
      <div className="flex items-center justify-between mb-5">
        <div>
          <h2 className="text-sm font-bold text-gray-900">Add New Person</h2>
          <p className="text-xs text-gray-400 mt-0.5">Create an account for a new employee or student</p>
        </div>
        <button onClick={onClose} className="text-gray-400 hover:text-gray-600 transition-colors">
          <i className="fa-solid fa-xmark" />
        </button>
      </div>

      {error && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
          {error}
        </div>
      )}

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Full Name *</label>
          <input className={inp} placeholder="John Doe"
            value={form.full_name_en}
            onChange={(e) => {
              const v = e.target.value;
              setForm(p => ({
                ...p,
                full_name_en: v,
                username: p.username ? p.username :
                  v.toLowerCase().replace(/\s+/g, '.').replace(/[^a-z0-9.]/g, '') + '.' + Date.now().toString().slice(-4),
              }));
            }} />
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Username *</label>
          <input className={inp} placeholder="auto-generated"
            value={form.username} onChange={f("username")} />
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Email *</label>
          <input className={inp} type="email" placeholder="john@company.com"
            value={form.email} onChange={f("email")} />
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Phone</label>
          <input className={inp} placeholder="+20 1234567890"
            value={form.phone} onChange={f("phone")} />
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Employee / Student ID</label>
          <input className={inp} placeholder="EMP-001" value={form.employee_id} onChange={f("employee_id")} />
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Department / Class *</label>
          <select className={inp} value={form.department} onChange={f("department")}>
            <option value="">Select department</option>
            {["Engineering","Marketing","Finance","Human Resources","Operations","Design","Sales","Class A","Class B"].map(d => (
              <option key={d} value={d}>{d}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-xs font-medium text-gray-600 mb-1 block">Role *</label>
          <select className={inp} value={form.role} onChange={f("role")}>
            <option value="employee">Employee</option>
            <option value="student">Student</option>
            <option value="manager">Manager</option>
            <option value="admin">Admin</option>
          </select>
        </div>
        <div className="col-span-2">
          <label className="text-xs font-medium text-gray-600 mb-1 block">Temporary Password *</label>
          <input className={inp} type="password" placeholder="Min. 6 characters" value={form.password} onChange={f("password")} />
        </div>
      </div>

      <div className="flex gap-3">
        <button onClick={handleSave} disabled={saving}
          className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors disabled:opacity-50">
          {saving ? <><i className="fa-solid fa-spinner animate-spin" /> Saving…</> : <><i className="fa-solid fa-user-plus" /> Add Person</>}
        </button>
        <button onClick={onClose} className="px-5 py-2.5 border border-gray-200 text-sm text-gray-500 rounded-lg hover:bg-gray-50 transition-colors">
          Cancel
        </button>
      </div>
    </div>
  );
}

/* ─── Main Component ──────────────────────────────────────────────────────── */
export default function AddPerson() {
  const [users,       setUsers]       = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [wsConnected, setWsConnected] = useState(false);
  const [search,      setSearch]      = useState("");
  const [roleFilter,  setRoleFilter]  = useState("all");
  const [showForm,    setShowForm]    = useState(false);
  const [selected,    setSelected]    = useState(null);   // person detail panel
  const [importing,   setImporting]   = useState(false);
  const socketRef = useRef(null);
  const fileInputRef = useRef(null);

  /* ── Bulk Import Excel ── */
  const handleImportExcel = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    setImporting(true);
    const reader = new FileReader();
    reader.onload = async (evt) => {
      try {
        const bstr = evt.target.result;
        const wb = XLSX.read(bstr, { type: "binary" });
        const wsname = wb.SheetNames[0];
        const ws = wb.Sheets[wsname];
        const data = XLSX.utils.sheet_to_json(ws);
        
        let successCount = 0;
        let failCount = 0;

        for (const row of data) {
          const name = row["Name"] || row["Full Name"] || row["full_name_en"] || "";
          const email = row["Email"] || row["email"] || "";
          const phone = row["Phone"] || row["phone"] || "";
          const dept = row["Department"] || row["department"] || "";
          const role = (row["Role"] || row["role"] || "employee").toLowerCase();
          const empId = row["Employee ID"] || row["employee_id"] || "";
          
          if (!name || !email) { failCount++; continue; }
          
          const username = name.toLowerCase().replace(/\s+/g, '.') + '.' + Date.now().toString().slice(-4) + Math.floor(Math.random() * 1000);
          
          const payload = {
            full_name_en: name.trim(),
            full_name_ar: name.trim(),
            username: username,
            email: email.trim(),
            phone: (phone+"").trim(),
            employee_id: (empId+"").trim(),
            department: dept,
            role: ["admin", "manager", "employee", "student"].includes(role) ? role : "employee",
            password: "changeme123"
          };
          
          try {
            const res = await apiFetch("/api/users", {
              method: "POST",
              body: JSON.stringify(payload),
            });
            if (res.success) successCount++;
            else failCount++;
          } catch(err) { failCount++; }
        }
        alert(`Import Complete!\nSuccessfully added: ${successCount}\nFailed: ${failCount}`);
        fetchUsers();
      } catch (error) {
        alert("Error reading Excel file. Please ensure it is a valid format.");
      } finally {
        setImporting(false);
        if (fileInputRef.current) fileInputRef.current.value = "";
      }
    };
    reader.readAsBinaryString(file);
  };

  /* ── fetch users ── */
  const fetchUsers = useCallback(async () => {
    try {
      const params = new URLSearchParams({ limit: 100 });
      if (roleFilter !== "all") params.set("role", roleFilter);
      if (search)               params.set("search", search);
      const data = await apiFetch(`/api/users?${params}`);
      if (data.success) setUsers(data.users);
    } catch { /* offline / no auth */ }
    finally { setLoading(false); }
  }, [roleFilter, search]);

  /* ── socket.io real-time ── */
  useEffect(() => {
    fetchUsers();

    const socket = io(WS_URL, { transports: ["websocket", "polling"] });
    socketRef.current = socket;
    socket.on("connect",        () => setWsConnected(true));
    socket.on("disconnect",     () => setWsConnected(false));
    // When a new user registers on mobile → backend emits "users:update"
    socket.on("users:update",   () => fetchUsers());
    // Any attendance change also refreshes the list (face enrolled status may change)
    socket.on("attendance:update", () => fetchUsers());

    return () => socket.disconnect();
  }, [fetchUsers]);

  /* ── filtered users ── */
  const filtered = users.filter(u => {
    const q = search.toLowerCase();
    return (
      (u.full_name_en || "").toLowerCase().includes(q) ||
      (u.email || "").toLowerCase().includes(q) ||
      (u.username || "").toLowerCase().includes(q) ||
      (u.department || "").toLowerCase().includes(q)
    );
  });

  /* ── stats ── */
  const total     = users.length;
  const enrolled  = users.filter(u => u.is_face_enrolled).length;
  const employees = users.filter(u => u.role === "employee").length;
  const students  = users.filter(u => u.role === "student").length;

  return (
    <>
      <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />

      <style>{`
        @keyframes slideIn {
          from { transform: translateX(100%); opacity: 0; }
          to   { transform: translateX(0);    opacity: 1; }
        }
        .animate-slideIn { animation: slideIn 0.25s ease-out; }
      `}</style>

      <div className="flex h-screen bg-gray-50 font-sans overflow-hidden">
        <MainMenu />

        <div className="flex-1 px-8 py-8 overflow-y-auto">

          {/* ── Header ── */}
          <div className="flex items-start justify-between mb-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">People Management</h1>
              <p className="text-sm text-gray-400 mt-1">
                Manage employees & students — see who registered from mobile vs admin-added
              </p>
            </div>
            <div className="flex items-center gap-3">
              {/* WS indicator */}
              <span className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full border
                ${wsConnected ? "text-emerald-600 bg-emerald-50 border-emerald-200"
                              : "text-gray-400 bg-gray-50 border-gray-200"}`}>
                <span className={`w-1.5 h-1.5 rounded-full ${wsConnected ? "bg-emerald-500 animate-pulse" : "bg-gray-300"}`} />
                {wsConnected ? "Real-time" : "Connecting…"}
              </span>

              <input type="file" accept=".xlsx, .xls, .csv" className="hidden" ref={fileInputRef} onChange={handleImportExcel} />
              <button onClick={() => fileInputRef.current?.click()} disabled={importing}
                className="flex items-center gap-2 bg-white border border-gray-200 text-gray-700 text-sm font-medium px-4 py-2.5 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50">
                {importing ? <i className="fa-solid fa-spinner animate-spin" /> : <i className="fa-solid fa-file-excel text-emerald-600" />} 
                {importing ? "Importing..." : "Import Excel"}
              </button>

              {!showForm && (
                <button onClick={() => setShowForm(true)}
                  className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-4 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
                  <i className="fa-solid fa-user-plus" /> Add Person
                </button>
              )}
            </div>
          </div>

          {/* ── Stats cards ── */}
          <div className="grid grid-cols-4 gap-4 mb-6">
            {[
              { label: "Total People",  value: total,     icon: "fa-users",           color: "text-gray-800" },
              { label: "Employees",     value: employees, icon: "fa-briefcase",       color: "text-blue-600" },
              { label: "Students",      value: students,  icon: "fa-graduation-cap",  color: "text-violet-600" },
              { label: "Face Enrolled", value: enrolled,  icon: "fa-face-smile",      color: "text-emerald-600" },
            ].map(c => (
              <div key={c.label} className="bg-white border border-gray-200 rounded-xl px-5 py-4 flex items-center gap-4 shadow-sm">
                <div className="w-10 h-10 rounded-xl bg-gray-50 flex items-center justify-center">
                  <i className={`fa-solid ${c.icon} text-gray-400`} />
                </div>
                <div>
                  <p className={`text-2xl font-bold ${c.color}`}>{c.value}</p>
                  <p className="text-xs text-gray-400">{c.label}</p>
                </div>
              </div>
            ))}
          </div>

          {/* ── Add Person Form ── */}
          {showForm && (
            <AddPersonForm
              onAdded={() => fetchUsers()}   /* always re-fetch from DB after add */
              onClose={() => setShowForm(false)}
            />
          )}

          {/* ── Filters ── */}
          <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
            <div className="flex items-center gap-4 px-6 py-4 border-b border-gray-100">
              {/* Search */}
              <div className="relative flex-1 max-w-sm">
                <i className="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-gray-300 text-xs" />
                <input
                  type="text"
                  placeholder="Search by name, email, department…"
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                  className="w-full pl-8 pr-3 py-2 text-sm border border-gray-200 rounded-lg bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                />
              </div>

              {/* Role filter */}
              <div className="flex gap-1.5">
                {["all", "employee", "student", "manager", "admin"].map(r => (
                  <button key={r}
                    onClick={() => setRoleFilter(r)}
                    className={`text-xs px-3 py-1.5 rounded-lg capitalize font-medium transition-colors
                      ${roleFilter === r
                        ? "bg-gray-900 text-white"
                        : "border border-gray-200 text-gray-500 hover:bg-gray-50"}`}>
                    {r === "all" ? "All" : r}
                  </button>
                ))}
              </div>

              <div className="ml-auto text-xs text-gray-400">
                {filtered.length} of {total} people
              </div>
            </div>

            {/* Table */}
            {loading ? (
              <div className="flex items-center justify-center py-16">
                <div className="w-7 h-7 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
              </div>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-100">
                    {["Person", "Department", "Role", "Face Status", "Registered", ""].map(h => (
                      <th key={h} className="text-left text-xs font-semibold text-gray-400 px-6 py-3">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {filtered.map(u => (
                    <tr key={u.id}
                      className="hover:bg-gray-50 transition-colors cursor-pointer"
                      onClick={() => setSelected(u)}>
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-3">
                          <Avatar name={u.full_name_en} photo={u.photo_url} size={9} />
                          <div>
                            <p className="text-sm font-medium text-gray-800">{u.full_name_en}</p>
                            <p className="text-xs text-gray-400">{u.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-500">{u.department || "—"}</td>
                      <td className="px-6 py-3">
                        <span className={roleBadge(u.role)}>{u.role}</span>
                      </td>
                      <td className="px-6 py-3">
                        {u.is_face_enrolled ? (
                          <span className="flex items-center gap-1.5 text-xs text-emerald-600">
                            <i className="fa-solid fa-circle-check" /> Enrolled
                          </span>
                        ) : (
                          <span className="flex items-center gap-1.5 text-xs text-gray-400">
                            <i className="fa-regular fa-circle" /> Not enrolled
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-3 text-xs text-gray-400">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-3">
                        <button className="text-xs text-blue-500 hover:text-blue-700 font-medium">
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))}
                  {filtered.length === 0 && (
                    <tr>
                      <td colSpan={6} className="py-16 text-center text-sm text-gray-400">
                        <i className="fa-solid fa-users text-3xl mb-3 block text-gray-200" />
                        No people found
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            )}
          </div>
          
          {/* ── Subscriptions Plans ── */}
          <div className="mt-8 border-t border-gray-200 pt-8 pb-12">
            <PricingPlans title="Upgrade Your Experience" subtitle="Get access to more users, advanced analytics, and premium AI security features." />
          </div>

        </div>
      </div>

      {/* Detail panel */}
      {selected && (
        <PersonDetailPanel person={selected} onClose={() => setSelected(null)} />
      )}
    </>
  );
}
