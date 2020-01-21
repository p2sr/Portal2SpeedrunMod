#pragma once

#include "Command.hpp"
#include "Utils.hpp"

extern Command in_dashdown;
extern Command in_dashup;

class CelesteMoveset {
public:
    CelesteMoveset();
    void ProcessMovement(void* pPlayer, CMoveData* pMove);
    void ProcessMovementDashing(void* pPlayer, CMoveData* pMove, float dt);

    void Dash() { dashRequested = true; }

    float dashingSpeed;
    float dashingInitBoost;
    float dashingDuration;
    float dashingCooldownDuration;
    float dashingOriginalVelMult;
    int maxDashes;
private:
    Vector dashingOldPos;
    Vector dashingDir;
    float dashing = 0;
    float dashingCooldown = 0;
    short dashesLeft = 0;
    int lastTickBase = 0;
    bool dashRequested = false;
};

extern CelesteMoveset celesteMoveset;

