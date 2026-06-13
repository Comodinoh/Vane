package HelloWorld

import "core:fmt"
import vane "vane:core"

main :: proc() {
    app : vane.App_State

    vane.init(&app, 
        start = proc(app: ^vane.App_State) -> bool {
            fmt.println("Starting...")
            return true
        },

        stop = proc(app: ^vane.App_State) -> bool {
            fmt.println("Stopping...")
            return true
        },

        update = proc(app: ^vane.App_State) -> bool {
            fmt.println("Updating once...")
            return false
        },
    )
    defer vane.destroy(&app)

    vane.run(&app)
}
