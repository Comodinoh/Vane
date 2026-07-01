#include "API.h"

#ifdef VANE_OPENGL

#include "Vane/Platform/OpenGL/API.h"

#endif

namespace Vane::Graphics {

    Texture* Texture::Create(const TextureSpecification &spec) {
        switch(Graphics::GetBackend()) {

#ifdef VANE_OPENGL
            case Backend::OpenGL:
                return new OpenGL::Texture(spec);
#endif

            default:
                VANE_UNREACHABLE("Unknown graphics backend");

        }
        return nullptr;
    }

    MutableTexture* Texture::CreateMutable(const TextureSpecification& spec) {
        switch(Graphics::GetBackend()) {

#ifdef VANE_OPENGL
            case Backend::OpenGL:
                return new OpenGL::MutableTexture(spec);
#endif

            default:
                VANE_UNREACHABLE("Unknown graphics backend");

        }
        return nullptr;
    }

    ImmutableTexture* Texture::CreateImmutable(const TextureSpecification& spec) {
        switch(Graphics::GetBackend()) {

#ifdef VANE_OPENGL
            case Backend::OpenGL:
                return new OpenGL::ImmutableTexture(spec);
#endif

            default:
                VANE_UNREACHABLE("Unknown graphics backend");

        }
        return nullptr;
    }
}
