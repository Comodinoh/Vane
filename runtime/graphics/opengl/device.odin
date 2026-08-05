package Graphics_OpenGL

import "vane:graphics"
import "vane:core/window"
import "vane:error"

import "core:mem"
import "core:fmt"
import gl "vendor:OpenGL"

Texture_Data :: struct {
    gl_handle: u32,
    dimension: graphics.Texture_Dimension,
    data_format: graphics.Texture_Data_Format,
    color_format: graphics.Texture_Color_Format,
    size: graphics.Texture_Size,
    vertices: int,
}

Shader_Data :: struct {
    gl_handle: u32,
    kind: graphics.Shader_Kind,
    size: uint,
}

Pipeline_Data :: struct {
    vertex_shader, pixel_shader: graphics.Shader_Handle,
}

Command_Pool_Data :: struct {
    free_buffers: [dynamic]^Command_Buffer_State,
    allocated_buffers: [dynamic]^Command_Buffer_State,
}

Device_State :: struct {
    allocator: mem.Allocator,
    texture_registry: Registry(Texture_Data),
    shader_registry: Registry(Shader_Data),
    pipeline_registry: Registry(Pipeline_Data),
    command_pool_registry: Registry(Command_Pool_Data),
    resource_loading_queue: Resource_Loading_Queue,
}

device_new :: proc(allocator := context.allocator) -> graphics.Device_State {
    state, _ := mem.new(Device_State, allocator)
    state.allocator = allocator

    gl.load_up_to(4, 6, window.set_proc_address)

    return state
}

device_destroy :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state
    mem.free(state, state.allocator)
}

device_init :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state

    registry_init(&state.texture_registry, state.allocator)
    registry_init(&state.shader_registry, state.allocator)
    registry_init(&state.pipeline_registry, state.allocator)
    registry_init(&state.command_pool_registry, state.allocator)

    state.resource_loading_queue.queue = make([dynamic]u8, 0, 1024, state.allocator)

    fmt.println("[OpenGL] All registries have been initialised")
}

device_deinit :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state

    delete(state.resource_loading_queue.queue)

    registry_deinit(&state.command_pool_registry)
    registry_deinit(&state.pipeline_registry)
    registry_deinit(&state.shader_registry)
    registry_deinit(&state.texture_registry)
}

create_texture :: proc(state: graphics.Device_State, spec: graphics.Texture_Spec) -> graphics.Texture_Handle {
    state := cast(^Device_State)state

    vertices := spec.size.x
    if spec.size.y != 0 do vertices *= spec.size.y
    if spec.size.z != 0 do vertices *= spec.size.z

    handle : graphics.Texture_Handle = registry_allocate(&state.texture_registry, Texture_Data{0, spec.dimension, spec.data_format, spec.color_format, spec.size, vertices})

    resource_push_texture(&state.resource_loading_queue, &state.texture_registry, handle, spec.data)

    return handle
}

create_shader :: proc(state: graphics.Device_State, spec: graphics.Shader_Spec) -> graphics.Shader_Handle {
    state := cast(^Device_State)state

    handle : graphics.Shader_Handle = registry_allocate(&state.shader_registry, Shader_Data{0, spec.kind, len(spec.source)})
    resource_push_shader(&state.resource_loading_queue, &state.shader_registry, handle, spec.source)

    return handle
}

create_pipeline :: proc(state: graphics.Device_State, spec: graphics.Pipeline_Spec) -> graphics.Pipeline_Handle {
    state := cast(^Device_State)state

    handle : graphics.Pipeline_Handle = registry_allocate(&state.pipeline_registry, Pipeline_Data{spec.vertex_shader, spec.pixel_shader})
    resource_push_pipeline(&state.resource_loading_queue, &state.pipeline_registry, handle)

    return handle
}

create_command_pool :: proc(state: graphics.Device_State) -> graphics.Command_Pool_Handle {
    state := cast(^Device_State)state

    slot := registry_allocate(&state.command_pool_registry)

    free_buffers := make([dynamic]^Command_Buffer_State, state.allocator)
    allocated_buffers := make([dynamic]^Command_Buffer_State, 0, DEFAULT_COMMAND_POOL_SIZE, state.allocator)

    for i in 0..<DEFAULT_COMMAND_POOL_SIZE {
        buffer, _ := mem.new(Command_Buffer_State, state.allocator)
        command_buffer_init(state, buffer, slot)

        append(&allocated_buffers, buffer)
    }

    handle := graphics.Command_Pool_Handle(slot)

    pool := registry_get(&state.command_pool_registry, handle)
    pool.free_buffers = free_buffers
    pool.allocated_buffers = allocated_buffers

    return slot
}

destroy_command_pool :: proc(state: graphics.Device_State, pool: graphics.Command_Pool_Handle) {
    state := cast(^Device_State)state

    pool_data := registry_get(&state.command_pool_registry, pool)

    for buffer in pool_data.free_buffers {
        command_buffer_deinit(buffer)
        mem.free(buffer, state.allocator)
    }
    for buffer in pool_data.allocated_buffers {
        command_buffer_deinit(buffer)
        mem.free(buffer, state.allocator)
    }

    delete(pool_data.free_buffers)
    delete(pool_data.allocated_buffers)

    registry_free(&state.command_pool_registry, pool.(int))
}

allocate_command_buffer :: proc(state: graphics.Device_State, pool: graphics.Command_Pool_Handle) -> graphics.Command_Buffer_State {
    state := cast(^Device_State)state

    pool_data := registry_get(&state.command_pool_registry, pool)

    buf: ^Command_Buffer_State

    if(len(pool_data.free_buffers) != 0) {
        buf = pop(&pool_data.free_buffers)
    } else {
        buf, _ = mem.new(Command_Buffer_State, state.allocator)
        command_buffer_init(state, buf, pool)
    }

    append(&pool_data.allocated_buffers, buf)

    return cast(rawptr)buf
}

reset_command_pool :: proc(state: graphics.Device_State, pool: graphics.Command_Pool_Handle) {
    state := cast(^Device_State)state
    pool_data := registry_get(&state.command_pool_registry, pool)

    for &buf in pool_data.allocated_buffers {
        command_buffer_clear(buf)
        append(&pool_data.free_buffers, buf)
    }

    clear(&pool_data.allocated_buffers)
}

process_resources :: proc(state: graphics.Device_State) -> Maybe(error.Error) {
    state := cast(^Device_State)state

    resource_decode_and_execute(&state.resource_loading_queue, state) or_return

    return nil
}
