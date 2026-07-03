#include "API2.h"
#include "Vane/Graphics/API2.h"
#include <memory>

namespace Vane::Graphics::OpenGL {

    constexpr usz DEFAULT_COMMAND_BUFFER_SIZE = 2 * 1024 * 1024;
    constexpr usz DEFAULT_COMMAND_POOL_SIZE = 10;


    TextureHandle Device::CreateTexture(const TextureSpecification& spec) {
        TextureHandle handle = {m_texture_registry.Alloc(
            TextureData{0, spec.dimension, spec.data_format, spec.color_format, spec.size}
        )};

        m_loading_queue.PushTexture(m_texture_registry, handle, spec);

        return handle;
    }

    ShaderHandle Device::CreateShader(const ShaderSpecification& spec) {
        ShaderHandle handle = {m_shader_registry.Alloc(
            ShaderData{0, spec.type, spec.source.size()}
        )};

        m_loading_queue.PushShader(m_shader_registry, handle, spec);

        return handle;
    }

    PipelineHandle Device::CreatePipeline(const PipelineSpecification& spec) {
        PipelineHandle handle = {m_pipeline_registry.Alloc(
            PipelineData{spec.vertex_shader, spec.pixel_shader}
        )};

        m_loading_queue.PushPipeline(m_pipeline_registry, handle, spec);

        return handle;
    }

    CommandPoolHandle Device::CreateCommandPool() {
        CommandPool* pool = new CommandPool();


        for(usz i = 0; i < DEFAULT_COMMAND_POOL_SIZE; i++) {
            CommandBuffer* buffer = new CommandBuffer();
            buffer->GetQueue().Reserve(DEFAULT_COMMAND_BUFFER_SIZE);
            pool->GetFree().push_back(buffer);
        }

        return {m_command_pool_registry.Alloc(pool)};
    }

    Graphics::CommandBuffer* Device::AllocateCommandBuffer(CommandPoolHandle handle) {
        CommandBuffer* buf = nullptr;
        CommandPool* pool = m_command_pool_registry[handle.id];

        if(!pool->GetFree().empty()) {
            buf = pool->GetFree().back();
            pool->GetFree().pop_back();
        }else {
            buf = new CommandBuffer{};
            buf->GetQueue().Reserve(DEFAULT_COMMAND_BUFFER_SIZE);
        }

        VANE_CORE_ASSERT(buf != nullptr, "CommandBuffer cannot be nullptr");
        pool->GetAllocated().push_back(buf);

        return buf;
    }

    void Device::ResetCommandPool(CommandPoolHandle handle) {
        CommandPool* pool = m_command_pool_registry[handle.id];
        for(auto* buf : pool->GetAllocated()) {
            buf->Clear();
            pool->GetFree().push_back(buf);
        }
        pool->GetAllocated().clear();
    }

	void ResourceLoadingQueue::PushTexture(const Registry<TextureData>& registry, TextureHandle handle, 
			const TextureSpecification& spec) {
		m_buffer.push_back(static_cast<u8>(LoadingOpcode::CreateTexture));
        Align(alignof(CreateTextureData));

        usz pixel_size = 0;
        switch(spec.data_format) {
            case TextureDataFormat::Float:
                {
                    pixel_size = sizeof(float);
                }
            case TextureDataFormat::UByte:
                {
                    pixel_size = sizeof(u8);
                }
        }

        switch(spec.color_format) {
            case TextureColorFormat::RGB:
                {
                    pixel_size *= 3;
                }
            case TextureColorFormat::RGBA:
                {
                    pixel_size *= 4;
                }
        }

        usz total_size = spec.size.GetTotalSize(pixel_size);

        CreateTextureData tdata = {
            handle, registry[handle]
        };

        usz offset = m_buffer.size();

        m_buffer.resize(offset + sizeof(tdata));
        std::memcpy(&m_buffer[offset], &tdata, sizeof(tdata));

        offset += sizeof(tdata);
        m_buffer.resize(offset + total_size);
        std::memcpy(&m_buffer[offset], spec.data, total_size);

        Align(alignof(std::max_align_t));
	}

	void ResourceLoadingQueue::PushShader(const Registry<ShaderData>& registry, ShaderHandle handle,
                const ShaderSpecification& spec) {
		m_buffer.push_back(static_cast<u8>(LoadingOpcode::CreateShader));
        Align(alignof(CreateShaderData));
        CreateShaderData sdata = {handle, registry[handle]};

        usz offset = m_buffer.size();

        m_buffer.resize(offset + sizeof(sdata));

        std::memcpy(&m_buffer[offset], &sdata, sizeof(sdata));

        offset += sizeof(sdata);
        usz size = spec.source.size();

        m_buffer.resize(offset + size);

        std::memcpy(&m_buffer[offset], spec.source.data(), size);

        Align(alignof(std::max_align_t));
	}

    void ResourceLoadingQueue::PushPipeline(const Registry<PipelineData>& registry, PipelineHandle handle,
                const PipelineSpecification& spec) {
        m_buffer.push_back(static_cast<u8>(LoadingOpcode::CreatePipeline));
        Align(alignof(CreatePipelineData));


        CreatePipelineData pdata = {
            handle, registry[handle]
        };
        usz offset = m_buffer.size();

        m_buffer.resize(offset + sizeof(pdata));

        std::memcpy(&m_buffer[offset], &pdata, sizeof(pdata));

        Align(alignof(std::max_align_t));
    }

}
