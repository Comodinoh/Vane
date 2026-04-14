#include "Application.h"
#include <chrono>
#include <gcpch.h>

#include <Vane/Core/GWindow.h>
#include <Vane/Core/Timing.h>
#include <Vane/Events/ApplicationEvent.h>
#include <Vane/Events/Event.h>
#include <Vane/Renderer/Renderer.h>
#include "Core.h"

namespace Vane
{
Application* Application::s_Instance = nullptr;

Application::Application()
{
    VANE_PROFILE_FUNC();
    ProcessedTime delta; {
        auto start = steady_clock::now();
        ScopedTimer timer(start, delta);
        VANE_CORE_ASSERT(!s_Instance,
                       "Application should not be initalized twice!")
        s_Instance = this;

        m_Window = std::unique_ptr<Window>(Window::Create({Backend::OpenGL}));
        m_Window->SetEventCallback(VANE_BIND_FN1(Application::OnEvent));

        m_AssetsManager = std::make_unique<AssetsManager>();

        VANE_CORE_ASSERT(m_AssetsManager, "AssetsManager should not be null!");

        Graphics::Init({1000});
        // VANE_CORE_TRACE("Allocated {0}",
        //               Memory::GetGlobalAllocator()->GetStatistics()->Allocated);
    }

    VANE_CORE_INFO("Took {0} seconds to initialize application.",
                 delta.GetSeconds());
}

Application::~Application()
{
    VANE_PROFILE_FUNC();
    s_Instance = nullptr;
    Graphics::Shutdown();
}

void Application::Exit()
{
    m_Running = false;
    Core::SetRunning(false);
}

void Application::Restart()
{
    m_Running = false;
}

void Application::Run()
{
    VANE_PROFILE_FUNC();
    while (m_Running) {
        VANE_PROFILE_SCOPE("RunLoop");
        ProcessedTime elapsed;
        m_FrameTimer.ProcessTime(elapsed, steady_clock::now());

        for (Layer* layer : m_LayerStack) {
            layer->OnUpdate(elapsed);
        }
        m_Window->OnUpdate();
    }
}

void Application::PushLayer(Layer* layer) { m_LayerStack.PushLayer(layer); }

void Application::PushOverlay(Layer* overlay)
{
    m_LayerStack.PushOverlay(overlay);
}

void Application::OnEvent(Event& e)
{
    VANE_PROFILE_FUNC();
    EventDispatcher dispatcher(e);

    dispatcher.Dispatch<WindowCloseEvent>(
        VANE_BIND_FN1(Application::OnWindowClose));
    dispatcher.Dispatch<WindowResizeEvent>(
        VANE_BIND_FN1(Application::OnWindowResize));

    for (auto it = m_LayerStack.end(); it != m_LayerStack.begin();) {
        (*--it)->OnEvent(e);
        if (e.Handled)
            break;
    }
}

bool Application::OnWindowClose(WindowCloseEvent&)
{
    Exit();
    return true;
}

bool Application::OnWindowResize(WindowResizeEvent& e)
{
    VANE_PROFILE_FUNC();
    Graphics::SetViewport({0, 0}, {e.GetNewWidth(), e.GetNewHeight()});
    return false;
}
} // namespace Vane
