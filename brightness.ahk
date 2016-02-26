#W::
	KeyWait LShift
	Send !{F4}
	Return

#Enter::
	KeyWait Enter
	Run C:\softwares\conemu\conemu64.exe
	Return

#N::
	KeyWait N
	Run notepad
	Return

#,::
  AdjustScreenBrightness(-3)
  Return
  
#.::
  AdjustScreenBrightness(3)
  Return
  
AdjustScreenBrightness(step) {
    service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
    monitors := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=TRUE")
    monMethods := ComObjGet(service).ExecQuery("SELECT * FROM wmiMonitorBrightNessMethods WHERE Active=TRUE")
    minBrightness := 5  ; level below this is identical to this

    for i in monitors {
        curt := i.CurrentBrightness
        break
    }
    toSet := curt + step
    if (toSet < 0 or toSet > 100)
        return
    if (toSet < minBrightness)  ; parenthesis is necessary here
        toSet := minBrightness

    for i in monMethods {
        i.WmiSetBrightness(1, toSet)
        break
    }
}