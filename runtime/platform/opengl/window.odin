package OpenGL

import "core:fmt"
import gfx "vane:graphics"
import debug "vane:crash"


Window_Spec :: struct {
    title: string,

    width:  int,
    height: int,

    backend: gfx.Backend
}

Window_Ctx :: struct {
    title: string,

    width:  int,
    height: int,
}

when gfx.OPENGL {
    
    init_window :: proc(ctx: ^Window_Ctx) {
        //TODO: Init window 

        // debug.todo("TODO: init_window");
        fmt.println("Initialised window");
    }
    
    destroy_window :: proc(ctx: ^Window_Ctx) {
        //TODO: Cleaup window
        fmt.println("Destroyed window");
        debug.todo("TODO: destroy_window");
    }

}
