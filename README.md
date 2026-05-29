# Overview
2D/3D (Visual Novel) Game engine written in the latest C++ standards.

If you want to see the past archived version of this repository, check out the [old](https://github.com/Comodinoh/GCrisp/tree/old) branch.

# Goals
- Redesign and refactor the RenderAPI for better readability
- Redesign the application integration, API and loop
- Memory tracing and tracking
- Multithreading and command queue
- Optional editor separate from the runtime
- Create a basic wiki explaining how to use runtime and editor

# Usage
## Linux
__Note:__ CMake >= 3.30.4 required

To use the Vane runtime in your project, you can import it with CMake by making a submodule:
```bash
    git submodule add https://github.com/Comodinoh/Vane.git lib/Vane
    git submodule update --init --remote --recursive lib/Vane
```

Then add that folder as a subdirectory in your `CMakeLists.txt` file and link the library with:
```CMake 
    add_subdirectory(lib/Vane)
    target_link_libraries(${PROJECT_NAME} PUBLIC Vane)
```
    
## Windows
__Note:__ CMake >= 3.30.4 required

Using the Vane runtime on windows is similar.
You can compile the project in both Visual Studio or CLion, 
whether it'd be with MSVC, CLang or GCC (I usually find GCC compilation times on windows to be significantly slower than on linux for some reason).

# Getting Started

I recommend checking out the [wiki](https://github.com/Comodinoh/Vane/wiki) to get started with the engine (Still work in progress!).
