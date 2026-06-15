package Core

import gfx "vane:graphics"
import gl  "vane:platform/opengl"

Create_Window_Proc :: proc(spec: Window_Spec) -> (Window, Window_Error);
Window_Init_Proc   :: proc(spec: ^gl.Window_Ctx);

Window :: struct {
    ctx: Window_Ctx,
    vtable: Window_VTable
}

Window_Ctx :: struct {
    using window: gl.Window_Ctx,
}

Window_VTable :: struct {
    init: Window_Init_Proc
}

Window_Spec :: struct {
    title:  string,

    width:  int,
    height: int,

    backend: gfx.Backend
}

when ODIN_OS == .Linux {
    create_window :: proc(backend: gfx.Backend, title: string = "Vane Game", 
        width: int = 1280, height: int = 720) -> (Window, Window_Error){
        #partial switch backend {
        case .OpenGL: {
            when gfx.OPENGL {
              return Window {
                  ctx = Window_Ctx{
                      title = title, 
                      width = width,
                      height = height
                  },
                  vtable = {
                      gl.init_window
                  }
              }, nil
            }
            fallthrough
        }
        case: {
            return {}, Invalid_Backend{"Unknown graphics backend"};
        }
       } 
    }
} else {
    // TODO: Add Windows support
    #panic("This platform is not supported")
}







