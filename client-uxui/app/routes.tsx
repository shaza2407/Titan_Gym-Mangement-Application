import { createBrowserRouter, Navigate } from "react-router";
import { AuthLayout } from "./layouts/auth-layout";
import { DashboardLayout } from "./layouts/dashboard-layout";
import { LoginPage } from "./components/login-page";
import { SignupPage } from "./components/signup-page";
import { ForgotPasswordPage } from "./components/forgot-password-page";

// Admin pages
import { AdminDashboard } from "./components/admin-dashboard";
import { AnnouncementsPage } from "./components/admin/announcements-page";
import { SchedulePage } from "./components/admin/schedule-page";
import { MembersPage } from "./components/admin/members-page";
import { EnhancedRetentionPage } from "./components/admin/enhanced-retention-page";
import { AttendancePage } from "./components/admin/attendance-page";
import { SettingsPage } from "./components/admin/settings-page";
import { AnalyticsPage } from "./components/admin/analytics-page";
import { AddMemberPage } from "./components/admin/add-member-page";

// Client pages
import { ClientDashboard } from "./components/client-dashboard";
import { ScanPage } from "./components/client/scan-page";
import { ClientSchedulePage } from "./components/client/schedule-page";
import { TrainingPlansPage } from "./components/client/training-plans-page";
import { BadgesPage } from "./components/client/badges-page";

// Coach pages
import { CoachDashboard } from "./components/coach-dashboard";
import { CoachSchedulePage } from "./components/coach/schedule-page";
import { CoachClassesPage } from "./components/coach/classes-page";
import { CoachGymsPage } from "./components/coach/gyms-page";

// Shared
import { ProfilePage } from "./components/profile-page";
import { GymPage } from "./components/gym-page";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AuthLayout />,
    children: [
      { index: true, element: <Navigate to="/login" replace /> },
      { path: "login", element: <LoginPage onLogin={() => {}} /> },
      { path: "signup", element: <SignupPage onBack={() => {}} /> },
      { path: "forgot-password", element: <ForgotPasswordPage onBack={() => {}} /> },
    ],
  },
  {
    path: "/dashboard",
    element: <DashboardLayout />,
    children: [
      { index: true, element: <div>Dashboard Redirect</div> },
    ],
  },
  {
    path: "/admin",
    element: <DashboardLayout />,
    children: [
      { path: "dashboard", element: <AdminDashboard onLogout={() => {}} onNavigate={() => {}} /> },
      { path: "announcements", element: <AnnouncementsPage onBack={() => {}} /> },
      { path: "schedule", element: <SchedulePage onBack={() => {}} /> },
      { path: "members", element: <MembersPage onBack={() => {}} /> },
      { path: "add-member", element: <AddMemberPage onBack={() => {}} /> },
      { path: "retention", element: <EnhancedRetentionPage onBack={() => {}} /> },
      { path: "attendance", element: <AttendancePage onBack={() => {}} /> },
      { path: "settings", element: <SettingsPage onBack={() => {}} /> },
      { path: "analytics", element: <AnalyticsPage onBack={() => {}} /> },
    ],
  },
  {
    path: "/client",
    element: <DashboardLayout />,
    children: [
      { path: "dashboard", element: <ClientDashboard onLogout={() => {}} onNavigate={() => {}} /> },
      { path: "scan", element: <ScanPage onBack={() => {}} /> },
      { path: "schedule", element: <ClientSchedulePage onBack={() => {}} /> },
      { path: "training", element: <TrainingPlansPage onBack={() => {}} /> },
      { path: "badges", element: <BadgesPage onBack={() => {}} /> },
      { path: "gym", element: <GymPage gymName="Titan Fitness Center" onBack={() => {}} /> },
      { path: "profile", element: <ProfilePage onBack={() => {}} userRole="client" userName="John Doe" /> },
    ],
  },
  {
    path: "/coach",
    element: <DashboardLayout />,
    children: [
      { path: "dashboard", element: <CoachDashboard onLogout={() => {}} onNavigate={() => {}} /> },
      { path: "schedule", element: <CoachSchedulePage onBack={() => {}} /> },
      { path: "classes", element: <CoachClassesPage onBack={() => {}} /> },
      { path: "gyms", element: <CoachGymsPage onBack={() => {}} /> },
      { path: "profile", element: <ProfilePage onBack={() => {}} userRole="coach" userName="Sarah Johnson" /> },
    ],
  },
  {
    path: "*",
    element: <Navigate to="/login" replace />,
  },
]);
