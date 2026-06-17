import { useState } from "react";
import { ArrowLeft, Calendar, Clock, Users, MapPin, X } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Badge } from "../ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../ui/tabs";
import { toast } from "sonner";
import { ScheduleTable } from "../shared/schedule-table";

interface ClientSchedulePageProps {
  onBack: () => void;
}

interface EnrolledClass {
  id: number;
  name: string;
  coach: string;
  day: string;
  time: string;
  duration: string;
  location: string;
  nextSession: string;
}

export function ClientSchedulePage({ onBack }: ClientSchedulePageProps) {
  const [enrolledClasses, setEnrolledClasses] = useState<EnrolledClass[]>([
    {
      id: 1,
      name: "Morning Cardio Blast",
      coach: "Coach Mike",
      day: "Monday",
      time: "07:00 AM",
      duration: "45 min",
      location: "Titan Downtown",
      nextSession: "Mar 11, 2026"
    },
    {
      id: 2,
      name: "Evening Yoga Flow",
      coach: "Coach Emily",
      day: "Wednesday",
      time: "07:00 PM",
      duration: "50 min",
      location: "Titan Downtown",
      nextSession: "Mar 13, 2026"
    },
    {
      id: 3,
      name: "HIIT Training",
      coach: "Coach Alex",
      day: "Saturday",
      time: "09:00 AM",
      duration: "45 min",
      location: "Titan Downtown",
      nextSession: "Mar 16, 2026"
    }
  ]);

  const upcomingSessions = [
    {
      id: 1,
      name: "Morning Cardio Blast",
      coach: "Coach Mike",
      date: "Mar 11, 2026",
      time: "07:00 AM",
      duration: "45 min"
    },
    {
      id: 2,
      name: "Evening Yoga Flow",
      coach: "Coach Emily",
      date: "Mar 13, 2026",
      time: "07:00 PM",
      duration: "50 min"
    },
    {
      id: 3,
      name: "HIIT Training",
      coach: "Coach Alex",
      date: "Mar 16, 2026",
      time: "09:00 AM",
      duration: "45 min"
    },
    {
      id: 4,
      name: "Morning Cardio Blast",
      coach: "Coach Mike",
      date: "Mar 18, 2026",
      time: "07:00 AM",
      duration: "45 min"
    }
  ];

  const handleUnenroll = (classId: number, className: string) => {
    setEnrolledClasses(enrolledClasses.filter(c => c.id !== classId));
    toast.success(`Unenrolled from ${className}`);
  };

  const weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

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
              <h1 className="text-lg font-semibold">My Schedule</h1>
              <p className="text-xs text-gray-600">View and manage your classes</p>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          <Card>
            <CardContent className="p-3">
              <div className="text-center">
                <Calendar className="w-6 h-6 text-green-600 mx-auto mb-1" />
                <p className="text-xl font-semibold">{enrolledClasses.length}</p>
                <p className="text-xs text-gray-600">Enrolled</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-3">
              <div className="text-center">
                <Clock className="w-6 h-6 text-blue-600 mx-auto mb-1" />
                <p className="text-xl font-semibold">{upcomingSessions.length}</p>
                <p className="text-xs text-gray-600">Upcoming</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-3">
              <div className="text-center">
                <Users className="w-6 h-6 text-purple-600 mx-auto mb-1" />
                <p className="text-xl font-semibold">
                  {enrolledClasses.reduce((sum, c) => sum + parseInt(c.duration), 0)}
                </p>
                <p className="text-xs text-gray-600">Min/Week</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="enrolled" className="mb-4">
          <TabsList className="grid w-full grid-cols-3 h-11">
            <TabsTrigger value="enrolled" className="text-sm">My Classes</TabsTrigger>
            <TabsTrigger value="upcoming" className="text-sm">Upcoming</TabsTrigger>
            <TabsTrigger value="browse" className="text-sm">Browse</TabsTrigger>
          </TabsList>

          <TabsContent value="enrolled" className="mt-6 space-y-3">
            {enrolledClasses.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center">
                  <Calendar className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                  <p className="text-gray-600 mb-1">No classes enrolled</p>
                  <p className="text-sm text-gray-500">Visit the gym page to enroll in classes</p>
                </CardContent>
              </Card>
            ) : (
              enrolledClasses.map((classItem) => (
                <Card key={classItem.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <h3 className="font-semibold text-base mb-1">{classItem.name}</h3>
                        <p className="text-sm text-gray-600 mb-2">{classItem.coach}</p>
                        <div className="flex flex-wrap gap-2 mb-2">
                          <Badge variant="outline" className="text-xs">
                            {classItem.day}
                          </Badge>
                          <Badge variant="outline" className="text-xs">
                            {classItem.time}
                          </Badge>
                          <Badge variant="outline" className="text-xs">
                            {classItem.duration}
                          </Badge>
                        </div>
                        <div className="flex items-center text-xs text-gray-600 space-x-4">
                          <span className="flex items-center">
                            <MapPin className="w-3 h-3 mr-1" />
                            {classItem.location}
                          </span>
                          <span className="flex items-center">
                            <Calendar className="w-3 h-3 mr-1" />
                            Next: {classItem.nextSession}
                          </span>
                        </div>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleUnenroll(classItem.id, classItem.name)}
                      className="w-full h-9"
                    >
                      <X className="w-4 h-4 mr-1" />
                      Unenroll
                    </Button>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="upcoming" className="mt-6 space-y-3">
            {upcomingSessions.map((session) => (
              <Card key={session.id}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3 flex-1">
                      <div className="bg-green-100 p-2 rounded-lg flex-shrink-0">
                        <Calendar className="w-5 h-5 text-green-600" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-semibold text-sm mb-1">{session.name}</h3>
                        <p className="text-xs text-gray-600 mb-1">{session.coach}</p>
                        <div className="flex items-center space-x-3 text-xs text-gray-600">
                          <span>{session.date}</span>
                          <span>•</span>
                          <span>{session.time}</span>
                        </div>
                      </div>
                    </div>
                    <Badge variant="default" className="bg-green-600 ml-2">
                      {session.duration}
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            ))}
          </TabsContent>

          <TabsContent value="browse" className="mt-6">
            <ScheduleTable userRole="client" gymName="Titan Fitness Center" />
          </TabsContent>
        </Tabs>

        {/* Weekly Overview */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">This Week's Schedule</CardTitle>
            <CardDescription className="text-sm">Your weekly class calendar</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="space-y-2">
              {weekDays.map((day, index) => {
                const dayClasses = enrolledClasses.filter(c => c.day.startsWith(day.slice(0, 3)));
                return (
                  <div key={index} className="flex items-start space-x-3 p-2 border rounded-lg">
                    <div className="font-semibold text-sm w-10 flex-shrink-0 pt-0.5">{day}</div>
                    <div className="flex-1">
                      {dayClasses.length > 0 ? (
                        <div className="space-y-1">
                          {dayClasses.map((c) => (
                            <div key={c.id} className="text-xs">
                              <span className="font-semibold">{c.time}</span> - {c.name}
                            </div>
                          ))}
                        </div>
                      ) : (
                        <span className="text-xs text-gray-500">No classes</span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
