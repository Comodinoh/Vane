package Graphics_OpenGL
import "vane:graphics"
import "core:mem"

Registry :: struct($T: typeid) {
    handle_to_data: [dynamic]int,
    data: [dynamic]T,
    data_to_handle: [dynamic]int,

    next_slot: int,
    freed_slots: [dynamic]int,
}

registry_init :: proc(registry: ^$T1/Registry($E), allocator: mem.Allocator) {
    registry.data = make([dynamic]E)
    registry.handle_to_data = make([dynamic]int)
    registry.data_to_handle = make([dynamic]int)
}

registry_deinit :: proc(registry: ^$T1/Registry($E)) {
    delete(registry.data_to_handle)
    delete(registry.handle_to_data)
    delete(registry.data)
}

registry_allocate_no_data :: proc(registry: ^$T1/Registry($E)) -> int {
    //TODO: Come up with a better strategy for slot reusing
    slot := registry.next_slot

    if len(registry.freed_slots) != 0 {
        slot = pop(&registry.freed_slots)
    } else {
        registry.next_slot += 1
    }

    if len(registry.handle_to_data) <= slot {
        resize(&registry.handle_to_data, slot+1)
    }

    resize(&registry.data, len(registry.data)+1)
    append(&registry.data_to_handle, slot)

    registry.handle_to_data[slot] = len(registry.data)-1

    return slot
}

registry_allocate_data :: proc(registry: ^$T/Registry($E), data: E) -> int {
    slot := registry_allocate_no_data(registry)

    registry_get(registry, slot)^ = data

    return slot
}

registry_allocate :: proc{registry_allocate_data, registry_allocate_no_data}

registry_free :: proc(registry: ^$T/Registry($E), slot: int) {
    idx := registry.handle_to_data[slot]
    size := len(registry.data)

    registry.data[idx] = registry.data[size-1]
    registry.data_to_handle[idx] = registry.data_to_handle[size-1]

    swapped := data_to_handle[size-1]

    registry.handle_to_data[swapped] = idx

    pop(registry.data)
    pop(registry.data_to_handle)

    append(&registry.freed_slots, slot)
}

registry_get :: proc{registry_get_int, registry_get_handle}

registry_get_int :: proc(registry: ^$T/Registry($E), slot: int) -> ^E {
    return &registry.data[registry.handle_to_data[slot]]
}

registry_get_handle :: proc(registry: ^$T/Registry($E), handle: $H/graphics.Handle) -> ^E{
    return registry_get_int(registry, handle.(int))
}
