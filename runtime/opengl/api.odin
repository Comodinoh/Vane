package OpenGL

import "core:strings"
import "core:slice"
import "core:container/queue"
import "vane:graphics"
import "core:mem"

Loading_Opcode :: enum(u8) {
    CreateTexture = 0,
    CreateShader,
    CreatePipeline,
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
    resource_loading_queue: Resource_Loading_Queue,
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
    //TODO: init
}

deinit :: proc(state: graphics.Device_State) {
    //TODO: deinit
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

register :: proc() {
    graphics.register_device_vtable(.OpenGL, {
        new = new,
        destroy = destroy,
        init = init,
        deinit = deinit,
    })
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
registry_get :: proc(registry: $T/Registry($E), slot: int) -> ^E {
    return &registry.data[registry.handle_to_data[slot]]
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
