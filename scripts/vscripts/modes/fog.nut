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
}

function NewFogControl(){
    EntFire("env_fog_controller", "SetColorSecondary", "200 215 230")
    EntFire("env_fog_controller", "SetColor", "200 205 210")
    EntFire("env_fog_controller", "SetStartDist", "0")
    EntFire("env_fog_controller", "SetEndDist", "200")
}

AddModeFunctions("fog_percent", FogPercentPostSpawn, FogPercentLoad)