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
    DisplayBerriesGot = 10,
    DisplayBerriesMax = 11,
    DisplayBerriesForce = 12,
    DisplayBerriesInLevelCount = 13,
    DisplayBerriesInLevelOffset = 20,
    BerriesOffset = 30,
};

function CelestePrecache(){
    self.PrecacheSoundScript("celeste.dash")
    self.PrecacheSoundScript("celeste.quantumberrylost")
    self.PrecacheSoundScript("celeste.quantumberrylost_distant")
    smsm.PrecacheModel("models/srmod/hintplank.mdl", true)
    smsm.PrecacheModel("models/srmod/strawberry.mdl", true)
    smsm.PrecacheModel("models/srmod/introcar.mdl", true)
    smsm.PrecacheModel("models/srmod/quantumberry.mdl", true)
}

//birb code

BirbHandle <- null;
IsBirbMap <- false;
BirbInterp <- 0.0;
BirbFrame <- 0;
BirbJumpLoop <-0;
BirbKeyframes <- [
    {pos=Vector(-2159,-1351,-5112),ang=Vector(0,315,0),speed=0.1},
    {pos=Vector(-2207,-1223,-5112),ang=Vector(0,60,0),speed=0.1},
    {pos=Vector(-2128,-1111,-5112),ang=Vector(0,90,0),speed=0.1},
    {pos=Vector(-2059,-1020,-5065),ang=Vector(0,175,0),speed=0.1},
    {pos=Vector(-2129,-927,-5112),ang=Vector(0,140,0),speed=0.1},
    {pos=Vector(-2176,-799,-5112),ang=Vector(0,120,0),speed=0.1},
    {pos=Vector(-2240,-687,-5112),ang=Vector(0,130,0),speed=0.1},
    {pos=Vector(-2256,-575,-5112),ang=Vector(0,100,0),speed=0.1},
    {pos=Vector(-2335,-415,-5070),ang=Vector(0,37,0),speed=0.1},
    {pos=Vector(-2224,-272,-5112),ang=Vector(0,80,0),speed=0.1},
    {pos=Vector(-2272,-96,-5112),ang=Vector(0,100,0),speed=0.1},
    {pos=Vector(-2208,64,-5112),ang=Vector(0,60,0),speed=0.1},
    {pos=Vector(-2240,208,-5112),ang=Vector(0,90,0),speed=0.1},
    {pos=Vector(-2272,368,-5112),ang=Vector(0,-80,0),speed = 0.02},
    {pos=Vector(-2360,378,-4568),ang=Vector(0,-60,0),speed=0.1},
    {pos=Vector(-2391,574,-4568),ang=Vector(0,50,0),speed=0.1},
    {pos=Vector(-2566,553,-4568),ang=Vector(0,0,0),speed=0.1},
    {pos=Vector(-2621,547,-4440),ang=Vector(0,0,0),speed = 0.05},
    {pos=Vector(-2929,415,-4529),ang=Vector(0,0,0),speed=0.1},

];
BirbMaxKeyframes <- 19;


function UpdateBirbPos(){
    if(BirbFrame >= BirbMaxKeyframes)return;
    local prevKf = BirbKeyframes[BirbFrame];
    local nextKf = prevKf;
    if(BirbFrame<BirbMaxKeyframes-1){
        nextKf = BirbKeyframes[BirbFrame+1];
    }

    local birbPos = prevKf.pos + ((nextKf.pos - prevKf.pos) * BirbInterp);
    local birbRot = prevKf.ang + ((nextKf.ang - prevKf.ang) * BirbInterp);

    local maxJH = ((nextKf.pos-prevKf.pos).Length());
    local jumpHeight = (-BirbInterp*(BirbInterp-1))*maxJH;
    birbPos.z += jumpHeight;

    if(BirbInterp == 0){
        local smallJump = sin(BirbJumpLoop)*10;
        if(smallJump<0)smallJump = -smallJump;
        birbPos.z += smallJump;
        BirbJumpLoop += 0.5;
    }
    //BirbHandle.SetOrigin(birbPos);
    BirbHandle.SetAbsOrigin(birbPos);
    //EntFireByHandle(BirbHandle, "SetLocalOrigin", birbPos.x + " " + birbPos.y + " " + birbPos.z, 0, null, null)
    BirbHandle.SetAngles(birbRot.x,birbRot.y,birbRot.z);
}

function FindBirb(){
    BirbHandle = GetEntity("bird");
    UpdateBirbPos();
    IsBirbMap = true;
}

function UpdateBirb(){
    if(BirbInterp>0){
        local d=BirbKeyframes[BirbFrame].speed;
        BirbInterp+=d;
        //print(BirbInterp+"\n")
        if(BirbInterp>=1){
            BirbInterp = 0;
            BirbFrame++;
            BirbJumpLoop = 0;
        }
    }else if(BirbFrame < BirbMaxKeyframes){
        local kfPos = BirbKeyframes[BirbFrame].pos;
        local pPos = GetPlayer().GetOrigin();
        pPos.z += 36;
        local dist = pPos-kfPos;
        if(dist.Length() < 80){
            if(BirbFrame < BirbMaxKeyframes-1){
                BirbInterp = 0.01;
                BirbHandle.EmitSound("BirdBirdBird.Idles");
            }else{
                EntFire("bird","SetAnimation","nest_flyOff",0.0)
                EntFire("bird_idle_timer", "Kill")
                EntFire("bird", "Kill", "", 3.66)
                BirbFrame++;
            }
        }
    }
    UpdateBirbPos();
}




//berries
BERRIES <- {};
//okay, look, i know you think "yaya me me smart" but 
//at least try to not spoil berries location for yourself
BERRIES["sp_a1_intro1"] <- [
    {pos=Vector(-1075, 4348, 2739), berryType=0}
];
BERRIES["sp_a1_intro2"] <- [
    {pos=Vector(-230, 190, 580), berryType=0}
];
BERRIES["sp_a1_intro3"] <- [
    {pos=Vector(-512, 1200, 1160), berryType=0},
    {pos=Vector(-1278, 3390, 400), berryType=0},
];
BERRIES["sp_a1_intro4"] <- [
    {pos=Vector(848, -704, 340), berryType=0}
];
BERRIES["sp_a1_intro5"] <- [
    {pos=Vector(-345, -876, 710), berryType=0}
];
BERRIES["sp_a2_laser_vs_turret"] <- [
    //{pos=Vector(64, 96, 320), berryType=1}
    {pos=Vector(0, 224, 320), berryType=1}
];
BERRIES["sp_a3_portal_intro"] <- [
    {pos=Vector(3600, 32, 5696), berryType=1}
];


BERRIES_counter <- 0;
BERRIES_max <- 0;

function CreateBerries(){
    //assigning ID to every berry, and check if its collected already
    foreach( mapname, berryset in BERRIES){
        foreach(index, berry in berryset){
            berry.id <- BERRIES_max;
            berry.collected <- false;
            if(smsm.GetModeParam(ModeParams.BerriesOffset+BERRIES_max)>0){
                berry.collected = true;
            }
            BERRIES_max++;
        }
    }

    //spawning uncollected berries
    if(GetMapName() in BERRIES)foreach( index, berry in BERRIES[GetMapName()] ) if(!berry.collected){
        local berryEnt = Entities.CreateByClassname("prop_dynamic_override");
        EntFireByHandle(berryEnt, "AddOutput", "targetname berry_"+index, 0, null, null);
        EntFireByHandle(berryEnt, "SetAnimation", "collect", 0, null, null);
        EntFireByHandle(berryEnt, "SetAnimation", "idle", 1, null, null);
        if(berry.berryType==0)berryEnt.SetModel("models/srmod/strawberry.mdl");
        if(berry.berryType==1)berryEnt.SetModel("models/srmod/quantumberry.mdl");
        berryEnt.SetOrigin(berry.pos);
        berry.entity <- berryEnt;
    }

    //prepare portal detection system
    CheckPortals(true);

    UpdateBerryCounter();
}

function ResetBerries(){
    for(local i=0;i<BERRIES_max;i++){
        smsm.SetModeParam(ModeParams.BerriesOffset+i,0);
    }
    UpdateBerryCounter();
}

function UpdateBerryCounter(){
    local berriesCollected = 0;
    for(local i=0;i<BERRIES_max;i++){
        if(smsm.GetModeParam(ModeParams.BerriesOffset+i)>0)berriesCollected++;
    }
    smsm.SetModeParam(ModeParams.DisplayBerriesGot, berriesCollected);

    local inLevelBerriesCount = 0;
    if(GetMapName() in BERRIES)foreach( index, berry in BERRIES[GetMapName()] ){
        if(index>=10)break;
        local berryType = berry.berryType;
        if(berry.collected) berryType+=2;
        smsm.SetModeParam(ModeParams.DisplayBerriesInLevelOffset + index, berryType);
        inLevelBerriesCount++;
    }
    smsm.SetModeParam(ModeParams.DisplayBerriesInLevelCount, inLevelBerriesCount);

}

BERRIES_portal_init <- 0;
BERRIES_quantum_removed <- false;

//not reliable!
//apparently sometimes portals appear in the level even if they're not placed,
//and sometimes it's not (0,0,0), so it's dumb solution, but it works in most cases
function CheckPortals(checkInitial){
    if(!BERRIES_quantum_removed){
        local portalCount = 0;
        local portal = null;
        while(portal = Entities.FindByClassname(portal, "prop_portal")){
            if(portal.GetOrigin().Length() > 0)portalCount++;
        }
        if(checkInitial){
            BERRIES_portal_init = portalCount
        }else if(BERRIES_portal_init != portalCount){
            RemovePortalBerries();
        }
    }
}

function RemovePortalBerries(){
    if(!BERRIES_quantum_removed){
        modlog("Portal placement detected, destroying quantum berries!")

        local emitDistant = true;

        if(GetMapName() in BERRIES)foreach( index, berry in BERRIES[GetMapName()] ){
            if(berry.berryType==1 && !berry.collected && berry.entity){
                local berryFizzle = Entities.CreateByClassname("prop_weighted_cube");
                if(berry.berryType==1)berryFizzle.SetModel("models/srmod/quantumberry.mdl");
                berryFizzle.SetOrigin(berry.pos);
                EntFireByHandle(berryFizzle, "Dissolve", "", 0, null, null);
                EntFireByHandle(berry.entity, "Skin", "2", 0, null, null);
                EntFireByHandle(berry.entity, "DisableDraw", "", 0, null, null)
                EntFireByHandle(berry.entity, "EnableDraw", "", 2, null, null)
                berry.entity = null;

                local dist = (berry.pos - GetPlayer().GetOrigin()).Length();
                if(dist<1000){
                    emitDistant = false;
                    berryFizzle.EmitSound("celeste.quantumberrylost");
                }
            }
        }

        if(emitDistant)GetPlayer().EmitSound("celeste.quantumberrylost_distant");

        BERRIES_quantum_removed = true;
    }
}

function UpdateBerries(){
    local pmin = GetPlayer().GetOrigin()+GetPlayer().GetBoundingMins();
    local pmax = GetPlayer().GetOrigin()+GetPlayer().GetBoundingMaxs();
    local quantumCount = 0;
    if(GetMapName() in BERRIES)foreach( index, berry in BERRIES[GetMapName()] ){
        if(!berry.collected && berry.entity){
            if(berry.berryType==1)quantumCount++;
            local bsize = 16;
            local bmin = berry.entity.GetOrigin() - Vector(bsize,bsize,bsize);
            local bmax = berry.entity.GetOrigin() + Vector(bsize,bsize,bsize);
            //if player bbox overlaps berry bbox
            if(pmax.x > bmin.x && pmin.x < bmax.x && pmax.y > bmin.y && pmin.y < bmax.y && pmax.z > bmin.z && pmin.z < bmax.z){
                berry.collected = true;
                //berry.entity.EmitSound("celeste.berryget");
                EntFireByHandle(berry.entity, "Kill", "", 2, null, null);
                EntFireByHandle(berry.entity, "Skin", "1", 0.01, null, null);
                EntFireByHandle(berry.entity, "SetAnimation", "collect", 0, null, null);
                smsm.SetModeParam(ModeParams.BerriesOffset+berry.id,1);
                UpdateBerryCounter();
            }
        }
    }
    if(quantumCount>0)CheckPortals(false);
}

//main code

function CelestePostSpawn(){
    //FOG_CONTROL_VALUES = {r=0.8, g=0.4, b=1.3};
    FIRST_MAP_WITH_POTATO_GUN = "sp_a3_speed_ramp"
    
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
        //normal wall. slanted one confused lots of peples
        local containerWall2 = Entities.FindByClassnameNearest("func_door", Vector(-5477, 1400, 285), 10)
        EntFireByHandle(containerWall2, "SetLocalOrigin", "-1210 4602 2745", 0, null, null)
        EntFireByHandle(containerWall2, "SetLocalAngles", "0 0 5", 0, null, null)

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
    case "sp_a3_transition01":
        FindBirb();
        EntFire("potatos_prop", "AddOutput", "targetname potato_powerup_prop");
        EntFire("sphere_entrance_potatos_button", "Unlock", "", 1)
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed potato_powerup_prop:Kill::0:1")
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed aud_alarm_beep_sm:StopSound::4:-1")
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed "+self.GetName()+":RunScriptCode:UpgradeDashes(2):0:1")
        EntFire("timer_potato_particles", "Enable")
        EntFire("timer_potato_particles", "AddOutput", "OnTimer timer_potato_particles:SubtractFromTimer:1:0.01:-1")

        /*
        local eletrigger = Entities.FindByClassnameNearest("trigger_once", Vector(-2026,-128,-4088), 10)
        EntFireByHandle(eletrigger, "AddOutput", "targetname eletrigger", 0, null, null)
        EntFire("eletrigger", "Disable", "", 1);
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed eletrigger:Enable::1:-1")
        */

        EntFire("exit_lift_doortop_movelinear", "SetPosition", 0.01, 1);
        EntFire("exit_lift_doorbottom_movelinear", "SetPosition", 0.01, 1);
        local eletrigger = Entities.FindByClassnameNearest("trigger_once", Vector(-2200,-128,-4088), 10)
        EntFireByHandle(eletrigger, "Kill", "", 0, null, null)
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed exit_lift_doortop_movelinear:Open::1:-1")
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed exit_lift_doorbottom_movelinear:Open::1:-1")
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed blocking_hintsign:Kill::0:-1")

        //level up text
        EntFire( "@chapter_subtitle_text", "SetTextColor2", "210 210 210 255", 0.0 )
        EntFire( "@chapter_subtitle_text", "SetTextColor", "200 200 80 255", 0.0 )
        EntFire( "@chapter_subtitle_text", "SetPosY", "0.35", 0.0 )
        EntFire( "@chapter_subtitle_text", "settext", "LEVEL UP!", 0.0 )
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed @chapter_subtitle_text:display::0:-1")

        //sign to block the intentional doors
        for(local i=0;i<2;i++){
            local sign = Entities.CreateByClassname("prop_dynamic_override");
            sign.SetModel("models/srmod/hintplank.mdl");
            sign.SetOrigin(Vector(-3276, 576, -4550 + i*100));
            sign.SetAngles(90,0,0);
            EntFireByHandle(sign, "AddOutput", "targetname blocking_hintsign", 0, null, null)
        }

        EntFire("celeste_window_fix", "Kill")

        //sing for idiots
        local sign1 = Entities.CreateByClassname("prop_dynamic_override");
        sign1.SetModel("models/srmod/hintplank.mdl");
        sign1.SetOrigin(Vector(-2160, -130, -4159));
        sign1.SetAngles(0,170,0);
        EntFireByHandle(sign1, "skin", "3", 0, null, null)
        EntFireByHandle(sign1, "AddOutput", "targetname blocking_hintsign", 0, null, null)

        break;
    case "sp_a1_intro5":
        local introcar = CreateProp("prop_physics", Vector(-400, -930, 668), "models/srmod/introcar.mdl", 1);
        EntFireByHandle(introcar, "AddOutput", "targetname introcar", 0, null, null)
        EntFireByHandle(introcar, "AddOutput", "solid 6", 0, null, null)
        introcar.SetAngles(0,225,0)
        print("INTRO CAAAR\n")
        break;
    }

    UpgradeDashes(dashes);
    CreateBerries();
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
        self.EmitSound("celeste.dash")
    } 
    previousDashCount=dashesLeft;

    if(IsBirbMap)UpdateBirb();

    UpdateBerries();
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
        color = Vector(150,75,255)
    }else if(dashesLeft==1){
        color = Vector(255,40,0)
    }
    
    smsm.SetPortalGunIndicatorColor(color);
}

function UpgradeDashes(dashes){
    smsm.SetModeParam(ModeParams.MaxDashes, dashes);
}

AddModeFunctions("celeste", CelestePostSpawn, CelesteLoad, CelesteUpdate, CelestePrecache)