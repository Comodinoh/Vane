package Core

import "core:fmt"
NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import error "vane:error"
import gfx   "vane:graphics"
import crash "vane:crash"
import win   "vane:core/window"

App_Proc :: proc(app: ^App_State) -> bool

App_State :: struct {
    running: bool,

    engine: Engine_State,
    window: win.Window,

    start: App_Proc,
    stop: App_Proc,
    update: App_Proc,
}

Engine_State :: struct {
    running: bool,
    window_spec: win.Window_Spec
}

@(private)
global_backend : gfx.Backend

report_proc :: proc(state: ^crash.Crash_State) {
    
}

init :: proc(state: ^App_State, 
    start: App_Proc, 
    stop: App_Proc, 
    update: App_Proc,
    backend := gfx.Backend.OpenGL,
    title: string = "Vane Game", width: int = 1280, height: int = 720,
    ) -> (err : Maybe(error.Error)){
    fmt.println("Initialising engine...")

    global_backend = backend

    crash.get_state().report_proc = report_proc;

    fmt.println("Initialised crash report system")

    state.running = true

    state.start = start
    state.stop = stop
    state.update = update

    state.engine = Engine_State{ running=true, 
        window_spec = { title = title, width = width, height = height } }

    win.new(&state.window, global_backend, state.engine.window_spec)
    win.init(&state.window) or_return

    fmt.println("Initialised engine")

    return nil
}

init_app :: proc(state: ^App_State) -> Maybe(error.Error) {
    fmt.println("Initialising app...")

    state.running = true;



    fmt.println("Initialised app")

    return nil;
}

destroy_app :: proc(state: ^App_State) {
    fmt.println("Destroying app...")
    fmt.println("Destroyed app")
}

run :: proc(state: ^App_State) {
    engine: {
        for state.engine.running && !win.should_close(&state.window){
            if err := init_app(state); err != nil {
                fmt.eprintln("Error: Could not initialise application");
                fmt.eprintfln("      Reason: {}", err.(error.Error).message);
                break engine;
            }

            if !state->start() {
                return
            }

            for state.running {
                if(!state->update()) {
                    break;
                }
            }

            state->stop()

            destroy_app(state);
        }
    }
}

destroy :: proc(state: ^App_State) {
    fmt.println("Destroying engine")
    win.destroy(&state.window)
}

restart :: proc(state: ^App_State) {
    state.running = false
}

stop :: proc(state: ^App_State) {
    state.running = false
    state.engine.running = false
}
