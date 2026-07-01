#include "API2.h"
#include "Vane/Graphics/API.h"
#include "Vane/Graphics/API2.h"

namespace Vane::Graphics::OpenGL {

    TextureHandle Device::CreateTexture(const TextureSpecification& spec) {
        TextureHandle handle = {m_texture_registry.Alloc(spec)};

        m_loading_queue.PushTexture(handle, spec);

        return handle;
    }

    ShaderHandle Device::CreateShader(const ShaderSpecification& spec) {
        ShaderHandle handle = {m_shader_registry.Alloc(spec)};

        m_loading_queue.PushShader(handle, spec);

        return handle;
    }

	void ResourceLoadingQueue::PushTexture(TextureHandle handle, 
			const TextureSpecification& spec) {
		m_buffer.push_back(static_cast<u8>(LoadingOpcode::CreateTexture));
        Align(alignof(TextureData));

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

        TextureData tdata = {
            .handle = handle,
            .dimension = spec.dimension,
            .data_format = spec.data_format,
            .color_format = spec.color_format,
            .size = total_size,
        };

        usz offset = m_buffer.size();

        m_buffer.resize(offset + sizeof(tdata));
        std::memcpy(&m_buffer[offset], &tdata, sizeof(tdata));

        offset += sizeof(tdata);
        m_buffer.resize(offset + total_size);
        std::memcpy(&m_buffer[offset], spec.data, total_size);

        Align(alignof(std::max_align_t));
	}

	void ResourceLoadingQueue::PushShader(ShaderHandle handle,
                const ShaderSpecification& spec) {
		m_buffer.push_back(static_cast<u8>(LoadingOpcode::CreateShader));
        ShaderData sdata = {handle, spec.sources.size()};
		

        usz offset = m_buffer.size();

        m_buffer.resize(offset + sizeof(sdata));

        std::memcpy(&m_buffer[offset], &sdata, sizeof(sdata));

        offset += sizeof(sdata);
        usz total_size = 0;

        for(auto& pair : spec.sources) {
            total_size += sizeof(pair.first) + sizeof(usz) + pair.second.size();
        }

        m_buffer.resize(offset + total_size);

        for(auto& pair : spec.sources) {
            ShaderElementData element_data = {
                pair.first,
                pair.second.size()
            };

            std::memcpy(&m_buffer[offset], &element_data, sizeof(element_data));

            offset += sizeof(element_data);

            std::memcpy(&m_buffer[offset], pair.second.data(), pair.second.size());

            offset += pair.second.size();
        }

        Align(alignof(std::max_align_t));

	}

}
