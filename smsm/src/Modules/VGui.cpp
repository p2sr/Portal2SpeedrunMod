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
    // drawing custom gui only once per frame
    // flag is set by RenderView detour in client
    if (vgui->canDrawThisFrame) { 
        surface->StartDrawing(surface->matsurface->ThisPtr());
        //currently drawn gui can have clipping enabled. disable that
        surface->DisableClipping(surface->matsurface->ThisPtr(), true);

        //get width and height for gui drawing
        int width, height;
        engine->GetScreenSize(width, height);

        //drawing covering color
        Color cColor = vgui->coverColor;
        if ((cColor.r() || cColor.g() || cColor.b())) {
            if (vgui->coverTexture == 0 || !surface->IsTextureIDValid(surface->matsurface->ThisPtr(), vgui->coverTexture)) {
                //generate the cover texture
                vgui->coverTexture = surface->CreateNewTextureID(surface->matsurface->ThisPtr(), true);
                const int scale = 400;
                const int fadeStart = 50;
                unsigned char testData[scale*scale * 4];
                for (int x = 0; x < scale; x++)for (int y = 0; y < scale; y++) {
                    int sideX = scale - x, sideY = scale - y;
                    int d = fmin(fmin(fmin(x, y),sideX),sideY);
                    int alpha = fmax(0, pow(1.0 - d / (float)fadeStart,3)*255);
                    int offset = (x * scale + y) * 4;
                    testData[offset] = 255;
                    testData[offset+1] = 255;
                    testData[offset+2] = 255;
                    testData[offset+3] = alpha;
                }
                surface->DrawSetTextureRGBA(surface->matsurface->ThisPtr(), vgui->coverTexture, testData, scale, scale);
            }
            surface->DrawSetColor(surface->matsurface->ThisPtr(), cColor.r(), cColor.g(), cColor.b(), cColor.a());
            surface->DrawSetTexture(surface->matsurface->ThisPtr(), vgui->coverTexture);
            surface->DrawTexturedRect(surface->matsurface->ThisPtr(), 0, 0, width, height);
        }
        surface->DisableClipping(surface->matsurface->ThisPtr(), false);
        surface->FinishDrawing();
    }

    auto result = VGui::Paint(thisptr, mode);

    vgui->canDrawThisFrame = false;
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
