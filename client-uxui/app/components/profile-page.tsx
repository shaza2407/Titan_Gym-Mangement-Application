import { useState } from "react";
import { ArrowLeft, User, Mail, Phone, Calendar, MapPin, Save, Camera } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Textarea } from "./ui/textarea";
import { Avatar, AvatarFallback } from "./ui/avatar";
import { toast } from "sonner";

interface ProfilePageProps {
  onBack: () => void;
  userRole: "client" | "coach" | "admin";
  userName: string;
}

export function ProfilePage({ onBack, userRole, userName }: ProfilePageProps) {
  const [profileData, setProfileData] = useState({
    name: userName,
    email: userRole === "client" ? "john.doe@email.com" : userRole === "coach" ? "sarah.johnson@email.com" : "admin@titan.com",
    phone: "+1 (555) 123-4567",
    dateOfBirth: "1990-05-15",
    address: "123 Main Street, New York, NY",
    bio: userRole === "coach"
      ? "Certified personal trainer with 8+ years of experience helping clients achieve their fitness goals."
      : userRole === "admin"
      ? "Gym administrator managing operations and member services."
      : "Fitness enthusiast passionate about strength training and healthy living.",
    emergencyContact: "Jane Doe - +1 (555) 987-6543",
    specializations: userRole === "coach" ? "Strength Training, HIIT, Yoga" : "",
    certifications: userRole === "coach" ? "NASM-CPT, ACE, RYT-200" : ""
  });

  const handleSave = () => {
    // Mock save functionality
    toast.success("Profile updated successfully!");
  };

  const handleChange = (field: string, value: string) => {
    setProfileData({
      ...profileData,
      [field]: value
    });
  };

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map(n => n[0])
      .join("")
      .toUpperCase();
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
              <h1 className="text-lg font-semibold">My Profile</h1>
              <p className="text-xs text-gray-600">Update your personal information</p>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* Avatar Section */}
        <Card className="mb-6">
          <CardContent className="p-6">
            <div className="flex flex-col items-center">
              <div className="relative mb-4">
                <Avatar className="w-24 h-24 border-4 border-white shadow-lg">
                  <AvatarFallback className={`text-2xl ${
                    userRole === "admin"
                      ? "bg-gradient-to-br from-indigo-400 to-indigo-600"
                      : userRole === "coach"
                      ? "bg-gradient-to-br from-purple-400 to-purple-600"
                      : "bg-gradient-to-br from-green-400 to-green-600"
                  } text-white`}>
                    {getInitials(profileData.name)}
                  </AvatarFallback>
                </Avatar>
                <Button
                  size="sm"
                  className="absolute bottom-0 right-0 rounded-full w-8 h-8 p-0"
                >
                  <Camera className="w-4 h-4" />
                </Button>
              </div>
              <h2 className="text-xl font-semibold mb-1">{profileData.name}</h2>
              <p className="text-sm text-gray-600 capitalize">{userRole}</p>
            </div>
          </CardContent>
        </Card>

        {/* Basic Information */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center">
              <User className={`w-5 h-5 mr-2 ${
                userRole === "admin" ? "text-indigo-600" :
                userRole === "coach" ? "text-purple-600" :
                "text-green-600"
              }`} />
              Basic Information
            </CardTitle>
            <CardDescription className="text-sm">Your personal details</CardDescription>
          </CardHeader>
          <CardContent className="pb-4 space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Full Name</Label>
              <Input
                id="name"
                className="h-11"
                value={profileData.name}
                onChange={(e) => handleChange("name", e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <Input
                id="email"
                type="email"
                className="h-11"
                value={profileData.email}
                onChange={(e) => handleChange("email", e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">Phone Number</Label>
              <Input
                id="phone"
                type="tel"
                className="h-11"
                value={profileData.phone}
                onChange={(e) => handleChange("phone", e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="dateOfBirth">Date of Birth</Label>
              <Input
                id="dateOfBirth"
                type="date"
                className="h-11"
                value={profileData.dateOfBirth}
                onChange={(e) => handleChange("dateOfBirth", e.target.value)}
              />
            </div>
          </CardContent>
        </Card>

        {/* Address */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center">
              <MapPin className={`w-5 h-5 mr-2 ${
                userRole === "admin" ? "text-indigo-600" :
                userRole === "coach" ? "text-purple-600" :
                "text-green-600"
              }`} />
              Address
            </CardTitle>
            <CardDescription className="text-sm">Your location information</CardDescription>
          </CardHeader>
          <CardContent className="pb-4 space-y-4">
            <div className="space-y-2">
              <Label htmlFor="address">Street Address</Label>
              <Textarea
                id="address"
                className="min-h-20"
                value={profileData.address}
                onChange={(e) => handleChange("address", e.target.value)}
              />
            </div>
          </CardContent>
        </Card>

        {/* Bio */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">About Me</CardTitle>
            <CardDescription className="text-sm">Tell us about yourself</CardDescription>
          </CardHeader>
          <CardContent className="pb-4 space-y-4">
            <div className="space-y-2">
              <Label htmlFor="bio">Bio</Label>
              <Textarea
                id="bio"
                className="min-h-24"
                value={profileData.bio}
                onChange={(e) => handleChange("bio", e.target.value)}
              />
            </div>
          </CardContent>
        </Card>

        {/* Coach-specific fields */}
        {userRole === "coach" && (
          <Card className="mb-6">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg">Professional Information</CardTitle>
              <CardDescription className="text-sm">Your coaching credentials</CardDescription>
            </CardHeader>
            <CardContent className="pb-4 space-y-4">
              <div className="space-y-2">
                <Label htmlFor="specializations">Specializations</Label>
                <Input
                  id="specializations"
                  className="h-11"
                  placeholder="e.g., Strength Training, Yoga"
                  value={profileData.specializations}
                  onChange={(e) => handleChange("specializations", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="certifications">Certifications</Label>
                <Input
                  id="certifications"
                  className="h-11"
                  placeholder="e.g., NASM-CPT, ACE"
                  value={profileData.certifications}
                  onChange={(e) => handleChange("certifications", e.target.value)}
                />
              </div>
            </CardContent>
          </Card>
        )}

        {/* Emergency Contact (Client only) */}
        {userRole === "client" && (
          <Card className="mb-6">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg">Emergency Contact</CardTitle>
              <CardDescription className="text-sm">In case of emergency</CardDescription>
            </CardHeader>
            <CardContent className="pb-4 space-y-4">
              <div className="space-y-2">
                <Label htmlFor="emergencyContact">Contact Information</Label>
                <Input
                  id="emergencyContact"
                  className="h-11"
                  placeholder="Name - Phone Number"
                  value={profileData.emergencyContact}
                  onChange={(e) => handleChange("emergencyContact", e.target.value)}
                />
              </div>
            </CardContent>
          </Card>
        )}

        {/* Save Button */}
        <Button onClick={handleSave} className="w-full h-12 text-base">
          <Save className="w-5 h-5 mr-2" />
          Save Changes
        </Button>
      </main>
    </div>
  );
}
