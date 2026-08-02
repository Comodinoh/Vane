package Graphics_OpenGL
import "vane:graphics"
import "core:mem"
import "core:sync"


Fence_State :: struct {
    sema: sync.Sema,
    allocator: mem.Allocator,
}

fence_new :: proc(device: graphics.Device_State, allocator := context.allocator) -> graphics.Fence_State {
    fence, _ := mem.new(Fence_State, allocator)

    fence.allocator = allocator

    sync.sema_post(&fence.sema)

    return cast(graphics.Fence_State)fence
}

fence_destroy :: proc(fence: graphics.Fence_State) {
    fence := cast(^Fence_State)fence

    free(fence, fence.allocator)
}

fence_wait :: proc(fence: graphics.Fence_State) {
    fence := cast(^Fence_State)fence

    sync.sema_wait(&fence.sema)
}

fence_signal :: proc(fence: graphics.Fence_State) {
    fence := cast(^Fence_State)fence

    sync.sema_post(&fence.sema)
}
