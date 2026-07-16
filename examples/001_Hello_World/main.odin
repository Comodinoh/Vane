package HelloWorld

import "core:os"
import "core:fmt"

import vane "vane:core"
import win  "vane:core/window"
import gfx  "vane:graphics"
import      "vane:error"

Data :: struct {
    device: gfx.Device_State,
}

main :: proc() {
    app: vane.App_State(Data)

    err : Maybe(error.Error)

    if app, err = vane.new(backend = gfx.Backend.OpenGL,
        start = vane.app_proc(proc(data: ^Data, app: ^vane.App_State(Data)) -> bool {
            fmt.println("Starting...")

            data.device = gfx.device_new()
            return true
        }),
        stop = vane.app_proc(proc(data: ^Data,app: ^vane.App_State(Data)) -> bool {
            fmt.println("Stopping...")
            gfx.device_destroy(data.device)
            return true
        }),
        update = vane.app_proc(proc(data: ^Data,app: ^vane.App_State(Data)) -> bool {
            win.poll_events()

            win.swap_buffers(&app.window)
            return !win.should_close(&app.window)
        }),
    ); err != nil {
        fmt.eprintln("Could not initialise engine")
        fmt.eprintfln("      Reason: {}", err.(error.Error).message)
        return
    }

    defer if err == nil do vane.destroy(&app)
    
    vane.start(&app)

    vane.run(&app)

    vane.stop(&app)

    
}
