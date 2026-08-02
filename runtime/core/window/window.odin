package Window

import "core:strings"
import "core:fmt"
import "core:c"
import "base:runtime"

import          "vane:error"
import gfx      "vane:graphics"
import glfw     "vendor:glfw"

Window :: struct {
    title: string,

    width:  int,
    height: int,

    backend: gfx.Backend,

    handle: rawptr
}

Window_Spec :: struct {
    title:  string,

    width:  int,
    height: int,
}

new :: proc(backend: gfx.Backend, spec: Window_Spec, allocator := context.allocator) -> ^Window{
    return new_clone(Window{title = spec.title, width = spec.width, height = spec.height, backend = backend}, allocator)
}

init :: proc(win: ^Window) -> (err : Maybe(error.Error)){
    glfw.SetErrorCallback(error_callback)
    if !bool(glfw.Init()) {
        desc, code := glfw.GetError()
        return error.Error{ 
            fmt.aprintf("Could not initialise glfw ({}): {}", code, desc) 
        }
    }
    defer if err != nil do glfw.Terminate()

    if win.backend == gfx.Backend.OpenGL {
        glfw.WindowHint(glfw.CLIENT_API, glfw.OPENGL_API)
        glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, c.int(gfx.OPENGL_VERSION_MAJOR))
        glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, c.int(gfx.OPENGL_VERSION_MINOR))
    }else {
        glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    }

    glfw_window : glfw.WindowHandle

    if glfw_window = glfw.CreateWindow(c.int(win.width), c.int(win.height), 
                     strings.clone_to_cstring(win.title, context.temp_allocator), nil, nil); glfw_window == nil {
        desc, code := glfw.GetError()
        return error.Error{ 
            fmt.aprintf("Could not create glfw window ({}): {}", code, desc) 
        }
    }
    defer if err != nil do glfw.DestroyWindow(glfw_window)
    win.handle = glfw_window 

    make_context_current(win)

    return nil
}

poll_events :: proc() {
    glfw.PollEvents()
}

swap_buffers :: proc(win: ^Window) {
    glfw.SwapBuffers(glfw.WindowHandle(win.handle))
}

should_close :: proc(win: ^Window) -> bool {
    return bool(glfw.WindowShouldClose(glfw.WindowHandle(win.handle)))
}

make_context_current :: proc(win: ^Window) {
    glfw.MakeContextCurrent(glfw.WindowHandle(win.handle))
}


detach_context_current :: proc(win: ^Window) {
    glfw.MakeContextCurrent(nil)
}

destroy :: proc(win: ^Window, allocator := context.allocator) {
    glfw.DestroyWindow(glfw.WindowHandle(win.handle))
    glfw.Terminate()

    free(win, allocator)
}

set_proc_address :: glfw.gl_set_proc_address

@(private)
error_callback :: proc "c" (code: i32, desc: cstring) {
    context = runtime.default_context()
    fmt.eprintln("[GLFW] ERROR: ", desc, " (", code, ")")
}
