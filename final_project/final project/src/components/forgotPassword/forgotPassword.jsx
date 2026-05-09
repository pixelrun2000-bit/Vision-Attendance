import { Mail, ArrowLeft } from "lucide-react";

export default function ForgotPassword() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-[#E9F0FF]">
      <div className="bg-white rounded-xl shadow-md  p-8">

        {/* Title */}
        <h2 className="text-xl font-semibold text-center">Forgot Password</h2>
        <p className="text-sm text-gray-500 text-center mt-2">
          Enter your email to receive a password reset link
        </p>

        {/* Email Field */}
        <div className="mt-6">
          <label className="text-sm font-medium">Email Address</label>

          <div className="flex items-center mt-2 border rounded-md px-3 py-2 bg-gray-50">
            <Mail size={18} className="text-gray-400 mr-2" />
            <input
              type="email"
              placeholder="Enter your email"
              className="w-full outline-none bg-transparent text-sm"
            />
          </div>
        </div>

        {/* Button */}
        <button className="w-full mt-5 bg-black text-white py-2.5 rounded-md hover:bg-gray-900 transition">
          Send Reset Link
        </button>

        {/* Back to login */}
        <div className="text-center mt-4">
          <a
            href="/login"
            className="text-blue-600 text-sm flex items-center justify-center gap-1 hover:underline"
          >
            <ArrowLeft size={16} />
            Back to login
          </a>
        </div>

      </div>
    </div>
  );
}
