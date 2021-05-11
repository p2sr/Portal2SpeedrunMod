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
#ifdef _WIN32
    engine->GetScreenSize(width, height);
#else
    engine->GetScreenSize(nullptr, width, height);
#endif

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



static int TextureFromDumbData(int& id, int width, int height, const unsigned char* texData, const unsigned char* colorData, bool grayscale) {
    if (id == 0 || !surface->IsTextureIDValid(surface->matsurface->ThisPtr(), id)) {
        id = surface->CreateNewTextureID(surface->matsurface->ThisPtr(), true);
        unsigned char dataRGBA[130 * 4];
        int size = width * height;
        for (int i = 0; i < size; i++) {
            int c = texData[i] * 4;
            if (grayscale) {
                int gc = (colorData[c] + colorData[c + 1] + colorData[c + 2]) / 3;
                dataRGBA[i * 4] = gc;
                dataRGBA[i * 4 + 1] = gc;
                dataRGBA[i * 4 + 2] = gc;
                dataRGBA[i * 4 + 3] = colorData[c + 3]*0.4;
            }
            else {
                dataRGBA[i * 4] = colorData[c];
                dataRGBA[i * 4 + 1] = colorData[c + 1];
                dataRGBA[i * 4 + 2] = colorData[c + 2];
                dataRGBA[i * 4 + 3] = colorData[c + 3];
            }
            
        }
        surface->DrawSetTextureRGBA(surface->matsurface->ThisPtr(), id, dataRGBA, 10, 13);
    }
    return id;
}


const unsigned char BERRY_TEX_DATA[130] = {
    0,0,0,0,0,1,1,0,0,0,0,0,1,1,1,2,2,1,0,0,0,1,2,2,1,3,3,2,1,0,1,3,1,4,2,2,4,1,2,1,0,1,4,5,
    4,4,5,4,1,0,1,6,7,5,5,5,5,5,6,1,1,5,5,7,5,5,5,7,5,1,1,5,5,6,5,7,5,6,5,1,1,5,6,5,5,6,5,6,
    5,1,0,1,5,6,6,6,6,5,1,0,0,0,1,5,6,6,5,1,0,0,0,0,0,1,5,5,1,0,0,0,0,0,0,0,1,1,0,0,0,0,
};

const unsigned char BERRY_COL_DATA[8*4] = {
    0, 0, 0, 0,
    0, 0, 0, 255,
    56, 142, 60, 255,
    46, 125, 50, 255,
    156, 39, 176, 255,
    211, 47, 47, 255,
    198, 40, 40, 255,
    255, 249, 196, 255,
};

const unsigned char QBERRY_TEX_DATA[130] = {
    0,0,0,0,0,1,1,0,0,0,0,0,1,1,1,2,2,1,0,0,0,1,2,2,1,3,3,2,1,0,1,2,1,4,2,2,4,1,2,1,0,1,4,5,
    4,4,7,4,1,0,0,1,5,6,5,7,4,8,1,0,1,5,6,5,6,4,7,9,8,1,1,6,5,6,4,7,9,8,9,1,1,5,6,5,7,4,8,9,
    8,1,0,1,5,7,4,8,9,8,1,0,0,0,1,4,7,9,8,1,0,0,0,0,0,1,4,8,1,0,0,0,0,0,0,0,1,1,0,0,0,0,
};

const unsigned char QBERRY_COL_DATA[10 * 4] = {
    0, 0, 0, 0,
    0, 0, 0, 255,
    56, 142, 60, 255,
    46, 125, 50, 255,
    178, 0, 255, 255,
    255, 128, 0, 255,
    255, 146, 36, 255,
    225, 220, 225, 255,
    0, 111, 222, 255,
    0, 128, 255, 255,
};

const unsigned char GBERRY_TEX_DATA[130] = {
    1,1,1,0,1,1,0,1,1,1,
    1,4,3,1,3,3,1,3,4,1,
    1,4,4,3,3,3,3,4,4,1,
    1,1,1,1,1,1,1,1,1,1,
    0,1,5,5,5,5,5,5,1,0,
    1,4,3,3,3,3,2,3,3,1,
    1,2,3,3,2,3,3,3,2,1,
    1,4,3,3,4,3,2,3,4,1,
    1,3,4,3,3,3,4,4,3,1,
    0,1,3,4,4,4,4,3,1,0,
    0,0,1,3,4,4,3,1,0,0,
    0,0,0,1,3,3,1,0,0,0,
    0,0,0,0,1,1,0,0,0,0,
};

const unsigned char GBERRY_COL_DATA[6 * 4] = {
    0, 0, 0, 0,
    0, 0, 0, 255,
    253,237,68,255,
    219, 193,42, 255,
    134, 118, 14, 255,
    115,88,22,255,
};
const unsigned char GQBERRY_TEX_DATA[130] = {
    1,1,1,0,1,1,0,1,1,1,
    1,3,2,1,2,2,1,2,3,1,
    1,3,2,2,2,2,2,3,3,1,
    1,1,1,1,1,1,1,1,1,1,
    0,1,4,4,4,4,4,4,1,0,
    0,1,6,5,6,8,6,7,1,0,
    1,6,5,6,5,6,8,6,7,1,
    1,5,6,5,6,8,6,7,6,1,
    1,6,5,6,8,6,7,6,7,1,
    0,1,6,8,6,7,6,7,1,0,
    0,0,1,6,8,6,7,1,0,0,
    0,0,0,1,6,7,1,0,0,0,
    0,0,0,0,1,1,0,0,0,0,
};

const unsigned char GQBERRY_COL_DATA[9 * 4] = {
    0, 0, 0, 0,
    0, 0, 0, 255,
    219, 193,42, 255,
    134, 118, 14, 255,
    115,88,22,255,
    155,118,68,255,
    255,218,0,255,
    238,185,0,255,
    225,224,220,255,
};

const unsigned char* BERRIES_TEX_DATAS[4] = {
    BERRY_TEX_DATA,
    QBERRY_TEX_DATA,
    GBERRY_TEX_DATA,
    GQBERRY_TEX_DATA,
};

const unsigned char* BERRIES_COL_DATAS[4] = {
    BERRY_COL_DATA,
    QBERRY_COL_DATA,
    GBERRY_COL_DATA,
    GQBERRY_COL_DATA,
};

int CelesteBerryHud::GetBerryTexture(int type) {
    int b = type / 2;
    return TextureFromDumbData(
        this->berryTexture[type], 10, 13,
        BERRIES_TEX_DATAS[b],
        BERRIES_COL_DATAS[b],
        type%2 == 0
    );
}

void CelesteBerryHud::Draw() {
    if (smsm.GetMode() != Celeste) return;

    if (server->gpGlobals->curtime < 1.6 || engine->hoststate->m_bWaitingForConnection || !engine->hoststate->m_activeGame || smsm.clients.size()==0) {
        oldBerryCount = smsm.GetModeParam(CelesteMoveset::DisplayBerriesGot);
        displayBerryCount = oldBerryCount;
        posOffset = 0;
        posOffset2 = 0;
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

    const float animDelay = 0.92;
    if (collectAnimState > 0) {
        collectAnimState -= 0.5 * dt;
        if (collectAnimState < animDelay)displayBerryCount = oldBerryCount;
        if (collectAnimState < 0.0) collectAnimState = 0;
    }

    if (posOffset == 0.0)return;

    int width, height;
#ifdef _WIN32
    engine->GetScreenSize(width, height);
#else
    engine->GetScreenSize(nullptr, width, height);
#endif

    int drawX = width + (pow((1.0 - posOffset), 2) *300.0) - 20;
    int drawY = 30;

    int font = vgui->GetDefaultFont() + 90;

    char counterText[128];
    sprintf(counterText, "%d\0", displayBerryCount);
    const char* xText = "x ";

    int counterTextWidth = surface->GetFontLength(font, counterText) + 20;
    int xTextWidth = surface->GetFontLength(font, xText);

    //surface->DrawRect(Color(0, 0, 0, 200), drawX - counterTextWidth - xTextWidth - 78, drawY - 10, drawX, drawY + 65);

    drawX -= counterTextWidth;
    float anim = fminf(fmaxf((animDelay -collectAnimState)/0.15,0),1.0);
    int animY = -sin(anim * 3.1416)*10;
    int animC = (anim==0 || anim==1) ? 0 : (sin(anim*15)+1) * 50;

    const int shadowOffset = 3;

    surface->DrawTxt(font, drawX + shadowOffset, drawY + shadowOffset + animY, Color(0, 0, 0, 150), counterText);
    surface->DrawTxt(font, drawX, drawY + animY, Color(255-animC, 255-animC*2, 255-animC*2, 255), counterText);
    drawX -= xTextWidth;
    surface->DrawTxt(font, drawX + shadowOffset, drawY - 4 + shadowOffset, Color(0, 0, 0, 150), xText);
    surface->DrawTxt(font, drawX, drawY - 4, Color(255, 255, 255, 255), xText);
    
    int textHeight = surface->GetFontHeight(font);

    if (int texture = this->GetBerryTexture(1)) {
        surface->DrawSetColor(surface->matsurface->ThisPtr(), 255,255,255,255);
        surface->DrawSetTexture(surface->matsurface->ThisPtr(), texture);
        int x = drawX - 60, y = drawY + textHeight/2 - 38;
        surface->DrawTexturedRect(surface->matsurface->ThisPtr(), x, y, x+50, y+65);
    }


    //drawing in-level berries
    if (smsm.isPaused) {
        if (posOffset2 < 1)posOffset2 += 5 * dt;
        if (posOffset2 > 1)posOffset2 = 1;
    }
    else {
        if (posOffset2 > 0)posOffset2 -= 5 * dt;
        if (posOffset2 < 0)posOffset2 = 0;
    }

    if (posOffset2 > 0) {
        int berriesCount = smsm.GetModeParam(CelesteMoveset::DisplayBerriesInLevelCount);
        const int margin = 20;
        const int berryWidth = 50;
        const int berryHeight = 65;

        for (int i = 0; i < berriesCount; i++) {
            int x = width - 10 - (berryWidth + margin) * (berriesCount - i);
            int y = height - (berryHeight + margin) * (1.0 - pow(1.0 - posOffset2, 2));

            int berryType = smsm.GetModeParam(CelesteMoveset::DisplayBerriesInLevelOffset + i);
            if (int texture = this->GetBerryTexture(berryType)) {
                surface->DrawSetTexture(surface->matsurface->ThisPtr(), texture);
                surface->DrawTexturedRect(surface->matsurface->ThisPtr(), x, y, x + berryWidth, y + berryHeight);
            }
        }
    }
}

CelesteBerryHud* celesteBerryHud;
