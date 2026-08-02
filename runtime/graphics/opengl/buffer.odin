package Graphics_OpenGL

import "vane:graphics"

Command_Buffer_State :: struct {
    buffer: [dynamic]u8,
    pool: graphics.Command_Pool_Handle,
}

Bind_Pipeline_Data :: struct {
    handle: graphics.Pipeline_Handle,
}

Command_Opcode :: enum {
    BindPipeline = 0,
}

command_buffer_init :: proc(state: ^Device_State, buffer: ^Command_Buffer_State, pool: graphics.Command_Pool_Handle) {
    buffer.buffer = make([dynamic]u8, 0, DEFAULT_COMMAND_BUFFER_SIZE, state.allocator)
    buffer.pool = pool
}

command_buffer_clear :: proc(buffer: graphics.Command_Buffer_State) {
    buffer := cast(^Command_Buffer_State)buffer
    clear(&buffer.buffer)
}

command_buffer_push_command :: proc(buffer: ^Command_Buffer_State, opcode: Command_Opcode, $T: typeid) -> ^T{
    append(&buffer.buffer, cast(u8)opcode)

    align(&buffer.buffer, align_of(T))

    idx := len(buffer.buffer)

    resize(&buffer.buffer, idx + size_of(T))

    return cast(^T)&buffer.buffer[idx]
}

bind_pipeline :: proc(buffer: graphics.Command_Buffer_State, handle: graphics.Pipeline_Handle) {
    buffer := cast(^Command_Buffer_State)buffer
    data := command_buffer_push_command(buffer, .BindPipeline, Bind_Pipeline_Data)
    data.handle = handle
}
