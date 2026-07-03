#ifndef VANE_GRAPHICS_OPENGL_H
#define VANE_GRAPHICS_OPENGL_H

#include "Vane/Utils/Aliases.h"
#include <Vane/Graphics/API2.h>
#include <cstddef>
#include <glad/glad.h>

namespace Vane::Graphics::OpenGL {
    enum class LoadingOpcode : u8 {
        CreateTexture = 0,
        CreateShader,
        CreatePipeline,
    };

    enum class CommandOpcode : u8 {
        BindPipeline,
    };

    struct BindPipelineCommand {
        PipelineHandle handle;
    };

    struct TextureData {
        GLint               gl_handle;
        TextureDimension    dimension;
        TextureDataFormat   data_format;
        TextureColorFormat  color_format;
        TextureSize         size;
    };

    struct ShaderData {
        GLint        gl_handle;
        ShaderType   type;
        usz          size;
    };

    struct PipelineData {
        ShaderHandle vertex_shader;
        ShaderHandle pixel_shader;
    };

    struct CreateTextureData {
        TextureHandle handle;
        TextureData   data;
    };

    struct CreateShaderData {
        ShaderHandle handle;
        ShaderData   data;
    };

    struct CreatePipelineData {
        PipelineHandle handle;
        PipelineData   data;
    };

    inline usz GetAlignedOffset(usz offset, usz alignment) {
        usz mask = alignment-1;

        return (offset + mask) & ~mask;
    }

    template<typename Data>
    class Registry {
        public:
            usz Alloc(const Data& data) {
                usz slot = m_next_free_slot;
                if(!m_freed_slots.empty()) {
                    slot = m_freed_slots.back();
                    m_freed_slots.pop_back();
                } else {
                    m_next_free_slot++;
                }

                if(m_handle_to_data.size() <= slot) {
                    m_handle_to_data.resize(slot+1);
                }

                m_data.push_back(data);

                m_data_to_handle.push_back(slot);

                m_handle_to_data[slot] = m_data.size()-1;

                return slot;
            }

            void Free(usz slot) {
                GLint idx = m_handle_to_data[slot];

                m_data[idx] = m_data[m_data.size()-1];

                m_data_to_handle[idx] = m_data_to_handle[m_data.size()-1];

                usz swapped = m_data_to_handle[m_data.size()-1];

                m_handle_to_data[swapped] = idx;

                m_data.pop_back();
                m_data_to_handle.pop_back();

                m_freed_slots.push_back(slot);
            }

            Data& Get(usz slot) {
                return m_data[m_handle_to_data[slot]];
            }

            const Data& Get(usz slot) const {
                return m_data[m_handle_to_data[slot]];
            }

            Data& operator[](usz slot) {
                return Get(slot);
            }

            const Data& operator[](usz slot) const {
                return Get(slot);
            }
        private:
            std::vector<usz>    m_handle_to_data;
            std::vector<Data>   m_data;
            std::vector<usz>    m_data_to_handle;

            usz m_next_free_slot = 0;
            std::vector<usz> m_freed_slots;
    };

    class ResourceLoadingQueue {
        public:
            void PushTexture(const Registry<TextureData>& registry, TextureHandle texture,
                const TextureSpecification& spec);
            void PushShader(const Registry<ShaderData>& registry, ShaderHandle handle,
                const ShaderSpecification& spec);
            void PushPipeline(const Registry<PipelineData>& registry, PipelineHandle handle,
                const PipelineSpecification& spec);

            inline const u8* Data() const {
                return m_buffer.data();
            }

            inline void Align(usz alignment) {
                usz size = m_buffer.size();
                usz aligned_size = GetAlignedOffset(size, alignment);

                if(aligned_size > size) {
                    m_buffer.resize(aligned_size, 0);
                }
            }
        private:
            std::vector<u8> m_buffer;
    };

    class CommandQueue {
        public:
            template<typename T>
            T& PushCommand(CommandOpcode opcode) {
                m_buffer.push_back(static_cast<u8>(opcode));

                usz offset = m_buffer.size();
                Align(alignof(T));

                m_buffer.resize(offset + sizeof(T));
                
                Align(alignof(std::max_align_t));

                return reinterpret_cast<T&>(m_buffer[offset]);
            }

            inline void Align(usz alignment) {
                usz size = m_buffer.size();
                usz aligned_size = GetAlignedOffset(size, alignment);

                if(aligned_size > size) {
                    m_buffer.resize(aligned_size, 0);
                }
            }

            inline void Reserve(usz bytes) {
                m_buffer.reserve(bytes);
            }

            inline void Clear() {
                m_buffer.clear();
            }
        private:
            std::vector<u8> m_buffer;
    };

    

    class CommandBuffer : public Graphics::CommandBuffer{
        public:
            inline virtual void BindPipeline(PipelineHandle handle) override {
                BindPipelineCommand& cmd = m_queue.PushCommand<BindPipelineCommand>(CommandOpcode::BindPipeline);
                cmd.handle = handle;
            }

            inline virtual void Clear() override {
                m_queue.Clear();
            }

            inline CommandQueue& GetQueue() {return m_queue;}
        private:
            CommandQueue m_queue;
    };

    class CommandPool {
        public:
            inline std::vector<CommandBuffer*>& GetFree() {return m_free_buffers;}
            inline std::vector<CommandBuffer*>& GetAllocated() {return m_free_buffers;}
        private:
            std::vector<CommandBuffer*> m_free_buffers;
            std::vector<CommandBuffer*> m_allocated_buffers;
    };

    class Device : public Graphics::Device {
        public:
            virtual TextureHandle CreateTexture(const TextureSpecification& spec) override;
            virtual ShaderHandle CreateShader(const ShaderSpecification& spec) override;
            virtual PipelineHandle CreatePipeline(const PipelineSpecification& spec) override;
            virtual CommandPoolHandle CreateCommandPool() override;

            virtual Graphics::CommandBuffer* AllocateCommandBuffer(CommandPoolHandle handle) override;
            virtual void ResetCommandPool(CommandPoolHandle handle) override;


            virtual void Submit(Graphics::CommandBuffer* buffer) override;
        private:
            Registry<TextureData>   m_texture_registry;
            Registry<ShaderData>    m_shader_registry;
            Registry<PipelineData>  m_pipeline_registry;
            Registry<CommandPool*>  m_command_pool_registry;

            ResourceLoadingQueue m_loading_queue;
    };
}

#endif
