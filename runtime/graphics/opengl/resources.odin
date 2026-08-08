package Graphics_OpenGL

import "vane:graphics"
import "vane:error"

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"

import gl "vendor:OpenGL"

Loading_Opcode :: enum(u8) {
    CreateTexture = 0,
    CreateShaderFromSource,
    CreateShaderFromBinary,
    CreatePipeline,
    CreateFramebuffer,
    CreateBuffer,
}

Resource_Loading_Queue :: struct {
    queue:  [dynamic]u8,
    allocator: mem.Allocator,
}

@(private)
Create_Data :: struct($H, $Data: typeid) {
    handle: H,
    using data: ^Data
}

Create_Texture_Data :: struct {
    using data: ^Texture_Data,
    handle: graphics.Texture_Handle,
    payload: rawptr,
}

Create_Shader_Data :: struct {
    using data: ^Shader_Data,
    handle: graphics.Shader_Handle,
    payload: []u8,
}

Create_Pipeline_Data :: distinct Create_Data(graphics.Pipeline_Handle, Pipeline_Data)

Create_Framebuffer_Data :: struct {
    using data: ^Framebuffer_Data,
    handle: graphics.Framebuffer_Handle,
}

Create_Buffer_Data :: distinct Create_Data(graphics.Buffer_Handle, Buffer_Data)

resource_loading_queue_init :: proc(queue: ^Resource_Loading_Queue, allocator: mem.Allocator) {
    queue.allocator = allocator
    queue.queue = make([dynamic]u8, 0, DEFAULT_RESOURCE_LOADING_QUEUE_CAPACITY)
}

resource_loading_queue_deinit :: proc(queue: ^Resource_Loading_Queue) {
    mem.delete(queue.queue)
}

resource_push_texture_byte :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Texture_Data), handle: graphics.Texture_Handle, payload: []u8) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateTexture)
    align(&queue.queue, align_of(Create_Texture_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Texture_Data{
        handle = handle,
        data = data,
        payload = raw_data(slice.clone(payload, queue.allocator)),
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))
}

resource_push_texture_float32 :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Texture_Data), handle: graphics.Texture_Handle, payload: []f32) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateTexture)
    align(&queue.queue, align_of(Create_Texture_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Texture_Data{
        handle = handle,
        data = data,
        payload = raw_data(slice.clone(payload, queue.allocator)),
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))
}

resource_push_texture :: proc{resource_push_texture_byte, resource_push_texture_float32}

resource_push_shader_source :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Shader_Data), handle: graphics.Shader_Handle, payload: []u8) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateShaderFromSource)
    align(&queue.queue, align_of(Create_Shader_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Shader_Data{
        handle = handle,
        payload = slice.clone(payload, queue.allocator),
        data = data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))

    idx += size_of(create_data)

    resize(&queue.queue, uint(idx) + data.size)

    copy(queue.queue[idx:], transmute([]u8)payload)
}

resource_push_shader_binary :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Shader_Data), handle: graphics.Shader_Handle, payload: []u8) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateShaderFromBinary)
    align(&queue.queue, align_of(Create_Shader_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Shader_Data{
        handle = handle,
        payload = slice.clone(payload, queue.allocator),
        data = data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))

    idx += size_of(create_data)

    resize(&queue.queue, uint(idx) + data.size)

    copy(queue.queue[idx:], transmute([]u8)payload)
}

resource_push_pipeline :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Pipeline_Data), handle: graphics.Pipeline_Handle) {
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
}

resource_push_framebuffer :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Framebuffer_Data), handle: graphics.Framebuffer_Handle) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateFramebuffer)
    align(&queue.queue, align_of(Create_Framebuffer_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Framebuffer_Data{
        handle = handle,
        data = data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))
}

resource_push_buffer ::  proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Buffer_Data), handle: graphics.Buffer_Handle) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateBuffer)
    align(&queue.queue, align_of(Create_Buffer_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Buffer_Data{
        handle = handle,
        data = data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))
}

get_shader_name :: proc(type: u32) -> string{
   switch type {
   case gl.VERTEX_SHADER: return "Vertex";
   case gl.FRAGMENT_SHADER: return "Pixel";
   }

   return "";
}

check_error_shader :: proc(shader: u32, type: u32) -> Maybe(error.Error){
   result, log_length: i32

   gl.GetShaderiv(shader, gl.COMPILE_STATUS, &result)
   gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &log_length)

   if result != 0 do return nil
   error_message := make([]u8, log_length, allocator = context.temp_allocator)

   gl.GetShaderInfoLog(shader, log_length, nil, raw_data(error_message))

   error_str := transmute(string)error_message[:log_length-1]

   return error.Error{fmt.aprintf("Could not compile {} shader:\n{}", get_shader_name(type), error_str)}
}

check_error_program :: proc(program: u32) -> Maybe(error.Error){
   result, log_length: i32

   gl.GetProgramiv(program, gl.COMPILE_STATUS, &result)
   gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, &log_length)

   if result != 0 do return nil
   error_message := make([]u8, log_length, allocator = context.temp_allocator)

   gl.GetProgramInfoLog(program, log_length, nil, raw_data(error_message))

   error_str := transmute(string)error_message[:log_length-1]

   return error.Error{fmt.aprintf("Could not link shader program:\n{}", error_str)}
}

resource_decode_and_execute :: proc(queue: ^Resource_Loading_Queue, device: ^Device_State) -> Maybe(error.Error){
    buffer := queue.queue[:]

    defer clear(&queue.queue)

    idx : uint = 0

    max_color_attachments : i32
    gl.GetIntegerv(gl.MAX_COLOR_ATTACHMENTS, &max_color_attachments)

    for idx < len(buffer) {
        opcode := cast(Loading_Opcode)buffer[idx]

        idx += 1

        #partial switch opcode {
         case .CreateShaderFromSource: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Shader_Data)))

            create_data := cast(^Create_Shader_Data)&buffer[idx]

            idx += size_of(Create_Shader_Data)

            cstr := strings.unsafe_string_to_cstring(transmute(string)create_data.payload)

            type := get_shader_type(create_data.data.kind)
            shader := gl.CreateShader(type)

            length := i32(create_data.size)

            gl.ShaderSource(shader, 1, &cstr, &length)
            gl.CompileShader(shader)

            check_error_shader(shader, type) or_return

            create_data.data.gl_handle = shader

            mem.delete(create_data.payload, queue.allocator)
         }
         case .CreateShaderFromBinary: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Shader_Data)))

            create_data := cast(^Create_Shader_Data)&buffer[idx]

            idx += size_of(Create_Shader_Data)

            type := get_shader_type(create_data.data.kind)
            shader := gl.CreateShader(type)

            length := i32(len(create_data.payload))

            gl.ShaderBinary(1, &shader, gl.SHADER_BINARY_FORMAT_SPIR_V, raw_data(create_data.payload), length)
            gl.SpecializeShader(shader, "main", 0, nil, nil)

            check_error_shader(shader, type) or_return

            create_data.data.gl_handle = shader

            mem.delete(create_data.payload, queue.allocator)
         }
         case .CreateTexture: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Texture_Data)))

            create_data := cast(^Create_Texture_Data)&buffer[idx]

            idx += size_of(Create_Texture_Data)
 
            target := get_texture_target(create_data.data.dimension)
            texture: u32

            gl.CreateTextures(target, 1, transmute([^]u32)&texture)

            switch create_data.dimension {
                case .Texture1D: {
                    gl.TextureStorage1D(
                        texture,
                        1,
                        gl.RGB8,
                        i32(create_data.size.x)
                    )

                    gl.TextureSubImage1D(
                        texture,
                        0,
                        0,
                        i32(create_data.size.x),
                        gl.RGB,
                        get_data_type(create_data.data_format),
                        create_data.payload
                    )
                }
                case .Texture2D: {
                    gl.TextureStorage2D(
                       texture,
                       1,
                       gl.RGBA8,
                       i32(create_data.size.x),
                       i32(create_data.size.y),
                    )

                    gl.TextureSubImage2D(
                        texture,
                        0,
                        0,
                        0,
                        i32(create_data.size.x),
                        i32(create_data.size.y),
                        gl.RGB,
                        get_data_type(create_data.data_format),
                        create_data.payload
                    )
                }
                case .Texture3D: {
                    gl.TextureStorage3D(
                       texture,
                       1,
                       gl.RGBA8,
                       i32(create_data.size.x),
                       i32(create_data.size.y),
                       i32(create_data.size.z),
                    )

                    gl.TextureSubImage3D(
                        texture,
                        0,
                        0,
                        0,
                        0,
                        i32(create_data.size.x),
                        i32(create_data.size.y),
                        i32(create_data.size.z),
                        gl.RGB,
                        get_data_type(create_data.data_format),
                        create_data.payload
                    )


                }
            }

            switch create_data.data_format {
                case .Float: mem.delete(slice.from_ptr(cast(^f32)create_data.payload, create_data.vertices), queue.allocator)
                case .UnsignedByte: mem.delete(slice.from_ptr(cast(^u8)create_data.payload, create_data.vertices), queue.allocator)
            }
         }
         case .CreatePipeline: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Pipeline_Data)))

            create_data := cast(^Create_Pipeline_Data)&buffer[idx]

            idx += size_of(Create_Pipeline_Data)

            vs := create_data.vertex_shader
            ps := create_data.pixel_shader

            program := gl.CreateProgram()

            gl.AttachShader(program, registry_get(&device.shader_registry, vs).gl_handle)
            gl.AttachShader(program, registry_get(&device.shader_registry, ps).gl_handle)

            gl.LinkProgram(program)

            check_error_program(program) or_return

            create_data.data.program_gl_handle = program
         }
         case .CreateFramebuffer: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Framebuffer_Data)))

            create_data := cast(^Create_Framebuffer_Data)&buffer[idx]

            idx += size_of(Create_Framebuffer_Data)

            fb: u32
            gl.CreateFramebuffers(1, transmute([^]u32)&fb)

            for i := i32(0); i < i32(len(create_data.attachments)) && i < max_color_attachments; i += 1 {
                gl.NamedFramebufferTexture(
                    fb,
                    u32(gl.COLOR_ATTACHMENT0 + i), 
                    registry_get(&device.texture_registry, create_data.attachments[i]).gl_handle,
                    0
                )
            }

            create_data.data.gl_handle = fb
         }
         case .CreateBuffer: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Buffer_Data)))

            create_data := cast(^Create_Buffer_Data)&buffer[idx]

            idx += size_of(Create_Buffer_Data)

            buffer_obj : u32

            gl.CreateBuffers(1, transmute([^]u32)&buffer_obj)

            create_data.data.gl_handle = buffer_obj
         }
        }
    }
    return nil
}
