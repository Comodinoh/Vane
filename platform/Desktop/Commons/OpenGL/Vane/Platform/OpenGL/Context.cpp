#include "API.h"

#include <GLFW/glfw3.h>
#include <glad/glad.h>

namespace Vane::Graphics::OpenGL {
    
    Context::Context(void* windowHandle) : m_handle(windowHandle) {
        GLFWwindow* window = static_cast<GLFWwindow*>(windowHandle);

        glfwMakeContextCurrent(window);
        VANE_CORE_VERIFY(gladLoadGLLoader((GLADloadproc)glfwGetProcAddress), 
                "Could not load glad from glfw"
        );
    }

    void Context::SwapBuffers() {
        glfwSwapBuffers(static_cast<GLFWwindow*>(m_handle));
    }

}
