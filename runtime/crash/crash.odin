package Crash

import "core:fmt"

Crash_Report :: struct {
    header: string,
    footer: string,
    body: string
}

Crash_State :: struct {
    reports: [dynamic]Crash_Report,
    report_proc: proc(state: ^Crash_State), 
}

@(private)
state := Crash_State{};

get_state :: proc() -> ^Crash_State {
    return &state
}

todo :: proc(format: string = "TODO", args: ..any, loc := #caller_location) {
    panic(fmt.aprintf(format, ..args), loc);
}

append_crash :: proc(report: Crash_Report) {
    append(&state.reports, report)
    if state.report_proc != nil {
        state.report_proc(&state)
    }
}
