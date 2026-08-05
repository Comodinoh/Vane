package HelloWorld

import "core:os"
import "core:fmt"
import "core:time"
import "core:mem"

import vane "vane:core"
import win  "vane:core/window"
import gfx  "vane:graphics"
import      "vane:renderer"
import      "vane:error"

Data :: struct {
    shader: gfx.Shader_Handle,
}

main :: proc() {
    app: vane.App_State(Data)

    err : Maybe(error.Error)

    when ODIN_DEBUG {

        allocator : mem.Tracking_Allocator
        mem.tracking_allocator_init(&allocator, context.allocator)
        context.allocator = mem.tracking_allocator(&allocator);

        defer {
            if len(allocator.allocation_map) > 0 {
                fmt.eprintfln("=== {} allocations not freed ===", len(allocator.allocation_map))
                for _, entry in allocator.allocation_map {
                    fmt.eprintfln("- {} bytes @ {}", entry.size, entry.location)
                }
            } else {
                fmt.eprintfln("All allocations have been freed")
            }
            mem.tracking_allocator_destroy(&allocator)
        }
    }

    {
        if app, err = vane.new(backend = gfx.Backend.OpenGL,
            start = vane.app_proc(
                proc(data: ^Data, app: ^vane.App_State(Data), current_frame: ^renderer.Frame_Context) -> bool {
                    data.shader = gfx.create_shader(app.device, {
                        kind = .Vertex,
                        source = "Meow!",
                    })
                    return true
                }
            ),
            stop = vane.app_proc(
                proc(data: ^Data, app: ^vane.App_State(Data), current_frame: ^renderer.Frame_Context) -> bool {
                    fmt.println("Stopping...")
                    return true
                }
            ),
            update = vane.app_proc(
                proc(data: ^Data, app: ^vane.App_State(Data), current_frame: ^renderer.Frame_Context) -> bool {
                    cmd := gfx.allocate_command_buffer(app.device, current_frame.pool)

                    gfx.submit_buffer(current_frame.queue, &cmd)
                    return !win.should_close(app.window)
                }
            ),
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

    
}
