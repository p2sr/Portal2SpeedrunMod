//*****************************************************
//====Save The Cube====
//bring the cube to the moon
//*****************************************************

CUBE_SPAWNS <- {}


function CubeCorePrecache(){
    smsm.PrecacheModel("models/srmod/cubecore.mdl", true);
    smsm.PrecacheModel("models/props/metal_box.mdl", true); // just in case
    smsm.PrecacheModel("models/props_underground/underground_boxdropper_cage.mdl", true);
    smsm.PrecacheModel("models/props_underground/underground_boxdropper.mdl", true);

    self.PrecacheSoundScript("celeste.dash");
}

function CubeCorePostSpawn(){

}

function CubeCoreLoad(){
    //create playerproxy for later
    local playerproxy = Entities.CreateByClassname("logic_playerproxy");
    EntFireByHandle(playerproxy, "AddOutput", "targetname cubecore_playerproxy",0,null,null);

    print("AAAAAAAAAAAA\n")

    switch(GetMapName()){
    case "sp_a1_intro1":
        CreateCubeCore(-1312,4448,3676);
        CreateCubeDropper(-1312,4448,3696, 0);
        CreateTriggerCubeHoldLockOrSomething(-688,3106,2532, true);
        EntFire("cubecore_cube", "EnableMotion", "", 4);
        EntFire("cubecore_dropper", "SetAnimation", "open", 3.5);
        EntFire("cubecore_dropper", "SetAnimation", "close", 5);

        EntFire("glass_break_193x193_d1", "SetAnimation", "collapse1", 5.5);
        EntFire("glass_break_193x193_d2", "SetAnimation", "collapse1", 5.5);
        EntFire("glass_break_193x193_d1", "EnableDraw", "", 5.5);
        EntFire("glass_break_193x193_d2", "EnableDraw", "", 5.5);
        EntFire("whole_glass_piece", "DisableDraw", "", 5.5);
        EntFire("glass_break", "Kill", "", 0);
        EntFire("aud_opening_glass_break", "PlaySound", "", 5.5);

        

        FixFilter("door_1-door_physics_clip","door_1-weighted_cube_filter");
        FixFilter("exit_door_cube_clip", "cube_filter");
        FixFilter("@exit_door-door_physics_clip", "@exit_door-weighted_cube_filter");
        FixFilter("@exit_elevator_cleanser");
        break
    case "sp_a1_intro2":
        CreateCubeCore(0,0,1000);
        GrabAndLockCubeFor(2);
        break
    }
    
}

CUBECORE_CORE <- null;

fuckingtimer <- 0


function CubeCoreUpdate(){
    fuckingtimer++
    if(fuckingtimer>60){
        GetEntity("cubecore_core").EmitSound("celeste.dash");
        fuckingtimer=0;
    }
}


//creates filter entity (or entities) and hook it into the fizzler/vclip
//so that cube core can freely pass through it
//entity - fizzler/vclip that has to be fixed
//existingFilter - name of a filter that is originally assigned to the entity.
function FixFilter(entity, existingFilter=null){
    local filter = Entities.CreateByClassname("filter_activator_name");
    local filtername = entity+"_hackyfilter";
    EntFireByHandle(filter,"AddOutput","targetname "+filtername,0,null,null);
    EntFireByHandle(filter,"AddOutput","filtername cubecore_cube",0,null,null);
    EntFireByHandle(filter,"AddOutput","negated 1",0,null,null);
    if(existingFilter!=null){
        //entity does have a filter, use filter_multi to connect old and new one
        local filtermulti = Entities.CreateByClassname("filter_multi");
        local filtermultiname = entity+"_hackymulti";
        EntFireByHandle(filtermulti,"AddOutput","targetname "+filtermultiname,0,null,null);
        EntFireByHandle(filtermulti,"AddOutput","filter01 "+existingFilter,0,null,null);
        EntFireByHandle(filtermulti,"AddOutput","filter02 "+filtername,0,null,null);
        EntFireByHandle(filtermulti,"RunScriptCode","smsm.RefreshEntity(self)",0.05,null,null);
        EntFire(entity,"AddOutput","filtername "+filtermultiname)
    }else{ 
        //entity doesnt have any filters, just add it
        EntFire(entity,"AddOutput","filtername "+filtername)
    }
    //janky hack mate >:]
    EntFire(entity,"RunScriptCode","smsm.RefreshEntity(self)",0.1);
    //TODO: add spawn in plugin (24)
}

//function naming is my pashion
function CreateTriggerCubeHoldLockOrSomething(x,y,z,startLocked){
    local endTrigger = Entities.FindByClassnameNearest("trigger_once", Vector(x,y,z), 20);
    //just to be sure lmao, probably useless
    if(!endTrigger) endTrigger = Entities.FindByClassnameNearest("trigger_multiple", Vector(x,y,z), 20); 
    EntFireByHandle(endTrigger, "AddOutput", "targetname cubecore_fixed_end_trigger",0,null,null);

    //disable and enable trigger whether player is holding a cube
    if(startLocked)EntFire("cubecore_fixed_end_trigger", "Disable");
    EntFire("cubecore_cube", "AddOutput", "OnPhysGunDrop cubecore_fixed_end_trigger:Disable::0:-1",0.5);
    EntFire("cubecore_cube", "AddOutput", "OnPlayerPickup cubecore_fixed_end_trigger:Enable::0:-1",0.5);

    //make sure the player cannot drop the cube when transitioning
    EntFireByHandle(endTrigger, "AddOutput", "OnStartTouch cubecore_playerproxy:ForceVMGrabController::0:-1",0,null,null);
    EntFireByHandle(endTrigger, "AddOutput", "OnStartTouch cubecore_playerproxy:SetDropEnabled:0:0:-1",0,null,null);
}

function GrabAndLockCubeFor(waitTime){
    EntFire("cubecore_playerproxy", "ForceVMGrabController", "", 0);
    EntFire("cubecore_playerproxy", "SetDropEnabled", "0", 0);

    EntFire("cubecore_cube", "Use", "", 0.2, GetPlayer())

    EntFire("cubecore_playerproxy", "ResetGrabControllerBehavior", "", waitTime);
    EntFire("cubecore_playerproxy", "SetDropEnabled", "1", waitTime);
}



function CreateCubeDropper(x,y,z,rot){
    local dropper = Entities.CreateByClassname("prop_dynamic");
    EntFireByHandle(dropper, "AddOutput", "targetname cubecore_dropper", 0, null, null);
    dropper.SetOrigin(Vector(x,y,z-96));
    dropper.SetAngles(0,0,0);
    dropper.SetModel("models/props_underground/underground_boxdropper.mdl");

    local dropperCage = Entities.CreateByClassname("prop_dynamic");
    EntFireByHandle(dropperCage, "AddOutput", "solid 6", 0, null, null);
    EntFireByHandle(dropperCage, "AddOutput", "targetname cubecore_dropper_cage", 0, null, null);
    dropperCage.SetOrigin(Vector(x,y,z-96));
    dropper.SetAngles(0,0,0);
    dropperCage.SetModel("models/props_underground/underground_boxdropper_cage.mdl");

    local dropperBlack = Entities.CreateByClassname("prop_dynamic");
    EntFireByHandle(dropperBlack, "Color", "0 0 0", 0, null, null);
    dropperBlack.SetOrigin(Vector(x,y,z+8));
    dropper.SetAngles(0,0,0);
    dropperBlack.SetModel("models/props_underground/underground_boxdropper.mdl");
}

function CreateCubeCore(x,y,z){
    //For some reason making functional cubes or cores with script functions is nearly impossible.
    //spawning the cube using commands. it always has targetname "cube".
    //needs to wait 1 tick before trying to modify it.
    SendToConsole("ent_create_portal_reflector_cube")
    SendToConsole("ent_create npc_personality_core")
    EntFire(self.GetName(), "RunScriptCode", "PostCreateCubeCore("+x+","+y+","+z+")", 0.1);
}

function PostCreateCubeCore(x,y,z){
    local cubeEnt = Entities.FindByName(null,"cube");
    EntFireByHandle(cubeEnt, "AddOutput", "targetname cubecore_cube", 0, null, null);
    //cubeEnt.SetModel("models/srmod/cubecore.mdl");
    cubeEnt.SetOrigin(Vector(x,y,z));
    cubeEnt.SetAngles(0,0,0);
    EntFireByHandle(cubeEnt, "DisableDraw", "", 0, null, null);
    EntFireByHandle(cubeEnt, "AddOutput", "solid 0", 0, null, null)
    EntFireByHandle(cubeEnt, "AddOutput", "solid 6", 1, null, null)
    EntFireByHandle(cubeEnt, "DisableMotion", "", 0, null, null)
    
    local coreEnt = null;
    local newCoreEnt = null;
    while(newCoreEnt = Entities.FindByClassname(coreEnt,"npc_personality_core")){
        coreEnt = newCoreEnt;
    }
    coreEnt.SetModel("models/srmod/cubecore.mdl");
    coreEnt.SetOrigin(Vector(x,y,z));
    coreEnt.SetAngles(0,90,0);
    EntFireByHandle(coreEnt, "DisableMotion", "", 0, null, null)
    EntFireByHandle(coreEnt, "AddOutput", "targetname cubecore_core", 0, null, null);
    EntFireByHandle(coreEnt, "SetParent", "cubecore_cube", 0, null, null);
    EntFireByHandle(coreEnt, "AddOutput", "solid 0", 0, null, null);
    EntFireByHandle(coreEnt, "SetIdleSequence", "sphere_plug_idle_normal", 0.5, null, null);
    EntFireByHandle(coreEnt, "DisablePickup", "", 0, null, null);
    EntFireByHandle(coreEnt, "RunScriptCode","smsm.RefreshEntity(self)",0.1, null, null);
    CUBECORE_CORE = coreEnt;
}

function CreateStartDropper(x,y,z, pitch, yaw, roll, delay){

}

function CreateEndDropper(pos, angles){

}

AddModeFunctions("cubecore", CubeCorePostSpawn, CubeCoreLoad, CubeCoreUpdate, CubeCorePrecache)