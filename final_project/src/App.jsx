// src/App.jsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import Layout from './components/Layout/Layout';
import Login from './components/login/login';
import Register from './components/register/register';
import ForgotPassword from './components/forgotPassword/forgotPassword';
import Dashboard from './components/dashboard/dashboard';
import RoomManagement from './components/roomManagement/roomManagement';
import AttendanceMethod from './components/attendanceMethod/attendanceMethod';
import AddPerson from './components/addPerson/addPerson';
import Settings from './components/settings/settings';
import ProtectedRoute from './components/ProtectedRoute/ProtectedRoute';
import Subscriptions from './components/subscriptions/subscriptions';

const router = createBrowserRouter([
  {
    path: "",
    element: <Layout />,
    children: [
      // ── Public routes ──────────────────────────────────────────────────────
      { path: "login",          element: <Login /> },
      { path: "register",       element: <Register /> },
      { path: "forgotpassword", element: <ForgotPassword /> },
      { path: "subscriptions",  element: <Subscriptions /> },

      // ── Protected routes (login required) ─────────────────────────────────
      {
        path: "/",
        element: <ProtectedRoute><Dashboard /></ProtectedRoute>,
      },
      {
        // Admin only
        path: "rooms",
        element: <ProtectedRoute><RoomManagement /></ProtectedRoute>,
      },
      {
        // Admin only
        path: "attendance",
        element: <ProtectedRoute><AttendanceMethod /></ProtectedRoute>,
      },
      {
        // Admin + Manager
        path: "add-person",
        element: <ProtectedRoute><AddPerson /></ProtectedRoute>,
      },
      {
        // Admin only
        path: "settings",
        element: <ProtectedRoute><Settings /></ProtectedRoute>,
      },
    ],
  },
]);

export default function App() {
  return <RouterProvider router={router} />;
}
