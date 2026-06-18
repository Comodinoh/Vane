package Graphics

OPENGL :: #config(VANE_OPENGL, true)
VULKAN :: #config(VANE_OPENGL, false)

OPENGL_VERSION_MAJOR :: 4
OPENGL_VERSION_MINOR :: 6

Backend :: enum {
    None = 0,
    OpenGL,
    Vulkan,
    Headless
}
