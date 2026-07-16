package Graphics

import "vane:error"
OPENGL :: #config(VANE_OPENGL, true)
VULKAN :: #config(VANE_OPENGL, false)
DIRECTX :: #config(VANE_DIRECTX, false)

OPENGL_VERSION_MAJOR :: 4
OPENGL_VERSION_MINOR :: 6

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

Texture_Size :: [3]int

Texture_Spec :: struct{
    dimension: Texture_Dimension,
    data_format: Texture_Data_Format,
    color_format: Texture_Color_Format,
    size: Texture_Size,
    data: rawptr
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

Device :: struct {
    new: proc(allocator := context.allocator) -> Device_State,
    destroy: proc(state: Device_State),

    init: proc(state: Device_State),
    deinit: proc(state: Device_State),

    create_texture: proc(state: Device_State, spec: Texture_Spec) -> Texture_Handle,
    create_shader: proc(state: Device_State, spec: Shader_Spec) -> Shader_Handle,
    create_pipeline: proc(state: Device_State) -> Pipeline_Handle,
}

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

@(private)
DEVICE_VTABLE: [Backend]Device
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
