#include "Vane/Assets/Assets.h"
#include <Vane/Vane.h>
#include <GLFW/glfw3.h>

using namespace Vane;

class TestLayer : public Layer
{
public:
    TestLayer() : Layer("Test"), m_CameraController(16.0f / 9.0f, 5)
    {
        m_WhiteTextureID = Application::Get().GetAssetsManager().LoadAsset({AssetType::Texture2D, "WhiteTexture.png"});
        // auto& app = Application::Get();
        // m_VertexArray.reset(app.GetGraphicsCreator()->CreateVertexArray());
        //
        // float vertices[] =
        // {
        //     0.5, 0.5, 0.0, 1.0, 1.0,
        //     0.5, -0.5, 0.0, 1.0, 0.0,
        //     -0.5, -0.5, 0.0, 0.0, 0.0,
        //     -0.5, 0.5, 0.0, 0.0, 1.0,
        // };
        //
        // m_VertexBuffer.reset(app.GetGraphicsCreator()->CreateVertexBuffer({vertices,
        // sizeof(vertices)}));
        //
        // Graphics::BufferLayout layout =
        // {
        //     {"a_Position", Graphics::ShaderDataType::Float3},
        //     {"a_TexCoord", Graphics::ShaderDataType::Float2}
        // };
        //
        // m_VertexBuffer->SetLayout(layout);
        // m_VertexArray->AddVertexBuffer(m_VertexBuffer);
        //
        // uint32_t indices[] =
        // {
        //     0, 1, 2,
        //     2, 3, 0
        // };
        // m_IndexBuffer.reset(app.GetGraphicsCreator()->CreateIndexBuffer({indices,
        // sizeof(indices)})); m_VertexArray->SetIndexBuffer(m_IndexBuffer);
        m_SubTexture = std::shared_ptr<Graphics::SubTexture2D>(
            Graphics::SubTexture2D::CreateFromCoords(
                AssetsManager::GetDefaultTexture(), {2, 2}, {256, 256}));
    }

    ~TestLayer()
    {
        const Memory::AllocatorStatistics& stats = Memory::GetGlobalAllocator()
            ->GetStatistics();
        VANE_CORE_INFO(
            "TestLayer: "
            "{0} Total MB used, "
            "{1} Total Allocations, "
            "{2} Total MB freed, "
            "{3} Total Frees",
            (static_cast<double>(stats.AllocatedBytes) / 1024.0) / 1024.0,
            stats.Allocated,
            (static_cast<double>(stats.FreedBytes) / 1024.0) / 1024.0,
            stats.Freed
            );
    }

    void OnUpdate(const ProcessedTime& delta) override
    {

        VANE_PROFILE_FUNC();
        // VANE_CORE_INFO("Elapsed time: {0}", static_cast<float>(delta));
        // Warning: movement will get messy while the camera is rotating

        {
            VANE_PROFILE_SCOPE("Camera Update - TestLayer")
            m_CameraController.OnUpdate(delta);
        }

        // const Memory::AllocatorStatistics& stats = Memory::GetGlobalAllocator()->
        //     GetStatistics();
        //
        // VANE_CORE_INFO(
        //     "TestLayer: "
        //     "{0} Total MB used, "
        //     "{1} Total Allocations, "
        //     "{2} Total MB freed, "
        //     "{3} Total Frees",
        //     (stats.AllocatedBytes / 1024) / 1024,
        //     stats.Allocated,
        //     (stats.FreedBytes / 1024) / 1024,
        //     stats.Freed
        //     );

        Graphics::Clear({0, 0, 0, 1});

        // auto shader =
        // Application::Get().GetAssetsManager().FetchShader("TextureBatchSlots.glsl");
        // Reference<Graphics::Texture>& texture =
        // Application::Get().GetAssetsManager().FetchTexture("default_texture.png");

        // {
        //     VANE_PROFILE_SCOPE("Render Prep - TestLayer");
        //     shader->Bind();
        //     texture->Bind();
        //     shader->UploadInt("u_Texture", 0);
        //     shader->UploadVec4("u_Color", glm::vec4(1.0f));
        // }

        // {
        //     VANE_PROFILE_SCOPE("Render Begin - TestLayer");
        //     Graphics::BeginRender(m_CameraController.GetCamera());
        // }
        //
        // {
        //     VANE_PROFILE_SCOPE("Geometry Submit - TestLayer");
        //     Graphics::Submit(m_VertexArray, shader);
        // }
        //
        // {
        //     VANE_PROFILE_SCOPE("Render End - TestLayer");
        //     Graphics::EndRender();
        // }

        {
            VANE_PROFILE_SCOPE("Render2D Begin - TestLayer");
            Graphics2D::BeginRender(m_CameraController.GetCamera());
        } {
            VANE_PROFILE_SCOPE("Render2D Draw - TestLayer");
            // Graphics2D::DrawQuad({-0.6, -0.6}, {1, 1}, texture);
            // Graphics2D::DrawQuad({1.4, 1.4}, {1, 1}, texture, {1, 0.8, 0.8,
            // 1}); Graphics2D::DrawQuad({0, 0},  {1, 1}, {1, 0, 0, 1});
            // Graphics2D::DrawQuad({-0.5, -0.5}, {0.5, 0.5}, {1, 0, 0, 1});
            // for (int y = -80;y<80;y++)
            // {
            //     for (int x = -80; x<80;x++)
            //     {
            //         Graphics2D::DrawQuad(glm::vec2(x, y)*0.50f, {0.25, 0.25},
            //         {1, 0, 0, 1});
            //     }
            // }
            // VANE_CORE_INFO("delta: {0}", delta.GetMillis());
            auto& app = Application::Get();
            auto [mx, my] = Input::GetMousePosition();
            // VANE_CORE_INFO("{0}, {1}", mx, my);

            mx = ((mx / app.GetWindow().GetWidth()) * 2 - 1) *
                 m_CameraController.GetCamera().GetScale();
            my = ((1 - (my / app.GetWindow().GetHeight())) * 2 - 1) *
                 m_CameraController.GetCamera().GetScale();
            // VANE_CORE_INFO("{0}, {1}", mx, my);

            i += delta;
            for (float x = -5.0f; x < 5.0f; x += 0.5f) {
                for (float y = -5.0f; y < 5.0f; y += 0.5f) {
                    float si = sin(i);
                    float ci = cos(i); 
                    Graphics2D::DrawQuadRST(
                        {
                            {x*cos(i/10.0f), y*sin(i/2.0f)},
                            {0.25f, 0.25f},
                            {cos(i) + x/10.0f, sin(i), 1.0f, 1.0f}
                        },
                        m_SubTexture, i/(1/(((x/(mx/3.0f))/(y/(my/3.0f))))));
                }
            }

            glm::vec3 pos = {
                mx * m_CameraController.GetCamera().GetAspectRatio(), my, 0.0f};
            pos += m_CameraController.GetCamera().GetPosition();

            Graphics2D::DrawQuadT(
                {
                    pos,
                    {1.0f, 1.0f}
                },
                m_WhiteTextureID);
            // Graphics2D::DrawQuad({ { 0.5f, 0.5f, 1.0f }, { 1.0f, 1.0f },
            // { 1.0f, 0.0f, 0.0f, 0.9f } });
        } {
            VANE_PROFILE_SCOPE("Render2D End - TestLayer");
            Graphics2D::EndRender();
        }
    }

    void OnEvent(Vane::Event& e) override { m_CameraController.OnEvent(e); }

private:
    // Reference<Graphics::VertexBuffer> m_VertexBuffer;
    // Reference<Graphics::IndexBuffer> m_IndexBuffer;
    // Reference<Graphics::VertexArray> m_VertexArray;
    Reference<Graphics::SubTexture2D> m_SubTexture;
    AssetID m_WhiteTextureID;

    OrthoCameraController m_CameraController;
    float i = 0.0f;
};

class TestApplication : public Vane::Application
{
public:
    TestApplication() { PushLayer(new TestLayer()); }

    ~TestApplication()
    {
    }
};

Vane::Application* Vane::CreateApplication()
{
    return new TestApplication();
}
