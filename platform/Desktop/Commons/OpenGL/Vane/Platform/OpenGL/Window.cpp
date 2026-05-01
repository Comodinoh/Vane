#include "API.h"

#include <GLFW/glfw3.h>

#include "Vane/Core/Base.h"

namespace Vane::Graphics::OpenGL {

    void glfwErrorCallback(int code, const char* desc) {
        VANE_CORE_ERROR("glfw Error: {} (code {})", desc, code);
    }


    Window::Window(const WindowSpecification& spec) : 
        m_info({spec.backend, spec.width, spec.height, spec.title}),
        m_vsync(spec.vsync) {
        Graphics::s_backend = spec.backend;

        VANE_CORE_VERIFY(glfwInit(), "Could not initialize glfw");
    

        glfwSetErrorCallback(glfwErrorCallback);

                
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

        VANE_CORE_VERIFY(m_handle = glfwCreateWindow(spec.width, spec.height, spec.title.c_str(), nullptr, nullptr), 
            "Could not create glfw window"
        );

        m_context = new OpenGL::Context();

        if(spec.vsync) {
           glfwSwapInterval(1); 
        } else {
           glfwSwapInterval(0);
        }

        //TODO: Implement all callbacks
    }

    void* Window::GetHandle() {
        return m_handle;
    }

    const WindowInfo& Window::GetInfo() const {
        return m_info;
    }

    void Window::SetVSync(bool enabled) {
        if(enabled) {
            glfwSwapInterval(1);
        } else {
            glfwSwapInterval(0);
        }

        m_vsync = enabled;
    }

    bool Window::IsVSync() const {
        return m_vsync;
    }

    void Window::Update() {
        glfwPollEvents();
        m_context->SwapBuffers();
    }

}
