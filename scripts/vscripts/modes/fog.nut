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
    EntFire("env_fog_controller", "SetColorSecondary", "70 75 80")
    EntFire("env_fog_controller", "SetColor", "70 75 80")
    EntFire("env_fog_controller", "SetStartDist", "-64")
    EntFire("env_fog_controller", "SetEndDist", "128")
    EntFire("env_fog_controller", "SetMaxDensity", 1)
}

AddModeFunctions("fog_percent", FogPercentPostSpawn, FogPercentLoad)