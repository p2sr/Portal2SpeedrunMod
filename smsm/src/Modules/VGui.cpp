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

REDECL(VGui::Paint);

// CEngineVGui::Paint
DETOUR(VGui::Paint, int mode)
{

    //drawing covering color
    if ((vgui->coverColor.r() || vgui->coverColor.g() || vgui->coverColor.b())) {
        surface->StartDrawing(surface->matsurface->ThisPtr());
        surface->DrawRect(vgui->coverColor, 0, 0, 10000, 10000);
        surface->FinishDrawing();
    }
    

    auto result = VGui::Paint(thisptr, mode);

    return result;
}

bool VGui::Init()
{
    this->enginevgui = Interface::Create(this->Name(), "VEngineVGui0");
    if (this->enginevgui) {
        this->enginevgui->Hook(VGui::Paint_Hook, VGui::Paint, Offsets::Paint);
    }

    return this->hasLoaded = this->enginevgui;
}
void VGui::Shutdown()
{
    Interface::Delete(this->enginevgui);
}

VGui* vgui;
