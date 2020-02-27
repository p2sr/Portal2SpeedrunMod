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
    void UpdateModeParams();

    bool IsPlaceSuitableForWallgrab(void * player, Vector pos, float angle, Vector * placeNormal = nullptr);

    float dashingSpeed; // speed that player will have at the end of a dash
    float dashingInitBoost; // speed that player will have at the beginning of a dash
    float dashingDuration; // how long will player be in dash
    float dashingCooldownDuration; // how long until the next dash
    float dashingOriginalVelMult; // how much of a original speed to keep
    float wavedashRefreshTime;

    float wallSlidingSpeed; // how fast can player slide vertically on a wall
    float wallSlidingSpeedSpeed; // how much should vertical speed be enforced to sliding speed
    float wallJumpForce; //how much should player be pushed away from a wall when jumping on it
    float wallJumpAngle; //what angle should be used to calculate wall jump direction (NOT IMPLEMENTED YET)

    float wallClimbMaxStamina; //how many units can you travel before stamina runs out
    float wallClimbJumpHeight; //how high can player jump when wallclimbing
    float wallClimbJumpDuration; //how long should that jump take
    float wallClimbMovementSpeed; // speed in which player can move on a wall
    float wallClimbHoldFatigue; // how much to take from stamina if not moving
    float wallClimbNextDelay = 0.4;

    int maxDashes;
private:
    Vector dashingOldPos;
    Vector dashingDir;
    float dashing = 0;
    float dashingCooldown = 0;
    short dashesLeft = 0;
    int lastTickBase = 0;
    bool dashRequested = false;
    bool dashedOnGround = false;

    bool holdingWall = false;
    float holdingWallAngle = 0;
    Vector climbedWallNorm;
    float climbJumping = 0;
    float climbStamina = 0;
    Vector playerWishVel;
    float playerForwardMove = 0;

    bool holdingJump = false;
    bool pressedJump = false;
    bool preGrounded = false;
    float walljumpCooldown = 0;
    float wallclimbCooldown = 0; //fuck you
public:
    const enum ModeParams {
        InitialValue = 0,
        MaxDashes = 1,
        MaxStamina = 2,
        DashesLeft = 3,
        StaminaLeft = 4,
        DisplayBerriesGot = 10,
        DisplayBerriesMax = 11,
        DisplayInLevelBerriesCount = 12,
        DisplayInLevelBerriesOffset = 13,
        BerriesOffset = 100,
    };
};

extern CelesteMoveset celesteMoveset;

