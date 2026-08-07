package Graphics_OpenGL

import "core:fmt"
import "core:mem"

import gl "vendor:OpenGL"

import "vane:graphics"
import "vane:renderer"
import "vane:container"
import "vane:error"

DEFAULT_COMMAND_BUFFER_SIZE :: 2 * 1024 * 1024
DEFAULT_COMMAND_POOL_SIZE :: 10
DEFAULT_RESOURCE_LOADING_QUEUE_CAPACITY :: 4 * 1024 

register :: proc() {
    graphics.register_device_vtable(.OpenGL, {
        new = device_new,
        destroy = device_destroy,
        init = device_init,
        deinit = device_deinit,

        create_texture = create_texture,
        create_shader_from_source = create_shader_from_source,
        create_shader_from_binary = create_shader_from_binary,
        create_pipeline = create_pipeline,
        create_command_pool = create_command_pool,
        create_framebuffer = create_framebuffer,

        destroy_command_pool = destroy_command_pool,

        allocate_command_buffer = allocate_command_buffer,
        reset_command_pool = reset_command_pool,
        process_resources = process_resources,

        swapchain_acquire_next = swapchain_acquire_next,
        swapchain_present = swapchain_present,
    })
    graphics.register_command_buffer_vtable(.OpenGL, {
        bind_pipeline = bind_pipeline,
        clear = command_buffer_clear,
    })
    graphics.register_command_queue_vtable(.OpenGL, {
        new = command_queue_new,
        destroy = command_queue_destroy,
        submit_buffer = submit_buffer,
        execute = execute,
    })
    graphics.register_fence_vtable(.OpenGL, {
        new = fence_new,
        destroy = fence_destroy,
        wait = fence_wait,
        signal = fence_signal
    })
}

align :: proc(array: ^$T/[dynamic]$E, alignment: int) {
    aligned := mem.align_forward_int(len(array), alignment)

    if aligned > len(array) {
        resize(array, aligned)
    }
}

get_data_type :: proc(data_fmt: graphics.Texture_Data_Format) -> u32 {
    switch data_fmt {
    case .Float: 
        return gl.FLOAT
    case .UnsignedByte:
        return gl.UNSIGNED_BYTE
    }
    return 0
}

get_data_size :: proc(data_fmt: graphics.Texture_Data_Format) -> int {
    switch data_fmt {
    case .Float: 
        return size_of(f32)
    case .UnsignedByte:
        return size_of(u8)
    }
    return 0
}

get_color_size :: proc(color_fmt: graphics.Texture_Color_Format) -> int {
    switch color_fmt {
    case .RGB: 
        return 3
    case .RGBA:
        return 4
    }
    return 0
}

get_shader_type :: proc(kind: graphics.Shader_Kind) -> u32 {
    switch kind {
    case .Vertex: return gl.VERTEX_SHADER
    case .Pixel: return gl.FRAGMENT_SHADER
    }

    return 0
}

get_texture_target :: proc(dimension: graphics.Texture_Dimension) -> u32 {
   switch dimension {
   case .Texture1D: return gl.TEXTURE_1D
   case .Texture2D: return gl.TEXTURE_2D
   case .Texture3D: return gl.TEXTURE_3D
   }
   
   return 0
}
