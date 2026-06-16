package WindowTypes

import gfx_types "vane:graphics/types"
import error "vane:error"

Create_Window_Proc  :: proc(spec: Window_Spec) -> (Window, Maybe(error.Error));
Window_Init_Proc    :: proc(ctx: ^Window_Ctx);
Window_Destroy_Proc :: proc(ctx: ^Window_Ctx);

Window :: struct {
    ctx:    Window_Ctx,
    vtable: Window_VTable
}

Window_Ctx :: struct {
    title: string,

    width:  int,
    height: int,
}

Window_VTable :: struct {
    init:       Window_Init_Proc,
    destroy:    Window_Destroy_Proc
}

Window_Spec :: struct {
    title:  string,

    width:  int,
    height: int,

    backend: gfx_types.Backend
}
