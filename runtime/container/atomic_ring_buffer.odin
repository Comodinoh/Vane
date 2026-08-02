package Container

import "core:sync"
import "base:runtime"

Atomic_Ring_Buffer :: struct($T: typeid, $N: uint) {
    array: [N]T,

    head: uint,
    tail: uint,

    allocator: runtime.Allocator,
}

arb_new :: proc($T: typeid, $N: uint, allocator := context.allocator) -> ^Atomic_Ring_Buffer(T, N)
    where N > 0 {
    out := new(Atomic_Ring_Buffer(T, N), allocator)
    out.allocator = allocator

    return out
}

arb_destroy :: proc(buffer: ^Atomic_Ring_Buffer($T, $N)) {
    free(buffer, buffer.allocator)
}

arb_push :: proc(buffer: ^Atomic_Ring_Buffer($T, $N), value: ^T) -> bool {
    head := sync.atomic_load(&buffer.head)
    tail := sync.atomic_load(&buffer.tail)

    next_head := (head + 1) % N

    if next_head == tail {
        return false
    }

    buffer.array[head] = value^

    sync.atomic_store(&buffer.head, next_head)

    return true
}

arb_pop :: proc(buffer: ^Atomic_Ring_Buffer($T, $N)) -> (^T, bool) {
    head := sync.atomic_load(&buffer.head)
    tail := sync.atomic_load(&buffer.tail)

    if head == tail {
        return nil, false
    }

    out := &buffer.array[tail]

    next_tail := (tail + 1) % N

    sync.atomic_store(&buffer.tail, next_tail)

    return out, true
}

arb_clear :: proc(buffer: ^Atomic_Ring_Buffer($T, $N)) {
    sync.atomic_store(&buffer.head, 0)
    sync.atomic_store(&buffer.tail, 0)
}
