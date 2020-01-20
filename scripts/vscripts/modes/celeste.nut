//*****************************************************
//====Celeste%====
//Advanced movement and stuff
//*****************************************************

function CelestePostSpawn(){
    
}

function Precache(){
    self.PrecacheSoundScript("player/windgust.wav")
}

function CelesteLoad(){
    //setup the dash button
    SendToConsole("alias dash sm_param "+SMSMParam.DashRequest+" 1")
    SetSMSMVariable(SMSMParam.DashRequest, 0)
}

DASHING_SPEED <- 300.0
DASHING_INIT_BOOST <- 350.0
DASHING_DURATION <- 0.2
DASHING_COOLDOWN <- 0.4
DASHING_OLDVEL_MULT <- 0.1
MAX_DASHES <- 1

dashingOldPos <- Vector(0,0,0)
dashingVec <- Vector(0,0,0)
dashing <- 0
dashingCooldown <- 0
dashesLeft <- MAX_DASHES

function CelesteUpdate(){
    local grounded = GetSMSMVariable(SMSMParam.PlayerGrounded)>0
    
    //refresh dashing if on ground
    if(grounded && dashing<DASHING_DURATION){
        dashesLeft = MAX_DASHES
    }

    //check for dashing
    local dashRequested = GetSMSMVariable(SMSMParam.DashRequest)>0
    if(dashRequested){
        if(dashesLeft && !dashing && !dashingCooldown && GetPlayer().GetHealth()>0){
            //modlog("DASHED!!!!!")

            //getting values from SMSM script interface
            local moveForward = GetSMSMVariable(SMSMParam.PlayerMoveForward)
            local moveSide = GetSMSMVariable(SMSMParam.PlayerMoveSide)
            local pitch = GetSMSMVariable(SMSMParam.PlayerAnglePitch)/180*3.14159265
            local yaw = GetSMSMVariable(SMSMParam.PlayerAngleYaw)/180*3.14159265

            //math
            //transforming move values into normalized vector
            local dir = Vector(moveForward, moveSide, 0)
            if(dir.Length()==0)dir.x = 1 //dash forward if nothing is held
            local vl = dir.Length();
            dir.x /= vl; dir.y /= vl;
            //applying pitch rotation
            dir.z = -dir.x*sin(pitch)
            dir.x *= cos(pitch)
            
            //applying yaw rotation
            local newDir = Vector(dir.x*cos(yaw)+dir.y*sin(yaw),-dir.y*cos(yaw)+dir.x*sin(yaw),dir.z)

            //multiplying vector by dashing speed
            newDir.x *= DASHING_SPEED
            newDir.y *= DASHING_SPEED
            newDir.z *= DASHING_SPEED

            //fix dash when grounded and aiming down
            if(grounded && newDir.z<60){
                newDir.z=60
                //newDir.x*=0.8
                //newDir.y*=0.8
            }

            //add little bit of current player vector on top of the dash
            local pv = GetPlayer().GetVelocity()
            newDir.x += pv.x*DASHING_OLDVEL_MULT
            newDir.y += pv.y*DASHING_OLDVEL_MULT
            newDir.z += pv.z*DASHING_OLDVEL_MULT

            //set new dashing velocity
            dashingVec = newDir
            if(grounded && newDir.z<300){
                GetPlayer().SetVelocity(Vector(newDir.x,newDir.y,300))
            }else{
                GetPlayer().SetVelocity(dashingVec)
            }
            dashingOldPos = GetPlayer().GetOrigin()

            dashesLeft--;
            dashing = DASHING_DURATION
            dashingCooldown = DASHING_COOLDOWN

            GetPlayer().EmitSound("player/windgust.wav")
        }
        SetSMSMVariable(SMSMParam.DashRequest, 0)
    }

    if(dashing>0){
        //check if player used portals by comparing old and new position
        local pp = GetPlayer().GetOrigin()
        local distance = Vector(dashingOldPos.x-pp.x,dashingOldPos.y-pp.y,dashingOldPos.z-pp.z).Length()
        if(distance>32){
            //change dash vector to aim correct direction
            local pv = GetPlayer().GetVelocity();
            local m = DASHING_SPEED/pv.Length()
            pv.x *= m; pv.y *= m; pv.z *= m;
            dashingVec = pv
        }
        dashingOldPos=pp

        local pv = GetPlayer().GetVelocity();
        //hyperdashing
        if(dashingVec.z<0 && pv.z>=0){
            pv.x *= 0.7-dashingVec.z/DASHING_SPEED;
            pv.y *= 0.7-dashingVec.z/DASHING_SPEED;
            GetPlayer().SetVelocity(pv)
            dashing=0
        }
        //initial dash speed management
        else if(dashing<DASHING_DURATION){
            local d = (dashing/DASHING_DURATION)
            local m = (DASHING_SPEED + DASHING_INIT_BOOST*d*d)/DASHING_SPEED
            local vec = Vector(dashingVec.x*m,dashingVec.y*m,dashingVec.z*m)
            GetPlayer().SetVelocity(vec)
        }
        dashing -= DeltaTime()
        if(dashing<0)dashing=0
    }

    if(dashingCooldown>0){
        dashingCooldown -= DeltaTime()
        if(dashingCooldown<0)dashingCooldown=0
    }

    local noUse = GetSMSMVariable(SMSMParam.PlayerUsed)==0
    if(!noUse)modlog("USED!!!!")
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate)