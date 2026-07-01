#ifndef VANE_OPENGL_API_H
#define VANE_OPENGL_API_H

#include "Vane/Graphics/API.h"

namespace Vane::Graphics::OpenGL {
    class Window : public Graphics::Window {
        public:
            Window(const WindowSpecification& spec);
            ~Window() override;
            
            virtual const Graphics::Handle& GetHandle() override;

            virtual const WindowInfo& GetInfo() const override;

            virtual void SetVSync(bool enabled) override;
            virtual bool IsVSync() const override;

            virtual void Update() override;
        private:
            Graphics::Handle m_handle;
            Context* m_context;
            WindowInfo m_info;
            bool m_vsync;
    };

    class Shader : public Graphics::Shader {
        public:
            Shader(const ShaderSpecification& spec);
            ~Shader() override;

            virtual const Graphics::Handle& GetHandle() override;

            virtual void Bind() override;
            virtual void Release() override;
        private:
            Graphics::Handle m_handle;
    };

    class MutableTexture : public Graphics::MutableTexture {
        public:
            MutableTexture(const TextureSpecification& spec);
            ~MutableTexture() override;

            virtual const Graphics::Handle& GetHandle() override;

            virtual void Bind(uint slot) override;
            virtual void Release(uint slot) override;

            virtual void UploadData(i64 x, i64 y, const TextureData& data) override;
        private:
            Graphics::Handle    m_handle;
            uint                m_dimension;
    };

    class ImmutableTexture : public Graphics::MutableTexture {
        public:
            ImmutableTexture(const TextureSpecification& spec);
            ~ImmutableTexture() override;

            virtual const Graphics::Handle& GetHandle() override;

            virtual void Bind(uint slot) override;
            virtual void Release(uint slot) override;
        private:
            Graphics::Handle    m_handle;
            uint                m_dimension;
    };

    class Context : public Graphics::Context {
        public:
            Context(void* windowHandle);

            virtual const Graphics::Handle& GetHandle() override;

            virtual void SwapBuffers() override;
        private:
            Graphics::Handle m_handle;
    };
}

#endif
