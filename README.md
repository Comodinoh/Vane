# Overview
2D/3D (Visual Novel) Game engine written in the latest C++ standards.

If you want to see the past archived version of this repository, check out the [old](https://github.com/Comodinoh/GCrisp/tree/old) branch.

# Goals
- Redesign and refactor the RenderAPI for better readability
- Redesign the application integration, API and loop
- Memory tracing and tracking
- Multithreading and command queue

# Usage
## Linux
__Note:__ CMake >= 3.30.4 required

To use GCrisp in your project, you can import it with CMake by making a submodule:
```bash
    git submodule add https://github.com/Comodinoh/GCrisp.git lib/GCrisp
    git submodule update --init --remote --recursive lib/GCrisp
```

Then add that folder as a subdirectory in your `CMakeLists.txt` file and link the library with:
```CMake 
    add_subdirectory(lib/GCrisp)
    target_link_libraries(${PROJECT_NAME} PUBLIC gcrisp)
```
    
## Windows
__Note:__ CMake >= 3.30.4 required

Using GCrisp on windows is similar.
You can compile the project in both Visual Studio or CLion, 
whether it'd be with MSVC, CLang or GCC (I usually find GCC compilation times on windows to be significantly slower than on linux for some reason).
I am personally testing MSVC and CLang support and working towards improving it.

# Getting Started

I recommend checking out the [wiki](https://github.com/Comodinoh/GCrisp/wiki) to get started with the engine (Still work in progress!).
