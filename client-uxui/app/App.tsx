import { useState, useEffect } from "react";
import { LoginPage } from "./components/login-page";
import { SignupPage } from "./components/signup-page";
import { ForgotPasswordPage } from "./components/forgot-password-page";
import { AdminDashboard } from "./components/admin-dashboard";
import { ClientDashboard } from "./components/client-dashboard";
import { CoachDashboard } from "./components/coach-dashboard";
import { GymPage } from "./components/gym-page";
import { ProfilePage } from "./components/profile-page";
import { BottomNav } from "./components/bottom-nav";
import { NotificationBell } from "./components/notification-bell";
import { Toaster } from "./components/ui/sonner";
import { toast } from "sonner";

// Admin pages
import { GymSelectionPage } from "./components/admin/gym-selection-page";
import { CreateGymPage } from "./components/admin/create-gym-page";
import { AccountSettingsPage } from "./components/admin/account-settings-page";
import { AnnouncementsPage } from "./components/admin/announcements-page";
import { SchedulePage } from "./components/admin/schedule-page";
import { MembersPage } from "./components/admin/members-page";
import { EnhancedRetentionPage } from "./components/admin/enhanced-retention-page";
import { AttendancePage } from "./components/admin/attendance-page";
import { SettingsPage } from "./components/admin/settings-page";
import { AnalyticsPage } from "./components/admin/analytics-page";
import { AddMemberPage } from "./components/admin/add-member-page";
import { MemberDetailsPage } from "./components/admin/member-details-page";
import { CoachesPage } from "./components/admin/coaches-page";

// Client pages
import { ScanPage } from "./components/client/scan-page";
import { ClientSchedulePage } from "./components/client/schedule-page";
import { TrainingPlansPage } from "./components/client/training-plans-page";
import { BadgesPage } from "./components/client/badges-page";

// Coach pages
import { CoachGymSelectionPage } from "./components/coach/gym-selection-page";
import { RequestClassPage } from "./components/coach/request-class-page";
import { UnifiedSchedulePage } from "./components/coach/unified-schedule-page";
import { RequestClassFormPage } from "./components/coach/request-class-form-page";
import { CoachGymsPage } from "./components/coach/gyms-page";
import { CoachGymAnnouncementsPage } from "./components/coach/gym-announcements-page";
import { CoachGymSchedulePage } from "./components/coach/gym-schedule-page";
import { LogOut } from "lucide-react";
import { Button } from "./components/ui/button";

type UserRole = "admin" | "client" | "coach";
type Page = "login" | "signup" | "forgot-password";

interface User {
  email: string;
  role: UserRole;
  name: string;
}

interface SelectedGym {
  id: string;
  name: string;
}

interface CoachSelectedGym {
  id: string | "all";
  name: string;
}

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [currentPage, setCurrentPage] = useState<Page | string>("login");
  const [selectedGym, setSelectedGym] = useState<SelectedGym | null>(null);
  const [coachSelectedGym, setCoachSelectedGym] = useState<CoachSelectedGym | null>(null);
  const [gyms, setGyms] = useState<any[]>([]);
  const [selectedMemberId, setSelectedMemberId] = useState<number | null>(null);

  const handleLogin = (email: string, password: string, role: UserRole) => {
    // Mock authentication - in production, this would call Supabase auth
    const mockUsers: Record<string, { role: UserRole; name: string }> = {
      "admin@gym.com": { role: "admin", name: "Admin User" },
      "admin@titan.com": { role: "admin", name: "Admin Manager" },
      "coach@gym.com": { role: "coach", name: "Sarah Johnson" },
      "coach@titan.com": { role: "coach", name: "Mike Thompson" },
      "client@gym.com": { role: "client", name: "John Doe" },
      "client@titan.com": { role: "client", name: "Emma Wilson" },
      "member@gym.com": { role: "client", name: "Alex Brown" },
    };

    const mockUser = mockUsers[email];

    if (mockUser && mockUser.role === role) {
      setUser({ email, role, name: mockUser.name });
      // Admin users go to gym selection first, others to dashboard
      if (role === "admin") {
        setCurrentPage("gym-selection");
      } else {
        setCurrentPage("dashboard");
      }
      toast.success(`Welcome ${mockUser.name}!`);
    } else {
      toast.error("Invalid credentials. Please check email and role.");
    }
  };

  const handleLogout = () => {
    setUser(null);
    setSelectedGym(null);
    setCoachSelectedGym(null);
    setCurrentPage("login");
    toast.success("Logged out successfully");
  };

  const handleNavigate = (page: string) => {
    setCurrentPage(page);
  };

  const handleBackToDashboard = () => {
    setCurrentPage("dashboard");
  };

  const handleSelectGym = (gymId: string, gymName: string) => {
    setSelectedGym({ id: gymId, name: gymName });
    setCurrentPage("dashboard");
    toast.success(`Now managing ${gymName}`);
  };

  const handleBackToGymSelection = () => {
    setSelectedGym(null);
    setCurrentPage("gym-selection");
  };

  const handleDeactivateAccount = () => {
    toast.error("Account deactivated. Logging out...");
    setTimeout(() => {
      handleLogout();
    }, 1500);
  };

  const handleCoachSelectGym = (gymId: string | "all", gymName: string) => {
    setCoachSelectedGym({ id: gymId, name: gymName });
    setCurrentPage("dashboard");
    toast.success(`Viewing classes for ${gymName}`);
  };

  const handleBackToCoachGymSelection = () => {
    setCoachSelectedGym(null);
    setCurrentPage("coach-gym-selection");
  };

  const handleCreateGym = (gym: any) => {
    setGyms([...gyms, gym]);
    setCurrentPage("gym-selection");
  };

  const handleUpdateGyms = (updatedGyms: any[]) => {
    setGyms(updatedGyms);
  };

  const handleViewMemberDetails = (memberId: number) => {
    setSelectedMemberId(memberId);
    setCurrentPage("member-details");
  };

  // Handle redirects when gym is not selected
  useEffect(() => {
    if (user?.role === "admin" && !selectedGym &&
        currentPage !== "gym-selection" &&
        currentPage !== "admin-settings" &&
        currentPage !== "profile" &&
        currentPage !== "create-gym") {
      setCurrentPage("gym-selection");
    }
  }, [user, selectedGym, currentPage]);


  // Auth pages (no user logged in)
  if (!user) {
    if (currentPage === "signup") {
      return (
        <>
          <SignupPage onBack={() => setCurrentPage("login")} />
          <Toaster />
        </>
      );
    }

    if (currentPage === "forgot-password") {
      return (
        <>
          <ForgotPasswordPage onBack={() => setCurrentPage("login")} />
          <Toaster />
        </>
      );
    }

    return (
      <>
        <LoginPage 
          onLogin={handleLogin}
          onNavigateToSignup={() => setCurrentPage("signup")}
          onNavigateToForgotPassword={() => setCurrentPage("forgot-password")}
        />
        <Toaster />
      </>
    );
  }

  // Common header with notification bell
  const PageHeader = ({ title, onBack }: { title?: string; onBack?: () => void }) => (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-20 shadow-sm">
      <div className="px-4 py-4 flex items-center justify-between">
        <div className="flex items-center space-x-3">
          {onBack && (
            <Button onClick={onBack} variant="ghost" size="icon">
              <LogOut className="w-5 h-5" />
            </Button>
          )}
          {title && <h1 className="text-lg font-semibold">{title}</h1>}
        </div>
        <NotificationBell role={user.role} />
      </div>
    </header>
  );

  // Admin gym selection (must select a gym before accessing features)
  if (user.role === "admin" && currentPage === "gym-selection") {
    return (
      <>
        <GymSelectionPage
          onSelectGym={handleSelectGym}
          userName={user.name}
          onLogout={handleLogout}
          onNavigate={handleNavigate}
          onCreateGym={handleCreateGym}
          gyms={gyms.length > 0 ? gyms : undefined}
          onUpdateGyms={handleUpdateGyms}
        />
        <Toaster />
      </>
    );
  }

  // Admin create gym page (no bottom nav)
  if (user.role === "admin" && currentPage === "create-gym") {
    return (
      <>
        <CreateGymPage onBack={() => setCurrentPage("gym-selection")} onCreateGym={handleCreateGym} />
        <Toaster />
      </>
    );
  }

  // Admin profile page when on gym selection (no bottom nav)
  if (user.role === "admin" && currentPage === "profile" && !selectedGym) {
    return (
      <>
        <ProfilePage onBack={() => setCurrentPage("gym-selection")} userRole="admin" userName={user.name} />
        <Toaster />
      </>
    );
  }

  // Admin profile page (with bottom nav, only when gym is selected)
  if (user.role === "admin" && currentPage === "profile" && selectedGym) {
    return (
      <>
        <ProfilePage onBack={handleBackToDashboard} userRole="admin" userName={user.name} />
        <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
        <Toaster />
      </>
    );
  }

  // Admin account settings (accessible from anywhere)
  if (user.role === "admin" && currentPage === "admin-settings") {
    return (
      <>
        <AccountSettingsPage
          onBack={handleBackToDashboard}
          userName={user.name}
          userEmail={user.email}
          onDeactivate={handleDeactivateAccount}
        />
        <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
        <Toaster />
      </>
    );
  }

  // Admin pages (only accessible after gym selection)
  if (user.role === "admin") {
    if (currentPage === "announcements") {
      return (
        <>
          <AnnouncementsPage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "schedule") {
      return (
        <>
          <SchedulePage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "members") {
      return (
        <>
          <MembersPage onBack={handleBackToDashboard} onAddMember={() => handleNavigate("add-member")} onViewDetails={handleViewMemberDetails} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "add-member") {
      return (
        <>
          <AddMemberPage onBack={() => handleNavigate("members")} gymName={selectedGym?.name} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "member-details" && selectedMemberId !== null) {
      return (
        <>
          <MemberDetailsPage onBack={() => handleNavigate("members")} memberId={selectedMemberId} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "coaches") {
      return (
        <>
          <CoachesPage onBack={handleBackToDashboard} onAddCoach={() => handleNavigate("add-member")} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "retention") {
      return (
        <>
          <EnhancedRetentionPage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "attendance") {
      return (
        <>
          <AttendancePage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "gym-settings" || currentPage === "settings") {
      return (
        <>
          <SettingsPage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "analytics") {
      return (
        <>
          <AnalyticsPage onBack={handleBackToDashboard} />
          <BottomNav role="admin" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
  }

  // Client pages
  if (user.role === "client") {
    if (currentPage === "gym") {
      return (
        <>
          <GymPage gymName="Titan Fitness Center" onBack={handleBackToDashboard} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "scan") {
      return (
        <>
          <ScanPage onBack={handleBackToDashboard} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "schedule") {
      return (
        <>
          <ClientSchedulePage onBack={handleBackToDashboard} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "training") {
      return (
        <>
          <TrainingPlansPage onBack={handleBackToDashboard} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "badges") {
      return (
        <>
          <BadgesPage onBack={handleBackToDashboard} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "profile") {
      return (
        <>
          <ProfilePage onBack={handleBackToDashboard} userRole="client" userName={user.name} />
          <BottomNav role="client" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
  }

  // Coach pages
  if (user.role === "coach") {
    if (currentPage === "gym-details" && coachSelectedGym) {
      return (
        <>
          <RequestClassPage onBack={() => handleNavigate("gyms")} gymName={coachSelectedGym.name} />
          <BottomNav role="coach" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "schedule") {
      return (
        <>
          <UnifiedSchedulePage onBack={handleBackToDashboard} onNavigate={handleNavigate} />
          <BottomNav role="coach" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "coach-gym-schedule" && coachSelectedGym) {
      return (
        <>
          <CoachGymSchedulePage
            onBack={() => handleNavigate("gyms")}
            gymName={coachSelectedGym.name}
          />
          <BottomNav role="coach" currentPage="gyms" onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "coach-gym-announcements" && coachSelectedGym) {
      return (
        <>
          <CoachGymAnnouncementsPage
            onBack={() => handleNavigate("gyms")}
            gymName={coachSelectedGym.name}
          />
          <BottomNav role="coach" currentPage="gyms" onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "request-class-form") {
      return (
        <>
          <RequestClassFormPage onBack={() => handleNavigate("schedule")} />
          <BottomNav role="coach" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "gyms") {
      return (
        <>
          <CoachGymsPage onBack={handleBackToDashboard} onSelectGym={handleCoachSelectGym} onNavigate={handleNavigate} />
          <BottomNav role="coach" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
    if (currentPage === "profile") {
      return (
        <>
          <ProfilePage onBack={handleBackToDashboard} userRole="coach" userName={user.name} />
          <BottomNav role="coach" currentPage={currentPage} onNavigate={handleNavigate} />
          <Toaster />
        </>
      );
    }
  }

  // Dashboard pages (default)
  return (
    <>
      {user.role === "admin" && selectedGym && (
        <AdminDashboard
          onLogout={handleLogout}
          onNavigate={handleNavigate}
          gymName={selectedGym.name}
          onSwitchGym={handleBackToGymSelection}
        />
      )}
      {user.role === "client" && (
        <ClientDashboard onLogout={handleLogout} onNavigate={handleNavigate} />
      )}
      {user.role === "coach" && (
        <CoachDashboard
          onLogout={handleLogout}
          onNavigate={handleNavigate}
        />
      )}
      <BottomNav role={user.role} currentPage={currentPage} onNavigate={handleNavigate} />
      <Toaster />
    </>
  );
}