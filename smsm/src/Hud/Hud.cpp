#include "Hud.hpp"

#include "Modules/Surface.hpp"
#include "Modules/Engine.hpp"
#include "Modules/VGui.hpp"
#include "Modules/Server.hpp"
#include "Modules/Console.hpp"

#include "SMSM.hpp"
#include "CelesteMoveset.hpp"


void Hud::Draw() {};

int StaminaHud::GetStaminaTexture() {
    if (this->staminaTexture == 0 || !surface->IsTextureIDValid(surface->matsurface->ThisPtr(), this->staminaTexture)) {
        this->staminaTexture = surface->CreateNewTextureID(surface->matsurface->ThisPtr(), true);
        const int scale = 400;
        const int fadeStart = 50;
        unsigned char testData[scale * scale * 4];
        for (int x = 0; x < scale; x++)for (int y = 0; y < scale; y++) {
            int sideX = scale - x, sideY = scale - y;
            int d = fmin(fmin(fmin(x, y), sideX), sideY);
            int alpha = fmax(0, pow(1.0 - d / (float)fadeStart, 3) * 255);
            int offset = (x * scale + y) * 4;
            testData[offset] = 255;
            testData[offset + 1] = 255;
            testData[offset + 2] = 255;
            testData[offset + 3] = alpha;
        }
        surface->DrawSetTextureRGBA(surface->matsurface->ThisPtr(), this->staminaTexture, testData, scale, scale);
    }
    return this->staminaTexture;
}

void StaminaHud::Draw() {
    //get width and height for gui drawing
    int width, height;
    engine->GetScreenSize(width, height);

    //drawing covering color
    Color cColor = this->staminaColor;
    if ((cColor.r() || cColor.g() || cColor.b()) && cColor.a() > 0) {
        if (int texture = this->GetStaminaTexture()) {
            surface->DrawSetColor(surface->matsurface->ThisPtr(), cColor.r(), cColor.g(), cColor.b(), cColor.a());
            surface->DrawSetTexture(surface->matsurface->ThisPtr(), texture);
            surface->DrawTexturedRect(surface->matsurface->ThisPtr(), 0, 0, width, height);
        }
    }
}
StaminaHud* staminaHud;


int CelesteBerryHud::GetBerryTexture() {
    if (this->berryTexture == 0 || !surface->IsTextureIDValid(surface->matsurface->ThisPtr(), this->berryTexture)) {
        this->berryTexture = surface->CreateNewTextureID(surface->matsurface->ThisPtr(), true);
        //yes, that's dumb, so what?
        const unsigned char berryData[130] = { 
            0,0,0,0,0,1,1,0,0,0,
            0,0,1,1,1,2,2,1,0,0,
            0,1,2,2,1,3,3,2,1,0,
            1,3,1,4,2,2,4,1,2,1,
            0,1,4,5,4,4,5,4,1,0,
            1,6,7,5,5,5,5,5,6,1,
            1,5,5,7,5,5,5,7,5,1,
            1,5,5,6,5,7,5,6,5,1,
            1,5,6,5,5,6,5,6,5,1,
            0,1,5,6,6,6,6,5,1,0,
            0,0,1,5,6,6,5,1,0,0,
            0,0,0,1,5,5,1,0,0,0,
            0,0,0,0,1,1,0,0,0,0,
        };
        unsigned char berryDataRGBA[130 * 4];
        for (int i = 0; i < 130; i++) {
            Color c;
            switch (berryData[i]) {
            case 0: c = Color(0, 0, 0, 0); break;
            case 1: c = Color(0, 0, 0, 255); break;
            case 2: c = Color(56, 142, 60, 255); break;
            case 3: c = Color(46, 125, 50, 255); break;
            case 4: c = Color(156, 39, 176, 255); break;
            case 5: c = Color(211, 47, 47, 255); break;
            case 6: c = Color(198, 40, 40, 255); break;
            case 7: c = Color(255, 249, 196, 255); break;
            }
            berryDataRGBA[i * 4] = c.r();
            berryDataRGBA[i * 4 + 1] = c.g();
            berryDataRGBA[i * 4 + 2] = c.b();
            berryDataRGBA[i * 4 + 3] = c.a();
        }
        surface->DrawSetTextureRGBA(surface->matsurface->ThisPtr(), this->berryTexture, berryDataRGBA, 10, 13);
    }
    return this->berryTexture;
}

void CelesteBerryHud::Draw() {
    if (smsm.GetMode() != Celeste) return;

    if (server->gpGlobals->tickcount<40 || engine->hoststate->m_bWaitingForConnection || !engine->hoststate->m_activeGame || smsm.clients.size()==0) {
        oldBerryCount = smsm.GetModeParam(CelesteMoveset::DisplayBerriesGot);
        displayBerryCount = oldBerryCount;
        return;
    }

    float dt = fmaxf(server->gpGlobals->realtime - prevRealTime, 0);
    prevRealTime = server->gpGlobals->realtime;

    int newBerryCount = (int)smsm.GetModeParam(CelesteMoveset::DisplayBerriesGot);
    bool forceShow = smsm.GetModeParam(CelesteMoveset::DisplayBerriesForce) > 0;
    if (newBerryCount != oldBerryCount || smsm.isPaused || forceShow) {
        if (posOffset < 1.0)posOffset += 4 * dt;
        if (posOffset >= 1.0) {
            posOffset = 1.0;
            if (newBerryCount != oldBerryCount) {
                collectAnimState = 1.0;
                oldBerryCount = newBerryCount;
            }
        }
    }else if (collectAnimState == 0.0) {
        if (posOffset > 0)posOffset -= 3 * dt;
        if (posOffset < 0)posOffset = 0;
    }

    const float animDelay = 0.88;
    if (collectAnimState > 0) {
        collectAnimState -= 0.8 * dt;
        if (collectAnimState < animDelay)displayBerryCount = oldBerryCount;
        if (collectAnimState < 0.0) collectAnimState = 0;
    }

    if (posOffset == 0.0)return;

    float xOffset = pow((1.0-posOffset), 2);

    int maxWidth, width, height;
    engine->GetScreenSize(width, height);
    maxWidth = width;
    width += (xOffset*300.0) - 20;
    height = 30;

    int font = vgui->GetDefaultFont() + 90;

    char counterText[128];
    sprintf(counterText, "%d\0", displayBerryCount);
    const char* xText = "x ";

    int counterTextWidth = surface->GetFontLength(font, counterText) + 20;
    int xTextWidth = surface->GetFontLength(font, xText);

    //surface->DrawRect(Color(0, 0, 0, 200), width - counterTextWidth - xTextWidth - 78, height - 10, width, height + 65);

    width -= counterTextWidth;
    float anim = fminf(fmaxf((animDelay -collectAnimState)/0.25,0),1.0);
    int animY = -sin(anim * 3.1416)*10;
    int animC = (anim==0 || anim==1) ? 0 : (sin(anim*15)+1) * 50;
    surface->DrawTxt(font, width+4, height+4 + animY, Color(0, 0, 0, 150), counterText);
    surface->DrawTxt(font, width, height + animY, Color(255-animC, 255-animC*2, 255-animC*2, 255), counterText);
    width -= xTextWidth;
    surface->DrawTxt(font, width+4, height - 4 + 4, Color(0, 0, 0, 150), xText);
    surface->DrawTxt(font, width, height - 4, Color(255, 255, 255, 255), xText);
    
    if (int texture = this->GetBerryTexture()) {
        surface->DrawSetColor(surface->matsurface->ThisPtr(), 255,255,255,255);
        surface->DrawSetTexture(surface->matsurface->ThisPtr(), texture);
        int x = width - 60, y = height-5;
        surface->DrawTexturedRect(surface->matsurface->ThisPtr(), x, y, x+50, y+65);
    }
}

CelesteBerryHud* celesteBerryHud;