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
    //SetSMSMVariable(SMSMParam.CelesteMode, 1)
}

tehRainbow <- 0;

function CelesteUpdate(){
    /* local makeSound = GetSMSMVariable(SMSMParam.DashRequested)
    if(makeSound){
        GetPlayer().EmitSound("player/windgust.wav")
        SetSMSMVariable(SMSMParam.DashRequested,0)
    } */
    tehRainbow += 10;
    local r = (tehRainbow%765)
    local g = ((tehRainbow+255)%765)
    local b = ((tehRainbow+510)%765)
    if(r>255)r = 510-r;
    if(g>255)g = 510-g;
    if(b>255)b = 510-b;
    if(r<0)r = 0;
    if(g<0)g = 0;
    if(b<0)b = 0;

    smsm.SetPortalGunIndicatorColor(Vector(r,g,b));
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate)