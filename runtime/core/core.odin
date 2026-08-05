package Core

import "core:fmt"
import "core:thread"
import "core:sync"


NAME :: #config(VANE_NAME, "Vane")
VERSION :: #config(VANE_VERSION, "0.0.1-BETA")

import win      "vane:core/window"
import error    "vane:error"
import gfx      "vane:graphics"
import gl       "vane:graphics/opengl"
import renderer "vane:renderer"
import crash    "vane:crash"

App_Proc_Struct :: struct($T: typeid) {
    app_proc: #type proc(data: ^T, app: ^App_State(T), current_frame: ^renderer.Frame_Context) -> bool
}

app_proc :: proc(
    procedure: #type proc(data: ^$E, app: ^App_State(E), current_frame: ^renderer.Frame_Context) -> bool
    ) -> App_Proc_Struct(E){
    return App_Proc_Struct(E) {procedure}
}

App_State :: struct($T: typeid) {
    running: bool,

    window: ^win.Window,
    
    device: gfx.Device_State,
    render_thread: ^thread.Thread,
    render_data: ^renderer.Render_Thread_Data,
    current_frame: uint,

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
    win.init(state.window) or_return
    
    fmt.println("Initialised window")

    state.device = gfx.device_new()
    fmt.println("Created device")

    state.render_thread, state.render_data = renderer.render_thread_create(state.device, state.window) or_return
    fmt.println("Created render thread")
    
    fmt.println("Initialised app")
    return
}

start :: proc(state: ^App_State($T)) -> bool {
    gfx.device_init(state.device)
    fmt.println("Initialised device")

    renderer.render_thread_init(state.render_data)

    win.detach_context_current(state.window)
    thread.start(state.render_thread)
    fmt.println("Started render thread")

    return state.start.app_proc(&state.data, state, &state.render_data.frames[state.current_frame])
}

stop :: proc(state: ^App_State($T)) -> bool{
    res := state.stop.app_proc(&state.data, state, &state.render_data.frames[state.current_frame])

    sync.atomic_store(&state.render_data.running, false)
    fmt.println("Waiting for render thread to terminate...")
    thread.join(state.render_thread)

    renderer.render_thread_deinit(state.render_data)

    gfx.device_deinit(state.device)

    return res
}

update :: proc(state: ^App_State($T)) -> bool {
    return state.update.app_proc(&state.data, state, &state.render_data.frames[state.current_frame])
}

run :: proc(state: ^App_State($T)){
    for {
        assert(state != nil, "app state is nil")
        if win.should_close(state.window) do break

        win.poll_events()

        render_data := state.render_data

        frame := &render_data.frames[state.current_frame]
        gfx.fence_wait(frame.fence)

        pool := &frame.pool

        gfx.reset_command_pool(state.device, pool^)

        if !update(state){
            break
        }

        sync.sema_post(&render_data.render_sema)

        state.current_frame = (state.current_frame + 1) % renderer.FRAMES_IN_FLIGHT

    }
}

destroy :: proc(state: ^App_State($T)) {
    fmt.println("Destroying app")

    renderer.render_thread_destroy(state.render_thread, state.render_data)
    gfx.device_destroy(state.device)
    win.destroy(state.window)
    fmt.println("Destroyed app")
}
