import {
  User,
  Calendar,
  QrCode,
  TrendingUp,
  Bell,
  Award,
  Target,
  LogOut,
  Dumbbell
} from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Progress } from "./ui/progress";
import { NotificationBell } from "./notification-bell";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "./ui/alert-dialog";

interface ClientDashboardProps {
  onLogout: () => void;
  onNavigate: (page: string) => void;
  accountStatus?: "active" | "pending" | "suspended";
}

export function ClientDashboard({ onLogout, onNavigate, accountStatus = "active" }: ClientDashboardProps) {
  const stats = [
    { label: "Days This Week", value: "4/7", icon: TrendingUp, color: "text-green-600" },
    { label: "Current Streak", value: "12 days", icon: Award, color: "text-orange-600" },
    { label: "Total Visits", value: "78", icon: QrCode, color: "text-blue-600" },
  ];

  const quickActions = [
    { label: "Scan QR Code", icon: QrCode, page: "scan", description: "Check in to the gym" },
    { label: "My Gym - Titan Fitness", icon: Bell, page: "gym", description: "View announcements and enroll in classes" },
    { label: "My Schedule", icon: Calendar, page: "schedule", description: "View and manage your classes" },
    { label: "Training Plans", icon: Target, page: "training", description: "Generate personalized workout plans" },
    { label: "My Profile", icon: User, page: "profile", description: "Update personal information" },
    { label: "My Badges", icon: Award, page: "badges", description: "View your achievements" },
  ];

  const badges = [
    { name: "First Timer", icon: "🎉", earned: true },
    { name: "3 Day Warrior", icon: "💪", earned: true },
    { name: "Weekly Streak", icon: "🔥", earned: true },
    { name: "Monthly Champion", icon: "🏆", earned: false },
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-10 shadow-sm">
        <div className="px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="bg-indigo-600 p-2 rounded-lg">
                <Dumbbell className="w-5 h-5 text-white" />
              </div>
              <div>
                <h1 className="text-lg font-semibold">My Dashboard</h1>
                <p className="text-xs text-gray-600">Welcome back!</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <NotificationBell role="client" />
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button variant="outline" size="sm">
                    <LogOut className="w-4 h-4" />
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Confirm Logout</AlertDialogTitle>
                    <AlertDialogDescription>
                      Are you sure you want to log out? You will need to sign in again to access your account.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                    <AlertDialogAction onClick={onLogout}>
                      Logout
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* Account Status Alerts */}
        {accountStatus === "pending" && (
          <Card className="mb-6 border-orange-200 bg-orange-50">
            <CardContent className="p-4">
              <div className="flex items-start space-x-3">
                <Bell className="w-5 h-5 text-orange-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-orange-900 mb-1">Account Pending Activation</p>
                  <p className="text-xs text-orange-700">
                    Your account is awaiting activation by the gym administrator. You'll have full access once activated.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {accountStatus === "suspended" && (
          <Card className="mb-6 border-red-200 bg-red-50">
            <CardContent className="p-4">
              <div className="flex items-start space-x-3">
                <Bell className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-red-900 mb-1">Subscription Suspended</p>
                  <p className="text-xs text-red-700">
                    Your subscription has been suspended. Please contact the gym administrator to reactivate your account.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Subscription Status */}
        {accountStatus === "active" && (
          <Card className="mb-6 border-green-200 bg-green-50">
            <CardContent className="p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="text-xs text-gray-600 mb-1">Active Subscription</p>
                  <p className="text-base font-semibold mb-2">Monthly Plan</p>
                  <p className="text-xs text-gray-600">Expires March 15, 2026 (20 days)</p>
                </div>
              <Badge variant="default" className="bg-green-600">Active</Badge>
            </div>
          </CardContent>
        </Card>
        )}

        {/* Stats Grid - Only show for active accounts */}
        {accountStatus === "active" && (
        <div className="grid grid-cols-3 gap-3 mb-6">
          {stats.map((stat, index) => (
            <Card key={index}>
              <CardContent className="p-3">
                <div className="flex flex-col items-center text-center space-y-2">
                  <stat.icon className={`w-6 h-6 ${stat.color}`} />
                  <div>
                    <p className="text-xl font-semibold">{stat.value}</p>
                    <p className="text-xs text-gray-600 mt-0.5">{stat.label}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
        )}

        {/* Weekly Progress - Only show for active accounts */}
        {accountStatus === "active" && (
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Weekly Attendance Goal</CardTitle>
            <CardDescription className="text-xs">Keep up the great work!</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>4 out of 5 days</span>
                <span className="font-semibold">80%</span>
              </div>
              <Progress value={80} className="h-3" />
            </div>
          </CardContent>
        </Card>
        )}

        {/* Quick Actions */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">
              {accountStatus === "active" ? "Quick Actions" : "My Profile"}
            </CardTitle>
            <CardDescription className="text-sm">
              {accountStatus === "active" ? "Access your fitness features" : "View your account information"}
            </CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            {accountStatus === "active" ? (
              <div className="grid grid-cols-1 gap-3">
                {quickActions.map((action, index) => (
                  <Button
                    key={index}
                    variant="outline"
                    className="h-auto p-4 flex items-center justify-start space-x-3 hover:border-green-600 hover:bg-green-50"
                    onClick={() => onNavigate(action.page)}
                  >
                    <action.icon className="w-6 h-6 text-green-600 flex-shrink-0" />
                    <div className="text-left flex-1">
                      <div className="font-semibold text-base">{action.label}</div>
                      <div className="text-xs text-gray-600 font-normal mt-0.5">{action.description}</div>
                    </div>
                  </Button>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <User className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                <p className="text-gray-600 mb-4">
                  Limited access while account is {accountStatus === "pending" ? "pending activation" : "suspended"}
                </p>
                <Button variant="outline" onClick={() => onNavigate("profile")}>
                  <User className="w-4 h-4 mr-2" />
                  View Profile
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Badges */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">My Achievements</CardTitle>
            <CardDescription className="text-sm">Unlock badges by reaching milestones</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="grid grid-cols-2 gap-3">
              {badges.map((badge, index) => (
                <div
                  key={index}
                  className={`p-4 rounded-lg border-2 text-center ${
                    badge.earned
                      ? "border-green-600 bg-green-50"
                      : "border-gray-200 bg-gray-50 opacity-50"
                  }`}
                >
                  <div className="text-3xl mb-2">{badge.icon}</div>
                  <div className="text-xs font-semibold">{badge.name}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}