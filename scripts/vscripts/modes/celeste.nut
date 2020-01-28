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

function CelesteUpdate(){
    /* local makeSound = GetSMSMVariable(SMSMParam.DashRequested)
    if(makeSound){
        GetPlayer().EmitSound("player/windgust.wav")
        SetSMSMVariable(SMSMParam.DashRequested,0)
    } */
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate)