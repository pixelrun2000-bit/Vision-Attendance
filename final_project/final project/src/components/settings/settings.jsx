import { useState } from "react";
import MainMenu from "../mainMenu/mainMenu";

const Toggle = ({ value, onChange }) => (
  <button
    onClick={() => onChange(!value)}
    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none ${
      value ? "bg-gray-900" : "bg-gray-200"
    }`}
  >
    <span
      className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${
        value ? "translate-x-6" : "translate-x-1"
      }`}
    />
  </button>
);

export default function Settings() {
  const [activeTab, setActiveTab] = useState("Profile");

  // Profile state
  const [profile, setProfile] = useState({
    fullName: "Administrator",
    email: "admin@company.com",
    phone: "+1234567890",
    organization: "Tech Company Inc.",
  });

  // Notifications state
  const [notifications, setNotifications] = useState({
    email: false,
    push: false,
    attendance: false,
    weekly: false,
  });

  // Privacy state
  const [privacy, setPrivacy] = useState({
    profileVisible: false,
    showEmail: false,
    showPhone: false,
  });

  // Security state
  const [security, setSecurity] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
    twoFactor: false,
    sessionTimeout: "30",
  });

  const tabs = [
    { label: "Profile", icon: "fa-user" },
    { label: "Notifications", icon: "fa-bell" },
    { label: "Privacy", icon: "fa-eye" },
    { label: "Security", icon: "fa-shield-halved" },
  ];

  return (
    <>
      <link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
      />

      <div className="flex h-screen bg-gray-50 font-sans overflow-hidden">
        <MainMenu/>
        <div className="flex-1 overflow-y-auto px-8 py-7">
        {/* Page Header */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
          <p className="text-sm text-gray-400 mt-1">
            Manage your account settings and preferences
          </p>
        </div>

        {/* Tabs */}
        <div className="bg-gray-100 rounded-full p-1 flex mb-5">
          {tabs.map((tab) => (
            <button
              key={tab.label}
              onClick={() => setActiveTab(tab.label)}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-full text-sm font-medium transition-all duration-150 ${
                activeTab === tab.label
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <i className={`fa-solid ${tab.icon} text-xs`}></i>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">

          {/* ── PROFILE ── */}
          {activeTab === "Profile" && (
            <>
              <h2 className="text-sm font-bold text-gray-900 mb-1">Profile Information</h2>
              <p className="text-xs text-gray-400 mb-6">Update your account profile information</p>

              {/* Avatar */}
              <div className="flex items-center gap-4 mb-6 pb-6 border-b border-gray-100">
                <div className="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center">
                  <i className="fa-solid fa-user text-2xl text-blue-500"></i>
                </div>
                <div>
                  <button className="border border-gray-300 text-sm text-gray-700 font-medium px-4 py-1.5 rounded-lg hover:bg-gray-50 transition-colors">
                    Change Photo
                  </button>
                  <p className="text-xs text-gray-400 mt-1">JPG, PNG or GIF. Max size 2MB</p>
                </div>
              </div>

              {/* Fields */}
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Full Name</label>
                  <input
                    type="text"
                    value={profile.fullName}
                    onChange={(e) => setProfile({ ...profile, fullName: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Email Address</label>
                  <input
                    type="email"
                    value={profile.email}
                    onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Phone Number</label>
                  <input
                    type="text"
                    value={profile.phone}
                    onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Organization</label>
                  <input
                    type="text"
                    value={profile.organization}
                    onChange={(e) => setProfile({ ...profile, organization: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <button className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
                  <i className="fa-solid fa-floppy-disk"></i> Save Changes
                </button>
              </div>
            </>
          )}

          {/* ── NOTIFICATIONS ── */}
          {activeTab === "Notifications" && (
            <>
              <h2 className="text-sm font-bold text-gray-900 mb-1">Notification Preferences</h2>
              <p className="text-xs text-gray-400 mb-6">Choose how you want to be notified</p>

              <div className="divide-y divide-gray-100">
                {[
                  {
                    key: "email",
                    icon: "fa-envelope",
                    label: "Email Notifications",
                    desc: "Receive notifications via email",
                  },
                  {
                    key: "push",
                    icon: "fa-mobile-screen",
                    label: "Push Notifications",
                    desc: "Receive push notifications on your mobile device",
                  },
                  {
                    key: "attendance",
                    icon: "fa-bell",
                    label: "Attendance Alerts",
                    desc: "Get notified when someone checks in/out",
                  },
                  {
                    key: "weekly",
                    icon: "fa-envelope",
                    label: "Weekly Reports",
                    desc: "Receive weekly attendance summary reports",
                  },
                ].map((item) => (
                  <div key={item.key} className="flex items-center justify-between py-4">
                    <div className="flex items-start gap-3">
                      <i className={`fa-solid ${item.icon} text-gray-400 mt-0.5 text-sm`}></i>
                      <div>
                        <p className="text-sm font-medium text-gray-800">{item.label}</p>
                        <p className="text-xs text-gray-400 mt-0.5">{item.desc}</p>
                      </div>
                    </div>
                    <Toggle
                      value={notifications[item.key]}
                      onChange={(v) => setNotifications({ ...notifications, [item.key]: v })}
                    />
                  </div>
                ))}
              </div>

              <div className="flex justify-end mt-4">
                <button className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
                  <i className="fa-solid fa-floppy-disk"></i> Save Changes
                </button>
              </div>
            </>
          )}

          {/* ── PRIVACY ── */}
          {activeTab === "Privacy" && (
            <>
              <h2 className="text-sm font-bold text-gray-900 mb-1">Privacy Controls</h2>
              <p className="text-xs text-gray-400 mb-6">
                Manage your privacy and data sharing preferences
              </p>

              <div className="divide-y divide-gray-100 mb-6">
                {[
                  {
                    key: "profileVisible",
                    label: "Profile Visibility",
                    desc: "Make your profile visible to other users",
                  },
                  {
                    key: "showEmail",
                    label: "Show Email Address",
                    desc: "Display your email on your public profile",
                  },
                  {
                    key: "showPhone",
                    label: "Show Phone Number",
                    desc: "Display your phone number on your public profile",
                  },
                ].map((item) => (
                  <div key={item.key} className="flex items-center justify-between py-4">
                    <div>
                      <p className="text-sm font-medium text-gray-800">{item.label}</p>
                      <p className="text-xs text-gray-400 mt-0.5">{item.desc}</p>
                    </div>
                    <Toggle
                      value={privacy[item.key]}
                      onChange={(v) => setPrivacy({ ...privacy, [item.key]: v })}
                    />
                  </div>
                ))}
              </div>

              {/* Data Management */}
              <div className="border-t border-gray-100 pt-5">
                <p className="text-sm font-bold text-gray-900 mb-3">Data Management</p>
                <div className="flex gap-3">
                  <button className="border border-gray-300 text-sm font-semibold text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors">
                    Download My Data
                  </button>
                  <button className="border border-gray-300 text-sm font-medium text-gray-600 px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors">
                    Export Attendance Records
                  </button>
                </div>
              </div>

              <div className="flex justify-end mt-6">
                <button className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
                  <i className="fa-solid fa-floppy-disk"></i> Save Changes
                </button>
              </div>
            </>
          )}

          {/* ── SECURITY ── */}
          {activeTab === "Security" && (
            <>
              <h2 className="text-sm font-bold text-gray-900 mb-1">Security Settings</h2>
              <p className="text-xs text-gray-400 mb-6">
                Manage your account security and authentication
              </p>

              {/* Change Password */}
              <div className="mb-6 pb-6 border-b border-gray-100">
                <p className="text-sm font-semibold text-gray-800 mb-3">Change Password</p>
                <div className="flex flex-col gap-3">
                  <input
                    type="password"
                    placeholder="Current password"
                    value={security.currentPassword}
                    onChange={(e) => setSecurity({ ...security, currentPassword: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                  <input
                    type="password"
                    placeholder="New password"
                    value={security.newPassword}
                    onChange={(e) => setSecurity({ ...security, newPassword: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                  <input
                    type="password"
                    placeholder="Confirm new password"
                    value={security.confirmPassword}
                    onChange={(e) => setSecurity({ ...security, confirmPassword: e.target.value })}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  />
                  <div>
                    <button className="border border-gray-300 text-sm font-medium text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors">
                      Update Password
                    </button>
                  </div>
                </div>
              </div>

              {/* Two-Factor Auth */}
              <div className="flex items-center justify-between py-4 border-b border-gray-100">
                <div className="flex items-center gap-2">
                  <i className="fa-regular fa-circle text-gray-400 text-sm"></i>
                  <div>
                    <p className="text-sm font-medium text-gray-800">Two-Factor Authentication</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      Add an extra layer of security to your account
                    </p>
                  </div>
                </div>
                <Toggle
                  value={security.twoFactor}
                  onChange={(v) => setSecurity({ ...security, twoFactor: v })}
                />
              </div>

              {/* Session Timeout */}
              <div className="py-4 border-b border-gray-100">
                <p className="text-sm font-semibold text-gray-800 mb-2">Session Timeout</p>
                <select
                  value={security.sessionTimeout}
                  onChange={(e) => setSecurity({ ...security, sessionTimeout: e.target.value })}
                  className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors mb-1"
                >
                  <option value="15">15 minutes</option>
                  <option value="30">30 minutes</option>
                  <option value="60">1 hour</option>
                  <option value="120">2 hours</option>
                </select>
                <p className="text-xs text-gray-400">
                  Automatically log out after period of inactivity
                </p>
              </div>

              {/* Active Sessions */}
              <div className="pt-4 mb-6">
                <p className="text-sm font-semibold text-gray-800 mb-3">Active Sessions</p>
                <div className="border border-gray-200 rounded-lg px-4 py-3 flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-800">Current Device</p>
                    <p className="text-xs text-gray-400 mt-0.5">Last active: Just now</p>
                  </div>
                  <button className="border border-gray-300 text-sm text-gray-600 px-3 py-1.5 rounded-lg hover:bg-gray-50 transition-colors">
                    Revoke
                  </button>
                </div>
              </div>

              <div className="flex justify-end">
                <button className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
                  <i className="fa-solid fa-floppy-disk"></i> Save Changes
                </button>
              </div>
            </>
          )}
        </div>
      </div>
      </div>
    </>
  );
}
