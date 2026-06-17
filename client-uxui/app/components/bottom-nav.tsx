import {
  LayoutDashboard,
  Calendar,
  Users,
  User,
  QrCode,
  Trophy,
  Building2,
  Dumbbell,
  BarChart2
} from "lucide-react";

interface BottomNavProps {
  role: "admin" | "client" | "coach";
  currentPage?: string;
  onNavigate?: (page: string) => void;
}

export function BottomNav({ role, currentPage = "dashboard", onNavigate }: BottomNavProps) {
  const handleNavigation = (page: string) => {
    if (onNavigate) {
      onNavigate(page);
    }
  };

  const adminLinks = [
    { page: "dashboard", icon: LayoutDashboard, label: "Home" },
    { page: "analytics", icon: BarChart2, label: "Analytics" },
    { page: "schedule", icon: Calendar, label: "Schedule" },
    { page: "profile", icon: User, label: "Profile" },
  ];

  const clientLinks = [
    { page: "dashboard", icon: LayoutDashboard, label: "Home" },
    { page: "schedule", icon: Calendar, label: "Schedule" },
    { page: "scan", icon: QrCode, label: "Scan" },
    { page: "profile", icon: User, label: "Profile" },
  ];

  const coachLinks = [
    { page: "dashboard", icon: LayoutDashboard, label: "Dashboard" },
    { page: "schedule", icon: Calendar, label: "Schedule" },
    { page: "gyms", icon: Building2, label: "Gyms" },
    { page: "profile", icon: User, label: "Profile" },
  ];

  const links = role === "admin" ? adminLinks : role === "coach" ? coachLinks : clientLinks;

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 safe-area-bottom">
      <div className="flex justify-around items-center h-16 px-2 max-w-screen-lg mx-auto">
        {links.map((link) => {
          const isActive = currentPage === link.page;
          return (
            <button
              key={link.page}
              onClick={() => handleNavigation(link.page)}
              className={`flex flex-col items-center justify-center flex-1 py-2 px-1 rounded-lg transition-colors ${
                isActive 
                  ? "text-indigo-600" 
                  : "text-gray-600 hover:text-indigo-600"
              }`}
            >
              <link.icon className={`w-6 h-6 mb-1 ${isActive ? "stroke-[2.5]" : ""}`} />
              <span className="text-xs font-medium">{link.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
