package Graphics

import "vane:error"

OPENGL :: #config(VANE_OPENGL, true)
VULKAN :: #config(VANE_VULKAN, false)
DIRECTX :: #config(VANE_DIRECTX, false)

when OPENGL {
    OPENGL_VERSION_MAJOR :: 4
    OPENGL_VERSION_MINOR :: 6
}

Backend :: enum {
    OpenGL,
    Vulkan,
    DirectX,
    Headless
}

Texture_Dimension :: enum {
    Texture1D,
    Texture2D,
    Texture3D,
}

Texture_Data_Format :: enum {
    Float,
    UnsignedByte,
}

Texture_Color_Format :: enum {
    RGB,
    RGBA,
}

Texture_Internal_Format :: enum {
   RGB8,
   RGBA8,
}

Texture_Size :: [3]int

Texture_Spec :: struct{
    dimension:       Texture_Dimension,
    data_format:     Texture_Data_Format,
    color_format:    Texture_Color_Format,
    internal_format: Texture_Internal_Format,
    size:            Texture_Size,
    data:            rawptr,
}

Shader_Kind :: enum {
    Vertex,
    Pixel
}

Shader_Spec :: struct {
    kind: Shader_Kind,
    source: string,
}

Pipeline_Spec :: struct {
    vertex_shader, pixel_shader: Shader_Handle
}

Handle :: union {
    rawptr,
    int
}

Texture_Handle :: distinct Handle
Shader_Handle :: distinct Handle
Pipeline_Handle :: distinct Handle
Command_Pool_Handle :: distinct Handle

Device_State :: rawptr
Command_Buffer_State :: rawptr
Command_Queue_State :: rawptr
Fence_State :: rawptr

Command_Buffer :: struct {
    bind_pipeline: proc(state: Command_Buffer_State, pipeline: Pipeline_Handle),

    clear: proc(state: Command_Buffer_State),
}

Command_Queue :: struct {
    new: proc(device: Device_State, allocator := context.allocator) -> Command_Queue_State,
    destroy: proc(state: Command_Queue_State),

    submit_buffer: proc(state: Command_Queue_State, buffer: ^Command_Buffer_State) -> bool,
    execute: proc(state: Command_Queue_State, fence: Fence_State),
}

Fence :: struct {
    new: proc(device: Device_State, allocator := context.allocator) -> Fence_State,
    destroy: proc(state: Fence_State),

    wait: proc(state: Fence_State),
    signal: proc(state: Fence_State),
}

Device :: struct {
    new: proc(allocator := context.allocator) -> Device_State,
    destroy: proc(state: Device_State),

    init: proc(state: Device_State),
    deinit: proc(state: Device_State),

    create_texture: proc(state: Device_State, spec: Texture_Spec) -> Texture_Handle,
    create_shader: proc(state: Device_State, spec: Shader_Spec) -> Shader_Handle,
    create_pipeline: proc(state: Device_State, spec: Pipeline_Spec) -> Pipeline_Handle,
    create_command_pool: proc(state: Device_State) -> Command_Pool_Handle,

    destroy_command_pool: proc(state: Device_State, pool: Command_Pool_Handle),

    allocate_command_buffer: proc(state: Device_State, pool: Command_Pool_Handle) -> Command_Buffer_State,
    reset_command_pool: proc(state: Device_State, pool: Command_Pool_Handle),

    process_resources: proc(state: Device_State) -> Maybe(error.Error),
}

/* -------------------------------------------------------- */
/*                          DEVICE                          */
/* -------------------------------------------------------- */


device_new :: proc(allocator := context.allocator) -> Device_State {
    return DEVICE_VTABLE[CURRENT_BACKEND].new(allocator)
}

device_destroy :: proc(state: Device_State) {
    DEVICE_VTABLE[CURRENT_BACKEND].destroy(state)
}

device_init :: proc(state: Device_State) {
    DEVICE_VTABLE[CURRENT_BACKEND].init(state)
}

device_deinit :: proc(state: Device_State) {
    DEVICE_VTABLE[CURRENT_BACKEND].deinit(state)
}

create_texture :: proc(state: Device_State, spec: Texture_Spec) -> Texture_Handle {
    return DEVICE_VTABLE[CURRENT_BACKEND].create_texture(state, spec)
}

create_shader :: proc(state: Device_State, spec: Shader_Spec) -> Shader_Handle {
    return DEVICE_VTABLE[CURRENT_BACKEND].create_shader(state, spec)
}

create_pipeline :: proc(state: Device_State, spec: Pipeline_Spec) -> Pipeline_Handle {
    return DEVICE_VTABLE[CURRENT_BACKEND].create_pipeline(state, spec)
}

create_command_pool :: proc(state: Device_State) -> Command_Pool_Handle {
    return DEVICE_VTABLE[CURRENT_BACKEND].create_command_pool(state)
}

destroy_command_pool :: proc(state: Device_State, pool: Command_Pool_Handle) {
    DEVICE_VTABLE[CURRENT_BACKEND].destroy_command_pool(state, pool)
}

allocate_command_buffer :: proc(state: Device_State, pool: Command_Pool_Handle) -> Command_Buffer_State {
    return DEVICE_VTABLE[CURRENT_BACKEND].allocate_command_buffer(state, pool)
}

reset_command_pool :: proc(state: Device_State, pool: Command_Pool_Handle){
    DEVICE_VTABLE[CURRENT_BACKEND].reset_command_pool(state, pool)
}

process_resources :: proc(state: Device_State) -> Maybe(error.Error){
    return DEVICE_VTABLE[CURRENT_BACKEND].process_resources(state)
}

/* -------------------------------------------------------- */
/*                          FENCE                           */
/* -------------------------------------------------------- */

fence_new :: proc(state: Device_State, allocator := context.allocator) -> Fence_State {
    return FENCE_VTABLE[CURRENT_BACKEND].new(state, allocator)
}

fence_destroy :: proc(fence: Fence_State) {
    FENCE_VTABLE[CURRENT_BACKEND].destroy(fence)
}

fence_wait :: proc(fence: Fence_State) {
    FENCE_VTABLE[CURRENT_BACKEND].wait(fence)
}

fence_signal :: proc(fence: Fence_State) {
    FENCE_VTABLE[CURRENT_BACKEND].signal(fence)
}

/* -------------------------------------------------------- */
/*                      COMMAND BUFFER                      */
/* -------------------------------------------------------- */

bind_pipeline :: proc(buffer: Command_Buffer_State, handle: Pipeline_Handle) {
    COMMAND_BUFFER_VTABLE[CURRENT_BACKEND].bind_pipeline(buffer, handle)
}

command_buffer_clear :: proc(buffer: Command_Buffer_State) {
    COMMAND_BUFFER_VTABLE[CURRENT_BACKEND].clear(buffer)
}

/* -------------------------------------------------------- */
/*                      COMMAND QUEUE                       */
/* -------------------------------------------------------- */

command_queue_new :: proc(device: Device_State, allocator := context.allocator) -> Command_Queue_State {
    return COMMAND_QUEUE_VTABLE[CURRENT_BACKEND].new(device, allocator)
}

command_queue_destroy :: proc(queue: Command_Queue_State) {
    COMMAND_QUEUE_VTABLE[CURRENT_BACKEND].destroy(queue)
}

submit_buffer :: proc(queue: Command_Queue_State, buffer: ^Command_Buffer_State) {
    COMMAND_QUEUE_VTABLE[CURRENT_BACKEND].submit_buffer(queue, buffer)
}

execute :: proc(queue: Command_Queue_State, fence: Fence_State) {
    COMMAND_QUEUE_VTABLE[CURRENT_BACKEND].execute(queue, fence)
}

/* -------------------------------------------------------- */

@(private)
DEVICE_VTABLE: [Backend]Device
@(private)
COMMAND_BUFFER_VTABLE: [Backend]Command_Buffer
@(private)
COMMAND_QUEUE_VTABLE: [Backend]Command_Queue
@(private)
FENCE_VTABLE: [Backend]Fence
@(private)
CURRENT_BACKEND: Backend = nil

get_backend :: proc() -> Backend {
    return CURRENT_BACKEND
}

init :: proc(backend: Backend) -> Maybe(error.Error){
    if(CURRENT_BACKEND != nil) {
        return error.Error{"Backend is already set. Cannot change it"}
    }

    when ODIN_OS == .Linux {
        if backend == .DirectX {
            return error.Error{"DirectX backend isn't supported on Linux"}
        }
    }

    when !OPENGL {
        if backend == .OpenGL {
            return error.Error{"OpenGL backend has been disabled"}
        }
    }

    when !VULKAN {
        if backend == .Vulkan {
            return error.Error{"Vulkan backend has been disabled"}
        }
    }

    when !DIRECTX {
        if backend == .DirectX {
            return error.Error{"DirectX backend has been disabled"}
        }
    }

    if backend == .Headless {
        return error.Error{"Headless backend isn't supported"}
    }

    CURRENT_BACKEND = backend

    return nil
}

register_device_vtable :: proc(backend: Backend, dev: Device) {
    DEVICE_VTABLE[backend] = dev
}

register_command_buffer_vtable :: proc(backend: Backend, command_buffer: Command_Buffer) {
    COMMAND_BUFFER_VTABLE[backend] = command_buffer
}

register_command_queue_vtable :: proc(backend: Backend, command_queue: Command_Queue) {
    COMMAND_QUEUE_VTABLE[backend] = command_queue
}

register_fence_vtable :: proc(backend: Backend, fence: Fence) {
    FENCE_VTABLE[backend] = fence
}

