add_library(Vane-OpenGL INTERFACE)

set(VANE_OPENGL_SOURCES 
    Vane/Platform/OpenGL/Window.cpp
    Vane/Platform/OpenGL/Shader.cpp
    Vane/Platform/OpenGL/Context.cpp
)

target_sources(Vane-OpenGL INTERFACE ${VANE_OPENGL_SOURCES})

target_include_directories(Vane-OpenGL INTERFACE .)
