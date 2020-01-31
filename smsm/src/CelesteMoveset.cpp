#include "CelesteMoveset.hpp"

#include "Offsets.hpp"
#include "SMSM.hpp"

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"

CelesteMoveset::CelesteMoveset()
    : dashingSpeed(300.0)
    , dashingInitBoost(350.0)
    , dashingDuration(0.2)
    , dashingCooldownDuration(0.4)
    , dashingOriginalVelMult(0.25)
    , maxDashes(1)

    , wallSlidingSpeedVertical(75.0)
    , wallSlidingSpeedHorizontal(50.0)
    , wallSlidingSpeedVerticalSpeed(20.0)
    , wallSlidingSpeedHorizontalSpeed(5.0)
    , wallJumpForce(250.0)

    , wallClimbMaxStamina(200)
    , wallClimbJumpHeight(45)
    , wallClimbJumpDuration(0.4)
    , wallClimbMovementSpeed(75)
    , wallClimbHoldFatigue(20)
{

}

void CelesteMoveset::PreProcessMovement(void* pPlayer, CMoveData* pMove) {
    if (holdingWall) {
        //block original movement, but store wish vel somewhere
        if (pMove->m_flForwardMove != 0 || pMove->m_flSideMove != 0) {
            float moveAng = atan2f(-pMove->m_flSideMove, pMove->m_flForwardMove) + DEG2RAD(pMove->m_vecViewAngles.y);
            playerWishVel.x = cos(moveAng);
            playerWishVel.y = sin(moveAng);
        }
        else {
            playerWishVel.x = 0;
            playerWishVel.y = 0;
        }
        playerForwardMove = pMove->m_flForwardMove;
        pMove->m_flForwardMove = 0;
        pMove->m_flSideMove = 0;
    }
}

void CelesteMoveset::ProcessMovement(void* pPlayer, CMoveData* pMove) {

    if (smsm.GetMode() != Celeste) return;

    //process jump input
    bool holdingSpace = (pMove->m_nButtons & 0x2);
    bool ducking = *reinterpret_cast<bool*>((uintptr_t)pPlayer + Offsets::m_bDucking);
    if (holdingSpace && !ducking) {
        pressedJump = !holdingJump;
        holdingJump = true;
    } else {
        holdingJump = false;
        pressedJump = false;
    }

    //just in case, use tickbase counter within player entity to make proper logic loop
    int tickBase = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_nTickBase);
    if (tickBase > lastTickBase) {
        float dt = (tickBase - lastTickBase) / 60.0f;

        ProcessMovementWallclimb(pPlayer, pMove, dt);
        ProcessMovementDashing(pPlayer, pMove, dt);
    }
    lastTickBase = tickBase;

    
    

}





void CelesteMoveset::ProcessMovementDashing(void* pPlayer, CMoveData* pMove, float dt) {
    auto m_fFlags = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_fFlags);
    bool grounded = (m_fFlags & FL_ONGROUND);

    //refresh dashing if on ground
    if (grounded && dashing < dashingDuration) {
        dashesLeft = maxDashes;
    }

    //check for dashing
    if (dashRequested) {
        int health = *reinterpret_cast<int*>((uintptr_t)pPlayer + 528);
        if (dashesLeft>0 && dashing==0 && dashingCooldown==0 && health>0) { //TODO: add player health to conditions

            //getting values I need for whole math
            float pitch = DEG2RAD(pMove->m_vecViewAngles.x);
            float yaw = DEG2RAD(pMove->m_vecViewAngles.y);
            float forwardMove = pMove->m_flForwardMove;
            float sideMove = pMove->m_flSideMove;

            //math
            //transforming move values into normalized vector
            Vector dir{ forwardMove, sideMove, 0 };
            if (dir.Length() == 0)dir.x = 1; //dash forward if nothing is held
            dir = dir * (1/dir.Length());

            //applying pitch rotation
            dir.z = -dir.x * sin(pitch);
            dir.x *= cos(pitch);

            //applying yaw rotation
            Vector newDir{ dir.x * cos(yaw) + dir.y * sin(yaw), -dir.y * cos(yaw) + dir.x * sin(yaw), dir.z };

            //multiplying vector by dashing speed
            newDir = newDir * dashingSpeed;

            //fix dash when grounded and aiming down
            if (grounded && newDir.z < 60) {
                newDir.z = 60; //newDir.x*=0.8; newDir.y*=0.8;
            }

            //add little bit of current player vector on top of the dash
            Vector pv = pMove->m_vecVelocity;

            Vector pvn = pv * (1 / pv.Length());
            Vector newDirN = newDir * (1 / newDir.Length());
            float vd = pvn * newDirN;
            if (vd < 0)vd = 0;

            newDir.x += pv.x * dashingOriginalVelMult * vd;
            newDir.y += pv.y * dashingOriginalVelMult * vd;
            newDir.z += pv.z * dashingOriginalVelMult * vd;

            //set new dashing velocity
            dashingDir = newDir;
            if (grounded && newDir.z < 300) {
                pMove->m_vecVelocity = Vector{ newDir.x, newDir.y, 300 };
            }
            else {
                pMove->m_vecVelocity = dashingDir;
            }
            dashingOldPos = *reinterpret_cast<Vector*>((uintptr_t)pPlayer + 700); //700

            dashesLeft--;
            dashing = dashingDuration;
            dashingCooldown = dashingCooldownDuration;

            // GetPlayer().EmitSound("player/windgust.wav")
            //smsm.modeParams[DashRequested] = true;
            //TODO: find a way to play sound
        }
        dashRequested = false;
    }

    if (dashing > 0) {
        //check if player used portals by comparing old and new position
        Vector pp = pMove->m_vecAbsOrigin;
        float distance = Vector{ dashingOldPos.x - pp.x, dashingOldPos.y - pp.y, dashingOldPos.z - pp.z }.Length();
        //console->Print("%f %f %f - %f\n", pp.x, pp.y, pp.z, distance);
        if (distance > 32) {
            //change dash vector to aim correct direction
            Vector pv = pMove->m_vecVelocity;
            float m = dashingSpeed / pv.Length();
            dashingDir = pv * m;
        }
        dashingOldPos = pp;

        Vector pv = pMove->m_vecVelocity;
        //hyperdashing
        if (dashingDir.z < 0 && pv.z >= 0) {
            pMove->m_vecVelocity = pv * (float)(0.5 - dashingDir.z / dashingSpeed);
            dashing = 0;
        }
        //initial dash speed management
        else if (dashing < dashingDuration) {
            float d = (dashing / dashingDuration);
            float m = (dashingSpeed + dashingInitBoost * d * d) / dashingSpeed;
            pMove->m_vecVelocity = dashingDir * m;
        }
        dashing -= dt;
        if (dashing < 0)dashing = 0;
    }

    if (dashingCooldown > 0) {
        dashingCooldown -= dt;
        if (dashingCooldown < 0)dashingCooldown = 0;
    }
}






bool CelesteMoveset::IsPlaceSuitableForWallgrab(void * player, Vector pos, float angle, Vector * placeNormal) {
    float alignedAng = DEG2RAD(std::floor((angle+45.0) / 90.0) * 90.0);

    CGameTrace tr;
    bool collidingWithSurface = false;
    Vector pn; float planeDist;
    CTraceFilterSimple filter;

    //cast four corners of a player wall where collision could happen
    for(int y=0;y<2;y++) for(int a = -1; a <= 1; a+=2) {

        float cosAng = cos(alignedAng), sinAng = sin(alignedAng);
        
        float bbsize = 16;
        float bbx = (abs(cosAng) < 0.1 ? a: cosAng) * 15;
        float bby = (abs(sinAng) < 0.1 ? a: sinAng) * 15;

        Ray_t ray;
        ray.m_IsRay = true; ray.m_IsSwept = true;
        float d = 2.5;
        ray.m_Delta = VectorAligned(cosAng * d + 0.001, sinAng * d+0.001, 0.001);
        ray.m_Start = VectorAligned(pos.x + bbx, pos.y + bby, pos.z + y*72.0f);
        ray.m_StartOffset = VectorAligned();
        ray.m_Extents = VectorAligned();

        //console->Print("m_start: %f", ray.m_Start.x);
        engine->TraceRay(engine->engineTrace->ThisPtr(), ray, MASK_PLAYERSOLID, &filter, &tr);
        //console->Print(", %f\n", ray.m_Start.x);

        /*
        That m_Start.x condition is literally pointless, but if it's gone then
        it would seem like TraceRay sets it to 0. It makes no fucking sense
        and I gave up on trying to find out why it's happening, so I'm just leaving it here.
        Fuck.
        */
        if (ray.m_Start.x == pos.x + bbx && tr.plane.normal.Length() > 0.9) {
            collidingWithSurface = true;
            pn = tr.plane.normal;
            planeDist = tr.plane.dist;
        }
    }

    //not colliding with any surface
    if (!collidingWithSurface) return false;

    //surface is too steep or too plain
    if (pn.z > 0.2 || pn.z < -0.71) return false;

    float surfAngle = RAD2DEG(atan2f(-pn.y, -pn.x));
    const float range = 45;
    float dist = abs(surfAngle - angle);
    if (dist > 180)dist = 360 - dist;
    //surface angle is not within specified range
    if (dist > range) return false;
    bool ducking = *reinterpret_cast<bool*>((uintptr_t)player + Offsets::m_bDucking);
    Vector posMid(pos.x, pos.y, pos.z + (ducking ? 18.0f : 36.0f));
    
    float d = -(posMid.x*pn.x + posMid.y*pn.y + posMid.z*pn.z - planeDist);
    //position projection on plane
    Vector posProj(posMid.x + pn.x * d, posMid.y + pn.y * d, posMid.z + pn.z * d);

    //checking if grabbed surface is flat
    Vector pnUp = (pn ^ Vector(0, 0, 1)) ^ pn;
    Vector pnSide = (pn ^ Vector(1, 0, 0)) ^ pn;

    short grabPlaces = 0;

    static int grabDist = 10;
    for (int x = -grabDist; x <= grabDist; x += grabDist) {
        CGameTrace grabTr;
        Ray_t ray;
        ray.m_IsRay = true; ray.m_IsSwept = true;

        ray.m_Delta = VectorAligned(pn.x*-4,pn.y*-4,pn.z*-4);
        ray.m_Start = VectorAligned(posProj.x + pnSide.x * x + pn.x*2, posProj.y + pnSide.y * x + pn.y * 2, posProj.z + pnSide.z * x + pn.z * 2);
        ray.m_StartOffset = VectorAligned();
        ray.m_Extents = VectorAligned();
        engine->TraceRay(engine->engineTrace->ThisPtr(), ray, MASK_PLAYERSOLID, &filter, &grabTr);

        if (grabTr.plane.normal.Length() > 0.9) {
            grabPlaces++;
        }
    }

    if (grabPlaces < 2)return false;

    /*if (holdingUse) {
        char buf[1024];
        sprintf(buf, "drawline %f %f %f %f %f %f", posProj.x, posProj.y, posProj.z, posProj.x + pn.x * 3, posProj.y + pn.y * 3, posProj.z + pn.z * 3);
        smsm.ServerCommand(buf);
        sprintf(buf, "drawline %f %f %f %f %f %f", posProj.x, posProj.y, posProj.z, posProj.x + pnSide.x * 3, posProj.y + pnSide.y * 3, posProj.z + pnSide.z * 3);
        smsm.ServerCommand(buf);
        sprintf(buf, "drawline %f %f %f %f %f %f", posProj.x, posProj.y, posProj.z, posProj.x + pnUp.x * 3, posProj.y + pnUp.y * 3, posProj.z + pnUp.z * 3);
        smsm.ServerCommand(buf);
    }*/

    //passing a wall normal to the reference
    if (placeNormal != nullptr) {
        placeNormal->x = pn.x;
        placeNormal->y = pn.y;
        placeNormal->z = pn.z;
    }

    return true;
}






void CelesteMoveset::ProcessMovementWallclimb(void* pPlayer, CMoveData* pMove, float dt) {
    auto m_fFlags = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_fFlags);
    bool grounded = (m_fFlags & FL_ONGROUND);
    

    //wallclimbing
    bool holdingUse = (pMove->m_nButtons & 0x20);
    if (grounded) {
        climbStamina = wallClimbMaxStamina;
    }
    else if (holdingUse && climbStamina > 0) {
        //depending on a state of a wallclimb, different angle is used.
        float grabAng = pMove->m_vecViewAngles.y;
        if (holdingWall) {
            grabAng = holdingWallAngle;
        }else if (pMove->m_outWishVel.Length() > 0) {
            grabAng = RAD2DEG(atan2f(pMove->m_outWishVel.y, pMove->m_outWishVel.x));
        }
        Vector wallNormal;
        //change climb jumping duration in a separate place to allow wall jump spam
        if(climbJumping > 0)climbJumping -= dt;
        //during climb jump, ignore that player is not next to the wall, they'll come back there (hopefully)
        if (climbJumping > 0) { 
            float cjState = climbJumping / wallClimbJumpDuration;
            float horizontalMov = 16 * (cjState-0.5);
            float verticalMov = (2 * wallClimbJumpHeight / wallClimbJumpDuration) * cjState;
            Vector climbVec = (climbedWallNorm ^ Vector(0, 0, 1)) ^ climbedWallNorm;
            climbVec = climbVec * verticalMov + climbedWallNorm*horizontalMov;

            climbVec.z += 5.0f;

            pMove->m_vecVelocity = climbVec;
            climbStamina -= verticalMov*dt;
        }
        //during wallclimbing, make sure player is still next to the same wall.
        else if (IsPlaceSuitableForWallgrab(pPlayer, pMove->m_vecAbsOrigin, grabAng, &wallNormal)) {
            if (!holdingWall) {
                holdingWallAngle = RAD2DEG(atan2f(-wallNormal.y, -wallNormal.x));
                climbedWallNorm = wallNormal;
                holdingWall = true;
            }
                
            Vector newVel = Vector(-climbedWallNorm.x, -climbedWallNorm.y, 0);

            float relMovAng = atan2f(playerWishVel.y, playerWishVel.x) - DEG2RAD(holdingWallAngle);

            //moving on a wall
            if (playerWishVel.Length() > 0) {
                Vector wnUp = (climbedWallNorm ^ Vector(0, 0, 1)) ^ climbedWallNorm;
                Vector wnSide(cos(DEG2RAD(holdingWallAngle + 90)), sin(DEG2RAD(holdingWallAngle + 90)), 0);

                //really funky way of making vertical movement out of horizontal movement and looking dir
                //hopefully it will feel natural and somewhat playable lmao
                
                float upMove = fmaxf(cosf(relMovAng), 0);
                float sideMove = sinf(relMovAng);
                if (playerForwardMove != 0) {
                    float pitch = DEG2RAD(pMove->m_vecViewAngles.x);
                    float sinPitch = sinf(pitch);
                    if (playerForwardMove > 0)sinPitch *= -1;
                    upMove = upMove * cosf(pitch) + sinPitch;
                    sideMove = sideMove * cosf(pitch);
                }

                newVel = newVel + (wnUp * (upMove * wallClimbMovementSpeed));
                newVel = newVel + (wnSide * (sideMove * wallClimbMovementSpeed));

                climbStamina -= wallClimbMovementSpeed * dt;
            } else {
                climbStamina -= wallClimbHoldFatigue * dt;
            }

            if (!IsPlaceSuitableForWallgrab(pPlayer, pMove->m_vecAbsOrigin + (newVel * dt), grabAng)) {
                newVel = Vector(0, 0, 0);
            }
            newVel.z += 5.0f;
            pMove->m_vecVelocity = newVel;

            if (pressedJump && (playerWishVel.Length() == 0 || cosf(relMovAng)>0)) {
                climbJumping = wallClimbJumpDuration;
            }
        }
        else {
            holdingWall = false;
        }
        if(holdingWall)console->Print("stamina: %f\n", climbStamina);
    }
    else {
        climbJumping = 0;
    }
    if (holdingWall && !holdingUse)holdingWall = false;
    


    //walljumping
    if ((pMove->m_outWishVel.Length2D() > 0.1 && pMove->m_vecVelocity.z < 0) || (holdingWall && climbJumping<=0)) {
        float wishVelAng = RAD2DEG(atan2f(pMove->m_outWishVel.y, pMove->m_outWishVel.x));
        if (holdingWall)wishVelAng = holdingWallAngle;
        Vector wallNormal;
        if (IsPlaceSuitableForWallgrab(pPlayer, pMove->m_vecAbsOrigin, wishVelAng, &wallNormal)) {
            if (pressedJump) {
                //calculate jumping vector
                float wall2dNormLen = wallNormal.Length2D();
                Vector wall2dNormal(wallNormal.x / wall2dNormLen, wallNormal.y / wall2dNormLen, 0);

                float jumpAng = asin(wallNormal.z) + 0.8f;

                Vector jumpNorm = wall2dNormal * cos(jumpAng);
                jumpNorm.z = sin(jumpAng);

                Vector jumpVec = jumpNorm * wallJumpForce;

                //apply old horizontal velocity on top of that.
                pMove->m_vecVelocity.x += jumpVec.x;
                pMove->m_vecVelocity.y += jumpVec.y;
                pMove->m_vecVelocity.z = jumpVec.z;
                holdingWall = false;
            }
            else if (!holdingWall) {
                if (pMove->m_vecVelocity.z < -wallSlidingSpeedVertical) {
                    float stepZ = pMove->m_vecVelocity.z + wallSlidingSpeedVerticalSpeed;
                    float newZ = (stepZ > wallSlidingSpeedVertical) ? wallSlidingSpeedVertical : stepZ;
                    pMove->m_vecVelocity.z = newZ;
                }
                float len = pMove->m_vecVelocity.Length2D();
                if (len > wallSlidingSpeedHorizontal) {
                    float stepSpeed = len - wallSlidingSpeedHorizontalSpeed;
                    float newSpeed = (stepSpeed > wallSlidingSpeedHorizontal) ? wallSlidingSpeedHorizontal : stepSpeed;
                    Vector newVel = pMove->m_vecVelocity * (stepSpeed / len);
                    newVel.z = pMove->m_vecVelocity.z;
                    pMove->m_vecVelocity = newVel;
                }
            }
        }
    }

}




void IN_DashDown(const CCommand& args) {
    if(smsm.GetMode()==Celeste)celesteMoveset.Dash();
}

void IN_DashUp(const CCommand& args) {

}

Command in_dashdown("+dash", IN_DashDown, "Dashing (celeste-mode only).");
Command in_dashup("-dash", IN_DashUp, "Dashing (celeste-mode only).");




CelesteMoveset celesteMoveset;