package OpenGL

import "core:fmt"
import gfx "vane:graphics"
import types "vane:core/window/types"
import debug "vane:crash"

when gfx.OPENGL {
    
    init_window : types.Window_Init_Proc : proc(ctx: ^types.Window_Ctx) {
        //TODO: Init window 

        // debug.todo("TODO: init_window");
        fmt.println("Initialised window");
    }
    
    destroy_window : types.Window_Destroy_Proc : proc(ctx: ^types.Window_Ctx) {
        //TODO: Cleaup window
        fmt.println("Destroyed window");
        debug.todo("TODO: destroy_window");
    }

}
