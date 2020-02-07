//*****************************************************
//====Celeste%====
//Advanced movement and stuff
//*****************************************************

ModeParams <- {
    InitialValue = 0,
    MaxDashes = 1,
    MaxStamina = 2,
    DashesLeft = 3,
    StaminaLeft = 4,
    BerriesOffset = 100,
};

function CelestePostSpawn(){
    
}

function Precache(){
    self.PrecacheSoundScript("player/windgust.wav")
}

FIRST_MAP_WITH_1_DASH <- "sp_a1_intro4"
FIRST_MAP_WITH_2_DASHES <- "sp_a3_speed_ramp"

function CelesteLoad(){
    //give player only viewmodel of portalgun, to for dashing indicator
    local dashes = 0;
    foreach( index, map in MapPlayOrder ){
        if(map == FIRST_MAP_WITH_1_DASH) dashes = 1;
        if(map == FIRST_MAP_WITH_2_DASHES) dashes = 2;
        if(map == GetMapName()) break;
    }

    switch(GetMapName()){
    case "sp_a1_intro1":

        //make portalgun broken
        EntFire("portal_red_0", "Kill")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser4 portal_red_0_emitter:Skin:2:0:-1")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser4 portal_red_0_emitter:Skin:0:0.1:-1")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser3 portal_red_0_activate_rl:FireUser4::0:-1")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser3 portal_red_0_activate_rl:FireUser4::0.7:-1")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser3 portal_red_0_activate_rl:FireUser4::0.9:-1")
        EntFire("portal_red_0_activate_rl", "AddOutput", "OnUser3 portal_red_0_activate_rl:FireUser3::2:-1")
        EntFire("portal_red_0_activate_rl", "FireUser3")
        EntFire("door_open_relay", "Trigger", 0, 2)

        //remove clock to make climbing easier
        EntFire("mmc_clock_flash_12", "Kill")
        EntFire("mmc_clock_flash_blank", "Kill")
        local clockModel = Entities.FindByClassnameNearest("prop_dynamic", Vector(-1137, 4353, 2853), 10)
        EntFireByHandle(clockModel, "SetLocalOrigin", "-1162 4353 2707", 0, null, null)
        EntFireByHandle(clockModel, "SetLocalAngles", "0 200 -180", 0, null, null)
        break;
    case "sp_a1_intro3":
        EntFire("pickup_portalgun_rl", "AddOutput", "OnTrigger "+self.GetName()+":RunScriptCode:UpgradeDashes(1):0:1")
        EntFire("emitter_orange_2", "Kill")
        EntFire("portal_orange_2", "Kill")
        EntFire("portal_orange_mtg", "Kill")
        EntFire("emitter_orange_mtg", "Kill")
        EntFire("prop_physics", "Kill")
        break;
    }

    UpgradeDashes(dashes);
}

rainbowColorState <- 0;
previousDashCount <- 0;
staminaAnimTimer <- 0;

function CelesteUpdate(){
    
    UpdateIndicatorDiode();
    UpdateStaminaCover();

    local dashesLeft = smsm.GetModeParam(ModeParams.DashesLeft);

    local makeSound = previousDashCount>dashesLeft;
    if(makeSound){
        self.EmitSound("player/windgust.wav")
    } 
    previousDashCount=dashesLeft;
}



function UpdateStaminaCover(){
    local stamina = smsm.GetModeParam(ModeParams.StaminaLeft);
    local colorAlpha = 0;
    if(stamina<50){
        local animSpeed = 0.4
        if(stamina<=0) animSpeed = 1.2;
        staminaAnimTimer = staminaAnimTimer+animSpeed;

        colorAlpha = (50-stamina)*0.2 * ((cos(staminaAnimTimer)+1.0)/2.0)
    }
    smsm.SetScreenCoverColor(200,0,0,colorAlpha);
    //print("Stamina:"+stamina+"\n");
}

function UpdateIndicatorDiode(){
local color = Vector(1,1,1);

    local dashesLeft = smsm.GetModeParam(ModeParams.DashesLeft);
    if(dashesLeft>2){
        rainbowColorState += 10;
        local r = (rainbowColorState%765)
        local g = ((rainbowColorState+255)%765)
        local b = ((rainbowColorState+510)%765)
        if(r>255)r = 510-r; if(g>255)g = 510-g; if(b>255)b = 510-b;
        if(r<0)r = 0; if(g<0)g = 0; if(b<0)b = 0;
        color = Vector(r,g,b);
    }else if(dashesLeft==2){
        color = Vector(100,50,255)
    }else if(dashesLeft==1){
        color = Vector(255,50,0)
    }
    
    smsm.SetPortalGunIndicatorColor(color);
}

function UpgradeDashes(dashes){
    smsm.SetModeParam(ModeParams.MaxDashes, dashes);
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate)