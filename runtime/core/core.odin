package Core

import "core:fmt"
NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import gfx "vane:graphics"

App_Proc :: proc(app: ^App_State) -> bool

App_State :: struct {
    running: bool,

    engine: Engine_State,
    window: Window,

    start: App_Proc,
    stop: App_Proc,
    update: App_Proc,
}

Engine_State :: struct {
    running: bool,
}

@(private)
global_backend : gfx.Backend

init :: proc(state: ^App_State, 
    start: App_Proc, 
    stop: App_Proc, 
    update: App_Proc,
    backend := gfx.Backend.OpenGL
    ) {

    state.running = true

    state.start = start
    state.stop = stop
    state.update = update

    state.engine = Engine_State{ running=true }
}

init_app :: proc(state: ^App_State) -> Maybe(Error) {
    state.running = true;

    state.window = create_window(global_backend) or_return
    
    state.window.vtable.init(&state.window.ctx);

    return nil;
}

destroy_app :: proc(state: ^App_State) {
    state.window.vtable.destroy(&state.window.ctx)
}

run :: proc(state: ^App_State) {
    engine: {
        for state.engine.running {
            if err := init_app(state); err != nil {
                fmt.eprintln("Error: Could not initialise application");
                fmt.eprintfln("      Reason: {}", err.(Error).message);
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

}

restart :: proc(state: ^App_State) {
    state.running = false
}

stop :: proc(state: ^App_State) {
    state.running = false
    state.engine.running = false
}
