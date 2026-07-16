package Core

import "core:fmt"


NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import win   "vane:core/window"
import error "vane:error"
import gfx   "vane:graphics"
import gl    "vane:opengl"
import crash "vane:crash"


App_Proc :: proc(app: ^App_State) -> bool

App_State :: struct {
    running: bool,
    window: win.Window,
    
    start: App_Proc,
    stop: App_Proc,
    update: App_Proc,
}

report_proc :: proc(state: ^crash.Crash_State) {
    
}

new :: proc( 
    start: App_Proc, 
    stop: App_Proc, 
    update: App_Proc,
    backend := gfx.Backend.OpenGL,
    title: string = "Vane Game", width: int = 1280, height: int = 720,
    ) -> (state: App_State, err : Maybe(error.Error)){
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

start :: proc(state: ^App_State) -> bool {
    return state.start(state)
}

stop :: proc(state: ^App_State) -> bool{
    return state.stop(state)
}

update :: proc(state: ^App_State) -> bool {
    return state.update(state)
}

run :: proc(state: ^App_State){
    for !win.should_close(&state.window) {
        if !update(state){
            break
        }
    }
}

destroy :: proc(state: ^App_State) {
    fmt.println("Destroying app")
    win.destroy(&state.window)
    fmt.println("Destroyed app")
}
