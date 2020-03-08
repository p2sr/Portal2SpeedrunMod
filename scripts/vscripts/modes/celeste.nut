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
    Dashing = 5,
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
    smsm.PrecacheModel("models/srmod/goldenberry.mdl", true)
    smsm.PrecacheModel("models/srmod/goldenquantumberry.mdl", true)
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
    {pos=Vector(-1075, 4348, 2739)},
];
BERRIES["sp_a1_intro2"] <- [
    {pos=Vector(-230, 190, 580)},
];
BERRIES["sp_a1_intro3"] <- [
    {pos=Vector(-512, 1200, 1160)},
    {pos=Vector(-1278, 3390, 400)},
];
BERRIES["sp_a1_intro4"] <- [
    {pos=Vector(848, -704, 340)},
];
BERRIES["sp_a1_intro5"] <- [
    {pos=Vector(-345, -876, 710)},
];
BERRIES["sp_a1_intro6"] <- [
    {pos=Vector(444, -256, 600)},
    {pos=Vector(1245, 394, 720)},
    {pos=Vector(1664, -472, 630), golden=1},
];
BERRIES["sp_a1_intro7"] <- [
    {pos=Vector(0, -448, 1280)},
    {pos=Vector(-588, -609, 1490), quantum=1},
];
BERRIES["sp_a1_wakeup"] <- [
    {pos=Vector(6974, 840, 620)},
];
BERRIES["sp_a2_intro"] <- [
    {pos=Vector(412, 520, -10288)},
];
BERRIES["sp_a2_laser_intro"] <- [
    {pos=Vector(224, 280, 42)},
];
BERRIES["sp_a2_laser_stairs"] <- [
    {pos=Vector(-665, -420, 828)},
    {pos=Vector(665, -41, 128)},
];
BERRIES["sp_a2_dual_lasers"] <- [
    {pos=Vector(303, -704, 1104)},
];
BERRIES["sp_a2_laser_over_goo"] <- [
    {pos=Vector(3004, -923, 102), quantum=1},
];
BERRIES["sp_a2_catapult_intro"] <- [
    {pos=Vector(-512, -351, 608), golden=1},
];
BERRIES["sp_a2_trust_fling"] <- [
    {pos=Vector(-992, -640, -320)},
    {pos=Vector(2035, -57, 258)},
    {pos=Vector(-1152, 1442, 64), quantum=1},
];
BERRIES["sp_a2_pit_flings"] <- [
    {pos=Vector(608, 194, 528)},
    {pos=Vector(-672, -352, 64), quantum=1},
];
BERRIES["sp_a2_fizzler_intro"] <- [
    {pos=Vector(164, -352, 544)},
];
BERRIES["sp_a2_sphere_peek"] <- [
    {pos=Vector(-1824, 1824, 264)},
    {pos=Vector(-1416, 2336, 800)},
];
BERRIES["sp_a2_ricochet"] <- [
    {pos=Vector(2464, 1152, -992)},
    {pos=Vector(3232, 1344, 480), golden=1},
];
BERRIES["sp_a2_bridge_intro"] <- [
    {pos=Vector(-104, 1116, -80), quantum=1, golden=1},
];
BERRIES["sp_a2_bridge_the_gap"] <- [
    {pos=Vector(-1123, -595, 1495)},
    {pos=Vector(-128, -256, 1752)},
];
BERRIES["sp_a2_turret_intro"] <- [
    {pos=Vector(256, -416, 192)},
    {pos=Vector(-475, 391, -191), golden=1},
];
BERRIES["sp_a2_turret_blocker"] <- [
    {pos=Vector(64, 1376, 64), quantum=1},
];
BERRIES["sp_a2_laser_vs_turret"] <- [
    {pos=Vector(864, -448, 360)},
];
BERRIES["sp_a2_pull_the_rug"] <- [
    {pos=Vector(128, -1104, 550), quantum=1},
];
BERRIES["sp_a2_column_blocker"] <- [
    {pos=Vector(32, -912, 660)},
    {pos=Vector(-192, 1060, 86)},
];
BERRIES["sp_a2_laser_chaining"] <- [
    {pos=Vector(448, 64, 704)},
    {pos=Vector(-432, -860, 704)},
];

BERRIES["sp_a2_bts4"] <- [
    {pos=Vector(1072, -2656, 7232), golden=1},
    {pos=Vector(1938, -3200, 7744)},
    {pos=Vector(2896, -5120, 6688)},
    {pos=Vector(-1664, -7360, 6720)},
];
BERRIES["sp_a2_core"] <- [
    {pos=Vector(168, 2118, -40)},
];
BERRIES["sp_a3_01"] <- [
    {pos=Vector(-528, -1363, 2451), golden=1},
    {pos=Vector(-1880, -2760, 396)},
    {pos=Vector(-1090, 194, 69)},
    {pos=Vector(-7, 2786, 512)},
];
BERRIES["sp_a3_03"] <- [
    {pos=Vector(-5416, -1808, -4928)},
    {pos=Vector(-7040, 1216, -4672)},
];
BERRIES["sp_a3_transition01"] <- [
    {pos=Vector(-2496, 704, -4832), golden=1},
];
BERRIES["sp_a3_speed_ramp"] <- [
    {pos=Vector(-1218, 1664, 0)},
    {pos=Vector(-640, 3, 600)},
    {pos=Vector(-160, -640, 1592)},
    {pos=Vector(1140, -702, 1800), golden=1},
    
];
BERRIES["sp_a3_speed_flings"] <- [
    {pos=Vector(2048, 768, 1484)},
    {pos=Vector(455, 1237, 502)},
];
BERRIES["sp_a3_portal_intro"] <- [
    {pos=Vector(3600, 32, 5696), quantum=1}
];


BERRIES["sp_a4_laser_platform"] <- [
    {pos=Vector(-20, -1142, 750)},
    {pos=Vector(-172, -720, 352)},
    {pos=Vector(3520, -608, -300), golden=1},
];

BERRIES["sp_a4_speed_tb_catch"] <- [
    {pos=Vector(448, 1192, 898)},
    {pos=Vector(-2688, 2080, 72)},
    {pos=Vector(-2400, 496, 64), quantum=1},
];



BERRIES_counter <- 0;
BERRIES_max <- 0;

function CreateBerries(){
    //assigning ID to every berry, and check if its collected already
    foreach( mapname, berryset in BERRIES){
        foreach(index, berry in berryset){
            berry.id <- BERRIES_max;
            berry.collected <- false;
            if(!("quantum" in berry))berry.quantum <- 0;
            if(!("golden" in berry))berry.golden <- 0;
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
        EntFireByHandle(berryEnt, "SetAnimation", "idle", 0, null, null);
        if(berry.golden && berry.quantum)berryEnt.SetModel("models/srmod/goldenquantumberry.mdl");
        else if(berry.quantum)berryEnt.SetModel("models/srmod/quantumberry.mdl");
        else if(berry.golden)berryEnt.SetModel("models/srmod/goldenberry.mdl");
        else berryEnt.SetModel("models/srmod/strawberry.mdl");
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
        local berryType = 0;
        if(berry.quantum)berryType+=2;
        if(berry.golden)berryType+=4;
        if(berry.collected) berryType++;
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
            if(berry.quantum && !berry.collected && berry.entity){
                local berryFizzle = Entities.CreateByClassname("prop_weighted_cube");
                if(berry.golden)berryFizzle.SetModel("models/srmod/goldenquantumberry.mdl");
                else berryFizzle.SetModel("models/srmod/quantumberry.mdl");
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
            if(berry.quantum)quantumCount++;
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

    //ensure that is turned on
    if(GetMapName()=="sp_a1_intro1" || GetMapName()=="sp_a1_intro3"){
        SendToConsole("gameinstructor_enable 1")
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
        EntFireByHandle(sign, "AddOutput", "targetname climb_sign", 0, null, null)
        sign.SetOrigin(Vector(-1405, 4374, 2740));
        sign.SetAngles(85,0,90)

        local hint = Entities.CreateByClassname("env_instructor_hint");
        EntFireByHandle(hint, "AddOutput", "targetname climb_hint", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_target climb_sign", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_binding +use", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_caption Wallclimb", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_color 255 255 255", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_icon_onscreen use_binding", 0, null, null)

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

        local hint = Entities.CreateByClassname("env_instructor_hint");
        EntFireByHandle(hint, "AddOutput", "targetname dash_hint", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_binding +dash", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_caption Dash", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_color 255 255 255", 0, null, null)
        EntFireByHandle(hint, "AddOutput", "hint_icon_onscreen use_binding", 0, null, null)
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
    case "sp_a2_bts1":
        local fakeBerryPos = Vector(352,-64,0);
        local fakeBerry = Entities.CreateByClassname("prop_dynamic_override");
        EntFireByHandle(fakeBerry, "AddOutput", "targetname jebaited", 0, null, null);
        EntFireByHandle(fakeBerry, "SetAnimation", "idle", 0, null, null);
        fakeBerry.SetModel("models/srmod/goldenberry.mdl");
        fakeBerry.SetOrigin(fakeBerryPos);
        local fakeBerry2 = Entities.CreateByClassname("prop_weighted_cube");
        fakeBerry2.SetModel("models/srmod/goldenberry.mdl");
        fakeBerry2.SetOrigin(fakeBerryPos);
        EntFireByHandle(fakeBerry2, "AddOutput", "targetname jebaited2", 0, null, null)
        EntFireByHandle(fakeBerry2, "DisableDraw", "", 0.5, null, null)
        EntFire("pre_solved_chamber-toxin_reveal_rl", "AddOutput", "OnTrigger jebaited:Disable::0:-1");
        EntFire("pre_solved_chamber-toxin_reveal_rl", "AddOutput", "OnTrigger jebaited2:EnableDraw::0:-1");
        EntFire("pre_solved_chamber-toxin_reveal_rl", "AddOutput", "OnTrigger jebaited2:Dissolve::0.01:-1");
    }

    UpgradeDashes(dashes);
    CreateBerries();
}

rainbowColorState <- 0;
previousDashing <- 0;
staminaAnimTimer <- 0;
hintState <- 0

function CelesteUpdate(){
    
    UpdateIndicatorDiode();
    UpdateStaminaCover();

    local dashing = smsm.GetModeParam(ModeParams.Dashing);

    local makeSound = dashing>previousDashing;
    if(makeSound){
        self.EmitSound("celeste.dash")
    } 
    previousDashing=dashing;

    if(IsBirbMap)UpdateBirb();

    UpdateBerries();

    UpdateHints();
}

function UpdateHints(){
    if(GetMapName()=="sp_a1_intro1" && hintState < 2){
        local o = GetPlayer().GetOrigin();
        if(hintState==0 && o.y < 4200 && o.x > -1348 && o.z < 2900){
            EntFire("climb_hint", "ShowHint");
            hintState++;
        }else if(hintState==1 && o.y > 4360 && o.x < -1348){
            hintState++;
            EntFire("climb_hint", "EndHint")
        }
    }
    if(GetMapName()=="sp_a1_intro3" && hintState < 2){
        if(hintState==0 && smsm.GetModeParam(ModeParams.MaxDashes)>0){
            EntFire("dash_hint", "ShowHint");
            hintState++;
        }else if(hintState==1 && smsm.GetModeParam(ModeParams.Dashing)>0){
            hintState++;
            EntFire("dash_hint", "EndHint")
        }
    }
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