#include "MaterialSystem.hpp"

#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Console.hpp"

#include "SMSM.hpp"

bool MaterialSystem::Init()
{
#ifdef _WIN32
    auto sigSize = "BE 00 60 22 00";
    auto sigTerm = "FF 0D ? ? ? ? 75 ? B9";
    auto sigInit = "83 3D ? ? ? ? 00 0F 85 ? ? ? ? 56";
    auto offSize = 1;
#else
    auto sigSize = "81 C3 00 60 22 00";
    auto sigInit = "A1 ? ? ? ? 85 C0 74 ? 83 C0 01";
    auto sigTerm = "83 2D ? ? ? ? 01 74 ? C3";
    auto offSize = 2;
#endif
    auto defaultContextSize = Memory::Scan(this->Name(), sigSize, offSize);
    if (defaultContextSize) {
        Memory::UnProtect((void *)defaultContextSize, 4);
        *(uint32_t *)defaultContextSize = 0x672000;

        // OHGODPLEASEHELP: This is very jank. I'm sorry.
        using _RenderContextTerm = void(__cdecl *)(void);
        using _RenderContextInit = void(__cdecl *)(void);
        auto RenderContextTerm = (_RenderContextTerm)Memory::Scan(this->Name(), sigTerm);
        auto RenderContextInit = (_RenderContextInit)Memory::Scan(this->Name(), sigInit);
        if (RenderContextTerm && RenderContextInit) {
            RenderContextTerm();
            RenderContextInit();
        }
    }
    this->hasLoaded = !!defaultContextSize;

    return this->hasLoaded;
}

void MaterialSystem::Shutdown()
{
}

MaterialSystem* materialSystem;
