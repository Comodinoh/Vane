package Graphics_OpenGL

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:container/queue"
import "vane:graphics"
import "core:mem"

DEFAULT_COMMAND_BUFFER_SIZE :: 2 * 1024 * 1024
DEFAULT_COMMAND_POOL_SIZE :: 10

Loading_Opcode :: enum(u8) {
    CreateTexture = 0,
    CreateShader,
    CreatePipeline,
}

Command_Opcode :: enum {
    BindPipeline = 0,
}

Texture_Data :: struct {
    gl_handle: i32,
    dimension: graphics.Texture_Dimension,
    data_format: graphics.Texture_Data_Format,
    color_format: graphics.Texture_Color_Format,
    size: graphics.Texture_Size,
    vertices: int,
}

Shader_Data :: struct {
    gl_handle: i32,
    kind: graphics.Shader_Kind,
}

Pipeline_Data :: struct {
    vertex_shader, pixel_shader: graphics.Shader_Handle,
}

Command_Pool_Data :: struct {
    free_buffers: [dynamic]^Command_Buffer_State,
    allocated_buffers: [dynamic]^Command_Buffer_State,
}

Bind_Pipeline_Data :: struct {
    handle: graphics.Pipeline_Handle,
}

@(private)
Create_Data :: struct($H, $Data: typeid) {
    handle: H,
    using data: ^Data
}

Create_Texture_Data :: distinct Create_Data(graphics.Texture_Handle, Texture_Data)
Create_Shader_Data :: distinct Create_Data(graphics.Shader_Handle, Shader_Data)
Create_Pipeline_Data :: distinct Create_Data(graphics.Pipeline_Handle, Pipeline_Data)

Resource_Loading_Queue :: struct {
    queue:  [dynamic]u8,
}

Registry :: struct($T: typeid) {
    handle_to_data: [dynamic]int,
    data: [dynamic]T,
    data_to_handle: [dynamic]int,

    next_slot: int,
    freed_slots: [dynamic]int,
}

Device_State :: struct {
    allocator: mem.Allocator,
    texture_registry: Registry(Texture_Data),
    shader_registry: Registry(Shader_Data),
    pipeline_registry: Registry(Pipeline_Data),
    command_pool_registry: Registry(Command_Pool_Data),
    resource_loading_queue: Resource_Loading_Queue,
}

Command_Buffer_State :: struct {
    buffer: [dynamic]u8,
}

new :: proc(allocator := context.allocator) -> graphics.Device_State {
    state, _ := mem.new(Device_State, allocator)
    state.allocator = allocator

    return state
}

destroy :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state
    mem.free(state, state.allocator)
}

init :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state

    registry_init(&state.texture_registry, state.allocator)
    registry_init(&state.shader_registry, state.allocator)
    registry_init(&state.pipeline_registry, state.allocator)
    registry_init(&state.command_pool_registry, state.allocator)

    fmt.println("[OpenGL] All registries have been initialised")
}

deinit :: proc(state: graphics.Device_State) {
    state := cast(^Device_State)state

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

    resource_push_texture(&state.resource_loading_queue, state.texture_registry, handle, spec.data)

    return handle
}

create_shader :: proc(state: graphics.Device_State, spec: graphics.Shader_Spec) -> graphics.Shader_Handle {
    state := cast(^Device_State)state

    handle : graphics.Shader_Handle = registry_allocate(&state.shader_registry, Shader_Data{0, spec.kind})
    resource_push_shader(&state.resource_loading_queue, state.shader_registry, handle, spec.source)

    return handle
}

create_pipeline :: proc(state: graphics.Device_State, spec: graphics.Pipeline_Spec) -> graphics.Pipeline_Handle {
    state := cast(^Device_State)state

    handle : graphics.Pipeline_Handle = registry_allocate(&state.pipeline_registry, Pipeline_Data{spec.vertex_shader, spec.pixel_shader})
    resource_push_pipeline(&state.resource_loading_queue, state.pipeline_registry, handle)

    return handle
}

create_command_pool :: proc(state: graphics.Device_State) -> graphics.Command_Pool_Handle {
    state := cast(^Device_State)state

    free_buffers := make([dynamic]^Command_Buffer_State, state.allocator)
    allocated_buffers := make([dynamic]^Command_Buffer_State, 0, DEFAULT_COMMAND_POOL_SIZE, state.allocator)

    for i in 0..<DEFAULT_COMMAND_POOL_SIZE {
        buffer, _ := mem.new(Command_Buffer_State, state.allocator)
        command_buffer_init(state, buffer)

        append(&allocated_buffers, buffer)
    }

    pool := Command_Pool_Data{free_buffers, allocated_buffers}

    return registry_allocate(&state.command_pool_registry, pool)
}

allocate_command_buffer :: proc(state: graphics.Device_State, pool: graphics.Command_Pool_Handle) -> graphics.Command_Buffer_State {
    state := cast(^Device_State)state

    pool_data := registry_get(state.command_pool_registry, pool)

    buf: ^Command_Buffer_State

    if(len(pool_data.free_buffers) != 0) {
        buf = pop(&pool_data.free_buffers)
    } else {
        buf, _ = mem.new(Command_Buffer_State, state.allocator)
        command_buffer_init(state, buf)
    }

    append(&pool_data.allocated_buffers, buf)

    return cast(rawptr)buf
}

reset_command_pool :: proc(state: graphics.Device_State, pool: graphics.Command_Pool_Handle) {
    state := cast(^Device_State)state

    pool_data := registry_get(state.command_pool_registry, pool)

    for &buf in pool_data.allocated_buffers {
        command_buffer_clear(buf)
        append(&pool_data.free_buffers, buf)
    }

    clear(&pool_data.allocated_buffers)
}

bind_pipeline :: proc(buffer: graphics.Command_Buffer_State, handle: graphics.Pipeline_Handle) {
    buffer := cast(^Command_Buffer_State)buffer
    data := command_buffer_push_command(buffer, .BindPipeline, Bind_Pipeline_Data)
    data.handle = handle
}

register :: proc() {
    graphics.register_device_vtable(.OpenGL, {
        new = new,
        destroy = destroy,
        init = init,
        deinit = deinit,

        create_texture = create_texture,
        create_shader = create_shader,
        create_pipeline = create_pipeline,
        create_command_pool = create_command_pool,

        allocate_command_buffer = allocate_command_buffer,
        reset_command_pool = reset_command_pool,
    })
    graphics.register_command_buffer_vtable(.OpenGL, {
        bind_pipeline = bind_pipeline,
        clear = command_buffer_clear,
    })
}

@(private)
registry_init :: proc(registry: ^$T/Registry($E), allocator: mem.Allocator) {
    registry.data = make([dynamic]E)
    registry.handle_to_data = make([dynamic]int)
    registry.data_to_handle = make([dynamic]int)
}

@(private)
registry_deinit :: proc(registry: ^$T/Registry($E)) {
    delete(registry.data_to_handle)
    delete(registry.handle_to_data)
    delete(registry.data)
}

@(private)
registry_allocate :: proc(registry: ^$T/Registry($E), data: E) -> int {
    //TODO: Come up with a better strategy for slot reusing
    slot := registry.next_slot

    if len(registry.freed_slots) != 0 {
        slot = pop(&registry.freed_slots)
    } else {
        registry.next_slot += 1
    }

    if len(registry.handle_to_data) <= slot {
        resize(&registry.handle_to_data, slot+1)
    }

    append(&registry.data, data)
    append(&registry.data_to_handle, slot)

    registry.handle_to_data[slot] = len(registry.data)-1

    return slot
}

@(private)
registry_free :: proc(registry: $T/Registry($E), slot: int) {
    idx := registry.handle_to_data[slot]
    size := len(registry.data)

    registry.data[idx] = registry.data[size-1]
    registry.data_to_handle[idx] = registry.data_to_handle[size-1]

    swapped := data_to_handle[size-1]

    registry.handle_to_data[swapped] = idx

    pop(registry.data)
    pop(registry.data_to_handle)

    append(&registry.freed_slots, slot)
}

@(private)
registry_get :: proc{registry_get_int, registry_get_handle}

@(private)
registry_get_int :: proc(registry: $T/Registry($E), slot: int) -> ^E {
    return &registry.data[registry.handle_to_data[slot]]
}

@(private)
registry_get_handle :: proc(registry: $T/Registry($E), handle: $H/graphics.Handle) -> ^E{
    return registry_get_int(registry, handle.(int))
}

@(private)
align :: proc(array: ^$T/[dynamic]$E, alignment: int) {
    aligned := mem.align_forward_int(len(array), alignment)

    if aligned > len(array) {
        resize(array, aligned)
    }
}

@(private)
get_data_size :: proc(data_fmt: graphics.Texture_Data_Format) -> int {
    switch data_fmt {
    case .Float: 
        return size_of(f32)
    case .UnsignedByte:
        return size_of(u8)
    }
    return 0
}

@(private)
get_color_size :: proc(color_fmt: graphics.Texture_Color_Format) -> int {
    switch color_fmt {
    case .RGB: 
        return 3
    case .RGBA:
        return 4
    }
    return 0
}

@(private)
resource_push_texture :: proc(queue: ^Resource_Loading_Queue, registry: Registry(Texture_Data), handle: graphics.Texture_Handle, payload: rawptr) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateTexture)
    align(&queue.queue, align_of(Create_Texture_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Texture_Data{
        handle,
        data
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))
     
    idx += size_of(create_data)

    total_size := (get_color_size(data.color_format) + get_data_size(data.data_format)) * data.vertices

    resize(&queue.queue, idx + total_size)

    copy(queue.queue[idx:], slice.from_ptr(transmute(^u8)payload, total_size))

    align(&queue.queue, mem.DEFAULT_ALIGNMENT)
}

@(private)
resource_push_shader :: proc(queue: ^Resource_Loading_Queue, registry: Registry(Shader_Data), handle: graphics.Shader_Handle, payload: string) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateShader)
    align(&queue.queue, align_of(Create_Shader_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Shader_Data{
        handle,
        data
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))

    idx += size_of(create_data)

    resize(&queue.queue, idx + len(payload))

    copy(queue.queue[idx:], transmute([]u8)payload)

    align(&queue.queue, mem.DEFAULT_ALIGNMENT)
}

@(private)
resource_push_pipeline :: proc(queue: ^Resource_Loading_Queue, registry: Registry(Pipeline_Data), handle: graphics.Pipeline_Handle) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreatePipeline)
    align(&queue.queue, align_of(Create_Pipeline_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Pipeline_Data{
        handle,
        data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))

    align(&queue.queue, mem.DEFAULT_ALIGNMENT)
}

@(private)
command_buffer_init :: proc(state: ^Device_State, buffer: ^Command_Buffer_State) {
    buffer.buffer = make([dynamic]u8, 0, DEFAULT_COMMAND_BUFFER_SIZE, state.allocator)
}

@(private)
command_buffer_clear :: proc(buffer: graphics.Command_Buffer_State) {
    buffer := cast(^Command_Buffer_State)buffer
    clear(&buffer.buffer)
}

@(private)
command_buffer_push_command :: proc(buffer: ^Command_Buffer_State, opcode: Command_Opcode, $T: typeid) -> ^T{
    append(&buffer.buffer, cast(u8)opcode)

    align(&buffer.buffer, align_of(T))

    idx := len(buffer.buffer)

    resize(&buffer.buffer, idx + size_of(T))

    align(&buffer.buffer, mem.DEFAULT_ALIGNMENT)

    return cast(^T)&buffer.buffer[idx]
}
