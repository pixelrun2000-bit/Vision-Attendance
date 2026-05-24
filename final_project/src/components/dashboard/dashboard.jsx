// src/components/dashboard/dashboard.jsx
// ─── Real-time Admin Dashboard ───────────────────────────────────────────────
// • Fetches live stats from /api/dashboard/stats
// • Subscribes to Socket.IO "dashboard:update" + "attendance:update"
// • Auto-refreshes every 30 s
// • Charts: 7-day bar trend + presence pie + room bar
// • Live recent check-ins feed
// ─────────────────────────────────────────────────────────────────────────────
import { useState, useEffect, useCallback, useRef } from "react";
import { io } from "socket.io-client";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  PieChart, Pie, Cell, ResponsiveContainer, Legend,
} from "recharts";
import MainMenu from "../mainMenu/mainMenu";
import PricingPlans from "../subscriptions/PricingPlans";

const API_BASE = import.meta.env.VITE_API_URL || "";
const WS_URL   = import.meta.env.VITE_WS_URL  || window.location.origin;
const token    = () => localStorage.getItem("token") || "";

async function apiFetch(path) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token()}` },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

/* ─── static demo data (shown when API not available) ──────────────────────── */
const DEMO = {
  today: { date: new Date().toISOString().slice(0,10), total_checkins: 47, present: 38,
           late: 9, absent: 15, avg_confidence: 0.92, attendance_rate: 73 },
  users: { total: 85, total_employees: 60, total_students: 25, enrolled: 52, enrollment_rate: 61,
           by_role: [{ role:"employee", count:60 },{ role:"student", count:25 }] },
  pending_vacations: 4,
  week_trend: [
    { date:"Mon", present:35, late:5 }, { date:"Tue", present:40, late:3 },
    { date:"Wed", present:38, late:8 }, { date:"Thu", present:42, late:2 },
    { date:"Fri", present:47, late:9 }, { date:"Sat", present:20, late:1 },
    { date:"Sun", present:10, late:0 },
  ],
  room_stats: [
    { name:"Main Hall", room_code:"RM-001", checkins:22 },
    { name:"Training",  room_code:"RM-002", checkins:14 },
    { name:"Meeting",   room_code:"RM-003", checkins: 8 },
  ],
  recent_checkins: [],
  alerts: [],
};

const PIE_COLORS = ["#10b981", "#ef4444"];

/* ─── small components ────────────────────────────────────────────────────── */
function StatCard({ label, value, sub, icon, color = "text-gray-900" }) {
  return (
    <div className="bg-white border border-gray-200 rounded-xl px-5 py-5 shadow-sm flex items-start gap-4">
      <div className="w-10 h-10 rounded-xl bg-gray-50 border border-gray-100 flex items-center justify-center shrink-0">
        <i className={`fa-solid ${icon} text-gray-400`} />
      </div>
      <div className="min-w-0">
        <p className={`text-2xl font-bold ${color}`}>{value ?? "—"}</p>
        <p className="text-xs text-gray-500 mt-0.5">{label}</p>
        {sub && <p className="text-xs text-gray-400 mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}

function SectionTitle({ children, live }) {
  return (
    <div className="flex items-center gap-2 mb-4">
      <h2 className="text-sm font-bold text-gray-900">{children}</h2>
      {live && (
        <span className="flex items-center gap-1 text-xs text-emerald-600">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse inline-block" />
          Live
        </span>
      )}
    </div>
  );
}

const statusBg = s => ({
  present: "bg-emerald-50 text-emerald-700",
  late:    "bg-amber-50 text-amber-700",
  absent:  "bg-red-50 text-red-600",
}[s] || "bg-gray-50 text-gray-500");

/* ─── main ────────────────────────────────────────────────────────────────── */
export default function Dashboard() {
  const [stats,       setStats]       = useState(DEMO);
  const [loading,     setLoading]     = useState(true);
  const [wsConnected, setWsConnected] = useState(false);
  const [demoMode,    setDemoMode]    = useState(false);
  const [lastUpdate,  setLastUpdate]  = useState(null);
  const [liveToast,   setLiveToast]   = useState(null);   // { name, room, time }
  const [newIds,      setNewIds]      = useState(new Set());
  const prevCheckins = useRef([]);
  const socketRef = useRef(null);

  /* ── fetch stats ── */
  const fetchStats = useCallback(async () => {
    try {
      const data = await apiFetch("/api/dashboard/stats");
      if (data.success) {
        // Detect NEW check-ins since last fetch
        const prev  = prevCheckins.current.map(r => r.id);
        const fresh = (data.recent_checkins || []).filter(r => !prev.includes(r.id));
        if (fresh.length > 0) {
          const latest = fresh[0];
          setLiveToast({ name: latest.full_name_en, room: latest.room_name, time: latest.checkin_time });
          setNewIds(ids => new Set([...ids, ...fresh.map(r => r.id)]));
          setTimeout(() => setLiveToast(null), 5000);
        }
        prevCheckins.current = data.recent_checkins || [];
        setStats(data);
        setDemoMode(false);
        setLastUpdate(new Date());
      }
    } catch {
      setStats(DEMO);
      setDemoMode(true);
    } finally {
      setLoading(false);
    }
  }, []);

  /* ── socket.io + polling ── */
  useEffect(() => {
    fetchStats();
    const poll = setInterval(fetchStats, 30_000);

    const socket = io(WS_URL, { transports: ["websocket", "polling"] });
    socketRef.current = socket;
    socket.on("connect",          () => setWsConnected(true));
    socket.on("disconnect",       () => setWsConnected(false));
    socket.on("dashboard:update", () => fetchStats());
    socket.on("attendance:update",() => fetchStats());
    socket.on("rooms:update",     () => fetchStats());

    return () => { clearInterval(poll); socket.disconnect(); };
  }, [fetchStats]);

  /* ── chart data ── */
  const weekData = (stats.week_trend || []).map(d => ({
    ...d,
    date: d.date ? new Date(d.date).toLocaleDateString("en", { weekday: "short" }) : d.date,
  }));

  const pieData = [
    { name: "Present", value: stats.today?.present || 0 },
    { name: "Absent",  value: stats.today?.absent  || 0 },
  ];

  const roomData = (stats.room_stats || []).map(r => ({
    room: r.room_code || r.name,
    checkins: r.checkins,
  }));

  return (
    <>
      <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />

      {/* ── Live Check-in Toast ── */}
      {liveToast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-gray-900 text-white px-5 py-3.5 rounded-2xl shadow-2xl animate-bounce-once max-w-xs">
          <div className="w-8 h-8 rounded-full bg-emerald-500 flex items-center justify-center shrink-0">
            <i className="fa-solid fa-circle-check text-sm" />
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold truncate">{liveToast.name}</p>
            <p className="text-xs text-gray-300">
              Checked in · {liveToast.room || 'No room'} ·{" "}
              {new Date(liveToast.time).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})}
            </p>
          </div>
          <button onClick={() => setLiveToast(null)} className="ml-2 text-gray-400 hover:text-white shrink-0">
            <i className="fa-solid fa-xmark" />
          </button>
        </div>
      )}

      <div className="flex h-screen bg-gray-50 font-sans overflow-hidden">
        <MainMenu />

        <div className="flex-1 px-8 py-8 overflow-y-auto">

          {/* ── Header ── */}
          <div className="flex items-start justify-between mb-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-sm text-gray-400 mt-1">
                {lastUpdate
                  ? `Last updated: ${lastUpdate.toLocaleTimeString()}`
                  : "Loading live data…"}
              </p>
            </div>
            <div className="flex items-center gap-3">
              <span className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full border
                ${wsConnected ? "text-emerald-600 bg-emerald-50 border-emerald-200"
                              : "text-gray-400 bg-gray-50 border-gray-200"}`}>
                <span className={`w-1.5 h-1.5 rounded-full ${wsConnected ? "bg-emerald-500 animate-pulse" : "bg-gray-300"}`} />
                {wsConnected ? "Real-time connected" : "Connecting…"}
              </span>
              <button onClick={fetchStats}
                className="flex items-center gap-1.5 text-xs border border-gray-200 px-3 py-1.5 rounded-lg text-gray-500 hover:bg-gray-100 transition-colors">
                <i className="fa-solid fa-rotate-right" /> Refresh
              </button>
            </div>
          </div>

          {/* ── Demo banner ── */}
          {demoMode && (
            <div className="mb-6 flex items-start gap-3 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-sm">
              <i className="fa-solid fa-triangle-exclamation text-amber-500 mt-0.5" />
              <p className="text-amber-700">
                <strong>Demo Mode</strong> — Start the backend and{" "}
                <a href="/login" className="underline">sign in</a> to see real data.
              </p>
            </div>
          )}

          {/* ── Stat cards row 1 ── */}
          <div className="grid grid-cols-4 gap-4 mb-4">
            <StatCard label="Total People"  value={stats.users?.total}    icon="fa-users"          color="text-gray-900" />
            <StatCard label="Checked In"    value={stats.today?.present}  icon="fa-circle-check"   color="text-emerald-600"
              sub={`+${stats.today?.late || 0} late`} />
            <StatCard label="Absent Today"  value={stats.today?.absent}   icon="fa-circle-xmark"   color="text-red-500" />
            <StatCard label="Pending Leave" value={stats.pending_vacations} icon="fa-umbrella-beach" color="text-amber-600" />
          </div>

          {/* ── Stat cards row 2 ── */}
          <div className="grid grid-cols-4 gap-4 mb-6">
            <StatCard label="Employees"     value={stats.users?.total_employees} icon="fa-briefcase"     color="text-blue-600" />
            <StatCard label="Students"      value={stats.users?.total_students}  icon="fa-graduation-cap" color="text-violet-600" />
            <StatCard label="Face Enrolled" value={stats.users?.enrolled}        icon="fa-face-smile"    color="text-teal-600"
              sub={`${stats.users?.enrollment_rate || 0}% of users`} />
            <StatCard label="Attendance Rate" value={`${stats.today?.attendance_rate || 0}%`} icon="fa-chart-line" color="text-indigo-600" />
          </div>

          {/* ── Charts row ── */}
          <div className="grid grid-cols-3 gap-5 mb-6">

            {/* 7-day trend */}
            <div className="col-span-2 bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
              <SectionTitle>7-Day Attendance Trend</SectionTitle>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={weekData} barSize={20}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                  <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#9ca3af" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: "#9ca3af" }} axisLine={false} tickLine={false} />
                  <Tooltip
                    contentStyle={{ borderRadius: 10, border: "1px solid #e5e7eb", fontSize: 12 }}
                    cursor={{ fill: "#f9fafb" }}
                  />
                  <Bar dataKey="present" name="Present" fill="#10b981" radius={[4,4,0,0]} />
                  <Bar dataKey="late"    name="Late"    fill="#f59e0b" radius={[4,4,0,0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* presence pie */}
            <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
              <SectionTitle>Today's Overview</SectionTitle>
              <ResponsiveContainer width="100%" height={160}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={65}
                    dataKey="value" nameKey="name" paddingAngle={3}>
                    {pieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i]} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 10, fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-center gap-4 mt-1">
                {pieData.map((d, i) => (
                  <span key={d.name} className="flex items-center gap-1.5 text-xs text-gray-500">
                    <span className="w-2 h-2 rounded-full" style={{ background: PIE_COLORS[i] }} />
                    {d.name}: {d.value}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* ── Room stats + Recent check-ins ── */}
          <div className="grid grid-cols-3 gap-5">

            {/* Room checkins bar */}
            <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
              <SectionTitle>Check-ins by Room</SectionTitle>
              <ResponsiveContainer width="100%" height={180}>
                <BarChart data={roomData} layout="vertical" barSize={16}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" horizontal={false} />
                  <XAxis type="number" tick={{ fontSize: 11, fill: "#9ca3af" }} axisLine={false} tickLine={false} />
                  <YAxis type="category" dataKey="room" tick={{ fontSize: 11, fill: "#6b7280" }} axisLine={false} tickLine={false} width={55} />
                  <Tooltip contentStyle={{ borderRadius: 10, fontSize: 12 }} />
                  <Bar dataKey="checkins" name="Check-ins" fill="#6366f1" radius={[0,4,4,0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Live recent check-ins */}
            <div className="col-span-2 bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
                <SectionTitle live>Recent Check-ins</SectionTitle>
                <a href="/attendance" className="text-xs text-blue-500 hover:underline">View all</a>
              </div>
              <div className="overflow-y-auto max-h-64">
                {loading ? (
                  <div className="flex items-center justify-center py-10">
                    <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
                  </div>
                ) : (stats.recent_checkins?.length === 0) ? (
                  <div className="py-10 text-center text-sm text-gray-400">
                    <i className="fa-regular fa-clock text-2xl mb-2 block" />
                    No check-ins today yet
                  </div>
                ) : (
                  <ul className="divide-y divide-gray-50">
                    {(stats.recent_checkins || []).map(r => (
                      <li key={r.id} className={`flex items-center gap-3 px-5 py-3 transition-colors
                        ${newIds.has(r.id) ? "bg-emerald-50 border-l-2 border-emerald-400" : "hover:bg-gray-50"}`}>
                        {/* avatar */}
                        <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-500 shrink-0">
                          {(r.full_name_en || "?")[0].toUpperCase()}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-800 truncate">{r.full_name_en}</p>
                          <p className="text-xs text-gray-400">
                            {r.department || "—"} · {r.room_name || "No room"}
                          </p>
                        </div>
                        <div className="text-right shrink-0">
                          <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusBg(r.status)}`}>
                            {r.status}
                          </span>
                          <p className="text-xs text-gray-300 mt-0.5">
                            {new Date(r.checkin_time).toLocaleTimeString([], { hour:"2-digit", minute:"2-digit" })}
                          </p>
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </div>
          </div>

          {/* ── AI Alerts ── */}
          {(stats.alerts?.length > 0) && (
            <div className="mt-5 bg-white border border-red-100 rounded-xl p-5 shadow-sm">
              <SectionTitle>⚠ AI Security Alerts (Last 24h)</SectionTitle>
              <ul className="space-y-2">
                {stats.alerts.map(a => (
                  <li key={a.id} className="flex items-center gap-3 bg-red-50 border border-red-100 rounded-lg px-4 py-3">
                    <i className="fa-solid fa-shield-halved text-red-400" />
                    <div className="flex-1">
                      <p className="text-sm font-medium text-red-800">{a.full_name_en}</p>
                      <p className="text-xs text-red-500">
                        Fraud risk: {Math.round((a.ai_fraud_risk || 0) * 100)}% ·
                        Spoof: {a.ai_spoof_passed ? "passed" : "failed"} ·
                        {new Date(a.checkin_time).toLocaleTimeString()}
                      </p>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* ── Subscriptions Plans ── */}
          <div className="mt-8 border-t border-gray-200 pt-8">
            <PricingPlans title="Upgrade Your Experience" subtitle="Get access to more users, advanced analytics, and premium AI security features." />
          </div>

        </div>
      </div>
    </>
  );
}