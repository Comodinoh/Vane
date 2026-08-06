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
    CreateShader,
    CreatePipeline,
    CreateFramebuffer,
}

Resource_Loading_Queue :: struct {
    queue:  [dynamic]u8,
}

@(private)
Create_Data :: struct($H, $Data: typeid) {
    handle: H,
    using data: ^Data
}

Create_Texture_Data :: distinct Create_Data(graphics.Texture_Handle, Texture_Data)
Create_Shader_Data :: distinct Create_Data(graphics.Shader_Handle, Shader_Data)
Create_Pipeline_Data :: distinct Create_Data(graphics.Pipeline_Handle, Pipeline_Data)
Create_Framebuffer_Data :: distinct Create_Data(graphics.Framebuffer_Handle, Framebuffer_Data)

resource_push_texture :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Texture_Data), handle: graphics.Texture_Handle, payload: rawptr) {
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


    // TODO: In the future we will need to store more arrays,
    // find a way to not have to encode it manually everytime
    copy(queue.queue[idx:], slice.from_ptr(transmute(^u8)payload, total_size))
}

resource_push_shader :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Shader_Data), handle: graphics.Shader_Handle, payload: string) {
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

resource_push_framebuffer :: proc(queue: ^Resource_Loading_Queue, registry: ^Registry(Framebuffer_Data), handle: graphics.Framebuffer_Handle, attachments: []graphics.Texture_Handle) {
    append(&queue.queue, cast(u8)Loading_Opcode.CreateFramebuffer)
    align(&queue.queue, align_of(Create_Framebuffer_Data))

    data := registry_get(registry, handle.(int))

    create_data := Create_Framebuffer_Data{
        handle,
        data,
    }

    idx := len(queue.queue)

    resize(&queue.queue, idx + size_of(create_data))
    copy(queue.queue[idx:], slice.from_ptr(cast(^u8)&create_data, size_of(create_data)))

    idx += size_of(create_data)

    resize(&queue.queue, uint(idx) + len(attachments)*size_of(graphics.Texture_Handle))

    copy(queue.queue[idx:], transmute([]u8)attachments)
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

resource_decode_and_execute :: proc(queue: ^Resource_Loading_Queue, device: ^Device_State) -> Maybe(error.Error){
    buffer := queue.queue[:]

    defer clear(&queue.queue)

    idx : uint = 0

    for idx < len(buffer) {
        opcode := cast(Loading_Opcode)buffer[idx]

        idx += 1

        #partial switch opcode {
         case .CreateShader: {

            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Shader_Data)))

            create_data := cast(^Create_Shader_Data)&buffer[idx]

            idx += size_of(Create_Shader_Data)

            start := idx
            end := idx + create_data.size

            cstr := strings.unsafe_string_to_cstring(transmute(string)buffer[start:end])

            type := get_shader_type(create_data.data.kind)
            shader := gl.CreateShader(type)

            length := i32(create_data.size)

            gl.ShaderSource(shader, 1, &cstr, &length)
            gl.CompileShader(shader)

            check_error_shader(shader, type) or_return

            create_data.data.gl_handle = shader

            idx += create_data.size
         }
         case .CreateTexture: {
            idx = uint(mem.align_forward_int(int(idx), align_of(Create_Texture_Data)))

            create_data := cast(^Create_Texture_Data)&buffer[idx]

            idx += size_of(Create_Texture_Data)
 
            target := get_texture_target(create_data.data.dimension)
            texture: u32

            gl.CreateTextures(target, 1, transmute([^]u32)&texture)

         }
        }

    }
    return nil
}
