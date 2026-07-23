load_configuration() {
    file_path := A_ScriptDir . "\brightness.ini"
    configuration := {}
    configuration.minimum := read_ini_value(file_path, "Brightness", "Minimum", "0")
    configuration.maximum := read_ini_value(file_path, "Brightness", "Maximum", "100")
    configuration.fine_step := read_ini_value(file_path, "Brightness", "FineStep", "3")
    configuration.coarse_step := read_ini_value(file_path, "Brightness", "CoarseStep", "10")
    configuration.fine_decrease := read_ini_value(file_path, "Hotkeys", "FineDecrease", "#,")
    configuration.fine_increase := read_ini_value(file_path, "Hotkeys", "FineIncrease", "#.")
    configuration.coarse_decrease := read_ini_value(file_path, "Hotkeys", "CoarseDecrease", "^!Down")
    configuration.coarse_increase := read_ini_value(file_path, "Hotkeys", "CoarseIncrease", "^!Up")
    configuration.set_minimum := read_ini_value(file_path, "Hotkeys", "SetMinimum", "^!End")
    configuration.set_maximum := read_ini_value(file_path, "Hotkeys", "SetMaximum", "^!Home")
    return configuration
}

read_ini_value(file_path, section_name, key_name, default_value) {
    configured_value := IniRead(file_path, section_name, key_name, default_value)
    return Trim(configured_value)
}

validate_configuration(configuration) {
    normalize_numeric_configuration(configuration)
    validate_brightness_ranges(configuration)
    validate_distinct_hotkeys(create_hotkey_definitions(configuration))
}

normalize_numeric_configuration(configuration) {
    configuration.minimum := require_integer(configuration.minimum, "Minimum")
    configuration.maximum := require_integer(configuration.maximum, "Maximum")
    configuration.fine_step := require_integer(configuration.fine_step, "FineStep")
    configuration.coarse_step := require_integer(configuration.coarse_step, "CoarseStep")
}

require_integer(configured_value, setting_name) {
    if !RegExMatch(configured_value, "^-?\d+$")
        throw Error(setting_name . " must be an integer.")
    return configured_value + 0
}

validate_brightness_ranges(configuration) {
    if (configuration.minimum < 0 || configuration.minimum >= configuration.maximum)
        throw Error("Minimum must be between 0 and Maximum - 1.")
    if (configuration.maximum > 100)
        throw Error("Maximum must not exceed 100.")
    if (configuration.fine_step <= 0 || configuration.coarse_step <= 0)
        throw Error("Brightness steps must be positive integers.")
}

validate_distinct_hotkeys(definitions) {
    normalized_hotkeys := Map()
    for definition in definitions {
        if (definition.key = "")
            throw Error("Hotkeys must not be empty.")
        normalized_hotkey := normalize_hotkey(definition.key)
        if normalized_hotkeys.Has(normalized_hotkey)
            throw Error("Hotkeys must be distinct: " . definition.key)
        normalized_hotkeys[normalized_hotkey] := true
    }
}

normalize_hotkey(hotkey) {
    remaining_hotkey := StrLower(hotkey)
    remaining_hotkey := StrReplace(StrReplace(remaining_hotkey, "~"), "$")
    normalized_hotkey := ""
    for modifier in ["*", "#", "^", "!", "+"] {
        if !InStr(remaining_hotkey, modifier)
            continue
        normalized_hotkey .= modifier
        remaining_hotkey := StrReplace(remaining_hotkey, modifier)
    }
    return normalized_hotkey . remaining_hotkey
}

create_hotkey_definitions(configuration) {
    return [
        {key: configuration.fine_decrease, kind: "relative", value: -configuration.fine_step},
        {key: configuration.fine_increase, kind: "relative", value: configuration.fine_step},
        {key: configuration.coarse_decrease, kind: "relative", value: -configuration.coarse_step},
        {key: configuration.coarse_increase, kind: "relative", value: configuration.coarse_step},
        {key: configuration.set_minimum, kind: "absolute", value: configuration.minimum},
        {key: configuration.set_maximum, kind: "absolute", value: configuration.maximum}
    ]
}

register_hotkeys(configuration) {
    hotkey_registrations := []
    try {
        for definition in create_hotkey_definitions(configuration)
            hotkey_registrations.Push(stage_hotkey(configuration, definition))
        enable_hotkeys(hotkey_registrations)
    } catch Error as registration_error {
        disable_hotkeys(hotkey_registrations)
        throw
    }
}

stage_hotkey(configuration, definition) {
    hotkey_handler := handle_brightness_action.Bind(configuration, definition)
    Hotkey(definition.key, hotkey_handler, "Off")
    return {key: definition.key, handler: hotkey_handler}
}

enable_hotkeys(hotkey_registrations) {
    for hotkey_registration in hotkey_registrations
        Hotkey(hotkey_registration.key, "On")
}

disable_hotkeys(hotkey_registrations) {
    for hotkey_registration in hotkey_registrations
        Hotkey(hotkey_registration.key, "Off")
}
