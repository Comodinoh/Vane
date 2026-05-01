#include <Vane/Core/Base.h>
#ifdef VANE_OPENGL
#include "Vane/Platform/OpenGL/API.h"
#endif

namespace Vane::Graphics {

Window* Window::Create(const WindowSpecification& spec) {
    switch (spec.backend) {
    case Backend::Headless: {
        VANE_CORE_ASSERT(false,  "Headless backend is unimplemented");
        return nullptr;
    }
#ifdef VANE_OPENGL
    case Backend::OpenGL: {
        return new OpenGL::Window(spec);
    }
#endif
   default:
        VANE_CORE_ASSERT(false, "Unknown Backend!");
        return nullptr;
    }
}

}
