#pragma once

#include "Command.hpp"
#include "Utils.hpp"

extern Command in_dashdown;
extern Command in_dashup;

class CelesteMoveset {
public:
    CelesteMoveset();
    void PreProcessMovement(void* pPlayer, CMoveData* pMove);
    void ProcessMovement(void* pPlayer, CMoveData* pMove);
    void ProcessMovementDashing(void* pPlayer, CMoveData* pMove, float dt);
    void ProcessMovementWallclimb(void* pPlayer, CMoveData* pMove, float dt);

    void Dash() { dashRequested = true; }

    bool IsPlaceSuitableForWallgrab(void * player, Vector pos, float angle, Vector * placeNormal = nullptr);

    float dashingSpeed; // speed that player will have at the end of a dash
    float dashingInitBoost; // speed that player will have at the beginning of a dash
    float dashingDuration; // how long will player be in dash
    float dashingCooldownDuration; // how long until the next dash
    float dashingOriginalVelMult; // how much of a original speed to keep

    float wallSlidingSpeedVertical; // how fast can player slide vertically on a wall
    float wallSlidingSpeedHorizontal; // how fast can player slide horizontally on a wall
    float wallSlidingSpeedVerticalSpeed; // how much should vertical speed be enforced to sliding speed
    float wallSlidingSpeedHorizontalSpeed; // how much should horizontal speed be enforced to sliding speed
    float wallJumpForce; //how much should player be pushed away from a wall when jumping on it
    float wallJumpAngle; //what angle should be used to calculate wall jump direction (NOT IMPLEMENTED YET)

    float wallClimbMaxStamina; //how many units can you travel before stamina runs out (NOT IMPLEMENTED YET)
    float wallClimbJumpHeight; //how high can player jump when wallclimbing (NOT IMPLEMENTED YET)
    float wallClimbJumpDuration; //how long should that jump take (NOT IMPLEMENTED YET)
    float wallClimbMovementSpeed; // speed in which player can move on a wall (NOT IMPLEMENTED YET)
    float wallClimbHoldFatigue; // how much to take from stamina if not moving (NOT IMPLEMENTED YET)

    int maxDashes;
private:
    Vector dashingOldPos;
    Vector dashingDir;
    float dashing = 0;
    float dashingCooldown = 0;
    short dashesLeft = 0;
    int lastTickBase = 0;
    bool dashRequested = false;

    bool holdingWall = false;
    float holdingWallAngle = 0;
    Vector climbedWallNorm;
    float climbJumping = 0;
    float climbStamina = 0;
    Vector playerWishVel;
    float playerForwardMove = 0;

    bool holdingJump = false;
    bool pressedJump = false;
};

extern CelesteMoveset celesteMoveset;

