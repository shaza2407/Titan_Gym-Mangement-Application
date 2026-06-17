import { useState, useEffect } from "react";
import { ArrowLeft, QrCode, CheckCircle, XCircle, Loader2 } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Badge } from "../ui/badge";
import { toast } from "sonner";

interface ScanPageProps {
  onBack: () => void;
}

export function ScanPage({ onBack }: ScanPageProps) {
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<"success" | "error" | null>(null);
  const [lastScan, setLastScan] = useState<{
    time: string;
    type: "check-in" | "check-out";
  } | null>({
    time: "07:15 AM",
    type: "check-in"
  });

  const handleScan = () => {
    setIsScanning(true);
    setScanResult(null);

    // Simulate QR code scanning
    setTimeout(() => {
      setIsScanning(false);
      setScanResult("success");
      
      const now = new Date();
      const time = now.toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit"
      });
      
      const newType = lastScan?.type === "check-in" ? "check-out" : "check-in";
      setLastScan({ time, type: newType });
      
      toast.success(
        newType === "check-in" ? "Checked in successfully!" : "Checked out successfully!",
        {
          description: `Time: ${time}`
        }
      );
    }, 2000);
  };

  const recentScans = [
    { date: "Mar 9, 2026", time: "07:15 AM", type: "check-in" as const },
    { date: "Mar 8, 2026", time: "06:45 AM", type: "check-in" as const },
    { date: "Mar 7, 2026", time: "07:30 AM", type: "check-in" as const },
    { date: "Mar 6, 2026", time: "08:00 AM", type: "check-in" as const },
    { date: "Mar 5, 2026", time: "07:00 AM", type: "check-in" as const }
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
              <h1 className="text-lg font-semibold">QR Code Check-in</h1>
              <p className="text-xs text-gray-600">Scan to check in or check out</p>
            </div>
          </div>
        </div>
      </header>

      <main className="px-4 py-6">
        {/* Current Status */}
        {lastScan && (
          <Card className="mb-6 border-green-200 bg-green-50">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-semibold mb-1">
                    Last {lastScan.type === "check-in" ? "Check-In" : "Check-Out"}
                  </p>
                  <p className="text-xs text-gray-600">{lastScan.time} - Today</p>
                </div>
                <CheckCircle className="w-8 h-8 text-green-600" />
              </div>
            </CardContent>
          </Card>
        )}

        {/* Scanner Card */}
        <Card className="mb-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Scan QR Code</CardTitle>
            <CardDescription className="text-sm">
              Point your camera at the gym's QR code
            </CardDescription>
          </CardHeader>
          <CardContent className="pb-6">
            <div className="relative">
              {/* Scanner Visual */}
              <div className="bg-gradient-to-br from-green-50 to-emerald-50 border-2 border-green-200 rounded-lg p-8 flex flex-col items-center justify-center min-h-[300px]">
                {!isScanning && !scanResult && (
                  <>
                    <QrCode className="w-32 h-32 text-green-600 mb-4" />
                    <p className="text-center text-sm text-gray-600 mb-2">
                      Ready to scan
                    </p>
                    <p className="text-center text-xs text-gray-500">
                      Position the QR code within the frame
                    </p>
                  </>
                )}

                {isScanning && (
                  <>
                    <Loader2 className="w-32 h-32 text-green-600 animate-spin mb-4" />
                    <p className="text-center text-sm text-gray-600">
                      Scanning...
                    </p>
                  </>
                )}

                {scanResult === "success" && !isScanning && (
                  <>
                    <div className="bg-green-600 p-6 rounded-full mb-4">
                      <CheckCircle className="w-20 h-20 text-white" />
                    </div>
                    <p className="text-center text-lg font-semibold text-green-600 mb-1">
                      Success!
                    </p>
                    <p className="text-center text-sm text-gray-600">
                      {lastScan?.type === "check-out" ? "Checked out" : "Checked in"} at {lastScan?.time}
                    </p>
                  </>
                )}

                {scanResult === "error" && !isScanning && (
                  <>
                    <div className="bg-red-600 p-6 rounded-full mb-4">
                      <XCircle className="w-20 h-20 text-white" />
                    </div>
                    <p className="text-center text-lg font-semibold text-red-600 mb-1">
                      Failed
                    </p>
                    <p className="text-center text-sm text-gray-600">
                      Unable to scan QR code. Please try again.
                    </p>
                  </>
                )}
              </div>

              {/* Scan Button */}
              <Button
                onClick={handleScan}
                disabled={isScanning}
                className="w-full mt-6 h-12 text-base"
              >
                {isScanning ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Scanning...
                  </>
                ) : (
                  <>
                    <QrCode className="w-5 h-5 mr-2" />
                    {scanResult ? "Scan Again" : "Start Scanning"}
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Recent Scans */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Recent Check-ins</CardTitle>
            <CardDescription className="text-sm">Your attendance history</CardDescription>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="space-y-2">
              {recentScans.map((scan, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-3 border rounded-lg"
                >
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                    <div>
                      <p className="text-sm font-semibold">{scan.time}</p>
                      <p className="text-xs text-gray-600">{scan.date}</p>
                    </div>
                  </div>
                  <Badge variant="outline" className="text-xs">
                    {scan.type}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
