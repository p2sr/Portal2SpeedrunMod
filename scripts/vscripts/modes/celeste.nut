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

DASHING_SPEED <- 350.0
DASHING_INIT_BOOST <- 300.0
DASHING_DURATION <- 0.2
DASHING_COOLDOWN <- 0.4
DASHING_OLDPOS <- Vector(0,0,0)


dashingVec <- Vector(0,0,0)
dashing <- 0
dashingCooldown <- 0
canDash <- false

function CelesteUpdate(){

    //refresh dashing if on ground
    local grounded = GetSMSMVariable(SMSMParam.PlayerGrounded)>0
    if(grounded && !canDash && dashing<DASHING_DURATION){
        canDash = true
    }

    //check for dashing
    local dashRequested = GetSMSMVariable(SMSMParam.DashRequest)>0
    if(dashRequested){
        if(canDash && !dashing && !dashingCooldown && GetPlayer().GetHealth()>0){
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
            if(grounded && newDir.z<120){
                newDir.z=120
                newDir.x*=0.8
                newDir.y*=0.8
            }

            dashingVec = newDir
            GetPlayer().SetVelocity(dashingVec)

            canDash = false
            dashing = DASHING_DURATION
            dashingCooldown = DASHING_COOLDOWN

            GetPlayer().EmitSound("player/windgust.wav")
        }
        SetSMSMVariable(SMSMParam.DashRequest, 0)
    }

    if(dashing>0){
        
        local pv = GetPlayer().GetVelocity();
        //hyperdashing
        if(dashingVec.z<0 && pv.z>=0){
            pv.x *= 0.5-dashingVec.z/DASHING_SPEED;
            pv.y *= 0.5-dashingVec.z/DASHING_SPEED;
            GetPlayer().SetVelocity(pv)
            dashing=0
        }
        //initial dash speed management
        else{
            local d = (dashing/DASHING_DURATION)
            local m = (DASHING_SPEED + DASHING_INIT_BOOST*d*d)/DASHING_SPEED
            local vec = Vector(dashingVec.x*m,dashingVec.y*m,dashingVec.z*m)
            GetPlayer().SetVelocity(vec)
            dashing -= DeltaTime()
            if(dashing<0)dashing=0
        }
    }

    if(dashingCooldown>0){
        dashingCooldown -= DeltaTime()
        if(dashingCooldown<0)dashingCooldown=0
    }
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate)