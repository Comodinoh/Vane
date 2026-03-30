#include "Buffer.h"
#include "Vane/Core/GWindow.h"

#ifdef VANE_OPENGL
#include <Vane/Platform/OpenGL/GLBuffer.h>
#endif

namespace Vane::Graphics {
    VertexBuffer* VertexBuffer::Create(const VertexBufferSpecification& spec) {
        switch(Vane::Window::GetBackend()) {
            case Vane::Backend::None:
                {
                    VANE_TODO("None Render backend isn't implemented");
                }
            case Vane::Backend::OpenGL:
                {
                    return new GLVertexBuffer(spec);
                }
            default:
                {
                    VANE_TODO("Unimplemented Render backend");
                }
        }
    }

    IndexBuffer* IndexBuffer::Create(const IndexBufferSpecification& spec) {
        switch(Vane::Window::GetBackend()) {
            case Vane::Backend::None:
                {
                    VANE_TODO("None Render backend isn't implemented");
                }
            case Vane::Backend::OpenGL:
                {
                    return new GLIndexBuffer(spec);
                }
            default:
                {
                    VANE_TODO("Unimplemented Render backend");
                }
        }
    }
}
