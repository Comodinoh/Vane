package Core

import "core:fmt"
NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import gfx_types "vane:graphics/types"
import types "vane:core/window/types"
import error "vane:error"
import window "vane:core/window"

App_Proc :: proc(app: ^App_State) -> bool

App_State :: struct {
    running: bool,

    engine: Engine_State,
    window: types.Window,

    start: App_Proc,
    stop: App_Proc,
    update: App_Proc,
}

Engine_State :: struct {
    running: bool,
}

@(private)
global_backend : gfx_types.Backend

init :: proc(state: ^App_State, 
    start: App_Proc, 
    stop: App_Proc, 
    update: App_Proc,
    backend := gfx_types.Backend.OpenGL
    ) {

    state.running = true

    state.start = start
    state.stop = stop
    state.update = update

    state.engine = Engine_State{ running=true }

    fmt.println("Initialised engine")
}

init_app :: proc(state: ^App_State) -> Maybe(error.Error) {
    fmt.println("Initialising app...")

    state.running = true;

    state.window = window.create_window(global_backend) or_return
    
    state.window.vtable.init(&state.window.ctx);

    fmt.println("Initialised app")

    return nil;
}

destroy_app :: proc(state: ^App_State) {
    fmt.println("Destroying app...")
    state.window.vtable.destroy(&state.window.ctx)
    fmt.println("Destroyed app")
}

run :: proc(state: ^App_State) {
    engine: {
        for state.engine.running {
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
}

restart :: proc(state: ^App_State) {
    state.running = false
}

stop :: proc(state: ^App_State) {
    state.running = false
    state.engine.running = false
}
