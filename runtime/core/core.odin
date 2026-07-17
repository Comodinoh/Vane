package Core

import "core:fmt"


NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import win   "vane:core/window"
import error "vane:error"
import gfx   "vane:graphics"
import gl    "vane:opengl"
import crash "vane:crash"

App_Proc_Struct :: struct($T: typeid) {
    app_proc: proc(data: ^T, app: ^App_State(T)) -> bool
}

app_proc :: proc(procedure: proc(data: ^$E, app: ^App_State(E)) -> bool) -> App_Proc_Struct(E){
    return App_Proc_Struct(E) {procedure}
}

App_State :: struct($T: typeid) {
    running: bool,
    window: win.Window,
    
    start: App_Proc_Struct(T),
    stop: App_Proc_Struct(T),
    update: App_Proc_Struct(T),
    data: T,
}

report_proc :: proc(state: ^crash.Crash_State) {
    
}

new :: proc(
    start: $T/App_Proc_Struct($E), 
    stop: T, 
    update: T,
    backend := gfx.Backend.OpenGL,
    title: string = "Vane Game", width: int = 1280, height: int = 720,
    ) -> (state: App_State(E), err : Maybe(error.Error)){
    fmt.println("Initialising app...")

    crash.get_state().report_proc = report_proc;

    fmt.println("Initialised crash report system")

    gfx.init(backend) or_return

    when gfx.OPENGL {
        gl.register()
        fmt.println("Registered OpenGL graphics API")
    }

    fmt.println("Registered graphics APIs")

    state.running = true

    state.start = start
    state.stop = stop
    state.update = update

    state.window = win.new(gfx.get_backend(), {title, width, height})
    win.init(&state.window) or_return

    fmt.println("Initialised app")
    return
}

start :: proc(state: ^App_State($T)) -> bool {
    return state.start.app_proc(&state.data, state)
}

stop :: proc(state: ^App_State($T)) -> bool{
    return state.stop.app_proc(&state.data, state)
}

update :: proc(state: ^App_State($T)) -> bool {
    return state.update.app_proc(&state.data, state)
}

run :: proc(state: ^App_State($T)){
    for !win.should_close(&state.window) {
        if !update(state){
            break
        }
    }
}

destroy :: proc(state: ^App_State($T)) {
    fmt.println("Destroying app")
    win.destroy(&state.window)
    fmt.println("Destroyed app")
}
