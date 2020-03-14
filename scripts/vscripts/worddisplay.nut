DoIncludeScript("modes/celeste", self.GetScriptScope());
CreateBerries();


//word display functions
LETTERS <- [];

FONT <- " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.'/()-_+=?,:[]{}*#";
FONT_LOOKUP <- {};
foreach(i,fontLetter in FONT){
  FONT_LOOKUP[fontLetter] <- i;
}
FONT_W <- [0.7,1,1,1,1,0.8,0.8,1,1,0.5,0.5,1,0.9,1.1,1,1,1,1,1,0.9,0.8,1,1,1.1,0.9,0.9,1, //uppercase letters
           0.9,0.8,0.9,0.9,0.9,0.7,1,1,0.5,0.5,0.9,0.6,1.1,0.8,0.9,0.85,1,0.7,0.8,0.7,0.9,0.9,1.1,0.8,0.9,0.9, //lowercase letters
           0.9,0.7,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9, //numbers
           0.5,0.5,0.5,0.5,0.5,1,1,1,1,0.7,0.5,0.5, //characters
           1,1,1,1,1,1]; //berries



function GetLetterFrame(letter){
  if(letter in FONT_LOOKUP)return FONT_LOOKUP[letter];
  return 0;
}

function Clear(){
  local ent = null;
  while(ent = Entities.FindByName(ent, "letter"))EntFireByHandle(ent,"Kill","",0,null,null);
}

function UpdateColor(){
  local ent = null;
  while(ent = Entities.FindByName(ent, "letter")){
    local ang = ent.GetAngles();
    if(ang.Length()>0){
      EntFireByHandle(ent,"Color",floor(ang.x*255)+" "+floor(ang.y*255)+" "+floor(ang.z*255),0,null,null);
      EntFireByHandle(ent,"SetLocalAngles","0 0 0",0,null,null);
    }
  }
}

function DisplayWord(x, y, z, word, color=Vector(1,1,1), scale=1.0){
  local xpos = x;
  foreach(i,letter in word){
    local f = 0;
    if(letter in FONT_LOOKUP)f = FONT_LOOKUP[letter];
    //using Z position for letter frame (material proxies). Using rotation for color (set by an UpdateColor function)
    self.SpawnEntityAtLocation(self.GetOrigin()+Vector(xpos*16,-y*16,z+f*0.01 + 0.004), color);
    xpos += FONT_W[f] * scale;
  }
}



//screen display functions

MAPS <- [
  {filename="sp_a1_intro1",name="Container Ride"},
  {filename="sp_a1_intro2",name="Portal Carousel"},
  {filename="sp_a1_intro3",name="Portal Gun"},
  {filename="sp_a1_intro4",name="Smooth Jazz"},
  {filename="sp_a1_intro5",name="Cube Momentum"},
  {filename="sp_a1_intro6",name="Future Starter"},
  {filename="sp_a1_intro7",name="Secret Panel"},
  {filename="sp_a1_wakeup",name="Wakeup"},
  {filename="sp_a2_intro",name="Incinerator"},
  {filename="sp_a2_laser_intro",name="Laser Intro"},
  {filename="sp_a2_laser_stairs",name="Laser Stairs"},
  {filename="sp_a2_dual_lasers",name="Dual Lasers"},
  {filename="sp_a2_laser_over_goo",name="Laser Over Goo"},
  {filename="sp_a2_catapult_intro",name="Catapult Intro"},
  {filename="sp_a2_trust_fling",name="Trust Fling"},
  {filename="sp_a2_pit_flings",name="Pit Flings"},
  {filename="sp_a2_fizzler_intro",name="Fizzler Intro"},
  {filename="sp_a2_sphere_peek",name="Ceiling Catapult"},
  {filename="sp_a2_ricochet",name="Ricochet"},
  {filename="sp_a2_bridge_intro",name="Bridge Intro"},
  {filename="sp_a2_bridge_the_gap",name="Bridge The Gap"},
  {filename="sp_a2_turret_intro",name="Turret Intro"},
  {filename="sp_a2_laser_relays",name="Laser Relays"},
  {filename="sp_a2_turret_blocker",name="Turret Blocker"},
  {filename="sp_a2_laser_vs_turret",name="Laser Vs Turret"},
  {filename="sp_a2_pull_the_rug",name="Pull The Rug"},
  {filename="sp_a2_column_blocker",name="Column Blocker"},
  {filename="sp_a2_laser_chaining",name="Laser Chaining"},
  {filename="sp_a2_triple_laser",name="Triple Laser"},
  {filename="sp_a2_bts1",name="Jailbreak"},
  {filename="sp_a2_bts2",name="Escape"},
  {filename="sp_a2_bts3",name="Turret Factory"},
  {filename="sp_a2_bts4",name="Turret Sabotage"},
  {filename="sp_a2_bts5",name="Neurotoxin Sabotage"},
  {filename="sp_a2_core",name="Core"},
  {filename="sp_a3_01",name="Underground"},
  {filename="sp_a3_03",name="Cave Johnson"},
  {filename="sp_a3_jump_intro",name="Repulsion Intro"},
  {filename="sp_a3_bomb_flings",name="Bomb Flings"},
  {filename="sp_a3_crazy_box",name="Crazy Box"},
  {filename="sp_a3_transition01",name="PotatOS"},
  {filename="sp_a3_speed_ramp",name="Propulsion Intro"},
  {filename="sp_a3_speed_flings",name="Propulsion Flings"},
  {filename="sp_a3_portal_intro",name="Conversion Intro"},
  {filename="sp_a3_end",name="Three Gels"},
  {filename="sp_a4_intro",name="Test"},
  {filename="sp_a4_tb_intro",name="Funnel Intro"},
  {filename="sp_a4_tb_trust_drop",name="Ceiling Button"},
  {filename="sp_a4_tb_wall_button",name="Wall Button"},
  {filename="sp_a4_tb_polarity",name="Polarity"},
  {filename="sp_a4_tb_catch",name="Funnel Catch"},
  {filename="sp_a4_stop_the_box",name="Stop The Box"},
  {filename="sp_a4_laser_catapult",name="Laser Catapult"},
  {filename="sp_a4_laser_platform",name="Laser Platform"},
  {filename="sp_a4_speed_tb_catch",name="Propulsion Catch"},
  {filename="sp_a4_jump_polarity",name="Repulsion Polarity"},
  {filename="sp_a4_finale1",name="Finale 1"},
  {filename="sp_a4_finale2",name="Finale 2"},
  {filename="sp_a4_finale3",name="Finale 3"},
  {filename="sp_a4_finale4",name="Finale 4"},
];


CURRENT_MAP <- -1;

function DisplayBerryList(mapID){
  Clear();
  local map = {filename="???",name="(undefined)"};
  if(mapID>=0 && mapID<MAPS.len())map = MAPS[mapID];
  DisplayWord(-11,-5.3,50,(map.name+":"));
  if(map.filename in BERRIES){
    foreach(i,berry in BERRIES[map.filename]){
      local color = Vector(1,1,0.6);
      if(!berry.collected)color = Vector(0.5,0.5,0.5);
      local scale = 1;
      if(berry.name.len()>25)scale=0.9;
      DisplayWord(-11.5,-4.5+i*1.6,0,berry.name, color, scale);
      //[]{}*#
      local berryChar = "[";
      if(berry.collected){
        if(berry.golden)berryChar = "#";
        else if(berry.quantum)berryChar = "}";
        else berryChar = "]";
      }else{
        if(berry.golden)berryChar = "*";
        else if(berry.quantum)berryChar = "{";
      }
      DisplayWord(-9.8,-3.6+i*1.2,60,berryChar);
    }
  }else{
    DisplayWord(-11.5,-4.5,0,"(no berries detected)", Vector(0.5, 0.5, 0.5));
  }
  CURRENT_MAP = mapID;
  UpdateColor();
}

BerryScanningInProgress <- false;

function DisplayPrevBerryList(){
  if(BerryScanningInProgress)return;
  CURRENT_MAP--;
  if(CURRENT_MAP<0)CURRENT_MAP=0;
  DisplayBerryList(CURRENT_MAP);
}

function DisplayNextBerryList(){
  if(BerryScanningInProgress)return;
  CURRENT_MAP++;
  if(CURRENT_MAP>=MAPS.len())CURRENT_MAP=MAPS.len()-1;
  DisplayBerryList(CURRENT_MAP);
}

function DisplayTestScreen(){
  Clear();
  DisplayWord(-13,-4,0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  DisplayWord(-13,-2,0,"abcdefghijklmnopqrstuvwxyz");
  DisplayWord(-13,0,0,"0123456789");
  DisplayWord(-13,2,0,".'/()-_+=?,:");
  DisplayWord(-13,4,0,"[]{}*#");
  UpdateColor();
}

function DisplayBerryOSLogo(){
  Clear();
  DisplayWord(-3.8,-1.5,150,"Berry",Vector(1,0.2,0.2));
  DisplayWord(0.4,-1.5,150,"OS");
  DisplayWord(1.5,-1.2,190,"]");
  DisplayWord(-13.1,3,0,"Your Personal Berry Collection Assistant",Vector(1,1,1), 0.85);
  UpdateColor();
}

function DisplayUnlockProgress(state){
  Clear();
  BerryScanningInProgress = (state != 7);
  local texts = [
    "Initiating berry count...",
    "Counting red berries...",
    "Red berries counted.",
    "Counting quantum berries...",
    "Quantum berries counted.",
    "Couting golden berries...",
    "Golden berries counted.",
    "Counting completed."
  ];
  DisplayWord(-10,-5,50,texts[state]);

  if(state>=1){
    DisplayWord(-3,-1.5,140,"]");
    if(state>=2){
      local countText = "x "+BERRIES_count_red_collected+" / "+BERRIES_count_red;
      local color = Vector(1,1,1);
      if(state>=3){
        if(BERRIES_count_red_collected==BERRIES_count_red)color=Vector(0.5,1,0.5);
        else color=Vector(1,0.5,0.5);
      }
      DisplayWord(-3,-2.2,50,countText,color);
    }
  }
  if(state>=3){
    DisplayWord(-3,-0.1,140,"}");
    if(state>=4){
      local countText = "x "+BERRIES_count_quantum_collected+" / "+BERRIES_count_quantum;
      local color = Vector(1,1,1);
      if(state>=5){
        if(BERRIES_count_quantum_collected==BERRIES_count_quantum)color=Vector(0.5,1,0.5);
        else color=Vector(1,0.5,0.5);
      }
      DisplayWord(-3,0.4,50,countText,color);
    }
  } 
  if(state>=5){
    DisplayWord(-3,1.3,140,"#");
    if(state>=6){
      local countText = "x "+BERRIES_count_golden_collected+" / "+BERRIES_count_golden;
      local color = Vector(1,1,1);
      if(state>=7){
        if(BERRIES_count_golden_collected==BERRIES_count_golden)color=Vector(0.5,1,0.5);
        else color=Vector(1,0.5,0.5);
      }
      DisplayWord(-3,3.2,50,countText,color);
    }
  }
  UnlockChambers(state);
  UpdateColor();
}

function UnlockChambers(state){
  local entToCall = null;
  local sound = 0;
  if(state==3){
    entToCall = "chamber1_";
    if(BERRIES_count_red_collected==BERRIES_count_red)entToCall += "success";
    else entToCall += "failure";
  }
  if(state==5){
    entToCall = "chamber2_";
    if(BERRIES_count_quantum_collected==BERRIES_count_quantum)entToCall += "success";
    else entToCall += "failure";
  }
  if(state==7){
    entToCall = "chamber3_";
    if(BERRIES_count_golden_collected==BERRIES_count_golden)entToCall += "success";
    else entToCall += "failure";
  }
  if(entToCall)EntFire(entToCall, "Trigger");
  else EntFire("computer_count", "PlaySound")
}

//DisplayUnlockProgress(7);
//DisplayTestScreen();
DisplayBerryOSLogo();


