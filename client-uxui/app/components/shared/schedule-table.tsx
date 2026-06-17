import { useState } from "react";
import { Card, CardContent } from "../ui/card";
import { Button } from "../ui/button";
import { Badge } from "../ui/badge";
import { Users, Clock, User as UserIcon, CheckCircle } from "lucide-react";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "../ui/alert-dialog";
import { toast } from "sonner";

interface ClassSlot {
  id: string;
  day: string;
  time: string;
  className: string;
  coach: string;
  enrolled: number;
  capacity: number;
  duration: string;
  isUserEnrolled?: boolean;
}

interface ScheduleTableProps {
  userRole: "admin" | "client" | "coach";
  gymName?: string;
  onClassAction?: (classId: string, action: "enroll" | "unenroll") => void;
}

export function ScheduleTable({ userRole, gymName = "Titan Fitness", onClassAction }: ScheduleTableProps) {
  const [selectedDay, setSelectedDay] = useState<string | "all">("all");

  const daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  const classSchedule: ClassSlot[] = [
    { id: "1", day: "Monday", time: "06:00 AM", className: "Morning Yoga", coach: "Sarah Johnson", enrolled: 12, capacity: 15, duration: "60 min", isUserEnrolled: false },
    { id: "2", day: "Monday", time: "08:00 AM", className: "HIIT Training", coach: "Mike Thompson", enrolled: 20, capacity: 20, duration: "45 min", isUserEnrolled: true },
    { id: "3", day: "Monday", time: "06:00 PM", className: "Spin Class", coach: "Sarah Johnson", enrolled: 14, capacity: 20, duration: "45 min", isUserEnrolled: false },
    { id: "4", day: "Tuesday", time: "07:00 AM", className: "CrossFit", coach: "Mike Thompson", enrolled: 15, capacity: 18, duration: "60 min", isUserEnrolled: false },
    { id: "5", day: "Tuesday", time: "06:00 PM", className: "Pilates", coach: "Emma Davis", enrolled: 10, capacity: 12, duration: "60 min", isUserEnrolled: true },
    { id: "6", day: "Wednesday", time: "06:00 AM", className: "Morning Yoga", coach: "Sarah Johnson", enrolled: 13, capacity: 15, duration: "60 min", isUserEnrolled: false },
    { id: "7", day: "Wednesday", time: "07:00 PM", className: "Boxing", coach: "Mike Thompson", enrolled: 16, capacity: 16, duration: "60 min", isUserEnrolled: false },
    { id: "8", day: "Thursday", time: "08:00 AM", className: "Strength Training", coach: "Emma Davis", enrolled: 18, capacity: 20, duration: "60 min", isUserEnrolled: false },
    { id: "9", day: "Thursday", time: "06:00 PM", className: "Zumba", coach: "Sarah Johnson", enrolled: 22, capacity: 25, duration: "45 min", isUserEnrolled: false },
    { id: "10", day: "Friday", time: "06:00 AM", className: "Morning Cardio", coach: "Mike Thompson", enrolled: 11, capacity: 15, duration: "45 min", isUserEnrolled: false },
    { id: "11", day: "Friday", time: "07:00 PM", className: "Yoga Flow", coach: "Emma Davis", enrolled: 14, capacity: 15, duration: "60 min", isUserEnrolled: true },
    { id: "12", day: "Saturday", time: "09:00 AM", className: "Boot Camp", coach: "Mike Thompson", enrolled: 19, capacity: 20, duration: "60 min", isUserEnrolled: false },
    { id: "13", day: "Saturday", time: "11:00 AM", className: "Family Fitness", coach: "Sarah Johnson", enrolled: 12, capacity: 20, duration: "45 min", isUserEnrolled: false },
    { id: "14", day: "Sunday", time: "10:00 AM", className: "Gentle Yoga", coach: "Emma Davis", enrolled: 8, capacity: 12, duration: "60 min", isUserEnrolled: false },
    { id: "15", day: "Sunday", time: "05:00 PM", className: "Stretch & Relax", coach: "Sarah Johnson", enrolled: 6, capacity: 10, duration: "45 min", isUserEnrolled: false },
  ];

  const filteredSchedule = selectedDay === "all"
    ? classSchedule
    : classSchedule.filter(slot => slot.day === selectedDay);

  const handleEnrollment = (classSlot: ClassSlot) => {
    if (classSlot.isUserEnrolled) {
      onClassAction?.(classSlot.id, "unenroll");
      toast.success(`Unenrolled from ${classSlot.className}`);
    } else if (classSlot.enrolled < classSlot.capacity) {
      onClassAction?.(classSlot.id, "enroll");
      toast.success(`Enrolled in ${classSlot.className} - ${classSlot.day} at ${classSlot.time}`);
    } else {
      toast.error("This class is full");
    }
  };

  const getCapacityColor = (enrolled: number, capacity: number) => {
    const percentage = (enrolled / capacity) * 100;
    if (percentage >= 100) return "text-red-600 bg-red-50";
    if (percentage >= 80) return "text-orange-600 bg-orange-50";
    return "text-green-600 bg-green-50";
  };

  return (
    <div className="space-y-4">
      {/* Day Filter */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        <Button
          variant={selectedDay === "all" ? "default" : "outline"}
          size="sm"
          onClick={() => setSelectedDay("all")}
          className="flex-shrink-0"
        >
          All Days
        </Button>
        {daysOfWeek.map((day) => (
          <Button
            key={day}
            variant={selectedDay === day ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedDay(day)}
            className="flex-shrink-0"
          >
            {day.slice(0, 3)}
          </Button>
        ))}
      </div>

      {/* Schedule Cards */}
      <div className="space-y-3">
        {filteredSchedule.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center text-gray-500">
              No classes scheduled for {selectedDay}
            </CardContent>
          </Card>
        ) : (
          filteredSchedule.map((classSlot) => (
            <Card key={classSlot.id} className="overflow-hidden">
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold text-base">{classSlot.className}</h3>
                      {classSlot.isUserEnrolled && userRole === "client" && (
                        <Badge variant="default" className="bg-blue-600 text-xs">
                          <CheckCircle className="w-3 h-3 mr-1" />
                          Enrolled
                        </Badge>
                      )}
                    </div>
                    <div className="flex items-center gap-3 text-sm text-gray-600 mb-2">
                      <span className="font-medium text-blue-600">{classSlot.day}</span>
                      <span className="flex items-center">
                        <Clock className="w-3.5 h-3.5 mr-1" />
                        {classSlot.time} ({classSlot.duration})
                      </span>
                    </div>
                    <div className="flex items-center text-sm text-gray-600">
                      <UserIcon className="w-3.5 h-3.5 mr-1" />
                      Coach: {classSlot.coach}
                    </div>
                  </div>
                  <div className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold ${getCapacityColor(classSlot.enrolled, classSlot.capacity)}`}>
                    <div className="flex items-center gap-1">
                      <Users className="w-3.5 h-3.5" />
                      {classSlot.enrolled}/{classSlot.capacity}
                    </div>
                  </div>
                </div>

                {/* Action Buttons Based on Role */}
                {userRole === "client" && (
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button
                        variant={classSlot.isUserEnrolled ? "outline" : "default"}
                        size="sm"
                        className="w-full"
                        disabled={!classSlot.isUserEnrolled && classSlot.enrolled >= classSlot.capacity}
                      >
                        {classSlot.isUserEnrolled ? "Unenroll" : classSlot.enrolled >= classSlot.capacity ? "Full" : "Enroll"}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>
                          {classSlot.isUserEnrolled ? "Unenroll from" : "Enroll in"} {classSlot.className}?
                        </AlertDialogTitle>
                        <AlertDialogDescription>
                          {classSlot.isUserEnrolled
                            ? `You will be removed from ${classSlot.className} on ${classSlot.day} at ${classSlot.time}.`
                            : `You will be enrolled in ${classSlot.className} on ${classSlot.day} at ${classSlot.time} with coach ${classSlot.coach}.`}
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={() => handleEnrollment(classSlot)}>
                          Confirm
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                )}

                {userRole === "admin" && (
                  <div className="grid grid-cols-2 gap-2">
                    <Button variant="outline" size="sm">
                      Edit Class
                    </Button>
                    <Button variant="outline" size="sm">
                      View Members
                    </Button>
                  </div>
                )}

                {userRole === "coach" && (
                  <div className="flex items-center justify-between pt-2 border-t">
                    <span className="text-xs text-gray-500">
                      Available slots: {classSlot.capacity - classSlot.enrolled}
                    </span>
                    <Button variant="outline" size="sm">
                      View Details
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}
