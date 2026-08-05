package Graphics_OpenGL
import "vane:graphics"
import "vane:container"
import "vane:renderer"
import "core:mem"

Command_Queue_State :: struct {
    buffer: ^container.Atomic_Ring_Buffer(^Command_Buffer_State, renderer.FRAMES_IN_FLIGHT*6),
    device: ^Device_State,
    allocator: mem.Allocator,
}

command_queue_new :: proc(device: graphics.Device_State, allocator := context.allocator) -> graphics.Command_Queue_State{
    state, _ := mem.new(Command_Queue_State, allocator)
    state.allocator = allocator
    state.device = cast(^Device_State)device
    state.buffer = container.arb_new(^Command_Buffer_State, renderer.FRAMES_IN_FLIGHT*6, allocator)

    return state
}

command_queue_destroy :: proc(queue: graphics.Command_Queue_State) {
    queue := cast(^Command_Queue_State)queue

    container.arb_destroy(queue.buffer)

    free(queue, queue.allocator)
}

submit_buffer :: proc(queue: graphics.Command_Queue_State, buffer: ^graphics.Command_Buffer_State) -> bool {
    queue := cast(^Command_Queue_State)queue

    res := container.arb_push(queue.buffer, cast(^^Command_Buffer_State)buffer^) 

    buffer^ = nil

    return res
}

decode_and_execute_commands :: proc(buffer: ^Command_Buffer_State) {
    buffer := buffer.buffer[:]

    idx := 0

    for idx < len(buffer) {
        opcode := cast(Command_Opcode)buffer[idx]

        idx += 1

        switch opcode {
            case .BindPipeline: {
                idx = mem.align_forward_int(idx, align_of(Bind_Pipeline_Data))

                pipeline_data := cast(^Bind_Pipeline_Data)&buffer[idx]

                idx += size_of(Bind_Pipeline_Data)
            }
        }
    }
}

execute :: proc(queue: graphics.Command_Queue_State, fence: graphics.Fence_State) {
    queue := cast(^Command_Queue_State)queue

    device := queue.device
    
    for cmd, ok := container.arb_pop(queue.buffer); ok; cmd, ok = container.arb_pop(queue.buffer) {
        decode_and_execute_commands(cmd^)
    }

    #force_inline fence_signal(fence)
}
