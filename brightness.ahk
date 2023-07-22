#,::
AdjustScreenBrightness(-3)
Return

#.::
AdjustScreenBrightness(3)
Return

AdjustScreenBrightness(step) {
    static service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
    monitors := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=TRUE")
    monMethods := ComObjGet(service).ExecQuery("SELECT * FROM wmiMonitorBrightNessMethods WHERE Active=TRUE")
    for i in monitors {
        curr := i.CurrentBrightness
        break
    }
    toSet := curr + step
    if (toSet < 10)
        toSet := 10
    if (toSet > 100)
        toSet := 100
    for i in monMethods {
        i.WmiSetBrightness(1, toSet)
        break
    }
    BrightnessOSD()
}

BrightnessOSD() {
    static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "PostMessageW" : "PostMessageA", "Ptr")
        , WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
    static FindWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "FindWindowW" : "FindWindowA", "Ptr")
    HWND := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")
    IF !(HWND) {
        try IF ((shellProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}"))) {
            try IF ((flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}"))) {
                DllCall(NumGet(NumGet(flyoutDisp + 0) + 3 * A_PtrSize), "Ptr", flyoutDisp, "Int", 0, "UInt", 0)
                    , ObjRelease(flyoutDisp)
            }
            ObjRelease(shellProvider)
        }
        HWND := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")
    }
    DllCall(PostMessagePtr, "Ptr", HWND, "UInt", WM_SHELLHOOK, "Ptr", 0x37, "Ptr", 0)
}