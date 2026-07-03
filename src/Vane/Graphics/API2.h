#ifndef VANE_GRAPHICS_API_H
#define VANE_GRAPHICS_API_H

#include <Vane/Utils/Aliases.h>

namespace Vane::Graphics {
    template<typename T>
    constexpr auto INVALID_HANDLE = Handle<T>(T{});

    template<typename T>
    struct Handle {
        T id;

        operator T() {
            return id;
        }

        inline bool IsValid() const {
            return id != INVALID_HANDLE<T>.id;
        }
    };

    struct TextureHandle : Handle<usz>{};
    struct ShaderHandle : Handle<usz>{};
    struct PipelineHandle : Handle<usz>{};
    struct CommandPoolHandle : Handle<usz>{};

    enum class ShaderType {
        Vertex,
        Pixel
    };

    using ShaderPair = std::pair<ShaderType, std::string>;

    struct ShaderSpecification {
        ShaderType  type;
        std::string source;
    };

    enum TextureDimension {
       TEXTURE_1D = 0,
       TEXTURE_2D,
       TEXTURE_3D
    };

    enum class TextureColorFormat {
        RGB,
        RGBA,
    };

    enum class TextureDataFormat {
        UByte,
        Float,
    };

    struct TextureSize {
        usz width;
        usz height;
        usz depth;

        TextureSize(usz _width, usz _height, usz _depth) :
            width(_width), height(_height), depth(_depth) {}

        TextureSize(usz _width, usz _height) : TextureSize(_width, _height, 0) {}

        TextureSize(usz _width) : TextureSize(_width, 0) {}

        usz GetTotalSize(usz pixel_size) const {
            usz total = pixel_size*width;

            if(height == 0) return total;
            total *= height;

            if(depth == 0) return total;
            total *= depth;
            
            return total;
        }
    };

    struct TextureSpecification {
        TextureDimension    dimension;
        TextureDataFormat   data_format;
        TextureColorFormat  color_format;
        TextureSize         size;
        void*               data;
    };

    struct PipelineSpecification {
        ShaderHandle vertex_shader;
        ShaderHandle pixel_shader;
    };

    class CommandBuffer {
        public:
            virtual void BindPipeline(PipelineHandle handle) = 0;
            virtual void Clear() = 0;
    };

    class Device {
        public:
            virtual ~Device() = default;

            virtual TextureHandle       CreateTexture(const TextureSpecification& spec) = 0;
            virtual ShaderHandle        CreateShader(const ShaderSpecification& spec) = 0;
            virtual PipelineHandle      CreatePipeline(const PipelineSpecification& spec) = 0;
            virtual CommandPoolHandle   CreateCommandPool() = 0;

            virtual CommandBuffer* AllocateCommandBuffer(CommandPoolHandle handle) = 0;
            virtual void           ResetCommandPool(CommandPoolHandle handle);

            virtual void Submit(CommandBuffer* buffer) = 0;
    };


}

#endif
