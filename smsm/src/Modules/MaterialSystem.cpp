#include "MaterialSystem.hpp"

#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Console.hpp"

#include "SMSM.hpp"

#define NEW_ALLOC 0x672000 // 6.45 MB

bool MaterialSystem::Init()
{
#ifdef _WIN32
    auto sigSize = "56 BE ? ? ? ? E8";
    auto sigTerm = "FF 0D ? ? ? ? 75 ? B9";
    auto sigInit = "83 3D ? ? ? ? 00 0F 85 ? ? ? ? 56";
    auto offSize = 2;
#else
    auto sigSize = "81 C3 ? ? ? ? E9";
    auto sigTerm = "83 2D ? ? ? ? 01 74 ? C3";
    auto sigInit = "A1 ? ? ? ? 85 C0 74 ? 83 C0 01";
    auto offSize = 2;
#endif
    defaultContextSize = (uint32_t *)Memory::Scan(this->Name(), sigSize, offSize);
    RenderContextTerm = (_RenderContextTerm)Memory::Scan(this->Name(), sigTerm);
    RenderContextInit = (_RenderContextInit)Memory::Scan(this->Name(), sigInit);
    if (defaultContextSize && RenderContextTerm && RenderContextInit) {
        if (*defaultContextSize != NEW_ALLOC) {
            Memory::UnProtect((void *)defaultContextSize, 4);
            origContextSize = *defaultContextSize;
            *defaultContextSize = NEW_ALLOC;
    
            // OHGODPLEASEHELP: This is very jank. I'm sorry.
            RenderContextTerm();
            RenderContextInit();
        }
        return this->hasLoaded = true;
    } else {
        return this->hasLoaded = false;
    }
}

void MaterialSystem::Shutdown()
{
    if (origContextSize) {
        *defaultContextSize = origContextSize;
        RenderContextTerm();
        RenderContextInit();
    }
}

MaterialSystem* materialSystem;
