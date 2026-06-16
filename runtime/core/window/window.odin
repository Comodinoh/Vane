package Window

import           "vane:error"
import gfx       "vane:graphics"
import gfx_types "vane:graphics/types"
import gl        "vane:core/opengl"
import types     "vane:core/window/types"

when ODIN_OS == .Linux {
    create_window :: proc(backend: gfx_types.Backend, title: string = "Vane Game", 
        width: int = 1280, height: int = 720) -> (types.Window, Maybe(error.Error)){
        #partial switch backend {
        case .OpenGL: {
            when gfx.OPENGL {
              return types.Window {
                  ctx = types.Window_Ctx{
                      title = title, 
                      width = width,
                      height = height
                  },
                  vtable = {
                      gl.init_window,
                      gl.destroy_window
                  }
              }, nil
            }
            fallthrough
        }
        case: {
            return {}, error.Error{"Unknown graphics backend"};
        }
       } 
    }
} else {
    // TODO: Add Windows support
    #panic("This platform is not supported")
}







