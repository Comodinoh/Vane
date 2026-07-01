#include "API.h"

#include <GLFW/glfw3.h>
#include <glad/glad.h>

namespace Vane::Graphics::OpenGL {
    
    Context::Context(void* windowHandle) : m_handle{._p = windowHandle} {
        GLFWwindow* window = static_cast<GLFWwindow*>(windowHandle);

        glfwMakeContextCurrent(window);
        VANE_CORE_VERIFY(gladLoadGLLoader((GLADloadproc)glfwGetProcAddress), 
                "Could not load glad from glfw"
        );
    }

    const Graphics::Handle& Context::GetHandle() {
        return m_handle;
    }

    void Context::SwapBuffers() {
        glfwSwapBuffers(static_cast<GLFWwindow*>(m_handle._p));
    }

}
