import { ArrowLeft, Award, Trophy, Star, Target, Zap, Crown } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Badge } from "../ui/badge";
import { Progress } from "../ui/progress";

interface BadgesPageProps {
  onBack: () => void;
}

interface Badge {
  id: number;
  name: string;
  description: string;
  icon: string;
  earned: boolean;
  earnedDate?: string;
  progress?: number;
  requirement?: string;
}

export function BadgesPage({ onBack }: BadgesPageProps) {
  const badges: Badge[] = [
    {
      id: 1,
      name: "First Timer",
      description: "Complete your first gym check-in",
      icon: "🎉",
      earned: true,
      earnedDate: "Jan 15, 2026"
    },
    {
      id: 2,
      name: "3 Day Warrior",
      description: "Check in for 3 consecutive days",
      icon: "💪",
      earned: true,
      earnedDate: "Jan 18, 2026"
    },
    {
      id: 3,
      name: "Weekly Streak",
      description: "Check in 5 days in a week",
      icon: "🔥",
      earned: true,
      earnedDate: "Jan 22, 2026"
    },
    {
      id: 4,
      name: "Monthly Champion",
      description: "Check in 20 times in a month",
      icon: "🏆",
      earned: false,
      progress: 78,
      requirement: "16/20 visits"
    },
    {
      id: 5,
      name: "Class Enthusiast",
      description: "Attend 10 different classes",
      icon: "⭐",
      earned: false,
      progress: 60,
      requirement: "6/10 classes"
    },
    {
      id: 6,
      name: "Early Bird",
      description: "Check in before 7 AM ten times",
      icon: "🌅",
      earned: false,
      progress: 40,
      requirement: "4/10 mornings"
    },
    {
      id: 7,
      name: "Consistency King",
      description: "Maintain a 30-day check-in streak",
      icon: "👑",
      earned: false,
      progress: 40,
      requirement: "12/30 days"
    },
    {
      id: 8,
      name: "Social Butterfly",
      description: "Participate in 5 group classes",
      icon: "🦋",
      earned: false,
      progress: 80,
      requirement: "4/5 classes"
    },
    {
      id: 9,
      name: "Goal Crusher",
      description: "Complete 3 training plans",
      icon: "⚡",
      earned: false,
      progress: 33,
      requirement: "1/3 plans"
    },
    {
      id: 10,
      name: "Fitness Legend",
      description: "Earn all other badges",
      icon: "🌟",
      earned: false,
      progress: 33,
      requirement: "3/9 badges"
    }
  ];

  const earnedBadges = badges.filter(b => b.earned);
  const inProgressBadges = badges.filter(b => !b.earned);

  const stats = [
    { label: "Earned", value: earnedBadges.length, icon: Award, color: "text-green-600" },
    { label: "In Progress", value: inProgressBadges.length, icon: Target, color: "text-orange-600" },
    { label: "Total", value: badges.length, icon: Trophy, color: "text-blue-600" },
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-6">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-10 shadow-sm">
        <div className="px-4 py-4">
          <div className="flex items-center space-x-3">
            <Button onClick={onBack} variant="ghost" size="sm" className="p-2">
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-lg font-semibold">My Achievements</h1>
              <p className="text-xs text-gray-600">Unlock badges by reaching milestones</p>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          {stats.map((stat, index) => (
            <Card key={index}>
              <CardContent className="p-3">
                <div className="text-center">
                  <stat.icon className={`w-6 h-6 ${stat.color} mx-auto mb-1`} />
                  <p className="text-xl font-semibold">{stat.value}</p>
                  <p className="text-xs text-gray-600">{stat.label}</p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Motivation Card */}
        <Card className="mb-6 bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
          <CardContent className="p-4">
            <div className="flex items-start space-x-3">
              <Trophy className="w-6 h-6 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-semibold text-base mb-1">Keep Going!</h3>
                <p className="text-sm text-gray-700">
                  You're doing great! You've earned {earnedBadges.length} badges. 
                  Just {inProgressBadges.length} more to collect them all!
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Earned Badges */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Earned Badges</CardTitle>
            <CardDescription className="text-sm">Your achievements so far</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="grid grid-cols-2 gap-3">
              {earnedBadges.map((badge) => (
                <Card key={badge.id} className="border-2 border-green-600 bg-green-50">
                  <CardContent className="p-4 text-center">
                    <div className="text-4xl mb-2">{badge.icon}</div>
                    <h3 className="font-semibold text-sm mb-1">{badge.name}</h3>
                    <p className="text-xs text-gray-600 mb-2">{badge.description}</p>
                    <Badge className="bg-green-600 text-xs">
                      {badge.earnedDate}
                    </Badge>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* In Progress Badges */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">In Progress</CardTitle>
            <CardDescription className="text-sm">Keep working towards these goals</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="grid grid-cols-1 gap-3">
              {inProgressBadges.map((badge) => (
                <Card key={badge.id} className="border-2 border-gray-200 bg-gray-50">
                  <CardContent className="p-4">
                    <div className="flex items-start space-x-3">
                      <div className="text-3xl flex-shrink-0 opacity-60">{badge.icon}</div>
                      <div className="flex-1">
                        <h3 className="font-semibold text-sm mb-1">{badge.name}</h3>
                        <p className="text-xs text-gray-600 mb-3">{badge.description}</p>
                        {badge.progress !== undefined && (
                          <div>
                            <div className="flex justify-between text-xs mb-1">
                              <span className="text-gray-600">{badge.requirement}</span>
                              <span className="font-semibold">{badge.progress}%</span>
                            </div>
                            <Progress value={badge.progress} className="h-2" />
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
