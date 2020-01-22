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
    , dashingOriginalVelMult(0.1)
    , maxDashes(1)
{

}

void CelesteMoveset::ProcessMovement(void* pPlayer, CMoveData* pMove) {

    if (!smsm.modeParams[CelesteMode])return;

    //just in case, use tickbase counter within player entity to make proper logic loop
    int tickBase = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_nTickBase);
    if (tickBase > lastTickBase) {
        float dt = (tickBase - lastTickBase) / 60.0f;

        ProcessMovementWallclimb(pPlayer, pMove, dt);
        ProcessMovementDashing(pPlayer, pMove, dt);
    }
    lastTickBase = tickBase;

    
    bool holdingUse = (pMove->m_nButtons & 0x02);
    bool holdingSpace = (pMove->m_nButtons & 0x20);
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
            newDir.x += pv.x * dashingOriginalVelMult;
            newDir.y += pv.y * dashingOriginalVelMult;
            newDir.z += pv.z * dashingOriginalVelMult;

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
            smsm.modeParams[DashRequested] = true;
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
            pMove->m_vecVelocity = pv * (float)(0.7 - dashingDir.z / dashingSpeed);
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


bool CelesteMoveset::IsPlaceSuitableForWallgrab(Vector pos, float angle) {
    float minAngle = std::floor((angle + 45) / 90.0) * 90.0 - 45.0;

    Ray_t ray;
    ray.m_IsRay = true; ray.m_IsSwept = true;
    CTraceFilterWorldOnly filter;
    CGameTrace tr;
    for (int a = 0; a < 2; a++) {
        float angRad = DEG2RAD(minAngle+90*a);

        float bbx = (cos(angRad) < 0 ? -1 : 1) * 16.01f;
        float bby = (sin(angRad) < 0 ? -1 : 1) * 16.01f;

        float d = 2;
        ray.m_Delta.x = cos(angRad) * d; 
        ray.m_Delta.y = sin(angRad) * d;

        ray.m_Start.x = pos.x + bbx;
        ray.m_Start.y = pos.y + bby;
        ray.m_Start.z = pos.z + 64.0f;
        console->Print("start1: %f , %f , %f \n", ray.m_Start.x, ray.m_Start.y, ray.m_Start.z);
        engine->TraceRay(engine->engineTrace->ThisPtr(), ray, MASK_PLAYERSOLID, &filter, &tr);
        console->Print("start2: %f , %f , %f \n", tr.startpos.x, tr.startpos.y, tr.startpos.z);
        console->Print("angle: %f,fraction: %f, fractionleftsolid: %f, surface: %f,%f,%f\n", minAngle+90*a, tr.fraction, tr.fractionleftsolid, tr.plane.normal.x, tr.plane.normal.y, tr.plane.normal.z);
        //if (tr.fraction < 1)return true;
    }

    return false;
}


void CelesteMoveset::ProcessMovementWallclimb(void* pPlayer, CMoveData* pMove, float dt) {
    bool pressingUse = (pMove->m_nButtons & 0x20);
    if (pressingUse && !holdingUse) {
        console->Print("Pressed E!!!\n");
        if (IsPlaceSuitableForWallgrab(pMove->m_vecAbsOrigin, pMove->m_vecViewAngles.y))console->Print("Grab!!!!\n");
        holdingUse = true;
    }
    else if (!pressingUse && holdingUse) {
        holdingUse = false;
    }
}




void IN_DashDown(const CCommand& args) {
    if(smsm.modeParams[CelesteMode])celesteMoveset.Dash();
}

void IN_DashUp(const CCommand& args) {

}

Command in_dashdown("+dash", IN_DashDown, "Dashing (celeste-mode only).");
Command in_dashup("-dash", IN_DashUp, "Dashing (celeste-mode only).");




CelesteMoveset celesteMoveset;