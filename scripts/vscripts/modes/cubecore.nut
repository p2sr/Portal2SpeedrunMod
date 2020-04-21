//*****************************************************
//====Save The Cube====
//bring the cube to the moon
//*****************************************************

CUBE_SPAWNS <- {}


function CubeCorePrecache(){
    smsm.PrecacheModel("models/srmod/cubecore.mdl", true);
    smsm.PrecacheModel("models/props/metal_box.mdl", true); // just in case
}

function CubeCorePostSpawn(){

}

function CubeCoreLoad(){
    switch(GetMapName()){
    case "sp_a1_intro1":
        CreateCubeCore(-1295,4462,2750, 0,0,0, 0);
        break
    }
}

CUBECORE_CUBE <- null;

function CubeCoreUpdate(){
    
}



function CreateCubeCore(x,y,z, pitch, yaw, roll, delay){
    //For some reason making functional cubes or cores with script functions is nearly impossible.
    //spawning the cube using commands. it always has targetname "cube".
    //needs to wait 1 tick before trying to modify it.
    //EntFire("@command", "Command", "ent_create_portal_reflector_cube")
    EntFire("@command", "Command", "ent_create npc_personality_core")
    EntFire(self.GetName(), "RunScriptCode", "PostCreateCubeCore("+x+","+y+","+z+","+pitch+","+yaw+","+roll+","+delay+")", 0.01);
}

function PostCreateCubeCore(x,y,z, pitch, yaw, roll, delay){
    // local cubeEnt = Entities.FindByName(null,"cube");
    // print(cubeEnt+"\n")
    // EntFireByHandle(cubeEnt, "AddOutput", "targetname cubecore_cube", 0, null, null);
    // cubeEnt.SetModel("models/srmod/cubecore.mdl");
    // cubeEnt.SetOrigin(Vector(x,y,z));
    // cubeEnt.SetAngles(pitch,yaw,roll);
    // EntFireByHandle(cubeEnt, "DisableDraw", "", 0, null, null);
    // EntFireByHandle(cubeEnt, "AddOutput", "solid 0", 0, null, null)
    // EntFireByHandle(cubeEnt, "AddOutput", "solid 6", 0.1, null, null)

    local coreEnt = null
    do{
        coreEnt = Entities.FindByClassname(coreEnt,"npc_personality_core");
    }while(coreEnt.GetName()!="");
    coreEnt.SetModel("models/srmod/cubecore.mdl");
    coreEnt.SetOrigin(Vector(x,y,z));
    coreEnt.SetAngles(pitch,yaw+90,roll);
    //EntFireByHandle(coreEnt, "AddOutput", "solid 0", 0, null, null)
    EntFireByHandle(coreEnt, "AddOutput", "targetname cubecore_core", 0, null, null);
    //EntFireByHandle(coreEnt, "SetParent", "cubecore_cube", 0, null, null);
    EntFireByHandle(coreEnt, "SetAnimation", "sphere_plug_idle_neutral", 0, null, null);
    //EntFireByHandle(coreEnt, "DisablePickup", "", 0, null, null);
    
}

function CreateStartDropper(x,y,z, pitch, yaw, roll, delay){

}

function CreateEndDropper(pos, angles){

}

AddModeFunctions("cubecore", CubeCorePostSpawn, CubeCoreLoad, CubeCoreUpdate, CubeCorePrecache)