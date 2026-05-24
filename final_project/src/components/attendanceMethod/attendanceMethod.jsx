import { useState } from "react";
import MainMenu from "../mainMenu/mainMenu";

export default function AttendanceMethod() {
  const [method, setMethod] = useState("qr");
  const [discountEnabled, setDiscountEnabled] = useState(true);
  const [discountCategory, setDiscountCategory] = useState("work");
  const [discountPercentage, setDiscountPercentage] = useState("10");
  const [qrGenerated, setQrGenerated] = useState(false);

  const discountPreviews = {
    work: "Employees with high attendance rates will receive a 10% discount on company services or benefits.",
    students: "Students with high attendance rates will receive a 10% discount on educational fees or services.",
    both: "Both employees and students with high attendance will receive a 10% discount on applicable services.",
  };

  return (
    <>
      <link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
      />

      <div className="flex bg-gray-50 font-sans">
        <MainMenu />

        <div className="flex-1 px-8 py-8 pb-24">
          {/* Page Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Attendance Method</h1>
            <p className="text-sm text-gray-400 mt-1">
              Configure how users will register their attendance via mobile app
            </p>
          </div>

          {/* Registration Method */}
          <div className="bg-white border border-gray-200 rounded-xl p-6 mb-5 shadow-sm">
            <h2 className="text-sm font-bold text-gray-900 mb-1">Registration Method</h2>
            <p className="text-xs text-gray-400 mb-4">
              Choose how users will check in through the mobile application
            </p>

            <div className="grid grid-cols-2 gap-4">
              {/* QR Code */}
              <button
                onClick={() => setMethod("qr")}
                className={`border-2 rounded-xl p-5 text-left transition-all ${method === "qr"
                    ? "border-blue-400 bg-blue-50"
                    : "border-gray-200 bg-white hover:border-gray-300"
                  }`}
              >
                <div className="flex items-center gap-2 mb-4">
                  <div
                    className={`w-3 h-3 rounded-full border-2 flex items-center justify-center ${method === "qr" ? "border-blue-500" : "border-gray-300"
                      }`}
                  >
                    {method === "qr" && (
                      <div className="w-1.5 h-1.5 rounded-full bg-blue-500"></div>
                    )}
                  </div>
                  <span className="text-sm font-semibold text-gray-800">QR Code Scanning</span>
                </div>

                <div className="flex justify-center mb-4">
                  <i className="fa-solid fa-qrcode text-5xl text-blue-500"></i>
                </div>

                <p className="text-xs text-gray-500 mb-3">
                  Users scan a unique QR code to register their attendance. Fast and contactless
                  registration method.
                </p>
                <ul className="text-xs text-gray-500 space-y-1">
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>Quick and easy</li>
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>No physical contact</li>
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>Works offline</li>
                </ul>
              </button>

              {/* Face Recognition */}
              <button
                onClick={() => setMethod("face")}
                className={`border-2 rounded-xl p-5 text-left transition-all ${method === "face"
                    ? "border-purple-400 bg-purple-50"
                    : "border-gray-200 bg-white hover:border-gray-300"
                  }`}
              >
                <div className="flex items-center gap-2 mb-4">
                  <div
                    className={`w-3 h-3 rounded-full border-2 flex items-center justify-center ${method === "face" ? "border-purple-500" : "border-gray-300"
                      }`}
                  >
                    {method === "face" && (
                      <div className="w-1.5 h-1.5 rounded-full bg-purple-500"></div>
                    )}
                  </div>
                  <span className="text-sm font-semibold text-gray-800">Face Recognition</span>
                </div>

                <div className="flex justify-center mb-4">
                  <i className="fa-solid fa-face-smile text-5xl text-purple-500"></i>
                </div>

                <p className="text-xs text-gray-500 mb-3">
                  Users register using facial recognition technology. Secure and automated
                  attendance tracking.
                </p>
                <ul className="text-xs text-gray-500 space-y-1">
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>Highly secure</li>
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>Prevents buddy punching</li>
                  <li><i className="fa-solid fa-check mr-1 text-gray-400"></i>Touchless experience</li>
                </ul>
              </button>
            </div>
          </div>

          {/* QR Code Configuration */}
          {method === "qr" && (
            <div className="bg-blue-50 border border-blue-100 rounded-xl p-6 mb-5 shadow-sm">
              <h2 className="text-sm font-bold text-gray-900 mb-1">QR Code Configuration</h2>
              <p className="text-xs text-gray-500 mb-4">
                QR codes will be generated for each room and can be displayed at entrances. Users
                scan the code with their mobile app to check in.
              </p>
              <button
                onClick={() => setQrGenerated(true)}
                className="border border-gray-300 bg-white text-sm text-gray-700 font-medium px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <i className="fa-solid fa-qrcode mr-2"></i>
                {qrGenerated ? "QR Codes Generated ✓" : "Generate QR Codes"}
              </button>
            </div>
          )}

          {/* Face Recognition Configuration */}
          {method === "face" && (
            <div className="bg-purple-50 border border-purple-100 rounded-xl p-6 mb-5 shadow-sm">
              <h2 className="text-sm font-bold text-gray-900 mb-1">Face Recognition Configuration</h2>
              <p className="text-xs text-gray-500 mb-4">
                Facial recognition requires users to register their face profile beforehand. Ensure
                proper lighting conditions for accurate detection.
              </p>
              <button className="border border-gray-300 bg-white text-sm text-gray-700 font-medium px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors">
                <i className="fa-solid fa-camera mr-2"></i>Configure Face Recognition
              </button>
            </div>
          )}

          {/* Discount & Benefits */}
          <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <h2 className="text-sm font-bold text-gray-900 mb-1">Discount & Benefits</h2>
            <p className="text-xs text-gray-400 mb-5">
              Configure discount options for different categories
            </p>

            {/* Enable Toggle */}
            <div className="flex items-center justify-between mb-5 pb-5 border-b border-gray-100">
              <div>
                <p className="text-sm font-medium text-gray-800">Enable Discount System</p>
                <p className="text-xs text-gray-400 mt-0.5">
                  Offer discounts or benefits based on attendance performance
                </p>
              </div>
              <button
                onClick={() => setDiscountEnabled((v) => !v)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none ${discountEnabled ? "bg-black" : "bg-gray-200"
                  }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${discountEnabled ? "translate-x-6" : "translate-x-1"
                    }`}
                />
              </button>
            </div>

            {discountEnabled && (
              <>
                {/* Discount Category */}
                <div className="mb-5">
                  <p className="text-xs font-medium text-gray-600 mb-2">Discount Category</p>
                  <div className="space-y-2">
                    {[
                      { value: "work", label: "Work/Company Employees" },
                      { value: "students", label: "Students/Educational" },
                      { value: "both", label: "Both Work & Study" },
                    ].map((cat) => (
                      <button
                        key={cat.value}
                        onClick={() => setDiscountCategory(cat.value)}
                        className="w-full flex items-center gap-3 border border-gray-200 rounded-lg px-4 py-3 hover:bg-gray-50 transition-colors text-left"
                      >
                        <div
                          className={`w-3.5 h-3.5 rounded-full border-2 flex items-center justify-center shrink-0 ${discountCategory === cat.value
                              ? "border-black"
                              : "border-gray-300"
                            }`}
                          onClick={() => setDiscountCategory(cat.value)}
                        >
                          {discountCategory === cat.value && (
                            <div className="w-2 h-2 rounded-full bg-black"></div>
                          )}
                        </div>
                        <span className="text-sm text-gray-700">{cat.label}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Discount Percentage */}
                <div className="mb-5">
                  <p className="text-xs font-medium text-gray-600 mb-2">Discount Percentage</p>
                  <select
                    value={discountPercentage}
                    onChange={(e) => setDiscountPercentage(e.target.value)}
                    className="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-white transition-colors"
                  >
                    <option value="5">5% - Small Discount</option>
                    <option value="10">10% - Standard Discount</option>
                    <option value="15">15% - Medium Discount</option>
                    <option value="20">20% - Large Discount</option>
                    <option value="25">25% - Premium Discount</option>
                  </select>
                </div>

                {/* Discount Preview */}
                <div className="bg-green-50 border border-green-100 rounded-lg px-4 py-3">
                  <div className="flex items-center gap-2 mb-1">
                    <i className="fa-solid fa-percent text-green-500 text-xs"></i>
                    <span className="text-xs font-semibold text-green-700">Discount Preview</span>
                  </div>
                  <p className="text-xs text-green-600">
                    {discountPreviews[discountCategory].replace("10%", `${discountPercentage}%`)}
                  </p>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Save Configuration - Fixed Bottom */}
        <div className="fixed bottom-0 right-0 p-4">
          <button className="flex items-center gap-2 bg-gray-900 text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-gray-700 transition-colors shadow-lg">
            <i className="fa-solid fa-floppy-disk"></i>
            Save Configuration
          </button>
        </div>
      </div>
    </>
  );
}