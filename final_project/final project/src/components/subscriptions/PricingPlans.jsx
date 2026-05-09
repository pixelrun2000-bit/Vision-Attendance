import { Link } from "react-router-dom";

export const plans = [
  {
    name: "Free",
    target: "Individuals & very small teams",
    price: "$0",
    features: [
      "Attendance and departure tracking using face recognition (basic accuracy model)",
      "Simple and lightweight dashboard for viewing daily attendance",
      "Limited cloud storage for user data and logs (short retention period)"
    ],
    color: "border-gray-200 bg-white hover:border-gray-300",
    badge: null
  },
  {
    name: "Basic",
    target: "Small businesses with 5–50 employees",
    price: "$2 – $3",
    unit: "per user / month",
    features: [
      "Face-based attendance tracking with improved accuracy",
      "Mobile application support for employees and admins",
      "Basic reporting system (daily/weekly attendance summaries)",
      "User management system (add/remove employees)"
    ],
    color: "border-blue-200 bg-blue-50 hover:border-blue-400",
    badge: "Popular for Startups"
  },
  {
    name: "Standard",
    target: "Medium companies (50–200 employees)",
    price: "$4 – $6",
    unit: "per user / month",
    features: [
      "Everything included in Basic plan",
      "Advanced analytics (lateness patterns, attendance trends, productivity insights)",
      "Multi-device support (mobile, tablet, desktop, kiosks)",
      "Extended cloud storage (long-term data retention)",
      "API integration with HR, payroll, and ERP systems"
    ],
    color: "border-indigo-200 bg-indigo-50 hover:border-indigo-400",
    badge: "Best Value"
  },
  {
    name: "Premium",
    target: "Large companies, universities, institutions",
    price: "$7 – $12",
    unit: "per user / month (or custom enterprise pricing)",
    features: [
      "Everything in Standard plan",
      "Unlimited cloud storage and data retention",
      "Dedicated cloud infrastructure or on-premise deployment",
      "High-level security (SLA 99.9%, encryption, compliance)",
      "Advanced AI modules (behavior prediction, anomaly detection)",
      "Multi-branch and hierarchical organizational structure",
      "Priority technical support and SLA guarantees",
      "Full customization of workflows and dashboards"
    ],
    color: "border-purple-200 bg-purple-50 hover:border-purple-400",
    badge: "Enterprise"
  }
];

export default function PricingPlans({ title = "Choose Your Perfect Plan", subtitle = "From small teams to large enterprises, we have a plan tailored to your organization's needs." }) {
  return (
    <div className="py-12">
      <div className="text-center mb-12">
        <h2 className="text-3xl font-extrabold text-gray-900 mb-3">{title}</h2>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">{subtitle}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        {plans.map((plan) => (
          <div key={plan.name} className={`relative flex flex-col rounded-3xl border-2 p-6 transition-transform transform hover:-translate-y-1 shadow-lg ${plan.color}`}>
            {plan.badge && (
              <div className="absolute top-0 right-6 transform -translate-y-1/2">
                <span className="bg-gray-900 text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider shadow-md">
                  {plan.badge}
                </span>
              </div>
            )}
            
            <div className="mb-5">
              <h3 className="text-xl font-bold text-gray-900 mb-1">{plan.name}</h3>
              <p className="text-xs text-gray-600 h-8">{plan.target}</p>
            </div>
            
            <div className="mb-6 pb-6 border-b border-gray-200 border-opacity-50">
              <div className="flex items-baseline">
                <span className="text-4xl font-extrabold text-gray-900 tracking-tight">{plan.price}</span>
              </div>
              {plan.unit && <p className="text-xs font-medium text-gray-500 mt-1">{plan.unit}</p>}
              {!plan.unit && <p className="text-xs font-medium text-gray-500 mt-1">Forever free</p>}
            </div>
            
            <ul className="flex-1 space-y-3 mb-6">
              {plan.features.map((feature, i) => (
                <li key={i} className="flex items-start">
                  <svg className="w-4 h-4 text-green-500 shrink-0 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span className="text-gray-700 text-xs leading-relaxed">{feature}</span>
                </li>
              ))}
            </ul>
            
            <Link 
              to={`/register?plan=${plan.name}`}
              className="w-full py-3 px-4 rounded-xl text-center font-bold text-white bg-gray-900 hover:bg-gray-800 transition-colors shadow mt-auto text-sm"
            >
              Get Started
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
}
