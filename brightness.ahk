#Requires AutoHotkey v2.0+
#SingleInstance Force
#Include "brightness_configuration.ahk"

initialize_brightness_control()

exit_after_notification() {
    ExitApp()
}

initialize_brightness_control() {
    try {
        configuration := load_configuration()
        validate_configuration(configuration)
        register_hotkeys(configuration)
    } catch Error as startup_error {
        notify_error("Startup failed: " . startup_error.Message)
        SetTimer(exit_after_notification, -5000)
    }
}

handle_brightness_action(configuration, definition, *) {
    Critical("On")
    try {
        apply_brightness(configuration, definition)
    } catch Error as brightness_error {
        notify_error("Brightness update failed: " . brightness_error.Message)
    } finally {
        Critical("Off")
    }
}

apply_brightness(configuration, definition) {
    wmi_service := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI")
    active_monitor := find_active_brightness_monitor(wmi_service)
    brightness_method := find_brightness_method(wmi_service, active_monitor.InstanceName)
    current_brightness := active_monitor.CurrentBrightness + 0
    ideal_brightness := calculate_ideal_brightness(configuration, definition, current_brightness)
    target_brightness := select_supported_brightness(configuration, active_monitor.Level, current_brightness, ideal_brightness)
    if (target_brightness != current_brightness)
        set_brightness(brightness_method, target_brightness)
    show_brightness_osd()
}

find_active_brightness_monitor(wmi_service) {
    active_monitors := wmi_service.ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=TRUE")
    for active_monitor in active_monitors
        return active_monitor
    throw Error("No active WMI brightness monitor was found.")
}

find_brightness_method(wmi_service, instance_name) {
    brightness_methods := wmi_service.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=TRUE")
    for brightness_method in brightness_methods {
        if (brightness_method.InstanceName = instance_name)
            return brightness_method
    }
    throw Error("No matching WMI brightness method was found.")
}

calculate_ideal_brightness(configuration, definition, current_brightness) {
    ideal_brightness := definition.value
    if (definition.kind = "relative")
        ideal_brightness := current_brightness + definition.value
    return Min(configuration.maximum, Max(configuration.minimum, ideal_brightness))
}

select_supported_brightness(configuration, supported_levels, current_brightness, ideal_brightness) {
    direction := compare_brightness(ideal_brightness, current_brightness)
    selection := {allowed_count: 0, has_target: false, target: 0, distance: 0}
    for supported_level in supported_levels
        consider_supported_level(configuration, selection, supported_level + 0, current_brightness, ideal_brightness, direction)
    if (selection.allowed_count = 0)
        throw Error("The monitor has no supported brightness levels in the configured range.")
    if !selection.has_target
        return current_brightness
    return selection.target
}

compare_brightness(first_brightness, second_brightness) {
    if (first_brightness > second_brightness)
        return 1
    if (first_brightness < second_brightness)
        return -1
    return 0
}

consider_supported_level(configuration, selection, supported_level, current_brightness, ideal_brightness, direction) {
    if (supported_level < configuration.minimum || supported_level > configuration.maximum)
        return
    selection.allowed_count += 1
    if !is_directional_candidate(supported_level, current_brightness, direction)
        return
    candidate_distance := Abs(supported_level - ideal_brightness)
    if !is_better_candidate(selection, supported_level, candidate_distance, direction)
        return
    selection.has_target := true
    selection.target := supported_level
    selection.distance := candidate_distance
}

is_directional_candidate(supported_level, current_brightness, direction) {
    if (direction > 0)
        return supported_level > current_brightness
    if (direction < 0)
        return supported_level < current_brightness
    return false
}

is_better_candidate(selection, supported_level, candidate_distance, direction) {
    if !selection.has_target
        return true
    if (candidate_distance < selection.distance)
        return true
    if (candidate_distance > selection.distance)
        return false
    return direction > 0 ? supported_level > selection.target : supported_level < selection.target
}

set_brightness(brightness_method, target_brightness) {
    wmi_result_code := brightness_method.WmiSetBrightness(0, target_brightness)
    ; Some WMI providers apply brightness without exposing a method status through AutoHotkey.
    if (wmi_result_code = "")
        return
    if !IsInteger(wmi_result_code)
        throw Error("WMI returned an invalid status after setting brightness " . target_brightness . ".")
    if (wmi_result_code != 0)
        throw Error("WMI rejected brightness " . target_brightness . " (code " . wmi_result_code . ").")
}

notify_error(message) {
    TrayTip(message, "Screen Brightness Control", "Iconx")
    SetTimer(() => TrayTip(), -5000)
}

show_brightness_osd() {
    static notified_osd_failure := false
    try {
        post_brightness_osd()
    } catch Error as osd_error {
        if notified_osd_failure
            return
        notified_osd_failure := true
        notify_error("Brightness changed, but OSD is unavailable: " . osd_error.Message)
    }
}

post_brightness_osd() {
    static shell_hook_message := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
    if !shell_hook_message
        throw Error("The SHELLHOOK window message could not be registered.")
    native_window_handle := find_native_window_handle()
    post_succeeded := DllCall("PostMessage", "Ptr", native_window_handle, "UInt", shell_hook_message, "Ptr", 0x37, "Ptr", 0)
    if !post_succeeded
        throw Error("PostMessage failed with Windows error " . A_LastError . ".")
}

find_native_window_handle() {
    native_window_handle := find_native_window()
    if native_window_handle
        return native_window_handle
    create_native_window_host()
    native_window_handle := find_native_window()
    if !native_window_handle
        throw Error("NativeHWNDHost was not found.")
    return native_window_handle
}

find_native_window() {
    return DllCall("FindWindow", "Str", "NativeHWNDHost", "Str", "", "Ptr")
}

create_native_window_host() {
    shell_provider := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}")
    flyout_display := ComObjQuery(shell_provider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}")
    if flyout_display
        ComCall(3, flyout_display, "Int", 0, "UInt", 0)
}
