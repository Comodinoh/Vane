#pragma once

#define ENGINE_NAME "Vane"

#include <memory>

#define BIT(x) (1 << x)
#define VANE_BIND_FN1(func) std::bind(&func, this, std::placeholders::_1)
#define VANE_CONCAT(x, y) x##y

#define VANE_TODO(x) VANE_ERROR("TODO: {0}", x)

#ifndef VANE_RELEASE

#if defined(VANE_WIN32)
#define VANE_BREAKPOINT() __debugbreak()
#elif defined(VANE_POSIX)
#include <signal.h>
#define VANE_BREAKPOINT() raise(SIGTRAP)
#else
#error "Platform doesn't support debugbreak!"
#endif

#define VANE_ASSERT(condition, ...)                                              \
    if (!(condition)) {                                                        \
        VANE_ERROR("Assertion Failed: {0}", __VA_ARGS__);                        \
        VANE_BREAKPOINT();                                                       \
    }

#define VANE_CORE_ASSERT(condition, ...)                                         \
    if (!(condition)) {                                                        \
        VANE_CORE_ERROR("Assertion Failed: {0}", __VA_ARGS__);                   \
        VANE_BREAKPOINT();                                                       \
    }

#else

#define VANE_ASSERT(condition, ...)
#define VANE_CORE_ASSERT(condition, ...)

#endif

#ifndef VANE_DIST

#define VANE_VERIFY(condition, msg, ...)                                         \
    if (!(condition)) {                                                        \
        VANE_ERROR(msg, __VA_ARGS__);                                            \
    }

#define VANE_CORE_VERIFY(condition, msg, ...)                                    \
    if (!(condition)) {                                                        \
        VANE_CORE_ERROR(msg, __VA_ARGS__);                                       \
    }

#else

#define VANE_VERIFY(condition, msg, ...)
#define VANE_CORE_VERIFY(condition, msg, ...)

#endif

// Note: This is currently way too slow to use for
// true profiling purposes, to be remade.
#define VANE_PROFILING 0
#if VANE_PROFILING

#ifndef __JETBRAINS_IDE__

#define VANE_PROFILE_START(name) ::Vane::TimingsProfiler::StartProfiler(name);
#define VANE_PROFILE_END() ::Vane::TimingsProfiler::EndProfiler();

#define VANE_PROFILE_SCOPE2(name, line)                                          \
    ProfileResult VANE_CONCAT(result, line) = {name,                             \
                                             std::this_thread::get_id()};      \
    ::Vane::ProfilerTimer VANE_CONCAT(timer, line)(VANE_CONCAT(result, line));

#define VANE_PROFILE_SCOPE(name) VANE_PROFILE_SCOPE2(name, __LINE__)

#if defined(_MSC_VER) && !defined(__llvm__) && !defined(__GNUC__) &&           \
    !defined(__clang__)

#define VANE_PROFILE_FUNC() VANE_PROFILE_SCOPE(__FUNCSIG__)

#else

#define VANE_PROFILE_FUNC() VANE_PROFILE_SCOPE(__PRETTY_FUNCTION__)

#endif

#else

#define VANE_PROFILE_START(1)
#define VANE_PROFILE_END()
#define VANE_PROFILE_SCOPE2(1, 2)
#define VANE_PROFILE_SCOPE(1)
#define VANE_PROFILE_FUNC() VANE_PROFILE_SCOPE(__PRETTY_FUNCTION__)

#endif

#else

#define VANE_PROFILE_START(name)
#define VANE_PROFILE_END()
#define VANE_PROFILE_SCOPE2(name, line)
#define VANE_PROFILE_SCOPE(name)
#define VANE_PROFILE_FUNC() VANE_PROFILE_SCOPE(__PRETTY_FUNCTION__)

#endif

namespace Vane {
template <typename T> using Reference = std::shared_ptr<T>;

template <typename T> using ScopedPtr = std::unique_ptr<T>;
} // namespace Vane
