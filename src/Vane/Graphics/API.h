#ifndef VANE_GRAPHICS_API
#define VANE_GRAPHICS_API

#include "Vane/Utils/Aliases.h"

namespace Vane::Graphics {
    union Handle {
        uint    _n;
        void*   _p;
    };

    enum class Backend {
        OpenGL,
        Headless,
        None
    };

    struct WindowInfo {
        Backend backend;
        uint width;
        uint height;
        std::string title;
    };

    struct WindowSpecification {
        Backend backend;
        uint width;
        uint height;
        std::string title;
       bool vsync = true;
    };

    enum class ShaderType {
        Vertex,
        Pixel
    };

    using ShaderPair = std::pair<ShaderType, std::string>;

    struct ShaderSpecification {
        std::vector<ShaderPair> sources;

        ShaderSpecification(const std::initializer_list<ShaderPair>& list) : sources(list) {}
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
    };

    struct TextureSpecification {
        TextureDimension    dimension;
        TextureDataFormat   data_format;
        TextureColorFormat  color_format;
        TextureSize         size;
        void*               data;
    };

    static Backend s_backend = Backend::None;

    static inline Backend GetBackend() {
        return s_backend;
    }

    class GraphicsObject {
        public:
            virtual ~GraphicsObject() = default;

            virtual const Handle& GetHandle() = 0;
    };

    class Window : public GraphicsObject {
        public:
            virtual const WindowInfo& GetInfo() const = 0;

            virtual void SetVSync(bool enabled) = 0;
            virtual bool IsVSync() const = 0;

            virtual void Update() = 0;


            // The implementation of this static method is
            // in platform/Desktop/Linux or platform/Desktop/Windows directory
            // It is only defined once since if you're compiling with windows
            // as a target platform/Desktop/Windows is gonna be chosen
            // and viceversa with linux
            // NOTE: The method this is gonna use is PLATFORM specific not BACKEND specific, the window created is chosen through the backend option in the passed specification struct (IF that graphics api is available on this platform)
            static Window* Create(const WindowSpecification& spec);
    };


    class Shader : public GraphicsObject {
        public:
            virtual void Bind() = 0;
            virtual void Release() = 0;

            static Shader* Create(const ShaderSpecification& spec);
    };


    class Texture : public GraphicsObject {
        public:
            virtual void Bind(uint slot) = 0;
            virtual void Release(uint slot) = 0;

            virtual void UploadData(i64 x, i64 y, const TextureData& data);

    };

    class Context : public GraphicsObject {
        public:
            virtual void SwapBuffers() = 0;
    };

}

#endif
