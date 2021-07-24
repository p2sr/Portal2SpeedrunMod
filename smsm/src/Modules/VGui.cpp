#include "VGui.hpp"

#include "Client.hpp"
#include "Console.hpp"
#include "Engine.hpp"
#include "Server.hpp"
#include "Surface.hpp"

#include "Game.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"
#include "CelesteMoveset.hpp"

REDECL(VGui::Paint);

// CEngineVGui::Paint
DETOUR(VGui::Paint, int mode)
{
    // drawing custom gui only once per frame
    // flag is set by RenderView detour in client
    if (vgui->canDrawThisFrame) { 
        for (auto hud : vgui->huds) {
            if (!hud->DrawingOnTop()) vgui->DrawCustomHud(hud);
        }
    }
    vgui->canDrawThisFrame = false;
    auto result = VGui::Paint(thisptr, mode);

    for (auto hud : vgui->huds) {
        if (hud->DrawingOnTop()) vgui->DrawCustomHud(hud);
    }
    
    return result;
}

void VGui::DrawCustomHud(Hud* hud) {
    surface->StartDrawing(surface->matsurface->ThisPtr());
    surface->DisableClipping(surface->matsurface->ThisPtr(), true);

    hud->Draw();

    surface->DisableClipping(surface->matsurface->ThisPtr(), false);
    surface->FinishDrawing();
}

unsigned long VGui::GetDefaultFont() {
    return this->GetFont(this->g_pScheme->ThisPtr(), "DefaultFixedOutline", 0);
}

bool VGui::Init()
{
    huds.push_back(staminaHud = new StaminaHud());
    huds.push_back(celesteBerryHud = new CelesteBerryHud());

    this->enginevgui = Interface::Create(this->Name(), "VEngineVGui001");
    if (this->enginevgui) {
        this->enginevgui->Hook(VGui::Paint_Hook, VGui::Paint, Offsets::Paint);
    }

    if (auto g_pVGuiSchemeManager = Interface::Create(MODULE("vgui2"), "VGUI_Scheme010", false)) {
        using _GetIScheme = void* (__func*)(void* thisptr, unsigned long scheme);
        auto GetIScheme = g_pVGuiSchemeManager->Original<_GetIScheme>(Offsets::GetIScheme);

        // Default scheme is 1
        this->g_pScheme = Interface::Create(GetIScheme(g_pVGuiSchemeManager->ThisPtr(), 1));
        if (this->g_pScheme) {
            this->GetFont = this->g_pScheme->Original<_GetFont>(Offsets::GetFont);
        }
        Interface::Delete(g_pVGuiSchemeManager);
    }

    return this->hasLoaded = this->enginevgui;
}
void VGui::Shutdown()
{
    Interface::Delete(this->enginevgui);
}

VGui* vgui;
