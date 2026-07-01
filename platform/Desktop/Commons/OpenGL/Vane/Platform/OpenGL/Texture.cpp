#include "API.h"
#include "Vane/Core/Base.h"
#include "Vane/Graphics/API.h"

#include <glad/glad.h>

namespace Vane::Graphics::OpenGL {

    GLenum GetTextureDimension(Graphics::TextureDimension dimension) {
        switch(dimension) {
            case Graphics::TextureDimension::TEXTURE_1D:
                return GL_TEXTURE_1D;
            case Graphics::TextureDimension::TEXTURE_2D:
                return GL_TEXTURE_2D;
            case Graphics::TextureDimension::TEXTURE_3D:
                return GL_TEXTURE_3D;
            default:
                VANE_UNREACHABLE();
        }
        return 0;
    }

    GLenum GetTextureFormat(Graphics::TextureFormat format) {
        switch(format) {
            case Graphics::TextureFormat::RGB:
                return GL_RGB;
            case Graphics::TextureFormat::RGBA:
                return GL_RGBA;
            default:
                VANE_UNREACHABLE();
        }
        return 0;
    }

    GLenum GetTextureType(Graphics::TextureType type) {
        switch(type) {
            case Graphics::TextureType::UByte:
                return GL_UNSIGNED_BYTE;
            case Graphics::TextureType::Float:
                return GL_FLOAT;
            default:
                VANE_UNREACHABLE();
        }
        return 0;
    }

    MutableTexture::MutableTexture(const TextureSpecification& spec) {
        uint id;
        glGenTextures(1, &id);        
        m_handle._n = id;

        GLenum dimension = GetTextureDimension(spec.dimension);
        GLenum type = GetTextureType(spec.data.type);
        GLenum format = GetTextureFormat(spec.format);
        GLenum data_format = GetTextureFormat(spec.data.format);

        m_dimension = dimension;

        this->Bind(0);

        switch(spec.data.dimension) {
            case TEXTURE_1D:
                {
                    glTexImage1D(dimension, 0, format, spec.data.size.width, 0, data_format, type, spec.data.data);
                }
            case TEXTURE_2D:
                {
                    glTexImage2D(dimension, 0, format, spec.data.size.width, spec.data.size.height, 0, data_format, type, spec.data.data);
                }
            case TEXTURE_3D:
                {
                    glTexImage3D(dimension, 0, format, spec.data.size.width, spec.data.size.height, spec.data.size.depth, 0, data_format, type, spec.data.data);
                }
            default:
                {
                    VANE_UNREACHABLE("Unknown texture data type");
                }
        }


        
    }

    void MutableTexture::Bind(uint slot) {
        if(GLAD_GL_ARB_direct_state_access) {
            glBindTextureUnit(slot, m_handle._n);
        }else {
            glActiveTexture(GL_TEXTURE0 + slot);
            glBindTexture(m_dimension, m_handle._n);
        }
    }

    void MutableTexture::Release(uint slot) {
        if(GLAD_GL_ARB_direct_state_access) {
            glBindTextureUnit(slot, 0);
        }else {
            glActiveTexture(GL_TEXTURE0 + slot);
            glBindTexture(m_dimension, 0);
        }
    }

    void UploadData(i64 x, i64 y, const TextureData& data) {
    }

    MutableTexture::~MutableTexture() {
        glDeleteTextures(1, &m_handle._n);
    }
    

    ImmutableTexture::ImmutableTexture(const TextureSpecification& spec) {
        VANE_CORE_VERIFY(GLAD_GL_ARB_texture_storage, "GL_ARB_texture_storage extension isn't supported on this device/OS/driver");

        uint id;
        glGenTextures(1, &id);
        m_handle._n = id;

        GLenum dimension = GetTextureDimension(spec.dimension);
        GLenum type = GetTextureType(spec.data.type);
        GLenum format = GetTextureFormat(spec.format);
        GLenum data_format = GetTextureFormat(spec.data.format);

        m_dimension = dimension;

        this->Bind(0);

        switch(spec.data.dimension) {
            case TEXTURE_1D:
                {
                    glTexStorage1D(dimension, 0, format, spec.data.size.width);
                }
            case TEXTURE_2D:
                {
                    glTexStorage2D(dimension, 0, format, spec.data.size.width, spec.data.size.height);
                }
            case TEXTURE_3D:
                {
                    glTexStorage3D(dimension, 0, format, spec.data.size.width, spec.data.size.height, spec.data.size.depth);
                }
            default:
                {
                    VANE_UNREACHABLE("Unknown texture data type");
                }
        }


        
    }

    void ImmutableTexture::Bind(uint slot) {
        if(GLAD_GL_ARB_direct_state_access) {
            glBindTextureUnit(slot, m_handle._n);
        }else {
            glActiveTexture(GL_TEXTURE0 + slot);
            glBindTexture(m_dimension, m_handle._n);
        }
    }

    void ImmutableTexture::Release(uint slot) {
        if(GLAD_GL_ARB_direct_state_access) {
            glBindTextureUnit(slot, 0);
        }else {
            glActiveTexture(GL_TEXTURE0 + slot);
            glBindTexture(m_dimension, 0);
        }
    }

    ImmutableTexture::~ImmutableTexture() {
        glDeleteTextures(1, &m_handle._n);
    }
}
