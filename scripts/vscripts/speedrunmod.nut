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

//parse developer level to mode id
function GetModeInfo(){
  local devLevel = GetDeveloperLevel()
  local modeNumber = abs(devLevel/1000000)
  local modeParam = abs(devLevel%1000000)
  return {id=modeNumber,param=modeParam,devLevel=devLevel}
}

function GetModeID(){
  return GetModeInfo().id
}

function GetModeParam(){
  return GetModeInfo().param
}



//actual script loader

POST_SPAWN_FUNCTIONS <- {};
MAP_SPAWN_FUNCTIONS <- {};

function AddModeFunctions(modeName, postSpawnFunc, mapSpawnFunc){
  POST_SPAWN_FUNCTIONS[modeName] <- postSpawnFunc
  MAP_SPAWN_FUNCTIONS[modeName] <- mapSpawnFunc
}

SPEEDRUN_MODES <- {}
SPEEDRUN_MODES[0] <- ["default"]
SPEEDRUN_MODES[1] <- ["default", "fog_percent"]

DoIncludeScript("modes/default", self.GetScriptScope())
DoIncludeScript("modes/fog", self.GetScriptScope())






function OnPostSpawn(){
  //debug mode info
  local info = GetModeInfo();
  printl("### SPEEDRUN MOD ###: Preparing the mod in mode "+info.id+", param:"+info.param)

  local auto = GetEntity("logic_auto")
  if(!auto){
    modlog("No logic_auto loaded yet. Speedrun Mod initialisation failed.")
    return false
  }
  //necessary to use OnMapSpawn event, since OnPostSpawn can be executed before some entities are even spawned
  EntFireByHandle(auto, "AddOutput", "OnMapSpawn "+self.GetName()+":RunScriptCode:OnMapSpawn():0:1", 0, null, null)

  foreach (id, modename in SPEEDRUN_MODES[info.id]){
    modlog("Loading PostSpawn function for "+modename+".")
    local func = POST_SPAWN_FUNCTIONS[modename]
    func()
  }
}


function OnMapSpawn(){
  foreach (id, modename in SPEEDRUN_MODES[GetModeID()]){
    modlog("Loading OnMapSpawn function for "+modename+".")
    local func = MAP_SPAWN_FUNCTIONS[modename]
    func()
  }
}