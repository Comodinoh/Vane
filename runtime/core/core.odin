package Core

NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

App_Proc :: proc(app: ^App_State) -> bool

App_State :: struct {
    running: bool,

    engine: Engine_State,

    start: App_Proc,
    stop: App_Proc,
    update: App_Proc,
}

Engine_State :: struct {
    running: bool,
     

}

init :: proc(state: ^App_State, start: App_Proc, stop: App_Proc, update: App_Proc) {
    state.running = true

    state.start = start
    state.stop = stop
    state.update = update

    state.engine = Engine_State{ running=true }
}

run :: proc(state: ^App_State) {
    engine: {
        for state.engine.running {
            if(!state->start()) {
                return
            }

            for state.running {
                if(!state->update()) {
                    break engine;
                }
            }

            state->stop()
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
