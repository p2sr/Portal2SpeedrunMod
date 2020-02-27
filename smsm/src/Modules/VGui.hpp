#pragma once
#include <vector>

#include "Module.hpp"

#include "Interface.hpp"
#include "Utils.hpp"
#include "Surface.hpp"
#include "Hud/Hud.hpp"

class VGui : public Module {
public:
    Interface* enginevgui = nullptr;
    Interface* g_pScheme = nullptr;

    using _GetFont = unsigned long(__func*)(void* thisptr, const char* fontName, bool proportional);
    _GetFont GetFont = nullptr;
    unsigned long GetDefaultFont();
    void AllowCustomHudThisFrame() { canDrawThisFrame = true; }
    void DrawCustomHud(Hud* hud);
private:
    bool canDrawThisFrame = true;
    std::vector<Hud*> huds;
public:
    // CEngineVGui::Paint
    DECL_DETOUR(Paint, int mode);

    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("engine"); }
};

extern VGui* vgui;
