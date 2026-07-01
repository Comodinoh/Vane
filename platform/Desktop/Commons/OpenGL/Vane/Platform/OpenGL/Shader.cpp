#include "Vane/Graphics/API.h"
#include "Vane/Platform/OpenGL/API.h"

#include <glad/glad.h>

namespace Vane::Graphics::OpenGL {

    using ShaderIDPair = std::pair<ShaderType, uint>;

    GLenum GetShaderType(Graphics::ShaderType type) {
        switch(type) {
            case Graphics::ShaderType::Pixel:
                return GL_FRAGMENT_SHADER;
            case Graphics::ShaderType::Vertex:
                return GL_VERTEX_SHADER;
            default:
        }

        VANE_CORE_VERIFY(false, "Unreachable");
        return 0;
    }

    const char* GetShaderTypeName(Graphics::ShaderType type) {
        switch(type) {
            case Graphics::ShaderType::Pixel:
                return "Pixel";
            case Graphics::ShaderType::Vertex:
                return "Vertex";
            default:
        }

        VANE_CORE_VERIFY(false, "Unreachable");
        return nullptr;
    }

    Shader::Shader(const ShaderSpecification& spec) : m_handle{glCreateProgram()}{
        std::vector<ShaderIDPair> shaders;
        shaders.reserve(spec.sources.size());
        for(const auto&[type, source] : spec.sources) {
            uint id = glCreateShader(GetShaderType(type));

            shaders.push_back(std::make_pair(type, id));

            const char* source_str = source.c_str();

            glShaderSource(id, 1, &source_str, NULL);
            glCompileShader(id);

            int status;
            glGetShaderiv(id, GL_COMPILE_STATUS, &status);
            if(status == GL_FALSE) {
                int max_len;
                glGetShaderiv(id, GL_INFO_LOG_LENGTH, &max_len);
                std::string err;
                err.reserve(max_len);

                glGetShaderInfoLog(id, max_len, &max_len, err.data());

                VANE_CORE_ERROR("Failed to compile {} shader with id {}. Refer to the logs below:", GetShaderTypeName(type), id); 
                VANE_CORE_ERROR("{}", err);
                VANE_CORE_VERIFY(false);
                return;
            }

            glAttachShader(m_handle._n, id);
        }

        uint id = m_handle._n;

        glLinkProgram(id);
        
        int status;
        glGetProgramiv(id, GL_LINK_STATUS, &status);
        if(status == GL_FALSE) {
            int max_len;
            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &max_len);
            std::string err;
            err.reserve(max_len);
            

            glGetShaderInfoLog(id, max_len, &max_len, err.data());

            glDeleteProgram(id);
            
            for(const auto&[_, shader_id] : shaders) {
                glDeleteShader(shader_id); 
            }

            VANE_CORE_ERROR("Failed to link shader program with id {}. Refer to the logs below:", id); 
            VANE_CORE_ERROR("{}", err);
            VANE_CORE_VERIFY(false);
            return;
        }

        glUseProgram(id);

        for(const auto&[_, shader_id] : shaders) {
            glDetachShader(id, shader_id);
            glDeleteShader(shader_id);
        }
    }

    Shader::~Shader() {
        glDeleteProgram(m_handle._n);
    }


    void Shader::Bind() {
        glUseProgram(m_handle._n);
    }

    void Shader::Release() {
        glUseProgram(0);
    }
}
