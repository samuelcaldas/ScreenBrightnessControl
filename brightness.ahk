AdjustScreenBrightness(step) {
    service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
    monitors := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=TRUE")
    monMethods := ComObjGet(service).ExecQuery("SELECT * FROM wmiMonitorBrightNessMethods WHERE Active=TRUE")

    for i in monitors {
        curt := i.CurrentBrightness
        break
    }
    
    toSet := curt + step
    if toSet < 0 or toSet > 100
        return

    for i in monMethods {
        i.WmiSetBrightness(1, curt+step)
        break
    }
}

#,::
  KeyWait `,
  AdjustScreenBrightness(-3)
  Return
  
#.::
  KeyWait .
  AdjustScreenBrightness(3)
  Return