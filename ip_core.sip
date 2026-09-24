set_global_assignment -entity "ip_core" -library "lib_ip_core" -name IP_TOOL_NAME "altchip_id"
set_global_assignment -entity "ip_core" -library "lib_ip_core" -name IP_TOOL_VERSION "24.1"
set_global_assignment -entity "ip_core" -library "lib_ip_core" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ip_core" -name SPD_FILE [file join $::quartus(sip_path) "ip_core.spd"]

set_global_assignment -library "lib_ip_core" -name MISC_FILE [file join $::quartus(sip_path) "ip_core_sim/ip_core.v"]
set_global_assignment -library "lib_ip_core" -name MISC_FILE [file join $::quartus(sip_path) "ip_core_sim/altchip_id/altchip_id.v"]
