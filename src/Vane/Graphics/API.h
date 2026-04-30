#ifndef VANE_GRAPHICS_API
#define VANE_GRAPHICS_API

#include "Vane/Utils/Aliases.h"

namespace Vane::Graphics {
    class GraphicsObject {
        public:
            virtual ~GraphicsObject() = default;
            
            virtual void* GetHandle() = 0;
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
        uint width;
        uint height;
        std::string title;

    };

    static Backend s_Backend = Backend::None; 

    static inline Backend GetBackend() {
        return s_Backend;
    }

    class Window : public GraphicsObject{
        public:
            virtual const WindowInfo& GetInfo() = 0; 
            virtual void SetVSync(bool enabled) = 0;

            virtual void Update() = 0;

            // The implementation of this static method is 
            // in platform/Desktop/Linux or platform/Desktop/Windows directory
            // It is only defined once since if you're compiling with windows 
            // as a target platform/Desktop/Windows is gonna be chosen
            // and viceversa with linux
            // NOTE: The method this is gonna use is PLATFORM specific not BACKEND specific, the window created is chosen through the backend option in the passed specification struct (IF that graphics api is available on this platform)
            static Window* Create(const WindowSpecification& spec);
    };

    class Context : public GraphicsObject {
        public:
            virtual void SwapBuffers() = 0;
    };

}

#endif
