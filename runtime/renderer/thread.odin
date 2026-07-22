package Renderer

import "core:fmt"
import "core:thread"
import "core:mem"
import "core:sync"
import "vane:core/window"
import "vane:error"

Render_Thread_Data :: struct {
    allocator: mem.Allocator,
    render_sema: sync.Sema,
    window: ^window.Window,
    running: bool,
}

render_thread_create :: proc(window: ^window.Window, allocator := context.allocator) -> (^thread.Thread, ^Render_Thread_Data, Maybe(error.Error)){
    thread := thread.create(render_thread_main)
    data, err := new(Render_Thread_Data, allocator)
    if err != nil {
        return nil, nil, error.Error{fmt.aprintf("{}", err)}
    }
    data.window = window
    data.allocator = allocator

    thread.data = data

    return thread, data, nil
}

render_thread_destroy :: proc(t: ^thread.Thread, data: ^Render_Thread_Data) {
    free(data, data.allocator)

    thread.destroy(t)
}

render_thread_main :: proc(thread: ^thread.Thread) {
    data := cast(^Render_Thread_Data)thread.data
    sync.atomic_store(&data.running, true)

    window.make_context_current(data.window)
    for sync.atomic_load(&data.running) {
        sync.sema_wait(&data.render_sema)

        window.swap_buffers(data.window)
    }

    fmt.println("[Render Thread] Terminated")
}


