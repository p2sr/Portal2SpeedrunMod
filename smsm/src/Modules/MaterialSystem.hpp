#pragma once
#include "Module.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Command.hpp"

class MaterialSystem : public Module {
public:
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("materialsystem"); }
private:
    uint32_t *defaultContextSize = nullptr;
    uint32_t origContextSize = 0;

    using _RenderContextTerm = void(__cdecl *)(void);
    using _RenderContextInit = void(__cdecl *)(void);
    _RenderContextTerm RenderContextTerm = nullptr;
    _RenderContextInit RenderContextInit = nullptr;
};

extern MaterialSystem* materialSystem;
