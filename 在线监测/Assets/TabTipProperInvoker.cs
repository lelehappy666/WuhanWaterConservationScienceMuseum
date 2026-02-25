#if UNITY_STANDALONE_WIN
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using UnityEngine;

public class TabTipProperInvoker : MonoBehaviour
{
    const string TABTIP_WND_CLASS = "IPTip_Main_Window";

    static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    const uint SWP_NOSIZE = 0x0001;
    const uint SWP_NOMOVE = 0x0002;
    const uint SWP_SHOWWINDOW = 0x0040;
    const uint SWP_NOACTIVATE = 0x0010;   // 不抢焦点
    const int SW_SHOW = 5;
    const int SW_RESTORE = 9;

    void Update()
    {
        //if (Input.GetMouseButtonDown(0))
        //    ShowTabTip();
    }

    public async void ShowTabTip()
    {
        IntPtr unityHwnd = GetUnityHwnd();

        // 1) 唤出
        try
        {
            Process.Start(new ProcessStartInfo { FileName = "ms-inputapp:", UseShellExecute = true });
        }
        catch { }

        // 2) 等窗口出现
        IntPtr tab = IntPtr.Zero;
        for (int i = 0; i < 60; i++)
        {
            tab = FindWindow(TABTIP_WND_CLASS, null);
            if (tab != IntPtr.Zero) break;
            await Task.Delay(50);
        }
        if (tab == IntPtr.Zero) return;

        // 3) 如果最小化/隐藏，先恢复
        ShowWindow(tab, SW_RESTORE);
        ShowWindow(tab, SW_SHOW);

        // 4) 强制把窗口移动到“当前鼠标所在屏幕”的底部
        MoveTabTipToVisibleArea(tab);

        // 5) 置顶（不激活，不抢焦点）
        SetWindowPos(tab, HWND_TOPMOST, 0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW | SWP_NOACTIVATE);

        // 6) 焦点回 Unity
        if (unityHwnd != IntPtr.Zero) SetForegroundWindow(unityHwnd);
    }

    static void MoveTabTipToVisibleArea(IntPtr hwnd)
    {
        // 当前鼠标在哪个屏幕，就用那个屏幕的工作区
        GetCursorPos(out POINT p);
        IntPtr hMon = MonitorFromPoint(p, MONITOR_DEFAULTTONEAREST);

        MONITORINFO mi = new MONITORINFO();
        mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        if (!GetMonitorInfo(hMon, ref mi)) return;

        // 取当前窗口大小
        GetWindowRect(hwnd, out RECT wr);
        int w = Math.Max(300, wr.Right - wr.Left);
        int h = Math.Max(200, wr.Bottom - wr.Top);

        // 放到底部居中（工作区，避开任务栏）
        int screenW = mi.rcWork.Right - mi.rcWork.Left;
        int screenH = mi.rcWork.Bottom - mi.rcWork.Top;

        int x = mi.rcWork.Left + (screenW - w) / 2;
        int y = mi.rcWork.Bottom - h;

        // 再做一次 clamp，确保不会出界
        x = Clamp(x, mi.rcWork.Left, mi.rcWork.Right - w);
        y = Clamp(y, mi.rcWork.Top, mi.rcWork.Bottom - h);

        SetWindowPos(hwnd, IntPtr.Zero, x, y, w, h, SWP_SHOWWINDOW | SWP_NOACTIVATE);
    }

    static int Clamp(int v, int min, int max)
    {
        if (v < min) return min;
        if (v > max) return max;
        return v;
    }

    static IntPtr GetUnityHwnd()
    {
        try
        {
            var h = Process.GetCurrentProcess().MainWindowHandle;
            if (h != IntPtr.Zero) return h;
        }
        catch { }
        return GetForegroundWindow();
    }

    // ---- WinAPI ----
    const uint MONITOR_DEFAULTTONEAREST = 2;

    [StructLayout(LayoutKind.Sequential)]
    struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    struct MONITORINFO
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
    }

    [DllImport("user32.dll")] static extern IntPtr FindWindow(string c, string n);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT pt, uint dwFlags);
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);
}
#endif
