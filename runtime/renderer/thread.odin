package Renderer

import "core:fmt"
import "core:thread"
import "core:mem"
import "core:sync"

import "vane:core/window"
import "vane:error"
import "vane:graphics"

FRAMES_IN_FLIGHT :: 2

Frame_Context :: struct {
    pool: graphics.Command_Pool_Handle,
    queue: graphics.Command_Queue_State,
    fence: graphics.Fence_State,
}

Render_Thread_Data :: struct {
    frames: [FRAMES_IN_FLIGHT]Frame_Context,
    allocator: mem.Allocator,
    render_sema: sync.Sema,
    window: ^window.Window,
    device: graphics.Device_State,
    current_frame: uint,
    running: bool,
}

render_thread_create :: proc(device: graphics.Device_State, window: ^window.Window, allocator := context.allocator) -> (^thread.Thread, ^Render_Thread_Data, Maybe(error.Error)){
    thread := thread.create(render_thread_main)
    data, err := new(Render_Thread_Data, allocator)
    if err != nil {
        return nil, nil, error.Error{fmt.aprintf("{}", err)}
    }
    data.window = window
    data.allocator = allocator
    data.device = device

    thread.data = data

    return thread, data, nil
}

render_thread_init :: proc(data: ^Render_Thread_Data) {
    for i in 0..<FRAMES_IN_FLIGHT {
        data.frames[i] = Frame_Context{
            pool = graphics.create_command_pool(data.device),
            queue = graphics.command_queue_new(data.device, data.allocator),
            fence = graphics.fence_new(data.device),
        }
    }
}

render_thread_deinit :: proc(data: ^Render_Thread_Data) {
    for i in 0..<FRAMES_IN_FLIGHT {
        frame := &data.frames[i]

        graphics.destroy_command_pool(data.device, frame.pool)
        graphics.command_queue_destroy(frame.queue)
        graphics.fence_destroy(frame.fence)
    }
}

render_thread_destroy :: proc(t: ^thread.Thread, data: ^Render_Thread_Data) {
    free(data, data.allocator)

    thread.destroy(t)
}

render_thread_main :: proc(thread: ^thread.Thread) {
    data := cast(^Render_Thread_Data)thread.data
    sync.atomic_store(&data.running, true)

    window.make_context_current(data.window)
    fmt.println("[Render Thread] Started")

    for sync.atomic_load(&data.running) {
        sync.sema_wait(&data.render_sema)

        frame := &data.frames[data.current_frame]

        err := graphics.process_resources(data.device)

        if err != nil {
           fmt.eprintln("[Render Thread] ERROR (process_resources):", err.(error.Error).message)
        }

        graphics.execute(frame.queue, frame.fence)

        graphics.swapchain_present(data.device, data.window)

        data.current_frame = (data.current_frame + 1 ) % FRAMES_IN_FLIGHT
    }

    fmt.println("[Render Thread] Terminated")
}


