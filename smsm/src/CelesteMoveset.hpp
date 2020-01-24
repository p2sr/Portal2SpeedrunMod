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
    void ProcessMovementWallclimb(void* pPlayer, CMoveData* pMove, float dt);

    void Dash() { dashRequested = true; }

    bool IsPlaceSuitableForWallgrab(void * player, Vector pos, float angle, Vector * placeNormal = nullptr);

    float dashingSpeed;
    float dashingInitBoost;
    float dashingDuration;
    float dashingCooldownDuration;
    float dashingOriginalVelMult;

    float wallSlidingSpeedVertical;
    float wallSlidingSpeedHorizontal;
    float wallSlidingSpeedSpeed; //SPEEEEEED
    float wallJumpForce;

    int maxDashes;
private:
    Vector dashingOldPos;
    Vector dashingDir;
    float dashing = 0;
    float dashingCooldown = 0;
    short dashesLeft = 0;
    int lastTickBase = 0;
    bool dashRequested = false;

    bool holdingUse = false;
};

extern CelesteMoveset celesteMoveset;

