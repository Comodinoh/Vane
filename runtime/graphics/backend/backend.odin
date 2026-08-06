package Graphics_Backend;

import "vane:error"

OPENGL :: #config(VANE_OPENGL, true)
VULKAN :: #config(VANE_VULKAN, false)
DIRECTX :: #config(VANE_DIRECTX, false)

when OPENGL {
    OPENGL_VERSION_MAJOR :: 4
    OPENGL_VERSION_MINOR :: 6
}

Backend :: enum {
    OpenGL,
    Vulkan,
    DirectX,
    Headless
}

@(private)
CURRENT_BACKEND: Backend = nil

get_backend :: proc() -> Backend {
    return CURRENT_BACKEND
}

init :: proc(backend: Backend) -> Maybe(error.Error){
    if(CURRENT_BACKEND != nil) {
        return error.Error{"Backend is already set. Cannot change it"}
    }

    when ODIN_OS == .Linux {
        if backend == .DirectX {
            return error.Error{"DirectX backend isn't supported on Linux"}
        }
    }

    when !OPENGL {
        if backend == .OpenGL {
            return error.Error{"OpenGL backend has been disabled"}
        }
    }

    when !VULKAN {
        if backend == .Vulkan {
            return error.Error{"Vulkan backend has been disabled"}
        }
    }

    when !DIRECTX {
        if backend == .DirectX {
            return error.Error{"DirectX backend has been disabled"}
        }
    }

    if backend == .Headless {
        return error.Error{"Headless backend isn't supported"}
    }

    CURRENT_BACKEND = backend

    return nil
}
