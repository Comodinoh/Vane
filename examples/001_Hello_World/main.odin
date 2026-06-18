package HelloWorld

import "vane:error"
import "core:fmt"

import vane "vane:core"
import win  "vane:core/window"
import gfx  "vane:graphics"

main :: proc() {
    app : vane.App_State

    err : Maybe(error.Error)

    if err := vane.init(&app, backend = gfx.Backend.None,
        start = proc(app: ^vane.App_State) -> bool {
            fmt.println("Starting...")
            return true
        },

        stop = proc(app: ^vane.App_State) -> bool {
            fmt.println("Stopping...")
            return true
        },

        update = proc(app: ^vane.App_State) -> bool {
            win.poll_events() 

            win.swap_buffers(&app.window)
            return !win.should_close(&app.window)
        },
    ); err != nil {
        fmt.eprintln("Could not initialise engine")
        fmt.eprintfln("      Reason: {}", err.(error.Error).message)
    }

    defer if err == nil do vane.destroy(&app)

    vane.run(&app)
}
