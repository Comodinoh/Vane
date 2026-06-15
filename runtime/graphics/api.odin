package Graphics

OPENGL :: #config(VANE_OPENGL, true)
VULKAN :: #config(VANE_OPENGL, false)

Backend :: enum {
    OpenGL,
    Vulkan,
    Headless
}
