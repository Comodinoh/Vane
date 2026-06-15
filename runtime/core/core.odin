package Core

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

init_app :: proc(state: ^App_State) {
    err : Window_Error = nil
    state.window, err = create_window(global_backend)

    assert(err == nil, "There has been an error with window creation")
    
    state.window.vtable.init(&state.window.ctx);
}

destroy_app :: proc(state: ^App_State) {
    //TODO: destroy window
}

run :: proc(state: ^App_State) {
    engine: {
        for state.engine.running {
            init_app(state);

            if(!state->start()) {
                return
            }

            for state.running {
                if(!state->update()) {
                    break engine;
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
