#include "CelesteMoveset.hpp"

#include "Offsets.hpp"
#include "SMSM.hpp"

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"
#include "Modules/Client.hpp"
#include "Modules/Surface.hpp"
#include "Modules/VGui.hpp"

CelesteMoveset::CelesteMoveset()
    : dashingSpeed(300.0)
    , dashingInitBoost(350.0)
    , dashingDuration(0.2)
    , dashingCooldownDuration(0.4)
    , dashingOriginalVelMult(0.25)
    , maxDashes(1)
    , wavedashRefreshTime(0.08)

    , wallSlidingSpeed(75.0)
    , wallSlidingSpeedSpeed(20.0)
    , wallJumpForce(250.0)

    , wallClimbMaxStamina(200)
    , wallClimbJumpHeight(45)
    , wallClimbJumpDuration(0.4)
    , wallClimbMovementSpeed(75)
    , wallClimbHoldFatigue(20)
{

}

void CelesteMoveset::PreProcessMovement(void* pPlayer, CMoveData* pMove) {

    if (smsm.GetMode() != Celeste) return;

    unsigned int groundEntity = *reinterpret_cast<unsigned int*>((uintptr_t)pPlayer + Offsets::m_hGroundEntity);
    bool grounded = groundEntity != 0xFFFFFFFF;

    //process jump input
    bool holdingSpace = (pMove->m_nButtons & 0x2);
    bool ducking = *reinterpret_cast<bool*>((uintptr_t)pPlayer + Offsets::m_bDucking);
    if (holdingSpace && !ducking) {
        pressedJump = !holdingJump;
        holdingJump = true;
    }
    else {
        holdingJump = false;
        pressedJump = false;
    }

    if (pressedJump && grounded) walljumpCooldown = 0.2;

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

void CelesteMoveset::UpdateModeParams() {
    smsm.SetModeParam(DashesLeft, dashesLeft);
    smsm.SetModeParam(StaminaLeft, climbStamina);
    if (!smsm.GetModeParam(InitialValue)) {
        smsm.SetModeParam(MaxDashes, maxDashes);
        smsm.SetModeParam(MaxStamina, wallClimbMaxStamina);
        smsm.SetModeParam(InitialValue, 1);
    }
    maxDashes = smsm.GetModeParam(MaxDashes);
    wallClimbMaxStamina = smsm.GetModeParam(MaxStamina);
}

void CelesteMoveset::ProcessMovement(void* pPlayer, CMoveData* pMove) {

    //void** grabbed = reinterpret_cast<void**>((uintptr_t)pPlayer + 2960);
    //*grabbed = pPlayer;
    //console->Print("Grabbed entity: %X\n", grabbed);

    if (smsm.GetMode() != Celeste) return;

    UpdateModeParams();

    //just in case, use tickbase counter within player entity to make proper logic loop
    int tickBase = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_nTickBase);
    if (tickBase > lastTickBase) {
        float dt = (tickBase - lastTickBase) / 60.0f;

        ProcessMovementWallclimb(pPlayer, pMove, dt);
        ProcessMovementDashing(pPlayer, pMove, dt);
    }
    lastTickBase = tickBase;

    //for maps where you spawn midair (incinerator, underground)
    if (tickBase < 30)climbStamina = wallClimbMaxStamina;
}





void CelesteMoveset::ProcessMovementDashing(void* pPlayer, CMoveData* pMove, float dt) {
    unsigned int groundEntity = *reinterpret_cast<unsigned int*>((uintptr_t)pPlayer + Offsets::m_hGroundEntity);
    bool grounded = groundEntity != 0xFFFFFFFF;

    //refresh dashing if on ground
    bool canWaveJump = dashingCooldown < dashingCooldownDuration - wavedashRefreshTime;
    if (grounded && ((!dashedOnGround && canWaveJump) || (dashedOnGround && dashingCooldown <=0))) {
        dashesLeft = maxDashes;
    }

    //check for dashing
    if (dashRequested) {
        int health = *reinterpret_cast<int*>((uintptr_t)pPlayer + 528);
        if (dashesLeft>0 && dashing==0 && dashingCooldown==0 && health>0) {
            if (grounded) dashedOnGround = true;
            else dashedOnGround = false;

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

            //hyperdashing
            //if (newDir.z < 0) {
            //    newDir = newDir * (float)(1 - newDir.z);
            //}

            //multiplying vector by dashing speed
            newDir = newDir * dashingSpeed;



            //add little bit of current player vector on top of the dash
            Vector pv = pMove->m_vecVelocity;

            if (pv.Length() > 1) {
                Vector pvn = pv * (1 / pv.Length());
                Vector newDirN = newDir * (1 / newDir.Length());
                float vd = pvn * newDirN;
                if (vd < 0)vd = 0;

                newDir.x += pv.x * dashingOriginalVelMult * vd;
                newDir.y += pv.y * dashingOriginalVelMult * vd;
                newDir.z += pv.z * dashingOriginalVelMult * vd;
            }
            
            //set new dashing velocity
            dashingDir = newDir;
            pMove->m_vecVelocity = dashingDir;
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
            if(pv.Length()<1){
                //something fucked up and i dont even know what, lets just cancel dashing.
                dashing = 0;
            }else {
                float m = dashingSpeed / pv.Length();
                dashingDir = pv * m;
            }
            
        }
        dashingOldPos = pp;

        Vector pv = pMove->m_vecVelocity;
        //hyperdashing
        if (dashingDir.z < 0 && ((grounded && pressedJump) || (dashingDir.z < -100 && pv.z > 100))) {
            if (!(dashingDir.z < -100 && pv.z > 300))pMove->m_vecVelocity = pv * (float)(0.5 - dashingDir.z / dashingSpeed);
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

    //cast four corners of a player wall where collision could happen
    for(int y=0;y<2;y++) for(int a = -1; a <= 1; a+=2) {

        float cosAng = cos(alignedAng), sinAng = sin(alignedAng);
        
        float bbsize = 15;
        float bbx = (abs(cosAng) < 0.1 ? a: cosAng) * bbsize;
        float bby = (abs(sinAng) < 0.1 ? a: sinAng) * bbsize;

        Ray_t ray;
        ray.m_IsRay = true; ray.m_IsSwept = true;
        float d = 8;
        ray.m_Delta = VectorAligned(cosAng * d + 0.001, sinAng * d+0.001, 0.001);
        ray.m_Start = VectorAligned(pos.x + bbx, pos.y + bby, pos.z + y*72.0f);
        ray.m_StartOffset = VectorAligned();
        ray.m_Extents = VectorAligned();
        CTraceFilterSimple filter;
        filter.SetPassEntity(player);

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
            //planeDist = tr.plane.dist;
            //plane.dist is incorrect for static object for some reason
            //use Ax + By + Cz = D to get it with MATH
            planeDist = tr.plane.normal.x * tr.endpos.x + tr.plane.normal.y * tr.endpos.y + tr.plane.normal.z * tr.endpos.z;
        }
    }

    //not colliding with any surface
    if (!collidingWithSurface) return false;

    //surface is too steep or too plain
    if (pn.z > 0.4 || pn.z < -0.2) return false;

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
        ray.m_Start = VectorAligned(posProj.x + pnSide.x * x + pn.x, posProj.y + pnSide.y * x + pn.y, posProj.z + pnSide.z * x + pn.z);
        ray.m_StartOffset = VectorAligned();
        ray.m_Extents = VectorAligned();
        CTraceFilterSimple filter;
        filter.SetPassEntity(player);

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
    unsigned int groundEntity = *reinterpret_cast<unsigned int*>((uintptr_t)pPlayer + Offsets::m_hGroundEntity);
    bool grounded = groundEntity != 0xFFFFFFFF;

    auto m_hUseEntity = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_hUseEntity);
    bool isHoldingSth = m_hUseEntity != 0xFFFFFFFF;


    if (wallclimbCooldown > 0)wallclimbCooldown -= dt;
    if (wallclimbCooldown < 0)wallclimbCooldown = 0;
    bool oldHoldingWall = holdingWall;

    //wallclimbing
    bool holdingUse = pMove->m_nButtons & 0x20;
    if (grounded) {
        climbStamina = wallClimbMaxStamina;
    }
    else if (holdingUse && climbStamina > 0 && !isHoldingSth && wallclimbCooldown<=0) {
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
            float horizontalMov = 100 * (cjState-0.5);
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
            
            float wallPullForce = 100;
            Vector newVel = Vector(-climbedWallNorm.x * wallPullForce, -climbedWallNorm.y * wallPullForce, 0);

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

                newVel = newVel * 0.2;
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
        //if(holdingWall)console->Print("stamina: %f\n", climbStamina);
    }
    else {
        climbJumping = 0;
        holdingWall = false;
        
    }
    if (holdingWall && (!holdingUse || isHoldingSth))holdingWall = false;
    
    if(oldHoldingWall && !holdingWall && !holdingUse)wallclimbCooldown = wallClimbNextDelay;

    //visually grab the wall by internally replacing convar variables
    float originalVmOffset = std::stof(viewmodel_offset_z.ThisPtr()->m_pszString);
    float currentVmOffset = viewmodel_offset_z.ThisPtr()->m_fValue;
    if (holdingWall) {
        crosshair.ThisPtr()->m_nValue = 0;
        const float lowerEnd = -15;
        if (currentVmOffset > lowerEnd)currentVmOffset -= 1.5;
        if (currentVmOffset < lowerEnd)currentVmOffset = lowerEnd;
        viewmodel_offset_z.ThisPtr()->m_fValue = currentVmOffset;
    }else{
        crosshair.ThisPtr()->m_nValue = (int)crosshair.ThisPtr()->m_fValue;
        if (currentVmOffset < originalVmOffset)currentVmOffset += 2.0;
        if (currentVmOffset > originalVmOffset)currentVmOffset = originalVmOffset;
    }
    viewmodel_offset_z.ThisPtr()->m_fValue = currentVmOffset;


    if (walljumpCooldown > 0)walljumpCooldown -= dt;
    if (walljumpCooldown < 0)walljumpCooldown = 0;

    //wallbounce
    if (dashingCooldown > 0 && pMove->m_vecVelocity.Length2D() < 200 && pMove->m_vecVelocity.z > 100 && pressedJump && !holdingWall && walljumpCooldown <= 0) {
        float angle = RAD2DEG(atan2f(pMove->m_outWishVel.y, pMove->m_outWishVel.x));
        for (int i = 0; i < 4; i++) {
            Vector wallNormal;
            if (IsPlaceSuitableForWallgrab(pPlayer, pMove->m_vecAbsOrigin, angle, &wallNormal)) {
                //calculate wallbounce vector
                float wall2dNormLen = wallNormal.Length2D();
                Vector wall2dNormal(wallNormal.x / wall2dNormLen, wallNormal.y / wall2dNormLen, 0);

                float bounceAng = asin(wallNormal.z) + 0.9f;

                Vector bounceNorm = wall2dNormal * cos(bounceAng);
                bounceNorm.z = sin(bounceAng);

                Vector bounceVec = bounceNorm * wallJumpForce;

                //apply old horizontal velocity on top of that.
                pMove->m_vecVelocity.x += bounceVec.x;
                pMove->m_vecVelocity.y += bounceVec.y;
                pMove->m_vecVelocity.z = bounceVec.z * 2.5;
                dashing = 0;
                break;
            }
            angle += 90;
        }
    }

    //walljumping
    if (dashingCooldown<=0 && ((pMove->m_outWishVel.Length2D() > 0.01) || (holdingWall && climbJumping<=0))) {
        float wishVelAng = RAD2DEG(atan2f(pMove->m_outWishVel.y, pMove->m_outWishVel.x));
        if (holdingWall)wishVelAng = holdingWallAngle;
        Vector wallNormal;
        if (IsPlaceSuitableForWallgrab(pPlayer, pMove->m_vecAbsOrigin, wishVelAng, &wallNormal)) {
            if (pressedJump && walljumpCooldown<=0) {
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
            //wallsliding
            else if (!holdingWall) {
                float len = fmaxf(pMove->m_vecVelocity.Length2D(), wallSlidingSpeed);
                if (pMove->m_vecVelocity.z < -len) {
                    float stepZ = pMove->m_vecVelocity.z + wallSlidingSpeedSpeed;
                    float newZ = (stepZ > wallSlidingSpeed) ? wallSlidingSpeed : stepZ;
                    pMove->m_vecVelocity.z = newZ;
                }
            }
        }
    }

    if (pressedJump) {
        walljumpCooldown = 0.2;
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