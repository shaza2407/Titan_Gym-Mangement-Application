import { useState } from "react";
import { ArrowLeft, Target, Sparkles, Dumbbell, TrendingUp, Download, RefreshCw } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../ui/select";
import { Badge } from "../ui/badge";
import { toast } from "sonner";

interface TrainingPlansPageProps {
  onBack: () => void;
}

interface WorkoutPlan {
  id: number;
  name: string;
  goal: string;
  level: string;
  duration: string;
  createdDate: string;
  exercises: Exercise[];
}

interface Exercise {
  name: string;
  sets: number;
  reps: string;
  rest: string;
  day: string;
}

export function TrainingPlansPage({ onBack }: TrainingPlansPageProps) {
  const [isGenerating, setIsGenerating] = useState(false);
  const [showGenerator, setShowGenerator] = useState(false);
  const [formData, setFormData] = useState({
    goal: "",
    level: "",
    duration: "",
    focus: ""
  });

  const [savedPlans, setSavedPlans] = useState<WorkoutPlan[]>([
    {
      id: 1,
      name: "Beginner Full Body Strength",
      goal: "Build Muscle",
      level: "Beginner",
      duration: "4 weeks",
      createdDate: "Mar 1, 2026",
      exercises: [
        { name: "Squats", sets: 3, reps: "10-12", rest: "60s", day: "Monday" },
        { name: "Push-ups", sets: 3, reps: "8-10", rest: "60s", day: "Monday" },
        { name: "Deadlifts", sets: 3, reps: "8-10", rest: "90s", day: "Wednesday" },
        { name: "Pull-ups", sets: 3, reps: "6-8", rest: "90s", day: "Wednesday" },
        { name: "Lunges", sets: 3, reps: "12 each", rest: "60s", day: "Friday" },
        { name: "Bench Press", sets: 3, reps: "10-12", rest: "90s", day: "Friday" }
      ]
    }
  ]);

  const handleGenerate = () => {
    if (!formData.goal || !formData.level || !formData.duration) {
      toast.error("Please fill in all required fields");
      return;
    }

    setIsGenerating(true);

    // Simulate AI generation
    setTimeout(() => {
      const newPlan: WorkoutPlan = {
        id: Date.now(),
        name: `${formData.level} ${formData.goal} Plan`,
        goal: formData.goal,
        level: formData.level,
        duration: formData.duration,
        createdDate: new Date().toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }),
        exercises: generateExercises(formData)
      };

      setSavedPlans([newPlan, ...savedPlans]);
      setIsGenerating(false);
      setShowGenerator(false);
      setFormData({ goal: "", level: "", duration: "", focus: "" });
      toast.success("Training plan generated!", {
        description: "Your personalized workout plan is ready"
      });
    }, 3000);
  };

  const generateExercises = (data: typeof formData): Exercise[] => {
    // Mock exercise generation based on form data
    const exercises: Exercise[] = [];
    const days = ["Monday", "Wednesday", "Friday"];
    
    if (data.goal === "Build Muscle") {
      exercises.push(
        { name: "Squats", sets: 4, reps: "8-10", rest: "90s", day: "Monday" },
        { name: "Bench Press", sets: 4, reps: "8-10", rest: "90s", day: "Monday" },
        { name: "Deadlifts", sets: 4, reps: "6-8", rest: "120s", day: "Wednesday" },
        { name: "Overhead Press", sets: 3, reps: "8-10", rest: "90s", day: "Wednesday" },
        { name: "Romanian Deadlifts", sets: 3, reps: "10-12", rest: "60s", day: "Friday" },
        { name: "Pull-ups", sets: 3, reps: "6-8", rest: "90s", day: "Friday" }
      );
    } else if (data.goal === "Lose Weight") {
      exercises.push(
        { name: "Jump Rope", sets: 3, reps: "2 min", rest: "30s", day: "Monday" },
        { name: "Burpees", sets: 3, reps: "15", rest: "45s", day: "Monday" },
        { name: "Running", sets: 1, reps: "20 min", rest: "-", day: "Wednesday" },
        { name: "Mountain Climbers", sets: 3, reps: "20", rest: "30s", day: "Wednesday" },
        { name: "HIIT Circuit", sets: 4, reps: "3 min", rest: "60s", day: "Friday" },
        { name: "Box Jumps", sets: 3, reps: "12", rest: "60s", day: "Friday" }
      );
    } else {
      exercises.push(
        { name: "Yoga Flow", sets: 1, reps: "20 min", rest: "-", day: "Monday" },
        { name: "Light Cardio", sets: 1, reps: "15 min", rest: "-", day: "Wednesday" },
        { name: "Stretching", sets: 1, reps: "15 min", rest: "-", day: "Friday" }
      );
    }

    return exercises;
  };

  const downloadPlan = (plan: WorkoutPlan) => {
    toast.success("Plan downloaded!", {
      description: "Check your downloads folder"
    });
  };

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
              <h1 className="text-lg font-semibold">Training Plans</h1>
              <p className="text-xs text-gray-600">AI-powered personalized workouts</p>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* AI Info Card */}
        <Card className="mb-6 bg-gradient-to-br from-purple-50 to-indigo-50 border-purple-200">
          <CardContent className="p-4">
            <div className="flex items-start space-x-3">
              <Sparkles className="w-6 h-6 text-purple-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-semibold text-base mb-1">AI-Powered Training Plans</h3>
                <p className="text-sm text-gray-700">
                  Generate personalized workout plans based on your goals, fitness level, and preferences. 
                  Our AI creates customized routines just for you.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Generate Button */}
        {!showGenerator ? (
          <Button 
            onClick={() => setShowGenerator(true)}
            className="w-full mb-6 h-12 text-base"
          >
            <Sparkles className="w-5 h-5 mr-2" />
            Generate New Training Plan
          </Button>
        ) : (
          <Card className="mb-6 border-green-200">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg">Generate Training Plan</CardTitle>
              <CardDescription className="text-sm">Tell us about your fitness goals</CardDescription>
            </CardHeader>
            <CardContent className="pb-4">
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="goal">Fitness Goal</Label>
                  <Select value={formData.goal} onValueChange={(value) => setFormData({ ...formData, goal: value })}>
                    <SelectTrigger className="h-11">
                      <SelectValue placeholder="Select your goal" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Build Muscle">Build Muscle</SelectItem>
                      <SelectItem value="Lose Weight">Lose Weight</SelectItem>
                      <SelectItem value="Improve Endurance">Improve Endurance</SelectItem>
                      <SelectItem value="General Fitness">General Fitness</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="level">Fitness Level</Label>
                  <Select value={formData.level} onValueChange={(value) => setFormData({ ...formData, level: value })}>
                    <SelectTrigger className="h-11">
                      <SelectValue placeholder="Select your level" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Beginner">Beginner</SelectItem>
                      <SelectItem value="Intermediate">Intermediate</SelectItem>
                      <SelectItem value="Advanced">Advanced</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="duration">Program Duration</Label>
                  <Select value={formData.duration} onValueChange={(value) => setFormData({ ...formData, duration: value })}>
                    <SelectTrigger className="h-11">
                      <SelectValue placeholder="Select duration" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="2 weeks">2 weeks</SelectItem>
                      <SelectItem value="4 weeks">4 weeks</SelectItem>
                      <SelectItem value="8 weeks">8 weeks</SelectItem>
                      <SelectItem value="12 weeks">12 weeks</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="focus">Specific Focus (Optional)</Label>
                  <Input
                    id="focus"
                    placeholder="e.g., Upper body, Core, Legs"
                    className="h-11"
                    value={formData.focus}
                    onChange={(e) => setFormData({ ...formData, focus: e.target.value })}
                  />
                </div>

                <div className="flex space-x-3">
                  <Button 
                    onClick={handleGenerate}
                    disabled={isGenerating}
                    className="flex-1 h-11"
                  >
                    {isGenerating ? (
                      <>
                        <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Sparkles className="w-4 h-4 mr-2" />
                        Generate
                      </>
                    )}
                  </Button>
                  <Button 
                    onClick={() => setShowGenerator(false)}
                    variant="outline"
                    className="h-11"
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Saved Plans */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">My Training Plans</CardTitle>
            <CardDescription className="text-sm">Your saved workout programs</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="space-y-3">
              {savedPlans.map((plan) => (
                <Card key={plan.id} className="border-green-200">
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <h3 className="font-semibold text-base mb-2">{plan.name}</h3>
                        <div className="flex flex-wrap gap-2 mb-3">
                          <Badge variant="outline" className="text-xs">
                            {plan.goal}
                          </Badge>
                          <Badge variant="outline" className="text-xs">
                            {plan.level}
                          </Badge>
                          <Badge variant="outline" className="text-xs">
                            {plan.duration}
                          </Badge>
                        </div>
                        <p className="text-xs text-gray-600 mb-3">Created: {plan.createdDate}</p>
                        
                        <div className="space-y-2">
                          <p className="text-xs font-semibold text-gray-700">Exercises:</p>
                          {plan.exercises.slice(0, 3).map((exercise, idx) => (
                            <div key={idx} className="flex items-center justify-between text-xs bg-white p-2 rounded border">
                              <div className="flex items-center space-x-2 flex-1">
                                <Dumbbell className="w-3 h-3 text-green-600" />
                                <span className="font-semibold">{exercise.name}</span>
                              </div>
                              <span className="text-gray-600">{exercise.sets} × {exercise.reps}</span>
                            </div>
                          ))}
                          {plan.exercises.length > 3 && (
                            <p className="text-xs text-gray-500 text-center">
                              +{plan.exercises.length - 3} more exercises
                            </p>
                          )}
                        </div>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => downloadPlan(plan)}
                      className="w-full h-9"
                    >
                      <Download className="w-4 h-4 mr-1" />
                      Download Full Plan
                    </Button>
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
