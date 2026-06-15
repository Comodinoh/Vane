package Crash

import "core:fmt"

todo :: proc(format: string = "TODO", args: ..any, loc := #caller_location) {
    panic(fmt.aprintf(format, ..args), loc);
}
