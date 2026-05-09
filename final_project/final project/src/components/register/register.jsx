// src/components/register/register.jsx
// ─── Web Admin Registration Page ──────────────────────────────────────────────
// • Calls POST /api/auth/register to create an admin account
// • Email + Email Confirm validation
// • Password + Confirm Password validation
// • Real-time error display
// • On success → saves token → redirects to dashboard
// ─────────────────────────────────────────────────────────────────────────────
import { useState, useEffect } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";

const API_BASE = import.meta.env.VITE_API_URL || "";

const INP =
  "w-full mt-1 border border-gray-200 rounded-lg px-3 py-2.5 text-sm bg-gray-50 focus:outline-none focus:border-gray-500 focus:bg-white transition-colors";

function Field({ label, id, type = "text", placeholder, value, onChange, error, hint }) {
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-gray-700 mb-0.5">
        {label}
      </label>
      <input
        id={id}
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        autoComplete="off"
        className={`${INP} ${error ? "border-red-400 bg-red-50" : ""}`}
      />
      {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
      {hint && !error && <p className="text-xs text-gray-400 mt-1">{hint}</p>}
    </div>
  );
}

const ORG_TYPES = ["Company", "University", "School", "Government"];

export default function Register() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [form, setForm] = useState({
    fullName: "",
    username: "",
    email: "",
    emailConfirm: "",
    gender: "",
    phone: "",
    orgType: "Company",
    orgSubType: "",
    orgName: "",
    plan: searchParams.get("plan") || "Free",
    accountRole: "",       // "admin" | "manager"
    password: "",
    passwordConfirm: "",
  });

  const COMPANY_SUB_TYPES = ["Startup", "Government", "Private", "Public"];
  const UNI_SUB_TYPES = ["Private", "Public", "National"];

  const [errors,  setErrors]  = useState({});
  const [loading, setLoading] = useState(false);
  const [serverErr, setServerErr] = useState("");

  const f = (key) => (e) => {
    setForm((p) => ({ ...p, [key]: e.target.value }));
    setErrors((p) => ({ ...p, [key]: "" }));
    setServerErr("");
  };

  // ── validation ──────────────────────────────────────────────────────────────
  const validate = () => {
    const errs = {};
    if (!form.fullName.trim())     errs.fullName = "Full name is required";
    if (!form.username.trim())     errs.username = "Username is required";
    if (!form.email.trim())        errs.email = "Email is required";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email))
                                   errs.email = "Invalid email format";
    if (!form.emailConfirm.trim()) errs.emailConfirm = "Please confirm your email";
    else if (form.email !== form.emailConfirm)
                                   errs.emailConfirm = "Emails do not match";
    if (!form.accountRole)         errs.accountRole = "Please select a role (Admin or Manager)";
    if (!form.password)            errs.password = "Password is required";
    else if (form.password.length < 8)
                                   errs.password = "Minimum 8 characters";
    if (!form.passwordConfirm)     errs.passwordConfirm = "Please confirm your password";
    else if (form.password !== form.passwordConfirm)
                                   errs.passwordConfirm = "Passwords do not match";
    
    if (form.orgType === "Company" || form.orgType === "University") {
      if (!form.orgSubType) errs.orgSubType = `Please select a ${form.orgType} type`;
      if (!form.orgName.trim()) errs.orgName = `Please enter the ${form.orgType} name`;
    }
    
    if (!form.plan) errs.plan = "Please select a subscription plan";
    return errs;
  };

  // ── submit ──────────────────────────────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    const errs = validate();
    if (Object.keys(errs).length) { setErrors(errs); return; }

    setLoading(true);
    setServerErr("");
    try {
      const res = await fetch(`${API_BASE}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          full_name_en: form.fullName.trim(),
          full_name_ar: form.fullName.trim(),
          username:     form.username.trim(),
          email:        form.email.trim(),
          phone:        form.phone.trim(),
          password:     form.password,
          gender:       form.gender || "male",
          role:         form.accountRole,   // "admin" | "manager"
          department:   `${form.orgType} - ${form.orgSubType || ""} - ${form.orgName || ""}`,
          plan:         form.plan,
        }),
      });

      const data = await res.json();

      if (!res.ok || !data.success) {
        setServerErr(data.message || "Registration failed. Please try again.");
        return;
      }

      // ── Save session ───────────────────────────────────────────────────────
      localStorage.setItem("token", data.token);
      localStorage.setItem("user",  JSON.stringify(data.user));
      navigate("/");
    } catch {
      setServerErr("Cannot reach the server. Make sure the backend is running on port 3001.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#E9F0FF] px-4 py-10">
      <div className="bg-white w-full max-w-2xl px-8 py-8 rounded-2xl shadow-md">

        {/* Header */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-12 h-12 bg-black rounded-xl mb-3">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900">Create Admin Account</h2>
          <p className="text-gray-500 text-sm mt-1">Register as an administrator for your organization</p>
        </div>

        {/* Server error */}
        {serverErr && (
          <div className="mb-5 flex items-start gap-2 px-4 py-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-600">
            <svg className="w-4 h-4 mt-0.5 shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
            {serverErr}
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate>

          {/* Row 1 — Name + Username */}
          <div className="grid grid-cols-2 gap-4 mb-4">
            <Field label="Full Name *" id="fullName" placeholder="John Doe"
              value={form.fullName} onChange={f("fullName")} error={errors.fullName} />
            <Field label="Username *" id="username" placeholder="johndoe"
              value={form.username} onChange={f("username")} error={errors.username} />
          </div>

          {/* Row 2 — Email + Confirm Email */}
          <div className="grid grid-cols-2 gap-4 mb-4">
            <Field label="Email Address *" id="email" type="email"
              placeholder="john@company.com"
              value={form.email} onChange={f("email")} error={errors.email} />
            <Field label="Confirm Email *" id="emailConfirm" type="email"
              placeholder="Re-enter your email"
              value={form.emailConfirm} onChange={f("emailConfirm")} error={errors.emailConfirm} />
          </div>

          {/* Row 3 — Gender + Phone */}
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-0.5">Gender</label>
              <select value={form.gender} onChange={f("gender")} className={INP}>
                <option value="">Select gender</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
            </div>
            <Field label="Phone Number" id="phone" placeholder="+20 1234567890"
              value={form.phone} onChange={f("phone")} />
          </div>

          {/* Role Selection */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Account Role *
            </label>
            <div className="grid grid-cols-2 gap-3">
              {[
                {
                  value: "admin",
                  label: "Admin",
                  icon: "🛡️",
                  desc: "Full access — manage rooms, users, attendance, settings, and all reports",
                  color: form.accountRole === "admin"
                    ? "border-gray-900 bg-gray-900 text-white"
                    : "border-gray-200 text-gray-600 hover:border-gray-400 bg-white",
                },
                {
                  value: "manager",
                  label: "Manager",
                  icon: "👔",
                  desc: "Limited access — view dashboard, view/add employees, and manage own check-in only",
                  color: form.accountRole === "manager"
                    ? "border-blue-600 bg-blue-600 text-white"
                    : "border-gray-200 text-gray-600 hover:border-blue-400 bg-white",
                },
              ].map((r) => (
                <button
                  type="button"
                  key={r.value}
                  onClick={() => { setForm((p) => ({ ...p, accountRole: r.value })); setErrors((p) => ({ ...p, accountRole: "" })); }}
                  className={`text-left p-4 rounded-xl border-2 transition-all ${r.color}`}
                >
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-lg">{r.icon}</span>
                    <span className="font-semibold text-sm">{r.label}</span>
                  </div>
                  <p className={`text-xs leading-relaxed ${form.accountRole === r.value ? "opacity-80" : "text-gray-400"}`}>
                    {r.desc}
                  </p>
                </button>
              ))}
            </div>
            {errors.accountRole && (
              <p className="text-xs text-red-500 mt-1">{errors.accountRole}</p>
            )}
          </div>

          {/* Organization Type */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Organization Type
            </label>
            <div className="grid grid-cols-4 gap-2 mb-4">
              {ORG_TYPES.map((opt) => (
                <button type="button" key={opt}
                  onClick={() => {
                    setForm((p) => ({ ...p, orgType: opt, orgSubType: "", orgName: "" }));
                    setErrors((p) => ({ ...p, orgSubType: "", orgName: "" }));
                  }}
                  className={`py-2.5 text-sm rounded-lg border font-medium transition-colors
                    ${form.orgType === opt
                      ? "bg-gray-900 text-white border-gray-900"
                      : "bg-white text-gray-600 border-gray-200 hover:bg-gray-50"}`}>
                  {opt}
                </button>
              ))}
            </div>
            
            {form.orgType === "Company" && (
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-0.5">Company Type</label>
                  <select value={form.orgSubType} onChange={f("orgSubType")} className={INP}>
                    <option value="">Select type</option>
                    {COMPANY_SUB_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                  {errors.orgSubType && <p className="text-xs text-red-500 mt-1">{errors.orgSubType}</p>}
                </div>
                <Field label="Company Name *" id="orgName" placeholder="e.g. Acme Corp"
                  value={form.orgName} onChange={f("orgName")} error={errors.orgName} />
              </div>
            )}

            {form.orgType === "University" && (
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-0.5">University Type</label>
                  <select value={form.orgSubType} onChange={f("orgSubType")} className={INP}>
                    <option value="">Select type</option>
                    {UNI_SUB_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                  {errors.orgSubType && <p className="text-xs text-red-500 mt-1">{errors.orgSubType}</p>}
                </div>
                <Field label="University Name *" id="orgName" placeholder="e.g. Cairo University"
                  value={form.orgName} onChange={f("orgName")} error={errors.orgName} />
              </div>
            )}
          </div>

          {/* Subscription Plans */}
          <div className="mb-6">
            <div className="flex justify-between items-end mb-2">
              <label className="block text-sm font-medium text-gray-700">
                Subscription Plan *
              </label>
              <Link to="/subscriptions" target="_blank" className="text-xs font-semibold text-blue-600 hover:underline">
                View Plan Details
              </Link>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {[
                { name: "Free", desc: "Basic tracking & dashboard", price: "$0" },
                { name: "Basic", desc: "Up to 50 users, reporting", price: "$2-3/mo" },
                { name: "Standard", desc: "Up to 200 users, analytics", price: "$4-6/mo" },
                { name: "Premium", desc: "Unlimited users, advanced AI", price: "$7-12/mo" }
              ].map(plan => (
                <button
                  type="button"
                  key={plan.name}
                  onClick={() => { setForm((p) => ({ ...p, plan: plan.name })); setErrors((p) => ({ ...p, plan: "" })); }}
                  className={`text-left p-3 rounded-xl border-2 transition-all ${
                    form.plan === plan.name
                      ? "border-blue-600 bg-blue-50"
                      : "border-gray-200 hover:border-blue-300 bg-white"
                  }`}
                >
                  <div className="flex justify-between items-center mb-1">
                    <span className={`font-bold ${form.plan === plan.name ? "text-blue-700" : "text-gray-900"}`}>{plan.name}</span>
                    <span className="text-xs font-semibold text-gray-500">{plan.price}</span>
                  </div>
                  <p className="text-xs text-gray-500">{plan.desc}</p>
                </button>
              ))}
            </div>
            {errors.plan && <p className="text-xs text-red-500 mt-1">{errors.plan}</p>}
          </div>

          {/* Row 4 — Password + Confirm Password */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            <Field label="Password *" id="password" type="password"
              placeholder="Min. 8 characters"
              value={form.password} onChange={f("password")} error={errors.password}
              hint="Must be at least 8 characters" />
            <Field label="Confirm Password *" id="passwordConfirm" type="password"
              placeholder="Re-enter password"
              value={form.passwordConfirm} onChange={f("passwordConfirm")}
              error={errors.passwordConfirm} />
          </div>

          {/* Submit */}
          <button type="submit" disabled={loading}
            className="w-full bg-gray-900 text-white py-3 rounded-xl text-sm font-semibold
              hover:bg-gray-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2">
            {loading ? (
              <>
                <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
                </svg>
                Creating account…
              </>
            ) : "Create Admin Account"}
          </button>

          <p className="text-center text-sm mt-4 text-gray-500">
            Already have an account?{" "}
            <Link to="/login" className="text-gray-900 font-medium hover:underline">
              Sign in
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
}
