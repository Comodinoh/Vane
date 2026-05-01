#ifndef VANE_OPENGL_API_H
#define VANE_OPENGL_API_H

#include "Vane/Graphics/API.h"

namespace Vane::Graphics::OpenGL {
    class Window : public Graphics::Window {
        public:
            Window(const WindowSpecification& spec);
            ~Window() override;
            
            virtual void* GetHandle() override;

            virtual const WindowInfo& GetInfo() const override;

            virtual void SetVSync(bool enabled) override;
            virtual bool IsVSync() const override;

            virtual void Update() override;
        private:
            void* m_handle;
            Context* m_context;
            WindowInfo m_info;
            bool m_vsync;
    };

    class Context : public Graphics::Context {
        public:
            Context(void* windowHandle);

            virtual void* GetHandle() override;

            virtual void SwapBuffers() override;
        private:
            void* m_handle;
    };
}

#endif
