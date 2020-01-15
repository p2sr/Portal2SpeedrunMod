//*****************************************************
//====FOG%====
//you cant see shit
//*****************************************************

function FogPercentPostSpawn(){
    FogControl = NewFogControl
}

function FogPercentLoad(){
    //vgui screens appears through the fog, but we don't have to see them so I just remove them lmfao
    //killing crashes the game, disabling them does nothing, so I just teleport them where noone can get
    EntFire("vgui_movie_display", "SetLocalOrigin", "-42069 0 0", 0.1)

    EntFire(self.GetName(), "AddOutput", "OnUser1 "+self.GetName()+":FireUser1::0.1:-1")
    EntFire(self.GetName(), "AddOutput", "OnUser1 "+self.GetName()+":RunScriptCode:UpdateFogToVelocity():0:-1")
    EntFire(self.GetName(), "FireUser1")
}

function NewFogControl(){
    EntFire("env_fog_controller", "SetColorSecondary", "70 75 80")
    EntFire("env_fog_controller", "SetColor", "70 75 80")
    EntFire("env_fog_controller", "SetStartDist", "-64")
    EntFire("env_fog_controller", "SetEndDist", "128")
    EntFire("env_fog_controller", "SetMaxDensity", 1)
    EntFire(self.GetName(), "AddOutput", "OnUser1 "+self.GetName()+":RunScriptCode:UpdateFogToVelocity():0:-1")
}

FOG_FADEAWAY_VALUE <- 0;
FOG_FADEAWAY_END <- false;

function UpdateFogToVelocity(){
    local vel = GetPlayer().GetVelocity();
    local totalVel = vel.x + vel.y + vel.z;
    if(totalVel == 0 && !FOG_FADEAWAY_END){
        if(FOG_FADEAWAY_VALUE<110)FOG_FADEAWAY_VALUE++;
    }else{
        FOG_FADEAWAY_END=true;
        FOG_FADEAWAY_VALUE-=10;
        if(FOG_FADEAWAY_VALUE<0){
            FOG_FADEAWAY_VALUE=0;
            FOG_FADEAWAY_END = false;
        }
    }
    local f = FOG_FADEAWAY_VALUE-60;
    local value = 1-(f<0 ? 0 : f)*0.0025
    EntFire("env_fog_controller", "SetMaxDensity", value)
}

AddModeFunctions("fog_percent", FogPercentPostSpawn, FogPercentLoad)