//*****************************************************
//*****************************************************
//====SPEEDRUN MOD v1.0 by Krzyhau====
//this mod removes all of major and most of minor cutscenes
//from the game, reducing the time for speedruning it lol.
//*****************************************************
//*****************************************************


//some useful functions

//Basically Entity.ConnectOutput, but adds this script to its execution scope
function AddOutput(entityname,event,func){
  local entity = GetEntity(entityname)
  if(entity){
    EntFire(entity.GetName(),"RunScriptFile","transitions/sp_transition_list.nut",0.0)
    entity.ConnectOutput(event,func)
  }else{
    //modlog("Failed to add output \""+event+":"+func+"\" for entity \""+entityname+"\"")
  }
}

//finding entity by name, and then by class
function GetEntity(name, old=null){
  local entity = Entities.FindByName(old,name);
  if(!entity)entity = Entities.FindByClassname(old,name);
  return entity;
}

//modlog
function modlog(msg){
  printl("### SPEEDRUN MOD ###: "+msg);
}

function IsSMSMActive(){
  return ("smsm" in this);
}



//actual script function loader
POST_SPAWN_FUNCTIONS <- {}
MAP_SPAWN_FUNCTIONS <- {}
UPDATE_FUNCTIONS <- {}

function AddModeFunctions(modeName, postSpawnFunc, mapSpawnFunc, updateFunc){
  POST_SPAWN_FUNCTIONS[modeName] <- postSpawnFunc
  MAP_SPAWN_FUNCTIONS[modeName] <- mapSpawnFunc
  UPDATE_FUNCTIONS[modeName] <- updateFunc
}

//all different modes
SPEEDRUN_MODES <- {};
SPEEDRUN_MODES[0] <- ["default"];
SPEEDRUN_MODES[1] <- ["default", "fog_percent"];
SPEEDRUN_MODES[2] <- ["default", "celeste"];

//import proper scripts
if(IsSMSMActive()){
  DoIncludeScript("modes/default", self.GetScriptScope());
  switch(smsm.GetMode()){
    case 1: DoIncludeScript("modes/fog", self.GetScriptScope()); break;
    case 2: DoIncludeScript("modes/celeste", self.GetScriptScope()); break;
  }
}




function OnPostSpawn(){

  if(!IsSMSMActive()){
    modlog("SMSM PLUGIN VERIFICATION FAILED!!!!!!")
    EntFire("@command", "Command", "disconnect", 1)
  }else{
    //debug mode info
    local mode = smsm.GetMode()
    printl("### SPEEDRUN MOD ###: Preparing the mod in mode "+mode)

    local auto = GetEntity("logic_auto")
    if(!auto){
      modlog("No logic_auto loaded yet. Speedrun Mod initialisation failed.")
      return false
    }
    //necessary to use OnMapSpawn event, since OnPostSpawn can be executed before some entities are even spawned
    EntFireByHandle(auto, "AddOutput", "OnMapSpawn "+self.GetName()+":RunScriptCode:OnMapSpawn():0:1", 0, null, null)

    foreach (id, modename in SPEEDRUN_MODES[mode]){
      modlog("Loading PostSpawn function for "+modename+".")
      local func = POST_SPAWN_FUNCTIONS[modename]
      func()
    }

    //override transition script Think function
    TransitionThink <- Think
    Think = SpeedrunModThink
  }
}


function OnMapSpawn(){
  local mode = SPEEDRUN_MODES[smsm.GetMode()]
  foreach (id, modename in mode){
    modlog("Loading OnMapSpawn function for "+modename+".")
    local func = MAP_SPAWN_FUNCTIONS[modename]
    func()
  }
}


OLD_TIME <- 0
NEW_TIME <- 0

function SpeedrunModThink(){
  if ( initialized ){
    OLD_TIME = OLD_TIME==0 ? Time() : NEW_TIME;
    NEW_TIME = Time();  //TICKING AWAY THE MOMENTS THAT MAKE UP A DULL DAY

    local mode = SPEEDRUN_MODES[smsm.GetMode()]
    foreach (id, modename in mode){
      local func = UPDATE_FUNCTIONS[modename]
      func()
    }
    return 0.001;
  }else{
    //apparently, when not in maploop, Think function is used only once, so that's pretty convenient for me
    TransitionThink()
  }
}

function DeltaTime(){
  return NEW_TIME-OLD_TIME
}

