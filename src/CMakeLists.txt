set(VANE_SOURCES
        Vane/Assets/Assets.h
        Vane/Assets/AssetsManager.cpp
        Vane/Assets/AssetsManager.h
        Vane/Core/Application.cpp
        Vane/Core/Application.h
        Vane/Core/Base.h
        Vane/Core/CameraController.cpp
        Vane/Core/CameraController.cpp
        Vane/Core/CameraController.h
        Vane/Core/Core.cpp
        Vane/Core/Core.h
        Vane/Core/Input.h
        Vane/Core/Layer.cpp
        Vane/Core/Layer.h
        Vane/Core/LayerStack.cpp
        Vane/Core/LayerStack.h
        Vane/Core/Log.cpp
        Vane/Core/Log.h
        Vane/Core/Memory/Allocable.h
        Vane/Core/Memory/Allocator.cpp
        Vane/Core/Memory/Allocator.h
        Vane/Core/Memory/Statistics.h
        Vane/Core/Timing.cpp
        Vane/Core/Timing.h
        Vane/Core/UUID.cpp
        Vane/Core/UUID.h
        Vane/Core/Window.cpp
        Vane/Entry.h
        Vane/Events/ApplicationEvent.h
        Vane/Events/Event.h
        Vane/Events/KeyEvent.h
        Vane/Events/MouseEvent.h
        Vane/Graphics/API.h
        Vane/Vane.h
)

add_library(Vane-Source STATIC ${VANE_SOURCES})

target_include_directories(Vane-Source PUBLIC .)

if (VANE_BUILD_DISTRIBUTABLE)
    target_compile_definitions(Vane-Source PUBLIC VANE_DIST=1)
    set(VANE_PROFILING OFF)
endif ()

if (VANE_PROFILING)
    target_compile_definitions(Vane-Source PUBLIC VANE_PROFILING=1)
    message(STATUS "${CMAKE_PROJECT_NAME}: Profiling enabled")
else ()
    if (VANE_FORCE_PROFILING)
        target_compile_definitions(Vane-Source PUBLIC VANE_PROFILING=1)
    endif ()
    target_compile_definitions(Vane-Source PUBLIC VANE_PROFILING=0)
    message(STATUS "${CMAKE_PROJECT_NAME}: Profiling disabled")
endif ()

target_precompile_headers(Vane-Source PUBLIC gcpch.h)
