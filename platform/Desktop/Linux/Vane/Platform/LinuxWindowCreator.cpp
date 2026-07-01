#include <Vane/Core/Base.h>
#ifdef VANE_OPENGL
#include "Vane/Platform/OpenGL/API.h"
#endif

namespace Vane::Graphics {

Window* Window::Create(const WindowSpecification& spec) {
    switch (spec.backend) {
#ifdef VANE_OPENGL
    case Backend::OpenGL: {
        return new OpenGL::Window(spec);
    }
#endif
    default:
        VANE_UNREACHABLE("Unknown graphics backend");
    }
    return nullptr;
}

}
