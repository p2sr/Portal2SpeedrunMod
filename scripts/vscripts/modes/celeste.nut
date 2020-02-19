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
    //FOG_CONTROL_VALUES = {r=0.8, g=0.4, b=1.3};
}

function Precache(){
    self.PrecacheSoundScript("player/windgust.wav")
    smsm.PrecacheModel("models/srmod/hintplank.mdl", true)
    smsm.PrecacheModel("models/srmod/strawberry.mdl", true)
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

        //build a wall-climb force-learn environment or something idk
        local containerWall1 = Entities.FindByClassnameNearest("func_door", Vector(-5818, 1327, 285), 10)
        EntFireByHandle(containerWall1, "SetLocalOrigin", "-1403.22 4404.75 2733.44", 0, null, null)
        EntFireByHandle(containerWall1, "SetLocalAngles", "0 90 98", 0, null, null)
        //slanted wall, can't climb it
        local containerWall2 = Entities.FindByClassnameNearest("func_door", Vector(-5477, 1400, 285), 10)
        EntFireByHandle(containerWall2, "SetLocalOrigin", "-1210 4602 2745", 0, null, null)
        EntFireByHandle(containerWall2, "SetLocalAngles", "-15 0 5", 0, null, null)

        local sign = Entities.CreateByClassname("prop_dynamic_override");
        sign.SetModel("models/srmod/hintplank.mdl");
        sign.SetOrigin(Vector(-1405, 4374, 2740));
        sign.SetAngles(85,0,90)

        break;
    case "sp_a1_intro2":
        EntFire("block_boxes", "Kill")

        local button1 = GetEntity("blue_1_portal_button");
        button1.SetOrigin(Vector(-532, 192, -62))
        EntFireByHandle(button1, "SetLocalAngles", "-12 180 0", 0, null, null)
        local button2 = GetEntity("blue_3_portal_button");
        button2.SetOrigin(Vector(-110, 134, -64))
        EntFireByHandle(button2, "SetLocalAngles", "-10 11 4", 0, null, null)

        local box = GetEntity("box");
        box.SetOrigin(Vector(0, 160, -16))

        break;
    case "sp_a1_intro3":
        EntFire("pickup_portalgun_rl", "AddOutput", "OnTrigger "+self.GetName()+":RunScriptCode:UpgradeDashes(1):0:1")
        EntFire("emitter_orange_2", "Kill")
        EntFire("portal_orange_2", "Kill")
        EntFire("portal_orange_mtg", "Kill")
        EntFire("emitter_orange_mtg", "Kill")
        EntFire("prop_physics", "Kill")

        local sign1 = Entities.CreateByClassname("prop_dynamic_override");
        sign1.SetModel("models/srmod/hintplank.mdl");
        sign1.SetOrigin(Vector(-131, 1995, -296));
        sign1.SetAngles(79,338,24);
        EntFireByHandle(sign1, "skin", "1", 0, null, null)

        local sign2 = Entities.CreateByClassname("prop_dynamic_override");
        sign2.SetModel("models/srmod/hintplank.mdl");
        sign2.SetOrigin(Vector(-54, 2050, -368));
        sign2.SetAngles(76,270,-43);
        EntFireByHandle(sign2, "skin", "2", 0, null, null)
        break;
    case "sp_a1_intro4":
        EntFire("portal_emitter_a_lvl3", "Kill")
        EntFire("portal_a_lvl3", "Kill")
        EntFire("section_2_portal_a1_rm3a", "Kill")
        EntFire("section_2_portal_emitter_a1_rm3a", "Kill")
        EntFire("section_2_portal_a2_rm3a", "Kill")
        EntFire("section_2_portal_emitter_a2_rm3a", "Kill")

        EntFire("glass_pane_1_door_1", "KillHierarchy")
        EntFire("glass_pane_1_door_1_blocker", "Kill")
        EntFire("glass_shard", "Kill")
        EntFire("aud_ramp_break_glass", "Kill")

        EntFire("logic_drop_box", "Trigger")
        EntFire("trigger_dropbox", "Kill")
        break;
    case "sp_a1_intro6":
        local berry = Entities.CreateByClassname("prop_dynamic");
        berry.SetModel("models/srmod/strawberry.mdl");
        berry.SetOrigin(Vector(-70, 220, 64));
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

        colorAlpha = (50-stamina)/50 * 130 * ((cos(staminaAnimTimer)+1.0)/2.0)
    }
    smsm.SetScreenCoverColor(80,20,20,colorAlpha);
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