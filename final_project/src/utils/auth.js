// src/utils/auth.js
// ─── Auth helpers + Role-Based Access Control ─────────────────────────────────

export function getUser() {
  try {
    return JSON.parse(localStorage.getItem("user") || "null");
  } catch { return null; }
}

export function getToken() {
  return localStorage.getItem("token") || null;
}

export function isLoggedIn() {
  return !!getToken() && !!getUser();
}

export function getUserRole() {
  return getUser()?.role || null;
}

export function isAdmin() {
  return getUserRole() === "admin";
}

export function isManager() {
  return getUserRole() === "manager";
}

export function isAdminOrManager() {
  return ["admin", "manager"].includes(getUserRole());
}

// ── Route permission map ──────────────────────────────────────────────────────
// Defines what each role can access
export const ROLE_PERMISSIONS = {
  admin: {
    routes:  ["/", "/rooms", "/attendance", "/add-person", "/settings"],
    label:   "Admin",
    color:   "bg-red-100 text-red-700",
  },
  manager: {
    routes:  ["/", "/add-person"],
    label:   "Manager",
    color:   "bg-blue-100 text-blue-700",
  },
};

export function canAccess(path) {
  const role = getUserRole();
  if (!role) return false;
  const perms = ROLE_PERMISSIONS[role];
  if (!perms) return false;
  return perms.routes.some(r => path === r || path.startsWith(r + "/"));
}
