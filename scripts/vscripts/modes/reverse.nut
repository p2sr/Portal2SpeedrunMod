//**********************************************************************************
//                                 Reverse Mod
// I'm not even gonna lie, this is straight up copy-pasted from the original vscript
//**********************************************************************************


if("Entities" in this) {

  printl("\n=== Loading Reverse mod...");
  printl("=== Version: release-1.4, ppmod2");
  printl("=== Made by PortalRunner\n");

  if(!("ppmod" in this)) {
    ::ppmod <- {};
    ppmod.debug <- false;
    ppmod.triggerlist <- {};
  }

  ppmod.fire <- function(ent, action = "Trigger", value = "", delay = 0, activator = null, caller = null) {
    if(typeof ent == "string") EntFire(ent, action, value, delay, activator);
    else EntFireByHandle(ent, action, value.tostring(), delay, activator, caller);
  }

  ppmod.fire_near <- function(classname, action, pos, radius, value = "", delay = 0) {
    local ent = Entities.FindByClassnameNearest(classname, pos, radius);
    ppmod.fire(ent, action, value, delay);
  }

  ppmod.addoutput <- function(ent, output, target, input = "", parameter = "", delay = 0, max = -1) {
    if(typeof target == "instance") {
      if(target == ent) target = "!self";
      else if("GetName" in target) target = target.GetName();
      else target = target.GetClassname();
    }
    ppmod.fire(ent, "AddOutput", output+" "+target+":"+input+":"+parameter+":"+delay+":"+max);
  }

  ppmod.addscript <- function(ent, output, str, delay = 0) {
    ppmod.addoutput(ent, output, "!self", "RunScriptCode", str, delay);
  }

  ppmod.keyval <- function(ent, key, val) {
    if(typeof ent == "string") {
      EntFire(ent, "AddOutput", key + " " + val);
    } else switch (typeof val) {
      case "integer":
      case "bool":
        ent.__KeyValueFromInt(key, val);
        break;
      case "float":
        ent.__KeyValueFromFloat(key, val);
        break;
      case "string":
        ent.__KeyValueFromString(key, val);
        break;
      case "Vector":
        ent.__KeyValueFromVector(key, val);
        break;
      default:
        printl("Invalid keyvalue type for " + ent);
        printl(key + " " + val + " (" + typeof val + ")");
    }
  }

  ppmod.wait <- function(str, sec) {
    local relay = Entities.CreateByClassname("logic_relay");
    ppmod.fire(relay, "RunScriptCode", str, sec);
    ppmod.keyval(relay, "SpawnFlags", 1);
  }

  ppmod.interval <- function(str, sec, name = "") {
    if(Entities.FindByName(null, name)) return;
    local timer = Entities.CreateByClassname("logic_timer");
    ppmod.keyval(timer, "targetname", name);
    ppmod.fire(timer, "RefireTime", sec);
    ppmod.addoutput(timer, "OnTimer", "!self", "RunScriptCode", str);
    ppmod.fire(timer, "Enable");
  }

  ppmod.once <- function(str, name = null) {
    if(name == null) name = str;
    if(Entities.FindByName(null, name)) return;
    local relay = Entities.CreateByClassname("logic_relay");
    ppmod.keyval(relay, "targetname", name);
    EntFire(name, "RunScriptCode", str);
  }

  ppmod.get <- function(key, ent = null, arg = 1) {
    switch (typeof key) {
      case "string":
        if(Entities.FindByName(ent, key)) return Entities.FindByName(ent, key);
        if(Entities.FindByClassname(ent, key)) return Entities.FindByClassname(ent, key);
        return Entities.FindByModel(ent, key);
      case "Vector":
        if(typeof ent != "string") return Entities.FindInSphere(ent, key, arg);
        return Entities.FindByClassnameNearest(ent, key, arg);
      case "integer":
        /*
          Dumb hack:
            P2SM uses sp_transition_list while Reverse is made for loading on mapspawn.nut
            Because Reverse also creates a logic_auto on load, this would usually offset
            entity IDs by one. But because all entities are already loaded when P2SM starts
            it's scripts, I compensate by literally offsetting the ID by one.
        */
        key -= 1;

        while((ent = Entities.Next(ent)).entindex() != key);
        return ent;
      case "instance":
        return Entities.Next(key);
      default: return null;
    }
  }

  if(!("player" in ppmod)) {
    ppmod.player <- {};
    ppmod.player.duck <- false;
    ppmod.player.jump <- false;
    ppmod.player.proxy <- Entities.FindByClassname(null, "logic_playerproxy");
    ppmod.player.listener <- Entities.CreateByClassname("logic_eventlistener");
    if(!ppmod.player.proxy) ppmod.player.proxy = Entities.CreateByClassname("logic_playerproxy");
    ppmod.player.ducked <- function(){ ppmod.player.duck = true }
    ppmod.player.unducked <- function(){ ppmod.player.duck = false }
    ppmod.player.jumped <- function() {
      ppmod.player.jump = true;
      ppmod.player.proxy.DisconnectOutput("OnJump", "ppmod.player.jumped");
    }
    ppmod.player.landed <- function() {
      ppmod.player.jump = false;
      ppmod.player.proxy.ConnectOutput("OnJump", "ppmod.player.jumped");
    }
    ppmod.addoutput(ppmod.player.proxy, "OnDuck", "!self", "RunScriptCode", "ppmod.player.duck = true");
    ppmod.addoutput(ppmod.player.proxy, "OnUnDuck", "!self", "RunScriptCode", "ppmod.player.duck = false");
    ppmod.addoutput(ppmod.player.proxy, "OnJump", "!self", "RunScriptCode", "ppmod.player.jumped()");
    ppmod.addoutput(ppmod.player.proxy, "OnEventFired", "!self", "RunScriptCode", "ppmod.player.landed()");
    ppmod.keyval(ppmod.player.listener, "EventName", "portal_player_touchedground");
    ppmod.fire(ppmod.player.listener, "Enable");
  }

  ppmod.trigger_get <- function(name) {
    try { return ppmod.triggerlist[name] }
    catch(e) return false;
  }
  ppmod.trigger_set <- function(name, val) {
    ppmod.triggerlist.rawset(name, val);
  }
  ppmod.trigger <- function(x1, y1, z1, x2, y2, z2, ent = null, name = null, reuse = false) {
    if(typeof ent == "string") {
      local tmp = name;
      name = ent;
      ent = tmp;
    }
    if(ent == null) ent = GetPlayer();
    if(name == null) name = x1+"_"+y1+"_"+z1+"_"+x2+"_"+y2+"_"+z2;
    try { if(!reuse && ppmod.trigger_get(name)) return false }
    catch(e) {}
    local pos = ent.GetOrigin();
    if(ppmod.debug) {
      if(reuse) DebugDrawBox(Vector(x1, y1, z1), Vector(), Vector(x2-x1, y2-y1, z2-z1), 255, 80, 0, 20, -1);
      else DebugDrawBox(Vector(x1, y1, z1), Vector(), Vector(x2-x1, y2-y1, z2-z1), 255, 165, 0, 20, -1);
    }
    local height = 72;
    if(ent != GetPlayer()) height = 0;
    else if(ppmod.player.duck) height = 36;
    if(pos.x >= x1-16 && pos.x <= x2+16 && pos.y >= y1-16 && pos.y <= y2+16 && pos.z+height >= z1 && pos.z <= z2){
      ppmod.trigger_set(name,true);
      return true;
    }
    return false;
  }
  ppmod.trigger_mp <- function(x1, y1, z1, x2, y2, z2, name = null, reuse = false) {
    if(name == null) name = x1+"_"+y1+"_"+z1+"_"+x2+"_"+y2+"_"+z2;
    try { if(!reuse && ppmod.triggerlist[name]) return false }
    catch(e) {}
    if(ppmod.debug) {
      if(reuse) DebugDrawBox(Vector(x1, y1, z1), Vector(), Vector(x2-x1, y2-y1, z2-z1), 255, 80, 0, 20, -1);
      else DebugDrawBox(Vector(x1, y1, z1), Vector(), Vector(x2-x1, y2-y1, z2-z1), 255, 165, 0, 20, -1);
    }
    local curr = null;
    while(curr = Entities.FindByClassname(curr, "player")) {
      local pos = curr.GetOrigin();
      if(pos.x >= x1-16 && pos.x <= x2+16 && pos.y >= y1-16 && pos.y <= y2+16 && pos.z+72 >= z1 && pos.z <= z2){
        ppmod.trigger_set(name,true);
        return curr;
      }
    }
    return false;
  }
  if(GetDeveloperLevel() == 2) ppmod.debug = true;

  if(!("rev" in this)) {
    ::rev <- {};
    rev.level <- {};
    rev.auto <- Entities.CreateByClassname("logic_auto");
    ppmod.addoutput(rev.auto, "OnMapTransition", "!self", "RunScriptCode", "rev.spawn()");
    ppmod.addoutput(rev.auto, "OnNewGame", "!self", "RunScriptCode", "rev.spawn()");

    rev.spawn <- function() {
      local reverse_maps = {};
      reverse_maps["sp_a1_intro1"] <- function() {
        rev.setup <- function() {
          EntFire("cryo_fade_in_from_white", "Kill");
          EntFire("camera_intro", "Kill");
          EntFire("relay_pre_exit_cryo_sequence", "Kill");
          EntFire("good_morning_vcd", "Kill");
          EntFire("camera_1", "Kill");
          // Sounds
          EntFire("@music_awake", "Kill");
          EntFire("announcer_ding_on_wav", "Kill");
          EntFire("pre_powerloss_soundscape", "Disable");
          EntFire("post_powerloss_soundscape", "Enable");
          EntFire("@music_chamberinside", "PlaySound");
          // Container
          ppmod.keyval("Actor_wall_destruction*", "Targetname", "rev_wall");
          EntFire("rev_wall", "SetAnimation", "anim1");
          EntFire("Actor_container_01", "Kill");
          EntFire("Actor_container_03", "Kill");
          ppmod.keyval("Actor_*", "Targetname", "rev_actor_rename");
          local collision = ppmod.get("container_collision");
          collision.SetOrigin(collision.GetOrigin() + Vector(288, 0, -494));
          collision.SetAngles(-7, 0, 0);
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(-1572, 4371, 3051));
          brush.SetSize(Vector(-54, -102, -4), Vector(54, 102, 4));
          ppmod.keyval(brush, "Solid", 3);
          // Lighting hack
          SendToConsole("mat_ambient_light_r 0.01");
          SendToConsole("mat_ambient_light_g 0.01");
          SendToConsole("mat_ambient_light_b 0.01");

          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(292);
          ppmod.addscript(trigger, "OnStartTouch", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(161).Destroy(); // Exit door close
          EntFire("trigger_boxplacementsuccess", "Kill");
          EntFire("trigger_door_close_rm1", "Kill");
          // Unsolving logic
          local door = "door_1-testchamber_door";
          ppmod.addoutput("button_1-proxy", "OnProxyRelay1", "door_1-door_open_relay", "Trigger");
          ppmod.addoutput("button_1-proxy", "OnProxyRelay2", "door_1-close_door_rl", "Trigger");
          EntFire("door_1-door_physics_clip", "Kill");
          // Level-specific modifications
          EntFire("aud_opening_glass_break", "Kill");
          ppmod.get("glass_break").SetOrigin(GetPlayer().GetOrigin());
          EntFire("drop_box_look_trigger", "Kill");
          EntFire("drop_box_fallback_trigger", "Kill");
          EntFire("drop_box_rl", "Trigger");
          EntFire("relay_start_map", "Kill");
          EntFire("kill_container_rl", "Kill");
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          // Open portals
          local trigger = ppmod.get(146);
          ppmod.addoutput(trigger, "OnStartTouch", "portal_red_0_activate_rl", "Trigger");
          ppmod.addoutput(trigger, "OnStartTouch", "portal_blue_0_activate_rl", "Trigger");
          ppmod.addscript("portal_red_0", "OnPlayerTeleportToMe", "rev.level.fizzleportal()", 0.1);
          ppmod.addscript("portal_red_0", "OnPlayerTeleportToMe", "rev.level.skyportal()", 1);
          // Fadeout button
          SendToConsole("ent_create func_rot_button");
          // Hack for removing fade-in
          SendToConsole("fadein 0");
        }

        rev.load <- function() {
          ppmod.once("rev.level.button()");
          ppmod.once("rev.level.actors()");
          ppmod.once("rev.level.panel()");
        }

        rev.level.actors <- function() {
          EntFire("rev_wall", "SetPlaybackRate", 1000);
          local ent = null;
          while(ent = Entities.FindByName(ent, "rev_actor_rename")) {
            local pos = ent.GetOrigin();
            ent.SetOrigin(pos + Vector(4010, 2457, 2836));
          }
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("box");
          cube.SetOrigin(Vector(-623.75, 4432, 2718));
          cube.SetAngles(0, 224, 0);
          ppmod.fire(cube, "Wake");
          EntFire("@exit_door-door_open_relay", "Trigger");
        }

        rev.level.button <- function() {
          local button = ppmod.get("func_rot_button");
          button.SetOrigin(Vector(-1692, 4325, 3081));
          button.SetSize(Vector(-36, -50, -14), Vector(36, 50, 14));
          ppmod.keyval(button, "SpawnFlags", 1024);
          ppmod.keyval(button, "Solid", 3);
          ppmod.keyval(button, "CollisionGroup", 2);
          ppmod.keyval(button, "Targetname", "rev_sleep_button");
          ppmod.addscript(button, "OnPressed", "rev.level.sleep()");
        }

        rev.level.sleep <- function() {
          EntFire("rev_sleep_button", "Kill");
          EntFire("cryo_fade_out", "Fade");
          local speedmod = Entities.CreateByClassname("player_speedmod");
          ppmod.keyval(speedmod, "SpawnFlags", 28);
          ppmod.fire(speedmod, "ModifySpeed", 0);
          ppmod.wait("rev.level.end()", 5);
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(-1470, 4368, 3384));
          panel.SetAngles(0, 0, 0);
        }

        rev.level.fizzleportal <- function() {
          EntFire("portal_blue_0", "Fizzle");
          rev.level.fizzleportal <- function(){};
        }
        rev.level.skyportal <- function() {
          ppmod.fire(ppmod.get("portal_blue_0_emitter"), "Skin", 0, 0, GetPlayer());
          EntFire("shake_portal_spawn_room1", "StartShake");
          SendToConsole("portal_place 0 0 -1463.969 4368 3384 0 0 0");
          rev.level.skyportal <- function(){};
        }

        rev.level.end <- function() {
          SendToConsole("mat_ambient_light_r 0");
          SendToConsole("mat_ambient_light_g 0");
          SendToConsole("mat_ambient_light_b 0");
          // local msg = "Thanks for playing Reverse mod!";
          SendToConsole("changelevel credits");
        }
      }
      reverse_maps["sp_a1_intro2"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(207);
          ppmod.addscript(trigger, "OnStartTouch", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(30).Destroy(); // Entrance door close
          ppmod.get(185).Destroy(); // Exit door close
          ppmod.get(51).Destroy(); // Orange portal activate
          // Unsolving logic
          local door = "@entry_door-testchamber_door";
          ppmod.addoutput("button_1-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("button_1-proxy", "OnProxyRelay1", door, "Open");
          EntFire("@entry_door-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          EntFire("departure_elevator-blocked_elevator_tube_anim", "Kill");
          EntFire("Fizzle_Trigger", "Kill");
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("ent_create_portal_weighted_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cubes()");
        }

        rev.level.cubes <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(0, 150, 10));
          ppmod.fire(cube, "Skin", 3);
          ppmod.fire(cube, "Wake");
          cube = Entities.Next(cube);
          cube.SetOrigin(Vector(0, 120, 10));
          ppmod.fire(cube, "Skin", 3);
          ppmod.fire(cube, "Wake");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("box");
          cube.SetOrigin(Vector(-607, 281, -20));
          ppmod.fire(cube, "Wake");
          EntFire("prop_portal", "Fizzle");
          EntFire("logic_make_blue_2", "Trigger");
          EntFire("orange_portal_activate_rl", "Trigger");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro1", 1);
        }
      }
      reverse_maps["sp_a1_intro3"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(276);
          ppmod.addoutput(trigger, "OnStartTouch", "door_3-door_open_relay", "Trigger");
          // Remove unnecessary triggers
          ppmod.get(27).Destroy(); // Exit door close
          ppmod.get(30).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("button_2-proxy", "OnProxyRelay1", door, "Close");
          ppmod.addoutput("button_2-proxy", "OnProxyRelay2", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("give weapon_portalgun");
          EntFire("@sphere", "Kill");
          EntFire("departure_elevator-tube*", "Kill");
          EntFire("departure_elevator-blocked_elevator_tube_anim", "Kill");
          EntFire("cheater_noportals", "Kill");
          EntFire("backtrack_brush", "Kill");
          ppmod.addoutput("room_1_portal_activate_rl", "OnTrigger", "portal_orange_mtg", "SetActivatedState", 0);
          ppmod.get(23).Destroy()
          EntFire("fall_splash", "Kill");
          ppmod.addscript(ppmod.get(45), "OnStartTouch", "rev.level.podium()");
          ppmod.addoutput(ppmod.get(103), "OnStartTouch", "door_0-door_open_relay", "Trigger");
          EntFire("door_0-close_door_rl", "Kill");
          // Portalgun logic
          EntFire("portalgun_button", "Lock");
          EntFire("portalgun", "DisableDraw");
          EntFire("timer_gun_particles", "Kill");
          ppmod.addscript("portalgun_button", "OnUseLocked", "rev.level.gun_toggle()");
          // End trigger
          local end = Entities.CreateByClassname("trigger_multiple");
          end.SetOrigin(Vector(185, 576, 1088));
          end.SetSize(Vector(-135, -148, -112), Vector(135, 148, 112));
          ppmod.keyval(end, "Solid", 3);
          ppmod.keyval(end, "CollisionGroup", 1);
          ppmod.keyval(end, "SpawnFlags", 1);
          ppmod.addscript(end, "OnStartTouch", "rev.level.end()");
          ppmod.addoutput(end, "OnEndTouch", "rev_finish_msg", "Kill");
          ppmod.fire(end, "Enable");
          // LP jump helper
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(128, 2198, -290));
          brush.SetSize(Vector(-31, -26, -4), Vector(31, 22, 4));
          ppmod.keyval(brush, "Solid", 3);
          // Hack for pedistal collapse portal
          SendToConsole("r_portalsopenall 1");
        }

        rev.level.gun_toggle <- function() {
          if(ppmod.get("weapon_portalgun")) rev.level.gun_put();
          else rev.level.gun_take();
          EntFire("particle_gun_charge", "Start");
          EntFire("particle_gun_charge", "Stop", "", 0.5);
          EntFire("snd_gun_zap", "PlaySound");
        }

        rev.level.gun_put <- function() {
          EntFire("portalgun", "Enable");
          EntFire("weapon_portalgun", "Kill");
          EntFire("viewmodel", "DisableDraw");
        }

        rev.level.gun_take <- function() {
          EntFire("portalgun", "Disable");
          SendToConsole("give weapon_portalgun");
          EntFire("viewmodel", "EnableDraw");
        }

        rev.level.podium <- function() {
          ppmod.get(125).Destroy();
          EntFire("door_pedistal_removal_lvl2", "Kill");
          EntFire("floor_rubble_drop", "Kill");
          for(local i = 1; i <= 8; i++) {
            EntFire("robot_drop_0"+i, "SetAnimation", "intro3_floorcollapse_0"+i);
            EntFire("robot_drop_0"+i, "SetDefaultAnimation", "intro3_floorcollapse_0"+i+"_idleend");
            EntFire("robot_drop_0"+i, "SetPlaybackRate", 1000, FrameTime());
          }
        }

        rev.level.end <- function() {
          if(ppmod.get("weapon_portalgun")) {
            ppmod.interval("rev.level.solvemsg()", 0, "rev_finish_msg");
          } else EntFire("door_1", "Open");
        }
        rev.level.solvemsg <- function() {
          ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
        }

        rev.level.finish <- function() {
          SendToConsole("r_portalsopenall 0");
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro2", 1);
        }
      }
      reverse_maps["sp_a1_intro4"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local doortrig = ppmod.get(238);
          ppmod.addoutput(doortrig, "OnStartTouch", "door_2-proxy", "OnProxyRelay2");
          ppmod.addoutput(doortrig, "OnStartTouch", "section_2_portal_a2_rm3a", "SetActivatedState", 1);
          // Remove unnecessary triggers
          ppmod.get(16).Destroy(); // Exit door close
          ppmod.get(18).Destroy();
          ppmod.get(77).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("just_enough_door_for_the_job-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("just_enough_door_for_the_job-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          EntFire("door_0-door_physics_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          EntFire("aud_ramp_break_glass", "Kill")
          EntFire("glass_pane_intact_model", "Kill");
          EntFire("glass_pane_fractured_model", "Enable");
          EntFire("glass_shard", "Kill");
          EntFire("glass_pane_1_door_1", "Open");
          EntFire("glass_pane_1_door_1_blocker", "Kill");
          EntFire("room_3_portal_activate_rl", "Kill");
          EntFire("section_2_trigger_portal_spawn_a2_rm3a", "Kill");
          ppmod.addscript(ppmod.get(54), "OnStartTouch", "rev.level.room1()");
          EntFire("section_2_trigger_portal_spawn_a1_rm3a", "Kill");
          ppmod.get(115).Destroy();
          EntFire("trigger_dropbox", "Kill");
          EntFire("looktrigger_dropbox", "Disable");
          EntFire("logic_drop_box", "Trigger");
          ppmod.addscript("just_enough_door_for_the_job-player_in_door_trigger", "OnStartTouch", "rev.level.room2p()");
        }

        rev.level.room1 <- function() {
          local cube = ppmod.get("section_2_box_2");
          cube.SetOrigin(Vector(468, -655, 42));
          ppmod.get("section_2_box_2", cube).SetOrigin(Vector(468, -398, 42));
          EntFire("section_2_box_2", "Wake");
          EntFire("room_3_portal_deactivate_rl", "Trigger");
          EntFire("room_2_portal_activate_rl", "Trigger");
          ppmod.addscript("door_1-close_door_rl", "OnTrigger", "rev.level.room2()");
        }

        rev.level.room2 <- function() {
          local cube = ppmod.get("box_dropper-cube_dropper_box");
          cube.SetOrigin(Vector(-444, 192, 34));
          ppmod.fire(cube, "Wake");
        }

        rev.level.room2p <- function() {
          EntFire("room_2_portal_deactivate_rl", "Trigger");
          EntFire("room_1_portal_activate_rl", "Trigger");
          EntFire("just_enough_door_for_the_job-player_in_door_trigger", "Kill");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro3", 1);
        }
      }
      reverse_maps["sp_a1_intro5"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(286);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(42).Destroy(); // Exit door close
          ppmod.get(30).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("button_2-proxy", "OnProxyRelay1", door, "Close");
          ppmod.addoutput("button_2-proxy", "OnProxyRelay2", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("ent_create_portal_weighted_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cubes()");
        }

        rev.level.cubes <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(64, 452, 300));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
          ppmod.addoutput(ppmod.get(Vector(368, 208, 264)), "OnPressed", "cube", "Dissolve");
          cube = Entities.Next(cube);
          ppmod.keyval(cube, "Targetname", "cube2");
          cube.SetOrigin(Vector(-192, -125, 170));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
          ppmod.addoutput(ppmod.get(Vector(-368, -112, 136)), "OnPressed", "cube2", "Dissolve");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
          cube = Entities.Next(cube);
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
          EntFire("room_1_portal_activate_rl", "Trigger");
          EntFire("room_1_portal_activate_rl", "Kill");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro4", 1);
        }
      }
      reverse_maps["sp_a1_intro6"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(252);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(86).Destroy(); // Exit door close
          ppmod.get(76).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_1-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_1-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("ent_create_portal_weighted_cube");
          EntFire("cube_dropper-cube_dropper_box", "Kill")
          EntFire("room_2_entry_door-proxy", "Kill");
          EntFire("room_2_entry_door-door_player_clip", "Kill");
          EntFire("room_2_entry_door-door_physics_clip", "Kill");
          ppmod.addoutput("button_2-proxy", "OnProxyRelay1", "room_2_entry_door-testchamber_door", "Open");
          ppmod.addoutput("button_2-proxy", "OnProxyRelay2", "room_2_entry_door-testchamber_door", "Close");
          ppmod.addscript("button_2-proxy", "OnProxyRelay1", "rev.level.platform_down()");
          ppmod.addscript("button_2-proxy", "OnProxyRelay2", "rev.level.platform_up()");
          ppmod.get(41).Destroy();
          ppmod.addscript(ppmod.get(88), "OnStartTouch", "rev.level.room2()");
          EntFire("room_1_entry_door-proxy", "Kill");
          EntFire("room_1_entry_door-door_player_clip", "Kill");
          ppmod.addoutput("button_1-proxy", "OnProxyRelay1", "room_1_entry_door-testchamber_door", "Open");
          ppmod.addoutput("button_1-proxy", "OnProxyRelay2", "room_1_entry_door-testchamber_door", "Close");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cubes()");
          ppmod.once("rev.level.platform()");
        }

        rev.level.cubes <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(1919, -450, 174));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
        }

        rev.level.platform <- function() {
          for(local i = 2; i <= 8; i += 2) {
            EntFire("robot_makeramp_0"+i, "SetAnimation", "makeramp_0"+i+"open");
            EntFire("robot_makeramp_0"+i, "AddOutput", "Targetname rev_platform"+i);
          }
        }

        rev.level.platform_up <- function() {
          for(local i = 2; i <= 8; i += 2) {
            EntFire("rev_platform"+i, "SetAnimation", "makeramp_0"+i+"open");
          }
        }
        rev.level.platform_down <- function() {
          for(local i = 2; i <= 8; i += 2) {
            EntFire("rev_platform"+i, "SetAnimation", "makeramp_0"+i+"close");
          }
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
          EntFire("room_2_fling_portal_activate_rl", "Trigger");
          EntFire("room_2_fling_portal_activate_rl", "Kill");
        }

        rev.level.room2 <- function() {
          local cube = ppmod.get(Vector(256, 192, 18), "prop_weighted_cube", 128);
          cube.SetOrigin(Vector(352, -158, 172));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "Wake");
          EntFire("room_2_fling_portal_deactivate_rl", "Trigger");
          EntFire("room_1_fling_portal_activate_rl", "Trigger");
          EntFire("room_1_fling_portal_activate_rl", "Kill");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro5", 1);
        }
      }
      reverse_maps["sp_a1_intro7"] <- function() {
        rev.setup <- function() {
          EntFire("transition_trigger", "Kill");
          EntFire("hobo_turret", "EnableGagging");
          EntFire("@sphere", "Kill");
          EntFire("spherebot*", "Kill");
          EntFire("door_0-door_player_clip", "Kill");
          EntFire("door_0-proxy", "Kill");
          EntFire("room_1_portal_deactivate_rl", "Kill");
          local spawnpos = Vector(-2208, 352, 1216.031);
          GetPlayer().SetOrigin(spawnpos);
          GetPlayer().SetAngles(0, -90, 0);
          ppmod.get(54).SetOrigin(spawnpos);
          ppmod.addoutput(ppmod.get(78), "OnStartTouch", "airlock_door-open_door", "Trigger");
          ppmod.addoutput("dont_leave_trigger", "OnStartTouch", "bts_panel_door-LR_heavydoor_open", "Trigger");
          ppmod.get(123).SetOrigin(Vector(-960, -544, 1296));
          ppmod.get(95).SetOrigin(Vector(-478, -225, 1270));
          local doortrig = ppmod.get(46);
          doortrig.SetOrigin(Vector(320, 0, 1352));
          doortrig.SetAngles(90, 0, 0);
          ppmod.addoutput(doortrig, "OnStartTouch", "door_0-testchamber_door", "Open");
          ppmod.addoutput(doortrig, "OnStartTouch", "arrival_elevator-light_elevator_fill", "TurnOn", 1);
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro6", 1);
        }
      }
      reverse_maps["sp_a1_wakeup"] <- function() {
        rev.setup <- function() {
          EntFire("glados_props_*", "Kill");
          EntFire("glados_cables_*", "Kill");
          EntFire("@sphere", "Kill");
          rev.level.enter();
          local trigger = Entities.CreateByClassname("trigger_multiple");
          trigger.SetOrigin(Vector(6977, 497, 444));
          trigger.SetSize(Vector(-95, -125, -60), Vector(95, 125, 60));
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          ppmod.fire(trigger, "Enable");
          ppmod.addscript(trigger, "OnStartTouch", "rev.level.finish()");
          local doortrig = ppmod.get("hub_catwalk_door_reopen_trigger");
          doortrig.SetOrigin(doortrig.GetOrigin() + Vector(256, 0, 0));
        }

        rev.level.enter <- function() {
          EntFire("aperture_door_brush_collide", "Open");
          EntFire("aperture_door_brush_collide", "Close", "", 1);
          EntFire("model_incinerator_door", "SetAnimation", "open");
          EntFire("model_incinerator_door", "SetDefaultAnimation", "idle");
          ppmod.keyval("model_incinerator_door", "CollisionGroup", 1);
          ppmod.get(100).Destroy(); // Vphys clipbrush
          ppmod.get(74).Destroy(); // Scene trigger
          ppmod.get(36).Destroy(); // Incinerator close trigger
          GetPlayer().SetOrigin(Vector(10376, 1212, 280));
          GetPlayer().SetAngles(0, 180, 0);
          GetPlayer().SetVelocity(Vector(-100, 0, 700));
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_intro7", 1);
        }
      }
      reverse_maps["sp_a2_bridge_intro"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          local trigger = ppmod.get(Vector(0, 816, 96));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(0, 760, 56)).Destroy(); // Exit door close
          ppmod.get(Vector(-728, -552, 80)).Destroy(); // Entrance door close
          local door = "door_52-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_52-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("departure_elevator-elevator_turret_wife", "Kill");
          EntFire("floor_up_relay", "Trigger");
          EntFire("ceiling_panel_repair1-wall_repair", "Trigger");
          SendToConsole("ent_create_portal_weighted_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-478, -348, 82.3));
          ppmod.fire(cube, "Sleep");
          ppmod.addoutput("cube_drop_button", "OnPressed", "cube", "Dissolve");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-479.625, -446.09, 104.2));
          cube.SetAngles(0, -12, 0);
          ppmod.fire(cube, "Wake");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_ricochet", 1);
        }
      }
      reverse_maps["sp_a2_bridge_the_gap"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          local trigger = ppmod.get(Vector(320, 896, 992));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(320, 624, 960)).Destroy(); // Exit door close
          ppmod.get(Vector(-592, -640, 1216)).Destroy(); // Main room lights
          ppmod.get(Vector(-1074, -640, 1224)).Destroy(); // Glitch door sequence
          ppmod.get(Vector(-496, -640, 1216)).Destroy(); // Glitch door close
          ppmod.get(Vector(-1456, -528, 1296)).Destroy(); // Corridor lights
          ppmod.get(Vector(-1456, -416, 1296)).Destroy(); // Corridor arms
          ppmod.get(Vector(-1296, -640, 1280)).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("trick_door_open_relay","trigger");
          SendToConsole("ent_create_portal_weighted_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-128, 564, 915));
          ppmod.fire(cube, "Sleep");
          ppmod.addoutput("prop_button", "OnPressed", "cube", "Dissolve");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-129.4, 449.63, 936.25));
          cube.SetAngles(0, 26, 0);
          ppmod.fire(cube, "Wake");
          EntFire("light_shadowed_02", "TurnOn");
          EntFire("hallway_wall_repair_clip_brush", "Kill");
          for(local i = 1; i <= 3; i++) {
            EntFire("tilex3_wall_repair-robotarm_powerupabot_0"+i, "SetDefaultAnimation", "powerupA_0"+i+"idleend");
          }
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_bridge_intro", 1);
        }
      }
      reverse_maps["sp_a2_bts1"] <- function() {
        rev.setup <- function() {
          EntFire("@sphere","kill");
          EntFire("spherebot_1_bottom_swivel_1","kill");
          EntFire("spherebot_1_top_swivel_1","kill");
          EntFire("spherebot_train_1_chassis_1","kill");
          EntFire("transition_trigger","kill");
          SendToConsole("ent_create prop_tractor_beam");
          SendToConsole("ent_create_portal_weighted_cube");
          GetPlayer().SetOrigin(Vector(1123, -1344, -447.969));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("trigger_once","kill",Vector(857.537,-416.489,32.097),128);
          EntFire("@pre_solved_chamber_solve_rl","kill");
          EntFire("@pre_solved_chamber_start_rl","trigger");
          EntFire("@pre_solved_chamber_start_rl","kill");
          EntFire("pre_solved_chamber-chamber_bridge","disable");
          Entities.FindByName(null,"pre_solved_chamber-chamber_bridge").__KeyValueFromString("targetname","");
          ppmod.fire_near("trigger_once","kill",Vector(857.537,-416.489,32.097),128);
          EntFire("@jailbreak_begin_logic","trigger");
          SendToConsole("ent_fire @jailbreak_exit_trigger enable");
          SendToConsole("ent_fire @jailbreak_exit_trigger starttouch");
          EntFire("jailbreak_chamber_unlit-jailbreak_restart_chamber_logic","trigger");
          EntFire("jailbreak_chamber_unlit-neurotoxin_start_timer","kill");
          EntFire("@jailbreak_1st_wall_1_2_open_logic","trigger");
          EntFire("@jailbreak_1st_wall_2_2_open_logic","trigger");
          EntFire("@jailbreak_1st_wall_close_relay","kill");
          EntFire("jailbreak_chamber_unlit-jailbreak_end_logic","kill");
          ppmod.fire_near("trigger_once","kill",Vector(-2818.040,-1588.390,0.031),128);
          EntFire("jailbreak_chamber_unlit-area_portal_outside_wall","open");
          EntFire("jailbreak_chamber_unlit-area_portal_inside_wall","open");
          ppmod.fire_near("trigger_once","kill",Vector(-3228.916,-1666.767,16.039),128);
          EntFire("chamber_door-door_open_relay","kill");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(815, -925, 172));
          brush.SetSize(Vector(-64, -346, -4), Vector(64, 346, 4));
          ppmod.keyval(brush, "Solid", 3);
          // World portal for ending
          SendToConsole("ent_create linked_portal_door");
          SendToConsole("ent_create linked_portal_door");
          EntFire("chamber_door-testchamber_door", "Open");
          EntFire("chamber_door-door_player_clip", "Kill");
          ppmod.fire_near("trigger_once", "Kill", Vector(-9248, -1952, 64), 32);
        }

        rev.load <- function() {
          ppmod.once("rev.level.funnel()");
          ppmod.once("rev.level.cube()");
          ppmod.once("rev.level.wportal()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(837.891, -1375.97, -447.969, 929.992, -1315.84, -244.472, "b179cb63dc_ppmod")){
            local funnel = ppmod.get("prop_tractor_beam");
            ppmod.fire(funnel, "Enable");
            ppmod.fire(funnel, "EnableDraw");
          }
          /* if(ppmod.trigger(1306.7, -1430.95, -447.969, 1376.45, -1392.84, -312.517, null, null, true)){
            GetPlayer().SetVelocity(GetPlayer().GetVelocity() + Vector(0,-GetPlayer().GetVelocity().y*2,0));
          } */
          if(ppmod.trigger(-3551.77, -2190.4, 0.03125, -3423.19, -2154.62, 143.523, "845e7ab6e7_ppmod")){
            GetPlayer().SetOrigin(Vector(-9247, -2217, 1));
          }
          if(ppmod.trigger(-10095.8, -2468.18, -143.969, -10063.8, -2395.81, -135.969, "fca12f6b3e6_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_triple_laser", 1);
          }
        }

        rev.level.funnel <- function() {
          local funnel = ppmod.get("prop_tractor_beam");
          funnel.SetOrigin(Vector(870, -1344, 350));
          funnel.SetAngles(90, 0, 0);
          ppmod.fire(funnel, "SetLinearForce", -500);
          ppmod.fire(funnel, "Disable");
          ppmod.fire(funnel, "DisableDraw");
          ppmod.fire(funnel, "EnableDraw", "", 0.5);
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(705,-64,-35));
        }

        rev.level.wportal <- function() {
          local p1 = ppmod.get("linked_portal_door");
          local p2 = ppmod.get("linked_portal_door", p1);
          ppmod.keyval(p1, "Targetname", "rev_wportal1");
          ppmod.keyval(p2, "Targetname", "rev_wportal2");
          ppmod.fire(p1, "SetPartner", "rev_wportal2");
          ppmod.fire(p2, "SetPartner", "rev_wportal1");

          p1.SetOrigin(Vector(-3488, -1888, 64));
          p1.SetAngles(0, 90, 0);
          p2.SetOrigin(Vector(-9248, -1888, 64));
          p2.SetAngles(0, -90, 0);

          ppmod.fire(p1, "Open");
          ppmod.fire(p2, "Open");
        }

      }
      reverse_maps["sp_a2_bts2"] <- function() {
        rev.setup <- function() {
          EntFire("@sphere","kill");
          EntFire("spherebot_1_bottom_swivel_1","kill");
          EntFire("spherebot_1_top_swivel_1","kill");
          EntFire("spherebot_train_1_chassis_1","kill");
          ppmod.fire_near("trigger_once","kill",Vector(2207,1879,624),128);
          GetPlayer().SetOrigin(Vector(2208, 1841, 624.031));
          GetPlayer().SetAngles(0, -90, 0);
          EntFire("security_door_1_open","trigger");
          ppmod.fire_near("trigger_once","kill",Vector(-1455.186,-3956.772,-31.969),256);
          ppmod.fire_near("trigger_once","kill",Vector(1308.487,-292.781,240.031),256);
          EntFire("fun_blocker","kill");
          EntFire("door_script","kill");
          EntFire("player_clip","kill");
          EntFire("pillar_collapse_rl", "Kill");
          EntFire("pillar_crumble_rl", "Kill");
          ppmod.addoutput("we_made_it_relay", "OnTrigger", "exit_elevator_open_entrance_relay", "Trigger");
          ppmod.addoutput("exit_elevator_open_entrance_relay", "OnTrigger", "!self", "Kill");
          EntFire("exit_elevator_clip_brush", "Kill");
          ppmod.get(132).Destroy();
          ppmod.get(162).Destroy();
          EntFire("turret_attack_3_start_rl", "Trigger");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(2027, -2944, -9));
          brush.SetSize(Vector(-211, -40, -4), Vector(211, 40, 4));
          ppmod.keyval(brush, "Solid", 3);
          EntFire("fun_saver", "Kill");
          brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(1984, -2886, 27));
          brush.SetSize(Vector(-86, -16, -11), Vector(86, 16, 11));
          ppmod.keyval(brush, "Solid", 3);
          ppmod.get(150).Destroy();
        }

        rev.loop <- function() {
          if(ppmod.trigger(728.031, -3914.14, 0.03125, 810.455, -3735.83, 190.218, "531f252fa8_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_bts1", 1);
          }
        }
      }
      reverse_maps["sp_a2_bts3"] <- function() {
        rev.setup <- function() {
          SendToConsole("prop_dynamic_create props/de_train/ladderaluminium.mdl");
          SendToConsole("prop_dynamic_create props/faith_plate.mdl");
          SendToConsole("prop_dynamic_create props_bts/hanging_walkway_512a.mdl");
          SendToConsole("prop_dynamic_create props_bts/hanging_walkway_32b.mdl");
          SendToConsole("prop_dynamic_create props_bts/hanging_walkway_32b.mdl");
          ppmod.fire_near("trigger_once","kill",Vector(5954,4628,-1754),128);
          GetPlayer().SetOrigin(Vector(5952, 4685, -1791.969));
          GetPlayer().SetAngles(0, 90, 0);
          SendToConsole("mat_ambient_light_r 0.01");
          SendToConsole("mat_ambient_light_g 0.01");
          SendToConsole("mat_ambient_light_b 0.01");
          EntFire("exit_airlock_door-proxy","kill");
          EntFire("exit_airlock_door-open_door","trigger");
          EntFire("@sphere","kill");
          EntFire("spherebot_1_bottom_swivel_1","kill");
          EntFire("spherebot_1_top_swivel_1","kill");
          EntFire("spherebot_train_1_chassis_1","kill");
          EntFire("func_noportal_volume","kill");
          EntFire("func_areaportal","open");
          EntFire("spirarooml_areaportal","SetFadeStartDistance",450);
          EntFire("spirarooml_areaportal","SetFadeEndDistance",650);
          EntFire("tuberoom_areaportal","SetFadeStartDistance",450);
          EntFire("tuberoom_areaportal","SetFadeEndDistance",550);
          EntFire("func_areaportalwindow","open");
          EntFire("tube_scanner_room-shutdown_tube_objects","kill");
          EntFire("end_item_tubes-start_tube_items","trigger");
          EntFire("entry_canyon_clip","kill");
          EntFire("entry_canyon_powering_off_relay","kill");
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          SendToConsole("prop_dynamic_create props_factory/turret_factory_closed.mdl");
          SendToConsole("prop_dynamic_create props_factory/turret_factory_closed.mdl");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(9344, 5381, -229));
          brush.SetSize(Vector(-64, -16, -27), Vector(64, 16, 27));
          ppmod.keyval(brush, "Solid", 3);
          ppmod.keyval(brush, "CollisionGroup", 2);
        }

        rev.load <- function() {
          ppmod.once("rev.level.props()");
          ppmod.once("rev.level.panel()");
          ppmod.once("rev.level.crate()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(4160.03, 754.885, 128.031, 4288, 1069.27, 136.031, "a3822fd2e6cb_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_bts2", 1);
            SendToConsole("mat_ambient_light_r 0");
            SendToConsole("mat_ambient_light_g 0");
            SendToConsole("mat_ambient_light_b 0");
          }
          if(ppmod.trigger(9136.03, 5407.87, -383.969, 9411.51, 5655.97, -131.501, "1c31cee6fac1_ppmod")){
            EntFire("tube_scanner_room-start_tube_objects", "trigger");
            EntFire("tube_scanner_room-start_tube_objects", "kill");
            ppmod.addscript("weapon_portalgun", "OnFiredPortal1", "SendToConsole(\"ent_create info_null;script rev.level.shoot(0)\")");
            ppmod.addscript("weapon_portalgun", "OnFiredPortal2", "SendToConsole(\"ent_create info_null;script rev.level.shoot(1)\")");
          }
          if(ppmod.trigger(9135.18, 3520.99, -455.938, 9167.77, 3552.99, -422.193, null, null, true)){
            GetPlayer().SetVelocity(Vector(0,0,310));
          }
          if(ppmod.trigger(9136.72, 3484.73, -313.575, 9169.01, 3516.73, -296.702, null, null, true)){
            local vel = GetPlayer().GetVelocity();
            GetPlayer().SetVelocity(vel + Vector(0,0,14));
          }
          if(ppmod.trigger(9088.03, 3718.81, -479.969, 9216.06, 3871.97, -306.059, "6c1201325ec3_ppmod")){
            EntFire("start_phys_train_relay","trigger");
            EntFire("laser_cutter_room_kill_relay","disable");
            rev.level.shoot <- function(id){};
            ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl").Destroy();
          }
          ppmod.trigger(7566.48, 2942.66, -255.969, 7680.1, 3071.99, 275.128, "c2520606e6c3_ppmod")
          if(ppmod.trigger_get("c2520606e6c3_ppmod")) rev.level.moveplate();
        }

        rev.level.moveplate <- function(){
          local plate = Entities.FindByModel(null,"models/props/faith_plate.mdl");
          local pos = plate.GetOrigin();
          if((GetPlayer().GetOrigin() - pos).Length() < 32) GetPlayer().SetVelocity(Vector(0,0,1000));
          if(pos.x < 10200) plate.SetOrigin(pos+Vector(2,0,0));
          else plate.SetOrigin(Vector(6322,3006,-255));
        }

        rev.level.props <- function() {
          local ladder = Entities.FindByModel(null,"models/props/de_train/ladderaluminium.mdl");
          ladder.SetOrigin(Vector(9153,3528,-398));
          ladder.SetAngles(10,-90,0);
          local plate = Entities.FindByModel(null,"models/props/faith_plate.mdl");
          plate.SetOrigin(Vector(6322,3006,-255));
          plate.SetAngles(0,0,0);
          local walk = Entities.FindByModel(null,"models/props_bts/hanging_walkway_512a.mdl");
          walk.SetOrigin(Vector(7232,2350,202));
          walk.SetAngles(0,0,0);
          local walk_end = Entities.FindByModel(null,"models/props_bts/hanging_walkway_32b.mdl");
          walk_end.SetOrigin(Vector(7232 2813 202));
          walk_end.SetAngles(0,180,0);
          walk_end = Entities.FindByModel(walk_end,"models/props_bts/hanging_walkway_32b.mdl");
          walk_end.SetOrigin(Vector(7232,2270,202));
          walk_end.SetAngles(0,0,0);
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(8832, 5072, -128));
          panel.SetAngles(0, 180, 0);
        }

        rev.level.shoot <- function(id) {
          local point = ppmod.get("info_null").GetOrigin();
          if(point.x == 8838.03125 && point.y > 5008.03125 && point.y < 5135.96875) {
            if(ppmod.get(Vector(8838.031, 5072, -128), "prop_portal", 8)) return;
            SendToConsole("portal_place 0 " + id + " 8838.031 5072 -128 0 0 0");
            SendToConsole("r_drawparticles 0");
            ppmod.wait("SendToConsole(\"r_drawparticles 1\")", 1);
          }
        }

        rev.level.crate <- function() {
          local crate = ppmod.get("models/props_factory/turret_factory_closed.mdl");
          crate.SetOrigin(Vector(7101, 2108, 76));
          crate.SetAngles(0, 0, 0);
          crate = Entities.Next(crate);
          crate.SetOrigin(Vector(7340, 4954, -519));
          crate.SetAngles(7, 180, 0);
        }
      }
      reverse_maps["sp_a2_bts4"] <- function() {
        rev.setup <- function() {
          ppmod.fire_near("trigger_once","kill",Vector(-4042.449,-7232.374,6272.031), 128);
          GetPlayer().SetOrigin(Vector(-3984, -7230, 6272.031));
          GetPlayer().SetAngles(0, 0, 0);
          SendToConsole("player_held_object_use_view_model 1");
          EntFire("exit_airlock_door-open_door","trigger");
          EntFire("exit_airlock_door-open_door","kill");
          EntFire("exit_airlock_door-proxy","kill");
          EntFire("@sphere","kill");
          EntFire("spherebot_train_1_chassis_1","kill");
          EntFire("science_fair_blocking_doors","enable");
          EntFire("blocking_doors","turnon");
          Entities.FindByName(null,"initial_template_turret").SetModel("models/npcs/turret/turret_skeleton.mdl");
          EntFire("start_turret_sequence","trigger");
          EntFire("@disable_turret_conveyor","kill");
          TurretVoManager.productionSwitched <- true;
          rev.level.switched <- false;
          TurretVoManager.grabbedTurretTalked <- -999999;
          EntFire("scanner_screen_script", "runscriptcode", "master_scanner_turret_type=0");
          for(i <- 1; i <= 7; i++){
            TurretVoManager.vcds["sp_sabotage_factory_defect_laugh0"+i] <- {handle=CreateSceneEntity(""),secs=0,group="defect_laugh"}
          }
          EntFire("control_room_blocking_doors","kill");
          EntFire("dummy_shoot_entry_door","setanimation","close");
          ppmod.fire_near("trigger_once","kill",Vector(2571,-4914,6702),256);
          ppmod.fire_near("trigger_once","kill",Vector(3251,-4792,6821),256);
          EntFire("turret_control_entry_door_glass_sound","kill");
          EntFire("turret_control_glass_break_rl","trigger");
          EntFire("gib_conveyor_shutdown_relay","kill");
          if(ppmod.get("replacement_template_turret")) ppmod.wait("rev.level.modelfix()", 0.1);
          rev.level.setplate();
        }

        rev.loop <- function() {
          if(ppmod.trigger(736.031, -3052.98, 7168.03, 863.986, -2739.07, 7176.03, "47d6867019e_ppmod")){
            SendToConsole("player_held_object_use_view_model -1");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_bts3", 1);
          }
          if(ppmod.trigger(-623.815, -7266.07, 6656.03, -495.397, -7200.01, 6778.12, "7825ae7f617f_ppmod")){
            local door1 = ppmod.get("science_fair_blocking_doors");
            local door2 = ppmod.get("science_fair_blocking_doors", door1);
            local pos1 = door1.GetOrigin();
            local pos2 = door2.GetOrigin();
            for(local i = 1; i < 25; i++){
              ppmod.fire(door1, "SetLocalOrigin", pos1.x+" "+(pos1.y-i*1.5)+" "+pos1.z, FrameTime()*i);
              ppmod.fire(door2, "SetLocalOrigin", pos2.x+" "+(pos2.y+i*1.5)+" "+pos2.z, FrameTime()*i);
            }
          }
          local turret = ppmod.get("replacement_template_turret");
          if(!rev.level.switched && turret && ppmod.trigger(1425.33, -7094.41, 6639.16, 1459.14, -7062.4, 6743.02, turret, null, true)){
            ppmod.wait("rev.level.unswitch()", FrameTime());
            turret.SetModel("models/npcs/turret/turret.mdl");
            ppmod.fire(turret, "Skin", 0);
            rev.level.switched = true;
          }
          if(ppmod.trigger(688.031, -7615.29, 6656.03, 971.634, -7464.03, 6793.65, "2d82720b180_ppmod")){
            EntFire("exit_turret_room_door-open_door","trigger");
            EntFire("exit_turret_room_door-open_door","kill");
          }
          if(rev.level.switched && ppmod.trigger(2153, -5514.91, 6656.03, 2231.01, -5265, 6776.56, "f1d1007c4e1ac_ppmod")){
            local door1 = ppmod.get("blocking_doors");
            local door2 = ppmod.get("blocking_doors", door1);
            local pos1 = door1.GetOrigin();
            local pos2 = door2.GetOrigin();
            for(local i = 1; i < 25; i++){
              ppmod.fire(door1, "SetLocalOrigin", (pos1.x-i*1.5)+" "+pos1.y+" "+pos1.z, FrameTime()*i);
              ppmod.fire(door2, "SetLocalOrigin", (pos2.x+i*1.5)+" "+pos2.y+" "+pos2.z, FrameTime()*i);
            }
            EntFire("proxy","onproxyrelay1");
            EntFire("dummyshoot_conveyor_1_spawn_rl","trigger");
          }
          if(!rev.level.switched && ppmod.trigger(2153.03, -5352.61, 6656.03, 2230.93, -5265.54, 6807.39, null, null, true)){
            ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
          }
          if(ppmod.trigger(2833.77, -4973.43, 6656.03, 2949.97, -4864.03, 6851.47, "22103481c196_ppmod")){
            EntFire("dummy_shoot_entry_door","setanimation","open");
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(2960, -4944.43, 6656.03),256);
          }
          rev.level.plate();
        }

        rev.level.setplate <- function() {
          SendToConsole("prop_dynamic_create props/faith_plate.mdl");
          local timer = Entities.CreateByClassname("logic_timer");
          while(!timer.ValidateScriptScope());
          local scope = timer.GetScriptScope();
          scope.check <- function() {
            local plate = ppmod.get("models/props/faith_plate.mdl");
            if(plate) {
              plate.SetOrigin(Vector(2173, -4288, 6630));
              plate.SetAngles(0, 0, 0);
              self.Destroy();
            }
          }
          ppmod.addscript(timer, "OnTimer", "check()");
          ppmod.fire(timer, "Enable");
        }
        rev.level.plate <- function() {
          local pos = Vector(2173, -4288, 6630);
          if((GetPlayer().GetOrigin() - pos).Length() < 32) GetPlayer().SetVelocity(Vector(0,0,1000));
        }

        rev.level.unswitch <- function() {
          TurretVoManager.productionSwitched <- false;
          TurretVoManager.productionStalled <- false;
          EntFire("turret_conveyor_1_production_switch","toggle");
          EntFire("scanner_screen_script", "runscriptcode", "master_scanner_turret_type=1");
        }
        rev.level.modelfix <- function() {
          local turret = ppmod.get("replacement_template_turret");
          if(rev.level.switched) turret.SetModel("models/npcs/turret/turret.mdl");
          else turret.SetModel("models/npcs/turret/turret_skeleton.mdl");
        }

      }
      reverse_maps["sp_a2_bts5"] <- function() {
        rev.setup <- function() {
          GetPlayer().SetOrigin(Vector(1390, 515, 4490));
          GetPlayer().SetAngles(0, 0, 0);
          SendToConsole("fadein 1");
          EntFire("exit_tube_1_exit_trigger","kill");
          for(i <- 1; i <= 8; i++){
            EntFire("intact_pipe_"+i,"kill");
            EntFire("cut_pipe_"+i,"setanimation","toxinpipe"+i+"_collapse", 1.1);
            EntFire("cut_pipe_"+i,"setplaybackrate",100,1.1);
            EntFire("cut_pipe_"+i,"enabledraw","",1.1);
          }
          for(i <- 1; i <= 7; i++){
            EntFire("toxinbeam"+i, "kill");
            EntFire("full_tubes_a"+i, "kill");
            EntFire("full_tubes_b"+i, "kill");
            EntFire("full_tubes_c"+i, "kill");
            EntFire("full_tubes_d"+i, "kill");
            EntFire("full_tubes_e"+i, "kill");
          }
          EntFire("func_breakable","kill");
          EntFire("toxin_tank_a", "kill");
          EntFire("toxin_tank_b", "kill");
          EntFire("toxin_tank_d", "kill");
          EntFire("toxin_tank_bot_a", "kill");
          EntFire("toxin_tank_bot_b", "kill");
          EntFire("toxin_tank_bot_d", "kill");
          EntFire("tank_bottom_phys_box", "kill");
          EntFire("ceiling_collapse_model", "kill");
          EntFire("@sphere", "kill");
          EntFire("spherebot_1_top_swivel_1", "kill");
          EntFire("spherebot_1_bottom_swivel_1", "kill");
          EntFire("spherebot_train_1_chassis_1","kill");
          EntFire("control_room_door", "kill");
          EntFire("control_room_door_clip", "kill");

          EntFire("security_door_areaportal","open");
          EntFire("panel_2_maker","kill");
          EntFire("side_1_panelpath_1-panel_1*","fireuser4");
          EntFire("side_1_panelpath_2-panel_1*","fireuser4");
          EntFire("side_1_panelpath_1-track_*","disable");
          EntFire("side_1_panelpath_2-track_*","disable");
          EntFire("@laser_blocker","kill");
          EntFire("@laser_blocker_front","kill");
          EntFire("spark_front","kill");
          EntFire("spark_back","kill");
          EntFire("side_1_panelpath_1-panel_1*","kill");
          EntFire("side_1_panelpath_2-panel_1*","kill");

          EntFire("button_push_button_knob","open");
          EntFire("button_power_green","togglesprite");
          EntFire("button_power_red_elevator","togglesprite");
          EntFire("button_stand","skin","0");
          EntFire("button_pressed_rl","lock");
          EntFire("button_relay","disable");
          EntFire("button","lock");
          rev.level.solve <- 0;
          local button = ppmod.get("button");
          ppmod.addscript(button, "OnUseLocked", "rev.level.unpress()");

          EntFire("lift_blocker","kill");
          EntFire("lift","open");
          EntFire("lift","setspeed",5000);
          ppmod.fire_near("trigger_once","kill",Vector(2945,945,3625), 128);

          EntFire("shredder_left","start");
          EntFire("shredder_right","startbackward");
        }

        rev.loop <- function() {
          if(ppmod.trigger(3651.07, -1789.76, 3392.03, 3899.96, -1664.03, 3548.6, null, null, true)){
            if(rev.level.solve == 1) {
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a2_bts4", 1);
              SendToConsole("sv_allow_mobile_portals 0");
              rev.level.solve = -1;
            } else if(rev.level.solve != -1) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
          if(ppmod.trigger(1320.01, 456.086, 4456.03, 2062.06, 567.969, 4565.42, null, null, true)){
            GetPlayer().SetVelocity(Vector(600, 0, 0));
          }
          if(ppmod.trigger(2494.51, 593.337, 4352.03, 2623.99, 749.021, 4525.92, "12c1deb49bd_ppmod")){
            EntFire("security_door-open_door","trigger");
          }
          if(ppmod.trigger(2887.28, 896.531, 4354.03, 2988.47, 992.469, 4396.49, "a5a32b1a7bb_ppmod")){
            EntFire("lift","setspeed",200);
            EntFire("lift","close");
            EntFire("controlroom_gate_a_rotating","close");
            EntFire("controlroom_gate_b_rotating","close");
          }
          if(ppmod.trigger(2887.28, 896.531, 3616.03, 2988.47, 992.469, 3624.03, "18636a5b6c0_ppmod")){
            EntFire("controlroom_gate_a_rotating","open");
            EntFire("controlroom_gate_b_rotating","open");
          }
          if(ppmod.trigger(2050.6, 645.071, 3648.03, 2175.97, 767.969, 3783, "33637e327c7_ppmod")){
            EntFire("airlock_door_01-proxy","kill");
            EntFire("airlock_door_02-proxy","kill");
            EntFire("airlock_door_01_areaportal","open");
            EntFire("airlock_door_02-open_door","trigger");
          }
          if(ppmod.trigger(2049.89, 340.362, 3648.03, 2176, 505.357, 3762.37, "fdd3bcd74d1_ppmod")){
            EntFire("airlock_door_01-open_door","trigger");
          }
        }

        rev.level.unpress <- function() {
          EntFire("button_push_button_knob","close");
          EntFire("button_power_green","togglesprite");
          EntFire("button_power_red_elevator","togglesprite");
          EntFire("button_stand","skin",1);
          EntFire("env_portal_laser","turnoff");
          EntFire("button","kill");
          rev.level.solve = 1;
        }
      }
      reverse_maps["sp_a2_bts6"] <- function() {
        rev.setup <- function() {
          GetPlayer().SetOrigin(Vector(-3544.5, 575.8, 433));
          GetPlayer().SetAngles(0, 180, 0);
          SendToConsole("+jump");
          if(GetDeveloperLevel() == 3) SendToConsole("developer 0");
          ppmod.wait("SendToConsole(\"-jump\")", FrameTime());
          EntFire("weaponstrip","strip");
          SendToConsole("wait 30 fadein 0.5");
          EntFire("tube_ride_start_relay","kill");
          EntFire("ending_relay","kill");
          EntFire("@sphere","kill");
          for(i <- 0; i <= 10; i++) EntFire("tube_main_prop_"+i,"kill");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-6753.03, 469.145, 364.608, -1778.38, 675.163, 550.674, null, null, true)){
            GetPlayer().SetVelocity(Vector(-600,0,10));
            pos <- GetPlayer().GetOrigin();
            if(pos.y < 550) GetPlayer().SetOrigin(Vector(pos.x,550,pos.z));
            if(pos.y > 595) GetPlayer().SetOrigin(Vector(pos.x,595,pos.z));
          }
          if(ppmod.trigger(-6916.54, 486.316, 350.061, -6756.76, 704.026, 563.881, "71d84ee0e93_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_bts5", 1);
          }
        }
      }
      reverse_maps["sp_a2_catapult_intro"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(Vector(-64, -1616, -352));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(334).Destroy(); // Exit door close
          EntFire("door_close_relay", "Kill"); // Entrance door close
          EntFire("wall_replace_relay", "Kill");
          // Unsolving logic
          local door = "door_1-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_1-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("ent_create_portal_weighted_cube");
          ppmod.addoutput("prop_button", "OnPressed", "cube", "Dissolve");
          local lastpanel = ppmod.get("wall_replace_4-wallPanel_128_d");
          ppmod.keyval(lastpanel, "Targetname", "rev_panel_rename");
          ppmod.fire(lastpanel, "SetAnimation", "anim6");
          for(local i = 1; i <= 4; i++) {
            EntFire("wall_repair_"+i+"_relay", "Trigger");
            EntFire("wall_replace_"+i+"-wallpanel*", "Kill");
          }
          EntFire("splash*", "Kill");
          EntFire("aud_catapult_jump_safety_block", "Kill");
          EntFire("catapult_target_relay", "Trigger");
          EntFire("aud_hallway*", "Kill");
          EntFire("hallway_sim_go", "Trigger");
          EntFire("hallway_sim_go", "Kill");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-192, -1372, -405));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
          EntFire("light_shadowed_02", "TurnOn");
          EntFire("aud_VFX.LightFlicker*", "Kill");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_over_goo", 1);
        }
      }
      reverse_maps["sp_a2_column_blocker"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_arrive","kill");
          EntFire("departure_elevator-logic_source_elevator_door_open","kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("departure_elevator-vacturret*", "kill");
          local trigger = ppmod.get(Vector(-1056, 256, 40.250));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(-992, 256, 96)).Destroy(); // Exit door close
          ppmod.get(Vector(-64, -1072, 304)).Destroy(); // Entrance door close
          ppmod.get(Vector(-76, -1040, 311.5)).Destroy(); // Surprise trigger
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-door_open_relay", "OnTrigger", door, "Close");
          ppmod.addoutput("@exit_door-door_close_relay", "OnTrigger", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("env_portal_laser", "TurnOff");
          EntFire("npc_portal_turret_floor", "Kill");
          SendToConsole("ent_create_portal_reflector_cube");
          SendToConsole("ent_create_portal_reflector_cube");
          ppmod.addoutput("prop_button", "OnPressed", "cube", "Dissolve");
          EntFire("light_shadowed_01", "TurnOn");
          ppmod.keyval("officedoor_1", "Targetname", "officedoor_rev");
          local doortrig = ppmod.get(Vector(-88, -696, 310));
          ppmod.addoutput(doortrig, "OnTrigger", "officedoor_rev", "SetAnimation", "Open");
          EntFire("surprise_room_fill_light", "TurnOn");
        }

        rev.load <- function() {
          EntFire("InstanceAuto87-fizzler_models", "EnableDraw");
          EntFire("@exit_elevator_cleanser", "Enable");
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-638.9, -446.7, 18.5));
          cube.SetAngles(0, 44.9, 0);
          ppmod.fire(cube, "Sleep");
          cube = ppmod.get("cube", cube);
          cube.SetOrigin(Vector(437.6, 623.4, 18.5));
          cube.SetAngles(0, 180, 0);
          ppmod.fire(cube, "Sleep");
        }

        rev.level.enter <- function() {
          EntFire("env_portal_laser", "TurnOn");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_pull_the_rug", 1);
        }
      }
      reverse_maps["sp_a2_core"] <- function() {
        rev.setup <- function() {
          GetPlayer().SetOrigin(Vector(0, 305, -440));
          GetPlayer().SetVelocity(Vector(0,0,1000));
          SendToConsole("fog_override 1");
          SendToConsole("fog_end 4000");
          EntFire("@environment_darkness_fog", "Kill");
          EntFire("!player", "SetFogController", "@environment_glados");

          EntFire("glados_chamber_body", "kill");
          EntFire("exit_elevator_train", "kill");
          EntFire("escape_elevator_clip", "kill");
          EntFire("iris_door_elevator_pit", "setspeed",100);
          EntFire("iris_door_elevator_pit", "open");
          EntFire("iris_door_elevator_pit", "close", "",1);
          EntFire("relaxation_vault_train", "startforward");
          EntFire("relaxation_vault_train", "setmaxspeed", 99999);
          EntFire("relaxation_vault_train", "setspeed", 99999);
          EntFire("entry_doors_close", "disable");
          EntFire("close_globe", "disable");
          EntFire("close_globe", "disable");
          EntFire("close_rv_gantry_entry_doors_rl", "disable");
          EntFire("open_globe", "trigger");
          EntFire("core_double_arms", "setplaybackrate",50,0.2);
          EntFire("core_double_arms_left", "setplaybackrate",50,0.2);
          EntFire("core_double_arms_right", "setplaybackrate",50,0.2);
          EntFire("rv_gantry_entry_doors", "open");
          EntFire("rv_gantry_entry_doors", "setspeed",500);
          EntFire("break_front_glass", "trigger");
          EntFire("break_left_glass", "trigger");
          EntFire("break_right_glass", "trigger");
          EntFire("front_glass_crack_sound", "kill");
          EntFire("left_glass_crack_sound", "kill");
          EntFire("right_glass_crack_sound", "kill");
          EntFire("upper_left_glass_break_sound", "kill");
          EntFire("crack_front_glass", "trigger");
          EntFire("crack_left_glass", "trigger");
          EntFire("crack_right_glass", "trigger");
          EntFire("crack_upper_left_glass", "trigger");
          EntFire("entry_doors_open", "trigger");
          for(i <- 1; i <= 4; i++) {
            EntFire("core_door_arm_0"+i, "setanimation", "open");
            EntFire("core_door_arm_0"+i, "setplaybackrate",50,0.2);
          }
          EntFire("rv_player_clip", "kill");
          EntFire("rv_trap_floor_areaportal", "open");
          EntFire("rvhallway_areaportal", "open");
          EntFire("rv_trap_floor_down_door_2", "kill");
          EntFire("rv_trap_floor_down_door_1", "kill");
          EntFire("rv_trap_doors_closed_counter", "kill");
          EntFire("smallwall", "setdefaultanimation", "anim_idleend");
          EntFire("smallwall_front", "setdefaultanimation", "anim_idleend");
          EntFire("rv_trap_right_wall", "setlocalorigin", "-1736 0 417");
          EntFire("robo_pushdoor", "setdefaultanimation", "arm_64x64_moveforward_08_idleend");
          for(i <- 1; i <= 9; i++) EntFire("robopeek_0"+i, "setdefaultanimation", "arm_64x64_moveforward_0"+i+"_idleend");
          EntFire("robopeek_04", "setdefaultanimation", "armwalkies_128_idleend");
          EntFire("robopeek_06", "setdefaultanimation", "armwalkies_128_idleend");
          EntFire("bigwallA_mover", "setdefaultanimation", "anim_idleend");
          for(i <- 1; i <= 11; i++) EntFire("roboA_walkout_"+floor(i/10).tostring()+(i%10).tostring(), "setdefaultanimation", "trap_walk_02_idleend");
          for(i <- 1; i <= 4; i++) EntFire("roboA_peekyman_0"+i, "setdefaultanimation", "trap_peekyman_02_idleend");
          EntFire("bigwall_mover", "setdefaultanimation", "anim_idleend");
          for(i <- 1; i <= 11; i++) EntFire("robo_walkout_"+floor(i/10).tostring()+(i%10).tostring(), "setdefaultanimation", "trap_walk_02_idleend");
          for(i <- 1; i <= 4; i++) EntFire("robo_peekyman_0"+i, "setdefaultanimation", "trap_peekyman_02_idleend");
          EntFire("rv_trap_fake_door", "kill");
          EntFire("light_dynamic_trap", "kill");
          for(i <- 1; i <= 5; i++) EntFire("turret_0"+i+"-chamber_npc_turret", "kill");
          EntFire("@sphere", "kill");
          ppmod.get(166).Destroy(); // Placement helper

          tubesuck <- Entities.CreateByClassname("point_push");
          tubesuck.__KeyValueFromString("targetname", "tube_suck");
          tubesuck.__KeyValueFromFloat("radius",64);
          tubesuck.__KeyValueFromInt("spawnflags",14);
          tubesuck.__KeyValueFromFloat("Magnitude",10000);
          tubesuck.SetOrigin(Vector(158, 3087, -245));
          tubesuck.SetAngles(-90,0,0);
          EntFire("tube_suck", "Enable");
          if(ppmod.debug) SendToConsole("ent_bbox tube_suck");
        }

        rev.loop <- function() {
          if(ppmod.trigger(80.5266, 3021.43, -174.43, 236.063, 3152.83, -39.4961, "37b761679129_ppmod")){
            SendToConsole("fadeout 1");
            ppmod.wait("SendToConsole(\"fog_override 0\")", 0.8);
            if(GetDeveloperLevel() == 0){
              ppmod.wait("SendToConsole(\"developer 3\")", 0.8);
              ppmod.wait("SendToConsole(\"clear\")", 0.8);
            }
            EntFire("@command", "Command", "changelevel sp_a2_bts6", 1);
          }
        }
      }
      reverse_maps["sp_a2_dual_lasers"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(301);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(119).Destroy(); // Exit door close
          ppmod.get(32).Destroy(); // Entrance door close
          ppmod.get(37).Destroy(); // Entrance panel trigger
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("door_1-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("door_1-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          EntFire("@sphere", "Kill");
          EntFire("platform_door", "Close");
          EntFire("ceiling_door_1", "Close");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("prop_weighted_cube");
          cube.SetOrigin(Vector(125, 33, 1050));
          cube.SetAngles(0, -90, 0);
          ppmod.fire(cube, "Sleep");
          EntFire("light_shadowed_02", "TurnOn");
          EntFire("aud_VFX.LightFlicker*", "Kill");
          EntFire("aud_9arm_linear", "Kill");

          EntFire("laser_01", "TurnOn");
          EntFire("laser_02", "TurnOn");
          EntFire("light_laser_01", "TurnOn");
          EntFire("light_laser_02", "TurnOn");

          for(local i = 1; i <= 4; i++) {
            EntFire("wall_tiles_"+i+"-robot2panelswt", "Kill");
            EntFire("wall_tiles_"+i+"-proxy", "OnProxyRelay1");
            EntFire("wall_tiles_"+i+"-robo*", "SetPlaybackRate", 1000, FrameTime());
          }
          EntFire("platform_tiles-panel_repair_64x64_6", "Trigger");
          EntFire("platform_tiles-robotarm_powerupA_0*", "SetPlaybackRate", 1000, FrameTime());
          EntFire("192_9arm_raise_platform-raise_platform", "Trigger");
          EntFire("192_9arm_raise_platform-*", "SetPlaybackRate", 1000, FrameTime());

          EntFire("center_platform_clip_brush", "Kill");
          EntFire("center_platform_clip_door", "Open");
          EntFire("wall_tile_2_clip_brush", "Kill");
          EntFire("large_arm_collision", "Kill");

          EntFire("@exit_elevator_cleanser", "Disable");
          SendToConsole("portal_place 0 0 -32 -287.969 1216 0 90 0");
          SendToConsole("portal_place 0 1 -224 224 1088.031 -90 0 0");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_stairs", 1);
        }
      }
      reverse_maps["sp_a2_fizzler_intro"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          local trigger = ppmod.get("departure_elevator-blocked_elevator_tube_anim");
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(872, -64, -8)).Destroy(); // Exit door close
          ppmod.get(Vector(-96, -128, 0)).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("ramp_up_relay", "Trigger");
          EntFire("tilex2_wall_repair_clip", "Kill");
          EntFire("tilex3_wall_repair_anim_rl", "Trigger");
          EntFire("floor_panel_1-proxy", "OnProxyRelay1");
          EntFire("floor_panel_1_a-proxy", "OnProxyRelay1");
          EntFire("floor_panel_1-repair_floor", "OnProxyRelay1");
          EntFire("tilex2*", "SetPlaybackRate", 1000, FrameTime());
          EntFire("tilex3*", "SetPlaybackRate", 1000, FrameTime());
          EntFire("floor_panel_1*", "SetPlaybackRate", 1000, 1.7);
          for(local i = 1; i <= 9; i ++) EntFire("floor_panel_1-roboarmN_0"+i, "DisableDraw");
          ppmod.keyval("tilex2_wall_1-robotarm_powerupB*", "Targetname", "");
          SendToConsole("ent_create_portal_reflector_cube");
          ppmod.addoutput("prop_button", "OnPressed", "cube", "Dissolve");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.enter <- function() {
          EntFire("light_shadowed_01", "TurnOn");
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(96, -928, 18.5));
          cube.SetAngles(0, 90, 0);
          ppmod.fire(cube, "Sleep");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(96, -864, 18.5));
          cube.SetAngles(0, 90, 0);
          ppmod.fire(cube, "Sleep");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_pit_flings", 1);
        }
      }
      reverse_maps["sp_a2_intro"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Stop sound effects
          EntFire("ss_incinerator_fall", "Kill");
          EntFire("aud_VFX.LightFlicker*", "Kill");
          // Give dual portal device
          SendToConsole("give weapon_portalgun");
          SendToConsole("upgrade_portalgun");
          // First door trigger
          EntFire("door_0-proxy", "Kill");
          EntFire("door_0-door_player_clip", "Kill");
          local trigger = ppmod.get(Vector(-744, 952, -10689.2));
          ppmod.addoutput(trigger, "OnStartTouch", "door_0-testchamber_door", "Open");
          ppmod.addoutput(trigger, "OnStartTouch", "texture_light_ceil_5", "TurnOn");
          // Corridor arms
          EntFire("@enable_corridor_arms", "Trigger");
          EntFire("arm_blocker", "Kill");
          EntFire("exit_corridor_arms-open", "Kill");
          // Chamber 19 room
          EntFire("double_panel_fall", "Trigger");
          EntFire("double_panel_fall", "Kill");
          EntFire("robo_dangle_ceiling_drop", "SetAnimation", "dangle_ceiling_04_idle");
          ppmod.keyval("robo_dangle_ceiling_drop", "Targetname", "");
          EntFire("panel_lowering_relay", "Trigger");
          ppmod.keyval("collapsing_rubble_instance-robo_flopintoplace_04", "Targetname", "");
          // Portalgun
          EntFire("snd_gun_zap", "Kill");
          EntFire("spr_gun_glow", "Kill");
          EntFire("timer_gun_particles", "Kill");
          EntFire("go_up", "Trigger");
          ppmod.get(Vector(-1256, 448, -10928)).Destroy(); // Trigger
          EntFire("player_near_portalgun", "Kill");
          EntFire("portalgun", "DisableDraw");
          EntFire("portalgun_button", "Lock");
          ppmod.addscript("portalgun_button", "OnUseLocked", "rev.level.portalgun()");
          EntFire("@disable_reveal_arms", "Kill");
          EntFire("@enable_reveal_arms", "Trigger");
          // Incinerator
          ppmod.get(Vector(-1864, 440, -10928)).Destroy();
          EntFire("incinerator_portal", "SetFadeDistance", 384);
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("ent_create_portal_companion_cube");
          EntFire("spawn_chute_*", "Kill");
          ppmod.get(Vector(-2982, 421.5, -10980.5)).Destroy();
          EntFire("blockerchute_1_open_wav", "Kill");
          EntFire("blockerchute_1_activate", "Trigger");
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          // End trigger
          local end = Entities.CreateByClassname("trigger_multiple");
          end.SetOrigin(Vector(-3324, 534, -10752));
          end.SetSize(Vector(-70, -101, -40), Vector(70, 101, 40));
          ppmod.keyval(end, "Solid", 3);
          ppmod.keyval(end, "CollisionGroup", 1);
          ppmod.keyval(end, "SpawnFlags", 1);
          ppmod.addscript(end, "OnStartTouch", "rev.level.finish()");
          ppmod.addoutput(end, "OnEndTouch", "rev_finish_msg", "Kill");
          ppmod.fire(end, "Enable");
          rev.level.fallanim(); // Stop fall animation
        }

        rev.load <- function() {
          ppmod.once("rev.level.corridor()"); // Set corridor arms
          ppmod.once("rev.level.cube()"); // Incinerator boost cubes
          ppmod.once("rev.level.teleport()");
          ppmod.once("rev.level.panel()");
        }

        rev.level.teleport <- function() {
          local elevator = Entities.FindByName(null, "departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(0, -90, 0);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
        }

        rev.level.fallanim <- function() {
          EntFire("camera_ghostanim", "Disable");
          EntFire("camera_ghostanim", "Kill", "", FrameTime());
          EntFire("ghostanim", "Kill", "", FrameTime());
          EntFire("impact_phys_clip", "Kill");
        }

        rev.level.corridor <- function() {
          for(local i = 1; i <= 13; i ++) {
            local curr = i;
            if(i < 10) curr = "0" + curr;
            local name = "exit_corridor_arms-robot_corridor_pathetic_";
            EntFire(name+curr, "SetAnimation", "corridor_pathetic_"+curr);
            EntFire(name+curr, "SetDefaultAnimation", "corridor_pathetic_"+curr+"_idleend");
            EntFire(name+curr, "SetPlaybackRate", 1000, FrameTime());
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-1538, 435, -10996));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "Wake");
          cube = Entities.Next(cube);
          cube.SetOrigin(Vector(-1906, 438, -10934));
          ppmod.fire(cube, "Wake");
          cube = Entities.Next(cube);
          cube.SetOrigin(Vector(-1906, 374, -10934));
          ppmod.fire(cube, "Wake");
        }

        rev.level.portalgun <- function() {
          EntFire("portalgun_button", "Kill");
          EntFire("portalgun", "EnableDraw");
          EntFire("go_down", "Trigger");
          EntFire("weapon_portalgun", "Kill");
          EntFire("viewmodel", "DisableDraw");
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(-1874, 410, -10986));
          panel.SetAngles(90, 0, 0);
          ppmod.fire(panel, "DisableDraw");
        }

        rev.level.finish <- function() {
          if(ppmod.get("weapon_portalgun")) {
            ppmod.interval("rev.level.solvemsg()", 0, "rev_finish_msg");
            return;
          }
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a1_wakeup", 1);
        }
        rev.level.solvemsg <- function() {
          ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
        }
      }
      reverse_maps["sp_a2_laser_chaining"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Remove unnecessary triggers
          local trigger = ppmod.get(Vector(1088, 352, 296));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(1048, 352, 320)).Destroy(); // Exit door close
          ppmod.get(Vector(-584, 64, 384)).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          EntFire("npc_portal_turret_floor", "Kill");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("box");
          cube.SetOrigin(Vector(-529.8, 75.9, 274.5));
          cube.SetAngles(0, 35, 0);
          cube = ppmod.get("box", cube);
          cube.SetOrigin(Vector(806, -670, 274.5));
          cube.SetAngles(0, 151, 0);
          cube = ppmod.get("box", cube);
          cube.SetOrigin(Vector(-620, -987.5, 274.4));
          cube.SetAngles(0, 12, 0);
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_column_blocker", 1);
        }
      }
      reverse_maps["sp_a2_laser_intro"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(65);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(30).Destroy(); // Exit door close
          ppmod.get(51).Destroy(); // Exit door open
          ppmod.get(31).Destroy(); // Entrance door close
          ppmod.get(34).Destroy();
          ppmod.get(12).Destroy();
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("catcher_1", "OnPowered", door, "Close");
          ppmod.addoutput("catcher_1", "OnUnpowered", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          rev.level.catwalk();
          EntFire("departure_elevator-vac*", "Kill");
          EntFire("aud_VFX.LightFlicker*", "Kill");
          EntFire("laser_catcher_door", "SetSpeed", 1000);
          EntFire("laser_catcher_door", "Close", "", FrameTime());
          EntFire("laser_catcher_side_mover", "SetSpeed", 1000);
          EntFire("laser_catcher_side_mover", "Close", "", FrameTime());
          EntFire("ball_catcher_door", "SetSpeed", 1000);
          EntFire("ball_catcher_door", "Open", "", FrameTime());
          EntFire("laser_emitter_wall_door", "SetSpeed", 1000);
          EntFire("laser_emitter_wall_door", "Open", "", FrameTime());
          EntFire("laser_emitter_door_horizontal", "SetSpeed", 1000);
          EntFire("laser_emitter_door_horizontal", "Open", "", FrameTime());
          EntFire("@ball_launcher_door", "Open");
          EntFire("aud_laser_activation", "Kill");
          EntFire("laser_emitter", "TurnOn");
          EntFire("lift_a", "SetSpeed", 5000);
          EntFire("lift_a", "Close", "", FrameTime());
          EntFire("lift_a", "SetSpeed", 80, 1);
        }

        rev.level.enter <- function() {
          EntFire("@exit_door-proxy", "OnProxyRelay2");
          EntFire("spotlight_1_startup_relay", "Trigger");

          EntFire("@exit_elevator_cleanser", "Disable");
          SendToConsole("portal_place 0 0 0 128 -119.969 -90 164 0");
          SendToConsole("portal_place 0 1 0 -128 255.969 90 0 0");
        }

        rev.level.catwalk <- function() {
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(820, -49, -79));
          brush.SetSize(Vector(-163, -22, -97), Vector(163, 16, 97));
          ppmod.keyval(brush, "Solid", 3);
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_intro", 1);
        }
      }
      reverse_maps["sp_a2_laser_over_goo"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          EntFire("departure_elevator-vac*", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(Vector(2384, -1056, 128));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(Vector(2552, -1056, 142.82)).Destroy(); // Exit door close
          ppmod.get(Vector(3528, -1680, 96)).Destroy(); // Entrance door close
          ppmod.get(57).Destroy(); // Dialogue trigger
          ppmod.get(Vector(3632, -1664, 95)).Destroy(); // Lights trigger
          ppmod.get(Vector(3760, -1664, 95)).Destroy(); // Panel removing trigger
          // Unsolving logic
          local door = "door_1-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_1-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("ent_create_portal_weighted_cube");
          ppmod.addoutput("box_restarter_button_model", "OnPressed", "cube", "Dissolve");
          SendToConsole("prop_dynamic_create props_ingame/striaght_piston_panel.mdl");
          SendToConsole("prop_dynamic_create props_bts/straight_piston_mid.mdl");
          EntFire("entry_landing_close_relay", "Kill");
          rev.level.ele_dir <- 0;
          EntFire("InstanceAuto69-corridor_repair-proxy", "Kill");
          EntFire("InstanceAuto69-corridor_repair-corridor_repair", "Kill");
          EntFire("instanceauto69-corridor_repair-repair_wall_*", "Trigger");
          EntFire("instanceauto69-corridor_repair-blocking_door*", "Open");
          EntFire("aud_VFX.LightFlicker*", "Kill");
          EntFire("wall_panel_2-repair_wall", "Trigger");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
          ppmod.once("rev.level.elevator()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(2752, -932, 70));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
        }

        rev.level.elevator <- function() {
          local elevator = ppmod.get("models/props_ingame/striaght_piston_panel.mdl");
          elevator.SetOrigin(Vector(3808, -1664, 50));
          elevator.SetAngles(0, 0, 0);
          ppmod.keyval(elevator, "Targetname", "rev_elevator");
          local piston = ppmod.get("models/props_bts/straight_piston_mid.mdl");
          piston.SetOrigin(Vector(3808, -1664, 50));
          piston.SetAngles(0, 0, 0);
          ppmod.fire(piston, "SetParent", "rev_elevator");
          local trigger = Entities.CreateByClassname("trigger_multiple");
          trigger.SetOrigin(Vector(3840, -1664, 50));
          trigger.SetSize(Vector(-32, -64, -4), Vector(32, 64, 4));
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          ppmod.fire(trigger, "Enable");
          ppmod.fire(trigger, "SetParent", "rev_elevator");

          ppmod.addscript(trigger, "OnStartTouch", "rev.level.ele_dir = 1");
          ppmod.addscript(trigger, "OnEndTouch", "rev.level.ele_dir = -1");
          ppmod.interval("rev.level.ele_move()", 0);
        }

        rev.level.ele_move <- function() {
          local elevator = ppmod.get("rev_elevator");
          local pos = elevator.GetOrigin();
          local speed = rev.level.ele_dir * 2;
          if((pos.z < 156 && speed > 0) || (pos.z > 50 && speed < 0)) {
            elevator.SetAbsOrigin(pos + Vector(0, 0, speed));
            if(speed > 0) {
              GetPlayer().SetAbsOrigin(GetPlayer().GetOrigin() + Vector(0, 0, speed));
              GetPlayer().SetVelocity(GetPlayer().GetVelocity() + Vector(0, 0, speed*30));
            }
          }
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
          // Set panel animations
          EntFire("AutoInstance1-robotarm_powerupAbot_02", "SetDefaultAnimation", "powerupA_02idleend");
          EntFire("AutoInstance1-robotarm_powerupAbot_03", "SetDefaultAnimation", "powerupA_03idleend");
          ppmod.get(Vector(3560, -1680, 96)).Destroy();
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_dual_lasers", 1);
        }
      }
      reverse_maps["sp_a2_laser_relays"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          EntFire("@transition_from_map", "Kill");
          EntFire("@exit_door-door_close_relay", "Disable");

          ppmod.get(Vector(1224, -704, 32)).Destroy(); // Industrial door trigger
          local trigger = ppmod.get(Vector(-320, -1376, 40));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.addscript("@exit_door-proxy", "OnProxyRelay1", "rev.level.elevator()");
          EntFire("laser_cube_spawner", "ForceSpawn");
          EntFire("lift_gate_close_rl", "Kill");

          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(-448, -704, -18));
          brush.SetSize(Vector(-64, -64, -18), Vector(64, 64, 18));
          ppmod.keyval(brush, "Solid", 3);
          ppmod.keyval(brush, "Targetname", "rev_elevator_brush");
        }

        rev.loop <- function() {
          if(ppmod.trigger(847.077, -743.969, -191.969, 976.753, -663.716, 79.5731, "4e61c8ce29b_ppmod")){
            EntFire("exit_airlock_door-open_door","trigger");
          }
          if(ppmod.trigger(1445.61, -743.969, -63.9688, 1744.02, -664.031, -55.9688, "b6c1d8c9d9c_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a2_turret_intro", 1);
          }
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("laser_cube");
          cube.SetOrigin(Vector(-549.94, -626.03, 18.46875));
          cube.SetAngles(0, 345.4, 0);
          SendToConsole("portal_place 0 0 447.969 -878.5 56 0 180 0");
          SendToConsole("portal_place 0 1 447.967 -633.6 56 0 180 0");
          EntFire("@exit_elevator_cleanser", "Disable");
          EntFire("exit_airlock_door-close_door_fast", "Trigger");
        }

        rev.level.elevator <- function() {
          EntFire("lift_down_rl","trigger");
          EntFire("lift_gate_open_rl","trigger");
          EntFire("lift_clips","kill");
          EntFire("player_on_top_branch","setvalue",0);
          EntFire("lift_up_branch","setvalue",0);
          EntFire("player_in_lift_branch","setvalue",0);
          EntFire("chamber_area_portal","open");
          EntFire("rev_elevator_brush", "Disable");
        }
      }
      reverse_maps["sp_a2_laser_stairs"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(404);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(158).Destroy(); // Exit door close
          ppmod.get(119).Destroy(); // Entrance door close
          ppmod.get(144).Destroy();
          ppmod.get(190).Destroy();
          ppmod.get(456).Destroy();
          ppmod.get(442).Destroy();
          ppmod.get(16).Destroy();
          ppmod.get(78).Destroy();
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("door_1-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("door_1-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          EntFire("cube_dropper_01-proxy", "OnProxyRelay1");
          EntFire("aud_VFX.LightFlicker*", "Kill");
          EntFire("InstanceAuto44-info_sign-info_panel_activate_rl", "Trigger");
          EntFire("floor_noportal_volume", "Deactivate");
          EntFire("floor_collsion_brush", "Enable");
          EntFire("04_laser", "TurnOn");
          EntFire("eyepeek", "Kill");
          EntFire("sphere_hide_trigger", "Kill");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube_dropper_01-cube_dropper_box");
          cube.SetOrigin(Vector(270, 320, 76));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "Wake");
          EntFire("light_shadowed_02", "TurnOn");
          // Floor panels
          EntFire("robo_flooranimA_*,", "DisableDraw");
          for(local i = 1; i <= 18; i ++) {
            local curr = i;
            if(i < 10) curr = "0" + curr;
            EntFire("robo_flooranimA_"+curr, "SetAnimation", "flooranimA_"+curr);
            EntFire("robo_flooranimA_"+curr, "SetPlaybackRate", 1000, FrameTime());
            EntFire("robo_flooranimA_"+curr, "SetDefaultAnimation", "flooranimA_"+curr+"_idleend");
          }
          // Wall panels
          EntFire("start_2x2error_arms_relay", "Trigger");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_intro", 1);
        }
      }
      reverse_maps["sp_a2_laser_vs_turret"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_arrive","kill");
          EntFire("departure_elevator-logic_source_elevator_door_open","kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "kill");

          EntFire("@transition_from_map", "kill");
          EntFire("@exit_door-door_close_relay","disable");
          EntFire("@exit_door-proxy","disable");

          local trigger = ppmod.get(Vector(-672, 384, 296));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(-631, 377, 322)).Destroy(); // Exit door close
          local door = ppmod.get("door_0-testchamber_door");
          ppmod.keyval(door, "Targetname", "rev_exit");
          ppmod.addoutput("panel_door-proxy", "OnProxyRelay1", door, "Close");
          ppmod.addoutput("panel_door-proxy", "OnProxyRelay2", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("npc_portal_turret_floor", "Kill");
          local cube = ppmod.get("room_10_box2");
          cube.SetOrigin(Vector(-94, 92.1, 293));
          cube.SetAngles(270, 39.6, 180);
          ppmod.fire(cube, "Wake");
          cube = ppmod.get("room_10_box3");
          cube.SetOrigin(Vector(283.6, 264.9, 274.5));
          cube.SetAngles(0, 180, 0);
          ppmod.fire(cube, "Sleep");
        }

        rev.level.enter <- function() {
          SendToConsole("portal_place 0 0 64 96 260.031 -90 180 0");
          SendToConsole("portal_place 0 1 286.031 -319.969 284 0 90 0");
          EntFire("@exit_elevator_cleanser", "Disable");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_turret_blocker", 1);
        }
      }
      reverse_maps["sp_a2_pit_flings"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null, "departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Remove unnecessary triggers
          ppmod.get(86).Destroy(); // Entrance door close
          ppmod.get(Vector(48, -529.45, -712)).Destroy(); // Room lights
          ppmod.get(Vector(64, -905.46, -668)).Destroy(); // Power up
          ppmod.get(Vector(72, -1068, -726.82)).Destroy(); // Corridor lights
          ppmod.get(Vector(73, -1325.46, -740)).Destroy(); // Cube dropper
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("entry_landing_open_relay", "OnTrigger", door, "Close");
          ppmod.addoutput("entry_landing_close_relay", "OnTrigger", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          EntFire("room_2_exit_door-close_door_rl", "Kill");
          // Level-specific modifications
          EntFire("cube_dropper-cube_dropper_relay", "Kill");
          EntFire("wall_repair_1_relay", "Trigger");
          EntFire("power_relay", "Trigger");
          EntFire("eyepeek2", "Kill");
          EntFire("spawn_new_cube_listener", "Kill");
          EntFire("first_cube_dissolve", "Kill");
          EntFire("companion_cube_trigger", "Kill");
          EntFire("exit_ledge_player_clip", "Kill");
          EntFire("walltunnel_1_Cover_clip", "Kill");
          SendToConsole("ent_create_portal_companion_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-447.34, -419.875, -87.7));
          cube.SetAngles(-90, 116, -52);
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_trust_fling", 1);
        }
      }
      reverse_maps["sp_a2_pull_the_rug"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_arrive","kill");
          EntFire("departure_elevator-logic_source_elevator_door_open","kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "kill");

          EntFire("@transition_from_map", "kill");
          EntFire("@exit_door-door_close_relay","disable");
          EntFire("@exit_door-proxy","disable");

          local trigger = ppmod.get(530);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(366).Destroy(); // Exit door close
          ppmod.get(66).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("button_1-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("button_1-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("laser_cube_wall_mixup_start_cube");
          cube.SetOrigin(Vector(192.2, -444.8, -155));
          cube.SetAngles(-90, 67, 180);
          ppmod.fire(cube, "Wake");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_vs_turret", 1);
        }
      }
      reverse_maps["sp_a2_ricochet"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          local trigger = ppmod.get(Vector(4064, 1152, -472));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(4128, 1152, -400)).Destroy(); // Elevator animation
          ppmod.get(Vector(4008, 1152, -456)).Destroy(); // Exit door close
          EntFire("door_0-proxy", "Kill"); // Entrance door
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          SendToConsole("portal_place 0 0 1120.031 1472 -872.031 0 0 0");
          SendToConsole("portal_place 0 1 2208 768.031 -327.969 0 90 0");
          SendToConsole("ent_create_portal_reflector_cube");

          EntFire("lower_gate_clip_brush", "Disable");
          EntFire("lower_blockade_player_teleport_trigger", "Disable");
        }

        rev.load <- function() {
          EntFire("lower_gate_laser", "TurnOn");
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(2208, 1473.66, -909.53));
          cube.SetAngles(0, 180, 0);
          ppmod.fire(cube, "Sleep");
          ppmod.addoutput("reflector_cube_button", "OnPressed", "cube", "Dissolve");
        }

        rev.level.enter <- function() {
          EntFire("@exit_elevator_cleanser", "Disable");
          local cube = ppmod.get("juggled_cube");
          cube.SetOrigin(Vector(3485.8, 960.3, -471));
          cube.SetAngles(0, -68, 90);
          ppmod.fire(cube, "Wake");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_sphere_peek", 1);
          EntFire("prop_weighted_cube", "Dissolve");
        }
      }
      reverse_maps["sp_a2_sphere_peek"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          local trigger = ppmod.get(Vector(-544, 944, 544));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(-544, 1096, 464)).Destroy(); // Exit door close
          ppmod.get(Vector(-1824, 1312, -113)).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("counter", "Add", 3);
          EntFire("ceiling_panel", "SetSpeed", 1000);
          EntFire("sound_panel_close", "Kill");
          EntFire("aud_lowering_ceiling*", "Kill");
          EntFire("@trigger_this_to_fix_ceiling", "Trigger");
          ppmod.get(Vector(-1936, 1540.24, 271.25)).Destroy();
          EntFire("aud_vfx.lightflicker*", "Kill");
          for(local i = 1; i <= 4; i++) {
            EntFire("wall_replace_0"+i+"_relay", "Trigger");
            EntFire("wall_replace_0"+i+"_relay", "Kill");
          }
          EntFire("landing_01-proxy", "OnProxyRelay2");
          EntFire("landing_01-proxy", "Kill");
          EntFire("aud_catapult_block_close_motor", "Kill")
          EntFire("floor_replace_relay", "Kill");
          EntFire("aud_catapult_block_close", "Kill");
          EntFire("catapult_block_relay", "Trigger");
          EntFire("catapult_block_relay", "Kill");
          for(local i = 1; i <= 3; i++) {
            EntFire("arm_spherepeek_0"+i, "Trigger");
            EntFire("arm_spherepeek_0"+i, "Kill");
          }
          EntFire("ramp_up_relay", "Trigger", "up01");
          EntFire("ramp_up_relay", "Kill");
          SendToConsole("ent_create_portal_reflector_cube");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.floor <- function() {
          for(local i = 0; i < 8; i++) {
            if(i % 2) EntFire("floor_repair_1-roboarmK_0"+i, "SetDefaultAnimation", "powerupK_0"+i+"down_idleend");
            else EntFire("floor_repair_2-roboarmK_0"+(i+1), "SetDefaultAnimation", "powerupK_0"+(i+1)+"down_idleend");
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-1085.5, 2249.125, 82.44));
          cube.SetAngles(0, -90, 0);
          ppmod.fire(cube, "Sleep");
          ppmod.addoutput("box_button", "OnPressed", "cube", "Dissolve");
        }

        rev.level.enter <- function() {
          SendToConsole("portal_place 0 0 -1088 1600.031 122.029 0 90 0");
          SendToConsole("portal_place 0 1 -1088 1535.969 122.029 0 -90 0");
          EntFire("@exit_elevator_cleanser", "Disable");
          EntFire("light_shadowed_01", "TurnOn");
          EntFire("catapult_malfunction_stop", "Trigger");
          rev.level.floor();
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_fizzler_intro", 1);
        }
      }
      reverse_maps["sp_a2_triple_laser"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_arrive","kill");
          EntFire("departure_elevator-logic_source_elevator_door_open","kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("departure_elevator-vacturret*", "kill");
          EntFire("box1_spawner", "forcespawn");
          EntFire("box1_spawner", "kill");
          local cube = ppmod.get("new_box");
          cube.SetOrigin(Vector(8000, -5725, 19));
          cube.SetAngles(0, 90, 0);
          local trigger = ppmod.get(Vector(6912, -5376, 40));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(6984, -5376, 40)).Destroy(); // Exit door close
          ppmod.get(Vector(7856, -5392, 128)).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-door_open_relay", "OnTrigger", door, "Close");
          ppmod.addoutput("@exit_door-door_close_relay", "OnTrigger", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("new_box1");
          cube.SetOrigin(Vector(7792, -5805, 19));
          cube.SetAngles(0, 56, 0);
        }

        rev.level.enter <- function() {
          SendToConsole("portal_place 0 0 7423.969 -5312.031 56 0 -90 0");
          SendToConsole("portal_place 0 1 7999.969 -5504.031 56 0 -90 0");
          EntFire("@exit_elevator_cleanser", "Disable");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_chaining", 1);
        }
      }
      reverse_maps["sp_a2_trust_fling"] <- function() {
        rev.setup <- function() {
          // Elevator cleanup
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          // Automatic teleportation
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");
          // Set entrance trigger
          local trigger = ppmod.get(510);
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          // Remove unnecessary triggers
          ppmod.get(107).Destroy(); // Exit door close
          ppmod.get(105).Destroy(); // Entrance door close
          ppmod.get(63).Destroy(); // Entrance door close
          // Unsolving logic
          local door = "door_0-testchamber_door";
          ppmod.addoutput("door_52-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("door_52-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          // Level-specific modifications
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("ent_create_portal_weighted_cube");
          ppmod.addoutput("dropper_button", "OnPressed", "cube", "Dissolve");
          ppmod.addoutput("dropper_button", "OnPressed", "!self", "Unlock", "", 1);
          EntFire("first_press_relay", "Kill");
          EntFire("malfunctioning_dropper_item_1_counter", "Add", 7);
          // Entrance arms
          EntFire("wall_panel_trigger", "Kill");
          EntFire("initial_arm_collision", "Kill");
          EntFire("wall_panel*", "AddOutput", "Targetname \"\"");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cubes()");
        }

        rev.level.cubes <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-192, 1184, -184));
          ppmod.fire(cube, "Sleep");
          local sphere = ppmod.get("malfunctioning_dropper_item_1");
          cube = Entities.Next(cube);
          cube.SetOrigin(sphere.GetOrigin());
          ppmod.keyval(cube, "Targetname", "cube_dropper_box");
          sphere.Destroy();
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-192, 1312, -223));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "Wake");
          EntFire("light_shadowed_01", "TurnOn");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_catapult_intro", 1);
        }
      }
      reverse_maps["sp_a2_turret_blocker"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator", "Kill");
          EntFire("departure_elevator-elevator_playerclip", "Kill");
          EntFire("departure_elevator-elevator_arrive", "Kill");
          EntFire("departure_elevator-logic_source_elevator_door_open", "Kill");
          local elevator = Entities.FindByName(null,"departure_elevator-elevator_1_body");
          local pos = elevator.GetOrigin();
          local ang = elevator.GetAngles();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 120));
          GetPlayer().SetAngles(ang.x, ang.y-90, ang.z);
          ppmod.fire_near("trigger_once", "Kill", pos, 128);
          EntFire("departure_elevator-elevator_1_body", "Kill");

          EntFire("@transition_from_map", "Kill");
          EntFire("@exit_door-door_close_relay", "Disable");
          EntFire("@exit_door-proxy", "Disable");

          local trigger = ppmod.get(Vector(64, 1776, 40));
          ppmod.addscript(trigger, "OnTrigger", "rev.level.enter()");
          ppmod.get(Vector(64, 1704, 64)).Destroy(); // Exit door close
          ppmod.get(Vector(-880, -896, 64)).Destroy(); // Entrance door close
          local door = "door_0-testchamber_door";
          ppmod.addoutput("stupid_sexy_open_relay", "OnTrigger", door, "Close");
          ppmod.addoutput("stupid_sexy_close_relay", "OnTrigger", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");

          EntFire("npc_portal_turret_floor", "Kill");
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("prop_weighted_cube");
          cube.SetOrigin(Vector(63.69, 508.47, 40));
          cube.SetAngles(0, 5, 0);
          ppmod.fire(cube, "Wake");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_laser_relays", 1);
        }
      }
      reverse_maps["sp_a2_turret_intro"] <- function() {
        rev.setup <- function() {
          EntFire("exit_airlock_door-open_door","trigger");
          EntFire("exit_airlock_door-open_door","kill");
          EntFire("exit_airlock_door-close_door","kill");
          EntFire("exit_airlock_door-close_door_fast","kill");
          EntFire("transition_trigger","kill");
          GetPlayer().SetOrigin(Vector(-297, 391, -255));

          local door = "door_0-testchamber_door";
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay2", door, "Close");
          ppmod.addoutput("@exit_door-proxy", "OnProxyRelay1", door, "Open");
          EntFire("door_0-door_player_clip", "Kill");
          ppmod.get(Vector(709.77, 143.75, 34.48)).Destroy(); // Exit door close
          ppmod.get(Vector(624, -1888, 0)).Destroy(); // Entrance door close
          local eletrigger = ppmod.get("arrival_elevator-source_elevator_door_open_trigger");
          ppmod.addscript(eletrigger, "OnTrigger", "rev.level.finish()");
          EntFire("@exit_door-door_physics_clip", "Kill");

          EntFire("@exit_elevator_cleanser", "Disable");
          EntFire("npc_portal_turret_floor", "Kill");
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          ppmod.addscript("weapon_portalgun", "OnFiredPortal1", "SendToConsole(\"ent_create info_null;script rev.level.shoot(0)\")");
          ppmod.addscript("weapon_portalgun", "OnFiredPortal2", "SendToConsole(\"ent_create info_null;script rev.level.shoot(1)\")");
        }

        rev.load <- function() {
          ppmod.once("rev.level.panel()");
          ppmod.once("rev.level.cubes()");
        }

        rev.level.finish <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_bridge_the_gap", 1);
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(773.5, 256, -192));
          panel.SetAngles(0, 0, 0);
        }

        rev.level.cubes <- function() {
          local cube = ppmod.get("prop_weighted_cube");
          cube.SetOrigin(Vector(1072, -690, 43));
          ppmod.fire(cube, "Wake");
          cube = ppmod.get("prop_weighted_cube", cube);
          cube.SetOrigin(Vector(484, -286, 43));
          ppmod.fire(cube, "Wake");
          cube = ppmod.get("prop_weighted_cube", cube);
          cube.SetOrigin(Vector(704.2, -508.9, 43));
          cube.SetAngles(0, 74, 0);
          ppmod.fire(cube, "Wake");
        }

        rev.level.shoot <- function(id) {
          local point = ppmod.get("info_null").GetOrigin();
          if((point - Vector(768, 256, -256)).Length() <= 128 && point.x == 767.468750) {
            if(ppmod.get(Vector(767.469, 256, -192), "prop_portal", 8)) return;
            SendToConsole("portal_place 0 " + id + " 767.469 256 -192 0 180 0");
            SendToConsole("r_drawparticles 0");
            ppmod.wait("SendToConsole(\"r_drawparticles 1\")", 1);
          }
        }
      }
      reverse_maps["sp_a3_00"] <- function() {
        rev.setup <- function() {
          for(i <- 0; i <= 10; i++){
            EntFire("shaft_section_"+i,"setspeeddir",-1);
            EntFire("shaft_section_"+i,"setspeedreal", 600);
          }
          EntFire("@chapter_subtitle_text", "SetText", "THE ASCENT");
          ppmod.wait("rev.level.end()", 5);
        }

        rev.level.end <- function() {
          SendToConsole("fadeout 1");
          EntFire("@command", "Command", "changelevel sp_a2_core", 1);
        }
      }
      reverse_maps["sp_a3_01"] <- function() {
        rev.setup <- function() {
          EntFire("knockout-viewcontroller","kill");
          EntFire("knockout-fadeout","kill");
          EntFire("knockout-portalgun-spawn","kill");
          SendToConsole("give weapon_portalgun");
          EntFire("vault_door_prop","setanimation","vault_door_open_anim");
          EntFire("vault_door_prop","setplaybackrate",30);
          EntFire("door_ominous_black_void","disable");
          EntFire("door_spotlight_2","turnon");
          EntFire("door_spotlight_2_fill","turnon");
          EntFire("big_door_clipbrush","kill");
          EntFire("AutoInstance1-door_button", "Kill");
          EntFire("hudhint_door", "Kill");
          EntFire("AutoInstance1-door_open", "Trigger");
          EntFire("platform_doors_10","open");
          EntFire("platform_doors_9","open");
          EntFire("platform_doors_8","open");
          EntFire("platform_doors_7","open");
          EntFire("platform_doors_6","open");
          EntFire("platform_doors_5","open");
          ppmod.fire_near("trigger_once","kill",Vector(5919.926,4520.781,-503.969),256);
          GetPlayer().SetOrigin(Vector(5919.926, 4520.781, -503.969));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("func_button","lock",Vector(3670.168,4482.717,-408.969),128);
          local button = Entities.FindByClassnameNearest("func_button",Vector(3670.168,4482.717,-408.969),128);
          ppmod.addscript(button, "OnUseLocked", "rev.level.unsolve()");
          rev.level.solve <- 0;
          EntFire("AutoInstance1-push_button_knob","pressin");
          EntFire("AutoInstance1-power_green","ToggleSprite");
          EntFire("AutoInstance1-power_red_elevator","ToggleSprite");
          EntFire("circuit_breaker_sparks4","kill");
          EntFire("circuit_breaker_sparks3","kill");
          EntFire("circuit_breaker_sparks2","kill");
          EntFire("circuit_breaker_sparks1","kill");
          EntFire("lights_on","kill");
          EntFire("humming","kill");
          EntFire("lights_entrance","turnon");
          EntFire("light_spots_entrance","turnon");
          EntFire("dyn_light_entrance","turnon");
          EntFire("AutoInstance1-power_on_sound","kill");
          EntFire("big_door_button*", "Lock");
        }

        rev.load <- function() {
          ppmod.once("rev.level.upgrade()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-1479.96, -2139.87, 0.03125, -1200.55, -1879.01, 459.788, null, null, true)){
            if(rev.level.solve == 1){
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_00", 1);
              rev.level.solve = -1;
            } else if(rev.level.solve != -1){
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
        }

        rev.level.upgrade <- function() {
          SendToConsole("upgrade_portalgun");
        }

        rev.level.unsolve <- function() {
          EntFire("AutoInstance1-push_button_knob","pressout");
          EntFire("AutoInstance1-power_green","ToggleSprite");
          EntFire("AutoInstance1-power_red_elevator","ToggleSprite");
          EntFire("AutoInstance1-circuit_breaker_lever_sound","playsound");
          EntFire("lights_entrance","turnoff");
          EntFire("light_spots_entrance","turnoff");
          EntFire("dyn_light_entrance","turnoff");
          EntFire("door_spotlight_2","turnoff");
          EntFire("door_spotlight_2_fill","turnoff");
          rev.level.solve = 1;
          ppmod.fire_near("func_button","Kill",Vector(3670.168,4482.717,-408.969),128);
        }

      }
      reverse_maps["sp_a3_03"] <- function() {
        rev.setup <- function() {
          EntFire("instanceauto3-exit_lift_doorbottom_movelinear","open");
          EntFire("instanceauto3-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once","kill",Vector(-3632.848,1279.630,-2543.969),256);
          GetPlayer().SetOrigin(Vector(-3632.848, 1279.630, -2543.969));
          GetPlayer().SetAngles(0, 90, 0);
          ppmod.fire_near("trigger_once","kill",Vector(-6046.75, -2906.02, -5222.05),256);
          EntFire("pump_machine_blue_rotate","open");
          EntFire("pump_machine_blue_button","lock");
          EntFire("pump_machine_relay","kill");
          EntFire("controlroom_gate_a_rotating","open");
          EntFire("controlroom_gate_b_rotating","open");
          EntFire("AutoInstance1-button", "Kill");
          EntFire("hudhint_breaker_lever*", "Kill");
          EntFire("AutoInstance1-push_button_knob", "PressIn");
          EntFire("AutoInstance1-power_green", "ToggleSprite");
          EntFire("AutoInstance1-power_red_elevator", "ToggleSprite");
          EntFire("AutoInstance1-power_on_sound", "Kill");
          EntFire("lights_on","kill");
          EntFire("aud_lights_on_power","kill");
          rev.level.solve <- 0;
          local button = ppmod.get("pump_machine_blue_button");
          ppmod.addscript(button, "OnUseLocked", "rev.level.pump()");

          ppmod.get(517).Destroy();
          EntFire("pumproom_noportal", "Kill");
          EntFire("pumproom_door_bottom_prop", "SetAnimation", "Open");
          EntFire("pumproom_door_bottom_trigger", "Kill");
          EntFire("pumproom_door_bottom_button", "Lock");
          EntFire("pumproom_door_bottom_portal", "Open");
          SendToConsole("prop_dynamic_create props_underground/wood_panel_64x128_01.mdl");
          SendToConsole("prop_dynamic_create props_underground/wood_panel_64x128_01.mdl");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-6636.82, -2935.97, -5215.97, -6357.12, -2793.46, -5017.91, null, null, true)){
            if(rev.level.solve == 1){
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_01", 1);
              rev.level.solve = -1;
            } else if(rev.level.solve != -1) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
          if(ppmod.trigger(-6151.91, -3015.02, -5224.31, -5978.66, -2731.48, -5087.43, "376ab793d130_ppmod")){
            EntFire("door1_prop","setanimation","open");
          }
        }

        rev.load <- function() {
          local plank = ppmod.get("models/props_underground/wood_panel_64x128_01.mdl");
          plank.SetOrigin(Vector(-3628, 1664, -2544));
          plank.SetAngles(45, 0, 0);
          plank = Entities.Next(plank);
          plank.SetOrigin(Vector(-3537.5, 1664, -2453.5));
          plank.SetAngles(45, 0, 0);
        }

        rev.level.pump <- function() {
          EntFire("pump_machine_blue_button","kill");
          EntFire("pump_machine_blue_rotate","close");
          EntFire("pump_machine_blue_rotate_sound","playsound");
          EntFire("pump_machine_blue_light_green","hidesprite");
          EntFire("pump_machine_blue_light_red","showsprite");
          rev.level.solve = 1;
        }
      }
      reverse_maps["sp_a3_bomb_flings"] <- function() {
        rev.setup <- function() {
          EntFire("instanceauto22-exit_lift_doorbottom_movelinear","open");
          EntFire("instanceauto22-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once", "Kill", Vector(-256, 1568, 576), 256);
          GetPlayer().SetOrigin(Vector(-256, 1568, 576.031));
          GetPlayer().SetAngles(0, 90, 0);
          EntFire("paint_sprayer_button","press");
          ppmod.addscript("paint_bomb_maker", "OnEntitySpawned", "rev.level.blob()");
          SendToConsole("ent_create info_placement_helper");
          SendToConsole("script rev.level.helper()");
          // The gel bounce is caused by a point_push
          local blobpush = Entities.CreateByClassname("point_push");
          ppmod.keyval(blobpush, "Radius", 50);
          ppmod.keyval(blobpush, "SpawnFlags", 18);
          ppmod.keyval(blobpush, "Magnitude", 510);
          blobpush.SetOrigin(Vector(140, 640, 320));
          blobpush.SetAngles(-90, 0, 0);
          // Gel for casual players. This needs to bounce a bit higher than usual.
          SendToConsole("ent_create info_paint_sprayer");
          SendToConsole("script rev.level.sprayer()");
          local geltrig = Entities.CreateByClassname("trigger_multiple");
          geltrig.SetOrigin(Vector(-1199, 449, -1286));
          geltrig.SetSize(Vector(-174, -192, -122), Vector(174, 192, 122));
          ppmod.keyval(geltrig, "Solid", 3);
          ppmod.keyval(geltrig, "CollisionGroup", 1);
          ppmod.keyval(geltrig, "SpawnFlags", 1);
          ppmod.fire(geltrig, "Enable");
          ppmod.addscript(geltrig, "OnStartTouch", "SendToConsole(\"bounce_paint_min_speed 600.0f\")");
          ppmod.addscript(geltrig, "OnEndTouch", "SendToConsole(\"bounce_paint_min_speed 500.0f\")");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-0.96875, 1955.4, 576.031, 61.3391, 2129.44, 746.095)){
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(132.498,-523.100,480.031),1024);
            EntFire("point_push", "Enable");
          }
          if(ppmod.trigger(-1253.72, -0.427623, -1067.97, -1175.03, 60.4601, -1028.67)){
            EntFire("instanceauto8-entrance_lift_doortop_movelinear","close");
            EntFire("instanceauto8-entrance_lift_doorbottom_movelinear","close");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_jump_intro", 1);
          }
        }

        rev.level.blob <- function() {
          local blob = ppmod.get("prop_paint_bomb");
          blob.SetOrigin(Vector(140, 640, 350));
          if(ppmod.debug) SendToConsole("ent_bbox point_push");
          rev.level.blob <- function(){};
        }

        rev.level.helper <- function() {
          local helper = ppmod.get("info_placement_helper");
          helper = ppmod.get("info_placement_helper", helper);
          ppmod.keyval(helper, "Radius", 128);
          ppmod.keyval(helper, "Force_Placement", 1);
          helper.SetOrigin(Vector(128, -712, 580));
          helper.SetAngles(-50,90,0);
        }

        rev.level.sprayer <- function() {
          local sprayer = ppmod.get("info_paint_sprayer");
          sprayer.SetOrigin(Vector(-1188, 445, -1397));
          sprayer.SetAngles(90, 0, 0);
          ppmod.keyval(sprayer, "maxblobcount", 250);
          ppmod.keyval(sprayer, "blobs_per_second", 100);
          ppmod.keyval(sprayer, "min_speed", 100);
          ppmod.keyval(sprayer, "max_speed", 100);
          ppmod.keyval(sprayer, "blob_spread_radius", 80);
          ppmod.keyval(sprayer, "min_streak_speed_dampen", 500);
          ppmod.keyval(sprayer, "max_streak_speed_dampen", 1000);
          ppmod.fire(sprayer, "Start");
          ppmod.fire(sprayer, "Stop", "", 1);
        }
      }
      reverse_maps["sp_a3_crazy_box"] <- function() {
        rev.setup <- function() {
          EntFire("instanceauto21-exit_lift_doorbottom_movelinear","open");
          EntFire("instanceauto21-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once","kill",Vector(639.293,175.220,1916.531),256);
          GetPlayer().SetOrigin(Vector(640.869, 175.989, 1920.031));
          GetPlayer().SetAngles(0, -90, 0);
          SendToConsole("viewmodel_offset_x 0");
          EntFire("proxy-5","onproxyrelay1");
          EntFire("proxy-5","onproxyrelay1");
          EntFire("proxy-5","onproxyrelay1");
          EntFire("proxy-5","onproxyrelay1");
          EntFire("crazy_box_break_glass_sound-1","kill");
          EntFire("crazy_box_break_glass_sound-2","kill");
          EntFire("crazy_box_break_glass_sound-3","kill");
          EntFire("crazy_box_break_glass_sound-4","kill");
          EntFire("crazy_box_break_glass_sound-5","kill");
          EntFire("crazy_box_break_glass_sound-6","kill");
          EntFire("crazy_box_break_glass_sound-7","kill");
          EntFire("crazy_box_break_glass_sound-8","kill");
          Entities.FindByClassname(null,"prop_weighted_cube").SetOrigin(Vector(353.075,-959.357,1572.423));
          EntFire("paint_sprayer_bounce","start");
          EntFire("noportal_volume_01","kill");
          EntFire("room_1_door_close_trigger","kill");
          rev.level.solve <- 1;
          local button = Entities.FindByClassnameNearest("prop_under_floor_button",Vector(352,-957,1543), 64);
          ppmod.addscript(button, "OnPressed", "rev.level.solve = 0");
          ppmod.addscript(button, "OnUnPressed", "rev.level.solve = 1");
          ppmod.get(42).Destroy(); // Last room entrance door close trigger
          local trigger = ppmod.get(135); // Last room entrance door open trigger
          trigger.SetOrigin(Vector(192, -1280, 1600));
        }

        rev.loop <- function() {
          if(ppmod.trigger(-1412.71, -163.747, -6139.97, -1341.17, -92.6758, -6097.51, "92379d049c7_ppmod")){
            EntFire("instanceauto2-entrance_lift_doortop_movelinear","close");
            EntFire("instanceauto2-entrance_lift_doorbottom_movelinear","close");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_crazy_box", 1);
          }
          if(ppmod.trigger(2200.17, 98.1405, -123.969, 2277.78, 160.352, -82.7551, null, null, true)){
            if(rev.level.solve == 1){
              EntFire("instanceauto17-entrance_lift_doortop_movelinear","close");
              EntFire("instanceauto17-entrance_lift_doorbottom_movelinear","close");
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_bomb_flings", 1);
              rev.level.solve = -1;
            } else if(rev.level.solve != -1) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
        }

      }
      reverse_maps["sp_a3_end"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          ppmod.fire_near("trigger_once","kill",Vector(-1531.672,-832.774,3319.573),256);
          GetPlayer().SetOrigin(Vector(-1531.672, -832.774, 3319.573));
          GetPlayer().SetAngles(0, 180, 0);
          EntFire("exit_door", "setanimation", "open_idle");
          EntFire("paint_duct_start_relay", "trigger");
          EntFire("paint_duct_stop_relay", "trigger", "", 10);
          EntFire("paint_duct_squirting_sound", "Kill");
          EntFire("big_door","setanimation","vault_door_rotate_open_anim");
          EntFire("big_door","setplaybackrate",50);
          EntFire("big_door_portal","open");
          EntFire("big_door_pipeconnect_movelinear","open");
          EntFire("big_door_pipeconnect_movelinear", "setspeed", 99999);
          EntFire("big_door_pipes_connected_relay","kill");
          EntFire("pumproom_lift*", "Kill");
          EntFire("light_array_sprite","togglesprite");
          EntFire("light_array_dynamic","skin",1);
          ppmod.fire_near("trigger_once","kill",Vector(-334.943,-810.475,-5055.97),256);
          EntFire("big_door_open_relay","kill");
          EntFire("big_door_button_move", "open");
          EntFire("big_door_button", "lock");
          rev.level.solved <- 0;
          ppmod.addscript("big_door_button", "OnUseLocked", "rev.level.button()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-384.481, -893.011, -5055.97, -255.531, -690.317, -4886.49, null, null, true)){
            if(rev.level.solved > 0){
              EntFire("entrance_door_prop", "setanimation", "open");
              rev.level.solved = -1;
            } else if(rev.level.solved == 0) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", 0.0334);
            }
          }
          if(ppmod.trigger(-383.969, -1103.97, -5055.97, -256.031, -914.031, -5047.97, "a3end-end")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_portal_intro", 1);
          }
        }

        rev.level.button <- function() {
          EntFire("big_door_button", "Kill");
          EntFire("big_door_button_move", "Close");
          EntFire("big_door_button_green", "ToggleSprite");
          EntFire("big_door_button_red", "ToggleSprite");
          EntFire("big_door_button_sound", "PlaySound");
          EntFire("light_array_sprite","togglesprite");
          EntFire("light_array_dynamic","skin",0);
          EntFire("pumproom_lift_tracktrain","startforward");
          EntFire("pumproom_lift_tracktrain","setspeedreal", 100);
          EntFire("pumproom_lift_rotate","close");
          EntFire("pumproom_lift_slide_movelinear","close");
          rev.level.solved = 1;
        }
      }
      reverse_maps["sp_a3_jump_intro"] <- function() {
        rev.setup <- function() {
          EntFire("instanceauto24-exit_lift_doorbottom_movelinear","open");
          EntFire("instanceauto24-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once","kill",Vector(-672,2080,1508),256);
          GetPlayer().SetOrigin(Vector(-672, 2080, 1508.031));
          GetPlayer().SetAngles(0, 180, 0);
          local cube = Entities.FindByClassnameNearest("prop_weighted_cube", Vector(-95,1154,1182), 350);
          cube.SetOrigin(Vector(-1175,1211,1235));
          ppmod.fire_near("prop_under_button","press",Vector(-290,780,288),64);
          rev.level.solve <- 2;
          local button = Entities.FindByClassnameNearest("prop_under_floor_button", Vector(-1177,1200,1180), 64);
          ppmod.addscript(button, "OnPressed", "rev.level.solve--");
          ppmod.addscript(button, "OnUnPressed", "rev.level.solve++");
          button = Entities.FindByClassnameNearest("prop_under_floor_button", Vector(356,547,280), 64);
          ppmod.addscript(button, "OnPressed", "rev.level.solve--");
          ppmod.addscript(button, "OnUnPressed", "rev.level.solve++");
        }

        rev.load <- function() {
          ppmod.once("rev.level.cube()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(-473.445, 2068.14, -89.9688, -394.406, 2128.58, -46.9298, null, null, true)){
            if(rev.level.solve >= 2) {
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_03", 1);
              rev.level.solve = -1;
            } else if(rev.level.solve != -1) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("room_1_cube_dropper-cube_dropper_box");
          cube.SetOrigin(Vector(352, 545, 332));
          ppmod.fire(cube, "Wake", "", 1);
        }
      }
      reverse_maps["sp_a3_portal_intro"] <- function() {
        rev.setup <- function() {
          EntFire("transition_trigger", "kill");
          GetPlayer().SetOrigin(Vector(3837.264, 307.283, 5632.031));
          GetPlayer().SetAngles(0, -90, 0);
          ppmod.fire_near("trigger_once","kill",Vector(3497.03, -103.176, 544.031),256);
          EntFire("sphere_entrance_lift_train", "startforward");
          EntFire("liftshaft_exit_door_prop", "SetAnimation", "Open");
          EntFire("liftshaft_exit_door_button", "Kill");
          local trigger = Entities.CreateByClassname("trigger_once");
          trigger.SetOrigin(Vector(2301, -63, -2533));
          trigger.SetSize(Vector(-68, -129, -91), Vector(68, 129, 91));
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          ppmod.addoutput(trigger, "OnStartTouch", "!self", "Kill");
          ppmod.addoutput(trigger, "OnStartTouch", "1970s_door2_door_upper", "Open");
          ppmod.addoutput(trigger, "OnStartTouch", "1970s_door2_door_lower", "Open");
          ppmod.fire(trigger, "Enable");
          EntFire("1970s_door_1_trigger", "Kill");
          EntFire("office_block_exit_button_button", "Kill");
          EntFire("abyss_fade_trigger", "Enable");

          EntFire("pumproom_door_1_blackbrush", "Kill");
          EntFire("pumproom_entrance_door-door_close", "Kill");
          EntFire("pump_machine_relay", "Trigger");
          EntFire("pump_machine_white_sprayer_stop_relay", "Kill");
          EntFire("bird", "Kill");

          rev.level.solve <- 0;
          local counter = Entities.CreateByClassname("math_counter");
          ppmod.keyval(counter, "Targetname", "rev_pump_counter");
          ppmod.keyval(counter, "Max", 3);
          ppmod.addscript(counter, "OnHitMax", "rev.level.solve=1");

          local gels = ["blue", "orange", "white"];
          for(local i = 0; i < 3; i++) {
            EntFire("pump_machine_"+gels[i]+"_rotate", "Open");
            EntFire("pump_machine_"+gels[i]+"_button", "Lock");
            EntFire("pump_machine_"+gels[i]+"_light_green", "ShowSprite");
            EntFire("pump_machine_"+gels[i]+"_light_red", "HideSprite");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "rev_pump_counter", "Add", 1);
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_rotate", "Close");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_light_green", "HideSprite");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_light_red", "ShowSprite");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_rotate_sound", "PlaySound");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_start_sound", "Kill");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "pump_machine_"+gels[i]+"_sprayer", "Stop");
            ppmod.addoutput("pump_machine_"+gels[i]+"_button", "OnUseLocked", "!self", "Kill");
          }
        }

        rev.loop <- function() {
          if(ppmod.trigger(3459.03, -180.273, 544.031, 3654.64, 34.95, 764.683)){
            EntFire("liftshaft_entrance_door-door_close","kill");
            EntFire("liftshaft_entrance_door-door_button","kill");
            EntFire("liftshaft_entrance_door-door_open","trigger");
          }
          if(ppmod.trigger(2307.93, -191.969, 544.031, 2523.16, 0.233047, 768.184)){
            ppmod.fire_near("trigger_once","kill",Vector(1674.43, -114.405, 544.031),256);
            ppmod.fire_near("trigger_once","kill",Vector(2407.5, -113.819, 544.031),256);
            EntFire("highdoor_areaportal","open");
            EntFire("highdoor_door_lower","open");
            EntFire("highdoor_door_upper","open");
            EntFire("giant_areaportal", "open");
            EntFire("giant_areaportal_b", "open");
            EntFire("giant_areaportal_blackbrush", "kill");
          }
          if(ppmod.trigger(1500.94, -134.473, 544.031, 1741.39, -57.5632, 683.884)){
            EntFire("damaged_sphere_door_3-proxy","onproxyrelay1");
            EntFire("damaged_sphere_door_4-proxy","onproxyrelay1");
            EntFire("damaged_sphere_door_3-proxy","kill");
            EntFire("damaged_sphere_door_4-proxy","kill");
            EntFire("bowl_areaportal", "open");
            EntFire("bowl_areaportal_blackbrush", "kill");
          }
          if(ppmod.trigger(221.168, -1027.74, 160.031, 295.66, -961.938, 193.507)){
            EntFire("giant_areaportal_b", "open", "", 0.95);
            EntFire("giant_areaportal", "open", "", 0.95);
            EntFire("sphere_entrance_lift_train","startbackward");
            EntFire("paint_sprayer_1","kill");
            EntFire("paint_sprayer_2","kill");
            ppmod.fire_near("trigger_once","kill",Vector(242.95, -985.969, -1655.97),256);
          }
          if(ppmod.trigger(874.595, -1381.99, -1535.97, 1011.43, -1306.03, -1409.48)){
            EntFire("office_block_exit_door_prop", "SetAnimation", "Open");
            EntFire("office_block_exit_button_push_button_knob", "Close");
            EntFire("office_block_exit_button_power_green", "ToggleSprite");
            EntFire("office_block_exit_button_power_red_elevator", "ToggleSprite");
          }
          if(ppmod.trigger(1373.01, -1155.56, -2950, 1443.06, -1084.38, -2932, null, null, true)){
            if(rev.level.solve == 1) {
              EntFire("entrance_lift_doortop_movelinear","close");
              EntFire("entrance_lift_doorbottom_movelinear","close");
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_speed_flings", 1);
              rev.level.solve = -1;
            } else if(rev.level.solve != -1) {
              ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
        }
      }
      reverse_maps["sp_a3_speed_flings"] <- function() {
        rev.setup <- function() {
          EntFire("InstanceAuto3-exit_lift_doorbottom_movelinear","open");
          EntFire("InstanceAuto3-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once","kill",Vector(380.769, 1133.22, 32.0312),256);
          GetPlayer().SetOrigin(Vector(399.150, 1152.313, 32.031));
          GetPlayer().SetAngles(0, 0, 0);
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(1146, 767, -748));
          brush.SetSize(Vector(-82, -82, -4), Vector(82, 82, 4));
          ppmod.keyval(brush, "Solid", 2);
          SendToConsole("ent_create_paint_bomb_jump");
          SendToConsole("script rev.level.blob()");
        }

        rev.load <- function() {
          ppmod.once("rev.level.panel()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(1506.24, -1159.91, -59.9688, 1574.52, -1089.35, -16.9298, "abd484ae11a0_ppmod")){
            EntFire("instanceauto6-entrance_lift_doortop_movelinear","close");
            EntFire("instanceauto6-entrance_lift_doorbottom_movelinear","close");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_speed_ramp", 1);
          }
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(1144, 765, -758));
          panel.SetAngles(90, 20, 0);
          ppmod.fire(panel, "Color", "20 110 160");
        }

        rev.level.blob <- function() {
          local blob = ppmod.get("prop_paint_bomb");
          blob.SetOrigin(Vector(1146, 767, -630));
        }
      }
      reverse_maps["sp_a3_speed_ramp"] <- function() {
        rev.setup <- function() {
          EntFire("InstanceAuto14-exit_lift_doorbottom_movelinear","open");
          EntFire("InstanceAuto14-exit_lift_doortop_movelinear","open");
          ppmod.fire_near("trigger_once","kill",Vector(1231.482,-638.207,384.031),256);
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          GetPlayer().SetOrigin(Vector(1231.482, -638.207, 384.031));
          GetPlayer().SetAngles(0, 180, 0);
          EntFire("noportal_01","kill");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(395, -642, -630));
          brush.SetSize(Vector(-82, -82, -4), Vector(82, 82, 4));
          ppmod.keyval(brush, "Solid", 2);
          SendToConsole("ent_create_paint_bomb_jump");
          SendToConsole("script rev.level.blob()");
          // Landing sound
          ppmod.fire_near("trigger_once", "Kill", Vector(856, -640, 404), 32);
        }

        rev.load <- function() {
          ppmod.once("rev.level.panel()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(984.132, 1250.19, 68, 1061.04, 1313.26, 110.491, "67667cc151be_ppmod")){
            EntFire("instanceauto20-entrance_lift_doortop_movelinear","close");
            EntFire("instanceauto20-entrance_lift_doorbottom_movelinear","close");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_transition01", 1);
          }
        }

        rev.level.panel <- function() {
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(395, -641, -640));
          panel.SetAngles(90, 20, 0);
          ppmod.fire(panel, "Color", "20 110 160");
        }

        rev.level.blob <- function() {
          local blob = ppmod.get("prop_paint_bomb");
          blob.SetOrigin(Vector(392, -638, -512));
        }
      }
      reverse_maps["sp_a3_transition01"] <- function() {
        rev.setup <- function() {
          EntFire("exit_lift_doorbottom_movelinear", "open");
          EntFire("exit_lift_doortop_movelinear", "open");
          ppmod.fire_near("trigger_once", "kill",Vector(-2062.67, -145.087, -4159.97),256);
          GetPlayer().SetOrigin(Vector(-2046.668, -129.087, -4159.969));
          GetPlayer().SetAngles(0, 180, 0);
          SendToConsole("upgrade_potatogun");
          EntFire("potatos_prop", "disabledraw");
          EntFire("sphere_entrance_potatos_button", "Lock");
          ppmod.addscript("sphere_entrance_potatos_button", "OnUseLocked", "rev.level.potatos()");
          ppmod.get(237).Destroy(); // PotatOS office door close trigger
          EntFire("potatos_shake_relay", "Kill");
          EntFire("exit_gate_clipbrush", "kill");
          EntFire("exit_gate_*", "Open");
          ppmod.get("sphere_entrance_lift_movelinear").SetOrigin(Vector(-2564, -128, -4164.13));
          EntFire("big_wall_noportal", "kill");
          EntFire("bird", "kill");
          EntFire("pumproom_door_top_trigger", "kill");
          EntFire("pumproom_exterior_portalblocker", "kill");
          EntFire("pump_machine_blue_rotate", "open");
          EntFire("pump_machine_orange_rotate", "open");
          EntFire("pump_machine_blue_start_sound", "kill");
          EntFire("pump_machine_orange_start_sound", "kill");
          EntFire("pump_machine_blue_button", "lock");
          EntFire("pump_machine_orange_button", "lock");
          local blue = ppmod.get("pump_machine_blue_button");
          local orange = ppmod.get("pump_machine_orange_button");
          ppmod.addscript(blue, "OnUseLocked", "rev.level.blue()");
          ppmod.addscript(orange, "OnUseLocked", "rev.level.orange()");
          EntFire("pumproom_door_bottom_trigger", "kill");
          EntFire("pumproom_fizzlerdoor_prop", "setanimation", "open");
          rev.level.solve <- 0;
          rev.level.door_top <- true;
          rev.level.door_bottom <- true;
          ppmod.addscript("pumproom_door_bottom_button", "OnPressed", "rev.level.door_bottom = false");
          ppmod.addscript("pumproom_door_top_button", "OnPressed", "rev.level.door_top = false");
        }

        rev.loop <- function() {
          if(ppmod.trigger(984.132, 1250.19, 68.0312, 1061.04, 1313.26, 110.491, "67667cc151be_ppmod")){
            EntFire("instanceauto20-entrance_lift_doortop_movelinear", "close");
            EntFire("instanceauto20-entrance_lift_doorbottom_movelinear", "close");
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a3_transition01", 1);
          }
          if(rev.level.door_top && ppmod.trigger(-2186.09, -1726.5, -5119.97, -2031.07, -1582.87, -4968.22, "c5c9d4a3c5_ppmod")){
            EntFire("pumproom_portal_top", "Open");
            EntFire("pumproom_door_top_prop", "SetAnimation", "Open");
            EntFire("pumproom_door_top_button", "Kill");
          }
          if(rev.level.door_bottom && ppmod.trigger(-1359.97, -2242.03, -5951.97, -1152, -2112.03, -5833.67, "d0219a649bf_ppmod")){
            EntFire("pumproom_door_bottom_prop", "SetAnimation", "Open");
            EntFire("pumproom_door_bottom_button", "Kill");
          }
          if(ppmod.trigger_get("a3t-potato") && ppmod.trigger(-3246.56, 517.367, -4575.97, -3160.87, 673.47, -4426, "e827828a9c6_ppmod")){
            EntFire("officedoor_4", "setanimation", "open");
          }
          if(ppmod.trigger(-1412.71, -163.747, -6139.97, -1341.17, -92.6758, -6097.51, null, null, true)){
            if(rev.level.solve >= 3) {
              EntFire("instanceauto2-entrance_lift_doortop_movelinear", "close");
              EntFire("instanceauto2-entrance_lift_doorbottom_movelinear", "close");
              SendToConsole("fadeout 1");
              EntFire("@command", "Command", "changelevel sp_a3_crazy_box", 1);
              rev.level.solve = -1;
            } else {
              if(rev.level.solve != -1) ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
            }
          }
        }

        rev.level.blue <- function() {
          rev.level.solve ++;
          EntFire("pump_machine_blue_button", "kill");
          EntFire("pump_machine_blue_rotate", "close");
          EntFire("pump_machine_blue_rotate_sound", "playsound");
          EntFire("pump_machine_blue_light_green", "hidesprite");
          EntFire("pump_machine_blue_light_red", "showsprite");
        }

        rev.level.orange <- function() {
          rev.level.solve ++;
          EntFire("pump_machine_orange_button", "kill");
          EntFire("pump_machine_orange_rotate", "close");
          EntFire("pump_machine_orange_rotate_sound", "playsound");
          EntFire("pump_machine_orange_light_green", "hidesprite");
          EntFire("pump_machine_orange_light_red", "showsprite");
        }

        rev.level.potatos <- function() {
          rev.level.solve ++;
          EntFire("potatos_prop", "EnableDraw", "", 1);
          local proxy = Entities.CreateByClassname("logic_playerproxy");
          ppmod.fire(proxy, "RemovePotatosFromPortalgun");
        }
      }
      reverse_maps["sp_a4_finale1"] <- function() {
        rev.setup <- function() {
          EntFire("timer_crushers", "Kill");
          ppmod.fire_near("trigger_once","kill",Vector(-12833,-3000,-154),512);
          GetPlayer().SetOrigin(Vector(-12833, -3000, -154));
          GetPlayer().SetAngles(0, 90, 0);
          EntFire("final_door-proxy","onproxyrelay1");
          EntFire("final_door-proxy","kill");
          ppmod.fire_near("trigger_once","kill",Vector(-10803.558,-2050.654,80.031),256);
          EntFire("tbeam_crusher_delivery","enable");
          EntFire("tbeam_crusher_delivery","setlinearforce",-1000);
          EntFire("catapult_3","kill");
          EntFire("relay_paint_bomb", "Trigger");
          EntFire("trigger_platform_painted", "Kill");
          ppmod.fire_near("trigger_once","kill",Vector(-5127.045,-1948.460,-681.699),512);
          EntFire("sound_crusher_walkway_sfx","kill");
          EntFire("sound_crusher_walkway","kill");
          EntFire("crusherArm_smashA", "kill");
          EntFire("template_crusher_portalbumper", "forcespawn");
          EntFire("brush_catwalk_monster_blocker", "kill");
          EntFire("monster_clip", "kill");
          EntFire("crusher_catwalk", "setanimation", "wall_smashA");
          EntFire("crusher_brush", "open");
          EntFire("movelinear_crushed_wall","open");
          EntFire("catwalk_crusher_portalsurf2","enable");
          EntFire("catwalk_crusher_portalsurf","kill");
          EntFire("catwalk_512_fx_A_1","setanimation","crush1");
          EntFire("catwalk_512_fx_A_1","setplaybackrate",20);
          ppmod.get(122).Destroy(); // Crusher trigger
          EntFire("studio-wheatley_rotating","setlocalorigin","0 0 100");
          ppmod.fire_near("trigger_once","kill",Vector(-4785.409,-5115.845,-464.520),512);
          ppmod.get(Vector(-9826.29, -2182.46, -617.1)).Destroy();
          ppmod.get(Vector(-8896, -2048, -240)).Destroy();
          EntFire("backstop", "Kill");
          EntFire("shake1", "Kill");
          EntFire("relay_smash_effects_fast", "Kill");
          EntFire("relay_destroy_platform", "Kill");
          EntFire("relay_crusher_volley", "Kill");
          local helper = ppmod.get(191);
          ppmod.keyval(helper, "Radius", 128);
          ppmod.keyval(helper, "Force_Placement", 1);
          ppmod.keyval(helper, "snap_to_helper_angles", 1);
          helper.SetOrigin(Vector(-8900, -2048, -260));
          helper.SetAngles(-90, 1, 0);
          helper = ppmod.get(Vector(-9936, -2208, -624.974));
          ppmod.keyval(helper, "Radius", 256);
          ppmod.keyval(helper, "Force_Placement", 1);
          local blobpush = Entities.CreateByClassname("point_push");
          ppmod.keyval(blobpush, "Targetname", "rev_blob_push");
          ppmod.keyval(blobpush, "Radius", 64);
          ppmod.keyval(blobpush, "SpawnFlags", 18);
          ppmod.keyval(blobpush, "Magnitude", 250);
          blobpush.SetOrigin(Vector(-8900, -2048, -260));
          blobpush.SetAngles(-20, 1, 0);
          EntFire("hatch_door*", "Kill");
          EntFire("relay_hatch", "Kill");
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetOrigin(Vector(-5134, -5172, -671));
          brush.SetSize(Vector(-109, -19, -118), Vector(109, 19, 118));
          ppmod.keyval(brush, "Solid", 3);
          ppmod.keyval(brush, "Targetname", "rev_funnel_brush");
          local trigger = Entities.CreateByClassname("trigger_once");
          trigger.SetOrigin(Vector(-5119, -5120, -666));
          trigger.SetSize(Vector(-131, -26, -81), Vector(131, 26, 81));
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          ppmod.fire(trigger, "Enable");
          ppmod.addoutput(trigger, "OnStartTouch", "!self", "Kill");
          ppmod.addoutput(trigger, "OnStartTouch", "tbeam_crusher_delivery", "Disable");
          ppmod.addoutput(trigger, "OnStartTouch", "rev_funnel_brush", "Kill", "", 1);
          ppmod.addscript(trigger, "OnStartTouch", "rev.level.fixbridge()");
          ppmod.addscript("paint_bomb_maker", "OnEntitySpawned", "rev.level.blob()");
          EntFire("sound_landing_1", "Kill");
          rev.level.bridge();
        }

        rev.loop <- function() {
          if(ppmod.trigger(-10854.6, -2096.25, 77.4912, -10779.3, -2016.03, 206.079, "fin1-door1")){
            EntFire("liftshaft_airlock_exit-proxy","onproxyrelay1");
            EntFire("liftshaft_airlock_exit-proxy","kill");
            EntFire("areaportal_airlock_1","open");
            EntFire("rev_blob_push", "Enable");
          }
          if(ppmod.trigger(-2112.79, -7838.23, -63.9688, -1919.32, -7493.3, 84.3305, "fin1-door2")){
            EntFire("entrance_door-proxy","onproxyrelay2");
            EntFire("entrance_door-proxy","kill");
          }
          if(ppmod.trigger(-432.159, -7716.18, -206.469, -400.158, -7643.82, -165.255, "fin1-end")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a4_jump_polarity", 1);
          }
        }

        rev.level.blob <- function() {
          ppmod.get("prop_paint_bomb").SetOrigin(Vector(-8903,-2047,-188));
          rev.level.blob <- function(){};
        }

        rev.level.bridge <- function() {
          SendToConsole("ent_create prop_wall_projector");
          SendToConsole("ent_create prop_wall_projector");
          local timer = Entities.CreateByClassname("logic_timer");
          while(!timer.ValidateScriptScope());
          local scope = timer.GetScriptScope();
          scope.check <- function() {
            local bridge = ppmod.get("prop_wall_projector");
            if(bridge) {
              bridge.SetOrigin(Vector(-2496, -5120, -126));
              bridge.SetAngles(13.4, 180, 0);
              ppmod.fire(bridge, "Enable");
              ppmod.keyval(bridge, "Targetname", "rev_bridge1");
              bridge = ppmod.get("prop_wall_projector", bridge);
              bridge.SetOrigin(Vector(-2690, -7264, 248));
              bridge.SetAngles(11.3, 90, 0);
              ppmod.fire(bridge, "Enable");
              self.Destroy();
            }
          }
          ppmod.addscript(timer, "OnTimer", "check()");
          ppmod.fire(timer, "Enable");
        }

        rev.level.fixbridge <- function() {
          local pos = GetPlayer().GetOrigin();
          GetPlayer().SetOrigin(pos + Vector(0, 0, 15));
          local bridge = ppmod.get("rev_bridge1");
          bridge.SetAngles(13.1, 180, 0);
          ppmod.fire(bridge, "Enable");
        }

      }
      reverse_maps["sp_a4_finale2"] <- function() {
        rev.setup <- function() {
          EntFire("npc_portal_turret_floor", "Kill");
          ppmod.fire_near("trigger_once", "kill",Vector(-3151,-1792,-319),256);
          EntFire("sound_walkway_break2", "Kill");
          local catwalk = ppmod.get(Vector(-1856, -1216, -512));
          ppmod.fire(catwalk, "EnableMotion");
          GetPlayer().SetOrigin(Vector(-3152, -1792, -319));
          GetPlayer().SetAngles(0, 90, 0);
          ppmod.get(217).Destroy(); // Trap chamber trigger
          EntFire("exit_door-proxy", "onproxyrelay1");
          EntFire("exit_door-proxy", "kill");
          ppmod.fire_near("trigger_once", "kill",Vector(-942.608,-1215.678,-511.969),128);
          ppmod.fire_near("trigger_once", "kill",Vector(3352.304,702.496,-191.969),128);
          EntFire("sound_walkway_creak", "kill");
          EntFire("sound_walkway_land", "kill");
          EntFire("rot_walkway_2", "open");
          EntFire("rot_walkway_4", "open");
          EntFire("walkway_breakpoint", "wake");
          EntFire("sound_walkway_tear", "kill");
          EntFire("shake_walkway_tear", "kill");
          EntFire("shake_chamber_move", "kill");
          EntFire("a4_chamber_fx_a_1", "setanimation", "grind1");
          EntFire("a4_chamber_fx_b_1", "setanimation", "grind1");
          EntFire("a4_armsWall_fx_A_1", "setanimation", "grind1");
          EntFire("a4_chamberArms_fx_a_1", "setanimation", "grind1");
          EntFire("sound_chamber_travel", "kill");
          EntFire("chamber_start_sfx", "kill");
          EntFire("door_swing_sfx", "kill");
          EntFire("shake_chamber", "kill");
          EntFire("relay_chamber_stopped", "trigger");
          EntFire("walkway_push", "kill");
          EntFire("walkway_push_2", "kill");
          local funnel = Entities.FindByClassnameNearest("prop_tractor_beam", Vector(-1084, 477, 163), 128);
          funnel.SetOrigin(Vector(-1088, 448, 0));
          funnel.SetAngles(-90, 0, 0);
          ppmod.fire(funnel, "SetLinearForce", -500);
          ppmod.fire(funnel, "SetLightingOrigin", "crusher_ride_tbeam");
          local sprayer = Entities.FindByName(null, "sprayer_1");
          sprayer.SetOrigin(Vector(-3736, -428, -64));
          sprayer.SetAngles(90, 0, 0);
          ppmod.fire(sprayer, "Start");
          ppmod.fire(sprayer, "Stop", "", 1);
          EntFire("turret_wall-open_upper_panels", "Trigger");
          EntFire("turret_wall-open_upper_panels", "Kill");
          EntFire("detector_portal*", "Kill");
          EntFire("relay_tbeam_escape", "Kill");
          SendToConsole("prop_dynamic_create props_factory/factory_panel_portalable_128x128.mdl");
          SendToConsole("ent_create info_placement_helper");
          EntFire("relay_world_shudder", "Kill");
          EntFire("trigger_crusher_escape", "Kill");
          local trigger = Entities.CreateByClassname("trigger_multiple");
          trigger.SetOrigin(Vector(2166, 575, -100));
          trigger.SetSize(Vector(-21, -85, -79), Vector(21, 85, 79));
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          ppmod.fire(trigger, "Enable");
          ppmod.addscript(trigger, "OnStartTouch", "rev.level.funnelclip_start()");

          SendToConsole("phys_timescale 2");
          EntFire("shake_pipe_fall_crash", "Kill");
          EntFire("sound_megasplat", "Kill");
          EntFire("physbox_pipe_*", "EnableMotion");
          ppmod.wait("SendToConsole(\"phys_timescale 1\")", 5);

          local jumpbrush = ppmod.get(54);
          ppmod.fire(jumpbrush, "ClearParent");
          ppmod.fire(jumpbrush, "SetLocalOrigin", "-2032 -1216 -514");
          ppmod.fire(jumpbrush, "SetLocalAngles", "90 0 0");
          ppmod.fire(jumpbrush, "DisableDraw");

          local jumpbrush_vis = ppmod.get("robo_flopintoplace_09panel");
          ppmod.fire(jumpbrush_vis, "ClearParent");
          ppmod.fire(jumpbrush_vis, "SetLocalOrigin", "-2048 -1216 -512");
          ppmod.fire(jumpbrush_vis, "SetLocalAngles", "78 0 0");
          ppmod.keyval(jumpbrush_vis, "CollisionGroup", 1);

          local idiotbrush = Entities.CreateByClassname("func_brush");
          idiotbrush.SetOrigin(Vector(163, -2400, -512));
          idiotbrush.SetSize(Vector(-323, -40, -4), Vector(323, 40, 11));
          ppmod.keyval(idiotbrush, "Solid", 3);
          idiotbrush = Entities.CreateByClassname("func_brush");
          idiotbrush.SetOrigin(Vector(416, -2249, -512));
          idiotbrush.SetSize(Vector(-40, -111, -4), Vector(40, 111, 11));
          ppmod.keyval(idiotbrush, "Solid", 3);

          // Spinny blade wall... prevention
          ppmod.get(215).Destroy();
          ppmod.get(48).Destroy();
          ppmod.get(463).Destroy();
          ppmod.fire(ppmod.get(289), "Disable");
          ppmod.fire(ppmod.get(458), "Disable");

          SendToConsole("ent_create_paint_bomb_jump");
          SendToConsole("script rev.level.blob()");
        }

        rev.load <- function() {
          ppmod.once("rev.level.panel()");
          ppmod.once("rev.level.helper()");
        }

        rev.loop <- function(){
          if(ppmod.trigger(3864.03, 787.21, -192.249, 3943.97, 1164.43, -184.249, "fin2-end")){
            SendToConsole("fadeout 1");
            ppmod.wait("SendToConsole(\"changelevel sp_a4_finale1\")", 1);
          }
          if(ppmod.trigger(-928.134, -1268.3, -511.969, -782.636, -1160.03, -397.402, "fin2-door1")){
            EntFire("bts_door_2-proxy", "onproxyrelay1");
            EntFire("bts_door_2-proxy", "kill");
            EntFire("movelinear_testchamber", "setspeed", 1000);
            EntFire("movelinear_testchamber", "close", "", FrameTime());
          }
          if(ppmod.trigger(527.979, 666.342, -191.969, 560.359, 743.969, -78.9082, "fin2-door2")){
            EntFire("bts_door_1-proxy", "onproxyrelay1");
            EntFire("bts_door_1-proxy", "kill");
            EntFire("areaportal_airlock_1", "open");
            local fizzler = ppmod.get(Vector(800.420, 704, -127.75));
            ppmod.fire(fizzler, "Disable");
            ppmod.fire(ppmod.get(Vector(801, 704, -135.99), fizzler), "Disable");
          }
          if(ppmod.trigger(609.179, 672.412, -191.969, 845.519, 743.969, -45.8105)){
            EntFire("areaportal_airlock_1", "open");
          }
        }

        rev.level.panel <- function() {
          local brush = ppmod.get(130);
          brush.SetOrigin(Vector(3106, 575.8, -110));
          brush.SetAngles(0, 180 90);
          local panel = ppmod.get("models/props_factory/factory_panel_portalable_128x128.mdl");
          panel.SetOrigin(Vector(3072, 575.8, -110));
          panel.SetAngles(0, 0, 0);
          ppmod.fire(panel, "SetLightingOrigin", "entrance_door-door_1");
          local blocker = Entities.CreateByClassname("func_brush");
          blocker.SetOrigin(Vector(3079, 578, -403));
          blocker.SetSize(Vector(-16, -64, -230), Vector(16, 64, 230));
          ppmod.keyval(blocker, "Solid", 3);
          blocker = Entities.CreateByClassname("func_brush");
          blocker.SetOrigin(Vector(3080, 576, 182));
          blocker.SetSize(Vector(-16, -66, -229), Vector(16, 66, 221));
          ppmod.keyval(blocker, "Solid", 3);
        }

        rev.level.funnelclip_start <- function() {
          SendToConsole("ent_create_portal_weighted_cube");
          SendToConsole("script rev.level.funnelclip()");
        }

        rev.level.funnelclip <- function() {
          local speedmod = Entities.CreateByClassname("player_speedmod");
          ppmod.keyval(speedmod, "Targetname", "rev_speedmod");

          ppmod.fire(speedmod, "ModifySpeed", 0);
          ppmod.keyval(GetPlayer(), "MoveType", 8);

          local cube = ppmod.get("cube");
          ppmod.keyval(cube, "Targetname", "rev_funnelclip_cube");
          ppmod.keyval(cube, "CollisionGroup", 1);
          ppmod.fire(cube, "DisableDraw");
          ppmod.fire(cube, "DisablePickup");
          cube.SetOrigin(GetPlayer().GetOrigin() + Vector(0, 0, 36));
          cube.SetAngles(0, 0, 0);

          local anchor = Entities.CreateByClassname("info_target");
          anchor.SetOrigin(GetPlayer().GetOrigin() + Vector(0, 0, 36));
          ppmod.keyval(anchor, "Targetname", "rev_funnelclip_anchor");
          ppmod.fire(GetPlayer(), "SetParent", "rev_funnelclip_anchor");

          local mirror = Entities.CreateByClassname("logic_measure_movement");
          ppmod.keyval(mirror, "MeasureType", 0);
          ppmod.keyval(mirror, "Targetname", "rev_funnelclip_mirror");
          ppmod.keyval(mirror, "TargetReference", "rev_funnelclip_mirror");
          ppmod.fire(mirror, "SetMeasureReference", "rev_funnelclip_mirror");
          ppmod.fire(mirror, "SetMeasureTarget", "rev_funnelclip_cube");
          ppmod.keyval(mirror, "Target", "rev_funnelclip_anchor");
          ppmod.fire(mirror, "Enable");

          ppmod.wait("rev.level.funnelclip_end()", 0.7);
        }

        rev.level.funnelclip_end <- function() {
          ppmod.fire("rev_speedmod", "ModifySpeed", 1);
          ppmod.keyval(GetPlayer(), "MoveType", 2);
          ppmod.fire("rev_funnelclip_mirror", "Disable");
          ppmod.fire(GetPlayer(), "ClearParent");
          EntFire("rev_funnelclip_cube", "Kill");
        }

        rev.level.helper <- function() {
          local helper = null;
          while(ppmod.get("info_placement_helper", helper)) helper = ppmod.get("info_placement_helper", helper);
          ppmod.keyval(helper, "Radius", 64);
          ppmod.keyval(helper, "Force_Placement", 1);
          helper.SetOrigin(Vector(3065.47, 580, -110));
        }

        rev.level.blob <- function() {
          local blob = ppmod.get("prop_paint_bomb");
          blob.SetOrigin(Vector(-2048, -1216, -388));
        }
      }
      reverse_maps["sp_a4_finale3"] <- function() {
        rev.setup <- function(){
          GetPlayer().SetOrigin(Vector(-635, 5375, 193));
          GetPlayer().SetAngles(0, 0, 0);
          SendToConsole("fog_override 1");
          SendToConsole("fog_end 5000");
          EntFire("door_lair-open_door", "trigger");
          ppmod.fire_near("trigger_once","kill",Vector(-66,-626,-63),128);
          ppmod.fire_near("trigger_once","kill",Vector(-68,-1258,-64),512);
          ppmod.fire_near("trigger_once","kill",Vector(-445,5218,235),128);
          /* EntFire("tractorbeam_emitter", "setlinearforce", 500); */
          EntFire("@exit_elevator_cleanser","disable","",1.8);
          EntFire("fg_wallsmash_trigger","kill");
          EntFire("fg_wallsmash","setanimation","smash_end");
          EntFire("fg_wallsmash","setplaybackrate",50);
          ppmod.get(181).Destroy();
          ppmod.get(109).Destroy();
          ppmod.get(132).Destroy();
          ppmod.get(60).Destroy();
          rev.level.transition <- false;
          rev.level.debris();
          // Prevent backtracking to Finale 4
          ppmod.get(360).Destroy();
          ppmod.get(329).Destroy();
          // Explode conversion gel pipe
          EntFire("practice_pipe_trigger", "Kill");
          EntFire("practice_tube_broken", "Enable");
          EntFire("practice_tube_broken", "SetAnimation", "pipe_explode_fin3_a_anim");
          EntFire("practice_tube_intact", "Kill");
          EntFire("practice_paint_sprayer", "Start");
          EntFire("practice_paint_sprayer", "Stop", "", 2);
          EntFire("fx_blob*", "Stop");
          EntFire("aud_paint_flow", "StopSound");
          // Explode propulsion gel pipe
          EntFire("shake_pipe_break", "Kill");
          EntFire("pipe_explode_relay", "Trigger");
          EntFire("pipe_explode_relay", "Kill");
          // Container crash animation
          EntFire("crash_model*", "Kill");
          EntFire("relay_container_destruction", "Kill");
        }

        rev.loop <- function() {
          if(rev.level.transition && ppmod.trigger(672.031, -2220.69, 128.031, 799.969, -1843.47, 136.031)){
            SendToConsole("fog_override 0");
            SendToConsole("fadeout 1");
            ppmod.wait("SendToConsole(\"changelevel sp_a4_finale2\")", 1);
          }
          if(ppmod.trigger(-93.6667, -669.851, -63.9688, -34.808, -636.07, 62.6508)){
            EntFire("airlock_door2_brush", "kill");
            EntFire("airlock_door2", "setanimation", "vert_door_opening");
          }
          if(ppmod.trigger(-388.316, -2726.56, 128.031, 127.969, -2272.03, 526.779)){
            EntFire("airlock_door2", "setplaybackrate", -1);
          }
        }

        rev.level.teleport <- function() {
          GetPlayer().SetOrigin(Vector(-635, 5375, 193));
          GetPlayer().SetAngles(0, 0, 0);
          rev.level.transition = true;
        }

        rev.level.debris <- function() {
          SendToConsole("prop_dynamic_create props_destruction/debris_metaljunk_01.mdl");
          local timer = Entities.CreateByClassname("logic_timer");
          while(!timer.ValidateScriptScope()); // why am i like this
          local scope = timer.GetScriptScope();
          scope.check <- function() {
            local ent = ppmod.get("models/props_destruction/debris_metaljunk_01.mdl");
            if(ent) {
              ent.SetOrigin(Vector(30, -340, -261));
              ent.SetAngles(0, 90, 0);
              self.Destroy();
              rev.level.teleport(); // this should not be here
            }
          }
          ppmod.addscript(timer, "OnTimer", "check()");
          ppmod.fire(timer, "Enable");
        }
      }
      reverse_maps["sp_a4_finale4"] <- function() {
        rev.setup <- function() {
          // Set up world portals for stalemate room
          SendToConsole("ent_create linked_portal_door");
          SendToConsole("ent_create linked_portal_door");

          // plug potatos into breaker
          EntFire("potatos_template", "ForceSpawn");
          EntFire("@potatos_prop", "DisableShadow");
          EntFire("@potatos_prop", "DisableMotion");
          ppmod.wait("ppmod.get(\"@potatos_prop\").SetOrigin(Vector(9, -16, -2))", 0.1);
          EntFire("player_proxy", "RemovePotatosFromPortalgun");

          // move breaker up to top
          EntFire("breaker_hatch_door", "Open");
          EntFire("basement_breakers_platform", "SetSpeedDir", 1);
          EntFire("basement_breakers_platform", "SetSpeedReal", 100000, 2);

          // kill some nuisance triggers
          EntFire("battle_start_relay", "Kill");
          EntFire("glados_plug_text_relay1", "Kill");
          EntFire("glados_core_text_relay4", "Kill");
          EntFire("breaker_socket_button", "Kill");
          ppmod.fire_near("trigger_once", "Kill", Vector(0, -384, 96), 1);

          // hit stalemate trigger
          GetPlayer().SetOrigin(Vector(0, 1550, 120));
          GetPlayer().SetAngles(45, 90, 0);
          EntFire("stalemate_door", "Kill");
          EntFire("stalemate_gate_rotating", "Kill");
          EntFire("stalemate_door_rotating", "Kill");

          // viewmodel shenanigans
          SendToConsole("r_drawviewmodel 0");
          ppmod.wait("SendToConsole(\"r_drawviewmodel 1\")", 15);

          // place portal next to outline, remove outline before gaining control
          ppmod.wait("SendToConsole(\"portal_place 0 1 0 224 -1 -90 0 0\")", 2);
          EntFire("ending_portal1_particle", "DestroyImmediately", "", 15);

          // wheatley shields
          EntFire("wheatley_shield", "SetAnimation", "idle");

          // paint and pipes
          EntFire("paint_white_event_sphere9", "Paint");
          EntFire("paint_pipe_white_intact_model", "Kill");
          EntFire("paint_pipe_white_model", "Enable");
          EntFire("paint_pipe_white_model", "SetAnimation", "pipe_explode_anim");
          EntFire("catwalk_model", "Kill");
          EntFire("catwalk2_model", "Kill");
          EntFire("catwalk_new_model", "Enable");
          EntFire("walkway_bounce_dest_model", "Kill");
          EntFire("pipe_bounce_model", "Kill");
          EntFire("pipe_bounce_dest_model", "Enable");
          EntFire("pipe_bounce_dest_model", "SetAnimation", "smash");
          EntFire("core1_wall_brush", "Kill");
          EntFire("orange_pipe-pipe_orange_model", "Kill");
          EntFire("paint_pipe_orange_model", "Kill");
          EntFire("paint_pipe_orange_model1", "Kill");
          EntFire("pipe_orange_dest1_model", "Kill");
          EntFire("pipe_orange_dest2_model", "Enable");

          // particles
          EntFire("sprinkler_system", "Start");
          EntFire("background_fire1", "Start", "", 1);
          EntFire("background_fire2", "Start", "", 1);
          EntFire("background_fire3", "Start", "", 1);
          EntFire("background_fire4", "Start", "", 1);
          EntFire("background_fire1_sound", "PlaySound");
          EntFire("background_fire2_sound", "PlaySound");
          EntFire("background_fire3_sound", "PlaySound");
          EntFire("background_fire4_sound", "PlaySound");

          // release the player. and so it begins
          EntFire("ending_vehicle", "unlock", "", 17.0);
          EntFire("ending_vehicle", "exitvehicle", "", 17.0);
          EntFire("ending_gun_model", "kill", "", 17.0);
          EntFire("moon_portal_brush", "kill", 17.0);
          EntFire("!player", "SetLocalOrigin", "529.334 73.915 1", 17.01);

          // Activate stalemate room world portals
          EntFire("rev_wportal*", "Open", "", 17.0);
          // Create floor brush to prevent softlock
          local brush = Entities.CreateByClassname("func_brush");
          brush.SetAbsOrigin(Vector(0, 1610, -36));
          brush.SetSize(Vector(-160, -138, -36), Vector(160, 138, 36));
          brush.__KeyValueFromInt("Solid", 3);
        }

        rev.load <- function() {
          ppmod.once("rev.level.wportal()");
        }

        rev.level.wportal <- function() {
          local p1 = ppmod.get("linked_portal_door");
          local p2 = ppmod.get("linked_portal_door", p1);
          ppmod.keyval(p1, "Targetname", "rev_wportal1");
          ppmod.keyval(p2, "Targetname", "rev_wportal2");
          ppmod.fire(p1, "SetPartner", "rev_wportal2");
          ppmod.fire(p2, "SetPartner", "rev_wportal1");

          p1.SetOrigin(Vector(0, 1271.9, 94));
          p1.SetAngles(0, -90, 0);
          p2.SetOrigin(Vector(0, 1288, 94));
          p2.SetAngles(0, 90, 0);
        }

        rev.loop <- function() {
          if(ppmod.trigger(-48, -92, -1, 47, -31, 8)){
            EntFire("hatch_clip", "kill");
            EntFire("ending_wheatley_model", "kill");
            EntFire("basement_breakers_platform", "setspeeddir", -1);
            EntFire("basement_breakers_platform", "setspeedreal", 150);
            EntFire("@potatos_prop", "kill");
            EntFire("breakers_door_brush", "kill");
            EntFire("breakers_clip_brush", "kill");
            SendToConsole("upgrade_potatogun");
          }
          if(ppmod.trigger(-128, -192, -550, 128, 64, -500)){
            EntFire("boss_music10", "FadeOut", 3);
            EntFire("logic_choreographed_scene", "Cancel");
            ppmod.wait("SendToConsole(\"scene_playvcd npc/sphere03/sp_sabotage_factoryturretonewhere01\")", 0.1);
            ppmod.wait("SendToConsole(\"scene_playvcd npc/glados/potatos_sp_a4_finale01_cameback02\")", 3.0);
          }
          if(ppmod.trigger(-98, -361, -1400, 36, -250, -1277)){
            EntFire("basement_breakers_platform", "setspeeddir", 1);
            EntFire("basement_breakers_platform", "setspeedreal", 150);
          }
          if(ppmod.trigger(-1774, -717, -3008, -1584, -392, -3000)){
            SendToConsole("fadeout 1");
            ppmod.wait("SendToConsole(\"changelevel sp_a4_finale3\")", 1);
          }
        }
      }
      reverse_maps["sp_a4_intro"] <- function() {
        rev.trigger <- function(pos, size) {
          local trigger = Entities.CreateByClassname("trigger_multiple");
          trigger.SetOrigin(pos);
          trigger.SetSize(Vector() - size, size);
          ppmod.keyval(trigger, "Solid", 3);
          ppmod.keyval(trigger, "CollisionGroup", 1);
          ppmod.keyval(trigger, "SpawnFlags", 1);
          return trigger;
        }

        rev.setup <- function() {
          SendToConsole("r_portalsopenall 1");
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          GetPlayer().SetOrigin(Vector(3146.701, -128.429, 369.718));
          GetPlayer().SetAngles(0, 180, 0);
          EntFire("map_end_trigger", "kill");
          EntFire("wheatley_studio-wheatley_rotating", "setlocalorigin", "0 0 100");
          ppmod.fire_near("trigger_once", "kill", Vector(1062.48, 366.699, 185.055), 256);
          EntFire("box_drop_relay","trigger");
          ppmod.addoutput("button_2-button", "OnPressed", "button_box_brush", "Kill", "", 1);
          EntFire("@exit_door2-door_open_relay","kill");
          EntFire("button_1_pressed", "Kill");
          EntFire("button_1_unpressed", "Kill");
          EntFire("indicator_door_toggle", "SetTextureIndex", 1);

          rev.level.ele_up <- false;
          rev.level.ele_isup <- false;
          local uptrig = rev.trigger(Vector(607, 335, 193), Vector(33, 16, 65));
          ppmod.addoutput(uptrig, "OnStartTouch", "rev_ele_down_activate", "Enable");
          ppmod.addoutput(uptrig, "OnStartTouch", "rev_ele_down", "Disable");
          ppmod.addscript(uptrig, "OnStartTouch", "rev.level.ele_tryup()");
          ppmod.fire(uptrig, "Enable");

          local downtrig = rev.trigger(Vector(1056, 384, 506), Vector(64, 64, 4));
          ppmod.addoutput(downtrig, "OnStartTouch", "test_chamber1_platform", "StartBackward");
          ppmod.addscript(downtrig, "OnStartTouch", "rev.level.ele_isup=false");
          ppmod.addoutput(downtrig, "OnStartTouch", "rev_ele_doorblock", "Disable");
          ppmod.addoutput(downtrig, "OnStartTouch", "!self", "Disable");
          ppmod.keyval(downtrig, "Targetname", "rev_ele_down");

          local downtrig_activate = rev.trigger(Vector(1136, 384, 567), Vector(16, 128, 55));
          ppmod.addoutput(downtrig_activate, "OnEndTouch", "rev_ele_down", "Enable");
          ppmod.addscript(downtrig_activate, "OnStartTouch", "rev.level.ele_isup=true");
          ppmod.keyval(downtrig_activate, "Targetname", "rev_ele_down_activate");
          downtrig_activate = rev.trigger(Vector(1056, 288, 567), Vector(64, 32, 55));
          ppmod.addoutput(downtrig_activate, "OnEndTouch", "rev_ele_down", "Enable");
          ppmod.addscript(downtrig_activate, "OnStartTouch", "rev.level.ele_isup=true");
          ppmod.keyval(downtrig_activate, "Targetname", "rev_ele_down_activate");

          local ele_doorblock = Entities.CreateByClassname("func_brush");
          ele_doorblock.SetOrigin(Vector(976, 383, 172));
          ele_doorblock.SetSize(Vector(-16, -42, -44), Vector(16, 42, 44));
          ppmod.keyval(ele_doorblock, "Solid", 3);
          ppmod.keyval(ele_doorblock, "Targetname", "rev_ele_doorblock");
          EntFire("rev_ele_doorblock", "Disable");

          EntFire("wall_panel_01-proxy", "OnProxyRelay1");
          EntFire("wall_panel_01-proxy", "Kill");
        }

        rev.loop <- function() {
          if(ppmod.trigger(2546.52, -166.969, 517.718, 2686.95, -88.9696, 623.167, "69f565da6d4_ppmod")){
            EntFire("@exit_door-testchamber_door", "open");
            EntFire("@exit_door-door_player_clip", "kill");
            EntFire("room2_wall_open", "trigger", "", 1);
          }
          if(ppmod.trigger(994.453, 320.031, 125.531, 1119.97, 447.969, 164.221, "ae5d7cded7_ppmod")){
            EntFire("entrance_door1_relay","trigger");
            EntFire("entrance_door1_relay","kill");
          }
          if(ppmod.trigger(413.568, -127.969, 0.03125, 535.969, 126.001, 158.543, "a4i-door1")){
            EntFire("@exit_door1-testchamber_door", "open");
            EntFire("@exit_door1-door_player_clip", "kill");
            ppmod.fire_near("trigger_portal_cleanser", "disable", Vector(431.326, -13.3421, 0.03125), 256);
            ppmod.fire_near("trigger_portal_cleanser", "disable", Vector(78.0279, 431.388, 0.03125), 256);
            EntFire("cube_bot_model","kill");
          }
          if(rev.level.ele_up && ppmod.trigger(1024, 320.031, 125.531, 1119.97, 447.969, 164.221, null, null, true)){
            EntFire("test_chamber1_platform", "startforward");
            rev.level.ele_up = false;
            EntFire("rev_ele_doorblock", "Enable");
          }
          if(ppmod.trigger(-3.45422, 416.706, 0.03125, 191.969, 608.5, 109.751, "a4i-door2")){
            EntFire("@entrance_door1-testchamber_door","open");
            EntFire("@entrance_door1-door_player_clip","kill")
            EntFire("test_chamber1_platform", "startbackward");
          }
          if(ppmod.trigger(-1254.72, -511.969, 256.031, -1069.7, -447.965, 359.763, "ee7ace73df_ppmod")){
            EntFire("door_0-door_open_relay","trigger");
            EntFire("door_0-door_open_relay","kill");
          }
          if(ppmod.trigger(-1935.84, -516.186, 145.531, -1903.84, -443.816, 186.745, "e2b82b2e3_ppmod")){
            SendToConsole("r_portalsopenall 0");
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("@command", "Command", "changelevel sp_a3_end", 1);
          }
        }

        rev.level.ele_tryup <- function() {
          if(rev.level.ele_isup) {
            EntFire("test_chamber1_platform", "StartBackward");
            rev.level.ele_up = false;
            ppmod.wait("rev.level.ele_up=true", 9.5);
            rev.level.ele_isup = false;
          } else rev.level.ele_up = true;
        }

      }
      reverse_maps["sp_a4_jump_polarity"] <- function() {
        rev.setup <- function() {
          SendToConsole("fadein 1");
          GetPlayer().SetOrigin(Vector(2560, -3080, 224.031));
          GetPlayer().SetAngles(0, -90, 0);
          EntFire("departure_elevator-elevator_1_body", "setplaybackrate", 30, 0.2);
          EntFire("departure_elevator-elevator_playerclip", "kill");
          ppmod.fire_near("trigger_multiple","kill",Vector(2559,-3080,224),128);
          EntFire("exit_door","setanimation","close");
          ppmod.fire_near("trigger_once","kill",Vector(927,2331,384),128);
          ppmod.fire_near("trigger_teleport","kill",Vector(929,2522,384),128);
          ppmod.fire_near("trigger_once","kill",Vector(1346,-63,128),128);

          EntFire("npc_portal_turret_floor", "Kill");

          EntFire("@start_antechamber_destruction", "Trigger");
          EntFire("@entry_door-door_close_relay", "Trigger");
          EntFire("@entry_door-door_close_relay", "Kill");
          ppmod.fire_near("prop_button","press",Vector(1080, 493, 128),128);
          ppmod.fire_near("trigger_once","kill",Vector(2400, -64, 128),512);
          EntFire("antechamber-aud_mega_paint_splat_01","kill");
          EntFire("antechamber-aud_mega_paint_splat_02","kill");
          EntFire("antechamber-SmashSounds","kill");
        }

        rev.load <- function() {
          ppmod.once("rev.level.gel()");
          ppmod.once("rev.level.antechamber()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(2521.03, -3648.08, 372.031, 2598.99, -3546.68, 511.753, "a4jp-entrance1")){
            EntFire("exit_door_to_elevator","open");
          }
          if(ppmod.trigger(2464, -3876, 367, 2656, -3808, 561, "a4jp-entrance2")){
            EntFire("exit_door_to_elevator","close");
          }
          if(ppmod.trigger(2463.93, -4062.71, 368.031, 2656, -3968.36, 480.505, "a4jp-entrancefizz")){
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(2559,-4077,368),128);
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(927,2448,384),128);
          }
          if(ppmod.trigger(2494.58, -4252.19, 368.031, 2623.97, -4096.29, 481.84, "a4jp-entrance3")){
            // from 2512.031 -4237.547 368.031
            // to   880.031 2290.454 384.031
            GetPlayer().SetOrigin(GetPlayer().GetOrigin() + Vector(-1632,6528,16));
          }
          if(ppmod.trigger(864.122, 2276.52, 384.031, 991.969, 2431.97, 502.333, "a4jp-entrance4")){
            EntFire("exit_door","setanimation","open");
          }
          if(ppmod.trigger(1279.92, -189.645, 128.031, 1344.15, 63.9688, 261.591, "a4jp-exit1")){
            EntFire("antechamber_exit", "setanimation", "open");
            EntFire("antechamber_door_sound", "playsound");
            EntFire("fizzler1", "Disable");
          }
          if(ppmod.trigger(2207.96, -191.894, 128.031, 2525.03, 63.9688, 287.826, "a4jp-exit2")){
            EntFire("@entry_door-proxy","onproxyrelay2");
            EntFire("@entry_door-proxy","kill");
          }
          if(ppmod.trigger(3199.84, -100.184, -14.4688, 3231.84, -27.816, 27.7288, "a4jp-end")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("@command", "Command", "changelevel sp_a4_speed_tb_catch", 1);
          }
        }

        rev.level.gel <- function() {
          local sprayer = ppmod.get("paint_sprayer");
          sprayer.SetOrigin(Vector(928, 1032, 1000));
          sprayer.SetAngles(90, 0, 0);
          ppmod.fire(sprayer, "Start");
          ppmod.fire(sprayer, "Stop", "", 1);
        }

        rev.level.antechamber <- function() {
          EntFire("antechamber_exit", "SetAnimation", "close");
        }
      }
      reverse_maps["sp_a4_laser_catapult"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          GetPlayer().SetOrigin(Vector(1252, -510, 369));
          GetPlayer().SetAngles(0, 180, 0);
          EntFire("wheatley_monitor_1-proxy","kill");
          EntFire("@exit_door-door_close_relay","kill");
          EntFire("huge_rumble", "Kill");
          for(local i = 1; i <= 4; i++) {
            EntFire("exit_panel_"+i+"-proxy", "OnProxyRelay1");
            EntFire("exit_panel_"+i+"-proxy", "Kill");
          }
        }

        rev.loop <- function() {
          if(ppmod.trigger(-1216.41, -474.376, 0, -1049.79, -320.031, 180.307, "42fbbdc69a_ppmod")){
            EntFire("@entry_door-proxy", "onproxyrelay2");
            EntFire("@entry_door-proxy", "kill");
          }
          if(ppmod.trigger(-1188.18, -1167.84, -142.469, -1115.82, -1135.84, -99.4298, "816cd9b09c_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("@command", "Command", "changelevel sp_a4_stop_the_box", 1);
          }
        }
      }
      reverse_maps["sp_a4_laser_platform"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          GetPlayer().SetOrigin(Vector(3470, -1055, -2512));
          EntFire("huge_rumble_1", "Kill");
          EntFire("wheatley_monitor_1-proxy","kill");
          EntFire("open_tb_catch_relay", "trigger");
          EntFire("open_tb_catch_relay", "kill");
          for(local i = 0; i < 5; i++) SendToConsole("prop_dynamic_create props/de_train/ladderaluminium.mdl");
          SendToConsole("prop_dynamic_create props/faith_plate.mdl");
          EntFire("office_ceiling_phys_tiles","kill");
          ppmod.fire_near("trigger_once", "kill", Vector(2249,-591,-130), 128);
          EntFire("falling_ceiling_tiles_relay","kill");
          SendToConsole("ent_create prop_wall_projector");
          local funnelhelp = Entities.CreateByClassname("func_brush");
          funnelhelp.SetOrigin(Vector(109, -625, -140));
          funnelhelp.SetSize(Vector(-20, -100, -106), Vector(20, 100, 106));
          ppmod.keyval(funnelhelp, "Solid", 3);
          ppmod.keyval(funnelhelp, "Targetname", "rev_funnel_help");
          EntFire("lightcage_power_timer_2", "Kill");
          EntFire("@domayhem", "Kill");
          EntFire("glados_destruction", "Kill");
          EntFire("moving_chamber_alarm", "Kill");
          EntFire("fall_fade", "Kill");

          SendToConsole("ent_create_portal_reflector_cube");
          ppmod.get(256).Destroy(); // Entrance door trigger
          ppmod.addoutput("close_exit_relay", "OnTrigger", "entrance_door-proxy", "OnProxyRelay2");
          ppmod.addoutput("open_exit_relay", "OnTrigger", "entrance_door-proxy", "OnProxyRelay1");
          ppmod.addoutput("box_drop_button", "OnPressed", "cube", "Dissolve");
        }

        rev.load <- function() {
          ppmod.once("rev.level.props()");
          ppmod.once("rev.level.bridge()");
          ppmod.once("rev.level.cube()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(3440, -1183.97, -2475.25, 3460, -1125.06, -2450, null, null, true)){
            GetPlayer().SetVelocity(Vector(0,-200,400));
          }
          if(ppmod.trigger(2346.26, -612.701, -2033.23, 2378.26, -580.701, -2025.23, null, null, true)){
            GetPlayer().SetVelocity(Vector(0,0,1500));
          }
          if(ppmod.trigger(2228.59, -649.417, -327.762, 2447.19, -547.978, -87.9041, "db342f763a2_ppmod")){
            EntFire("tbeam", "enable");
            EntFire("tbeam", "setlinearforce", -700);
          }
          if(ppmod.trigger(166, -686, -233, 202, -536, -53, "a4lp_tb_disable")) {
            EntFire("tbeam", "disable");
            EntFire("rev_funnel_help", "disable", "", 1);
          }
          if(ppmod.trigger(115.554, -1118.05, -28.9452, 199.969, -933.276, 113.813, "12944caa4a2_ppmod")){
            SendToConsole("portal_place 0 0 -64.461 -1152.031 328.031 0 -90 0");
            SendToConsole("portal_place 0 1 895.969 -1472 192 0 180 0");
            EntFire("@exit_elevator_cleanser", "Disable");
          }
          if(ppmod.trigger(-1199.84, -1284.19, -142.469, -1167.84, -1211.82, -100.009, "e1d42fd4a6_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("@command", "Command", "changelevel sp_a4_laser_catapult", 1);
          }

          // Long ladder logic
          if(ppmod.trigger(2592, -1108, -2400, 2596, -1086, -1895, null, "ladder_climb", true)) {
            local vel = GetPlayer().GetVelocity();
            vel.z = 150;
            vel.x = 5;
            vel.y = 0;
            GetPlayer().SetVelocity(vel);
          } else if(ppmod.trigger(2596.1, -1108, -2400, 2597, -1086, -1895, null, "ladder_hold", true)) {
            local vel = GetPlayer().GetVelocity();
            vel.z = 10;
            if(vel.x < 0) vel.x = -50;
            else vel.x = 0;
            if(vel.y > 0) vel.y -= 5;
            if(vel.y < 0) vel.y += 5;
            if(abs(vel.y) < 5) vel.y = 0;
            GetPlayer().SetVelocity(vel);
          }
        }

        rev.level.props <- function() {
          local ladder = Entities.FindByModel(null, "models/props/de_train/ladderaluminium.mdl");
          ladder.SetOrigin(Vector(3450, -1167, -2428));
          ladder.SetAngles(-20, 90, 0);

          for(local i = 0; i < 4; i++) {
            ladder = Entities.Next(ladder);
            ladder.SetOrigin(Vector(2593.1, -1097, -2315 + 126 * i));
            ladder.SetAngles(0, 180, 0);
          }

          local plate = Entities.FindByModel(ladder,"models/props/faith_plate.mdl");
          plate.SetOrigin(Vector(2366, -596, -2040));
          plate.SetAngles(0, 0, 0);
        }

        rev.level.bridge <- function() {
          local bridge = ppmod.get("prop_wall_projector");
          bridge.SetOrigin(Vector(164, 0, -550));
          bridge.SetAngles(-28.5, -90, 0);
          ppmod.fire(bridge, "Disable");
          ppmod.fire(bridge, "DisableDraw");
          ppmod.fire(bridge, "Enable", "", 1);
          ppmod.fire(bridge, "EnableDraw", "", 1);
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube");
          cube.SetOrigin(Vector(-64.688, -2412.812, 277.938));
          cube.SetAngles(0, 73.16894, 0);
          ppmod.fire(cube, "Sleep");
          ppmod.addoutput("prop_button", "OnPressed", "cube", "Fizzle");
        }

      }
      reverse_maps["sp_a4_speed_tb_catch"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          GetPlayer().SetOrigin(Vector(-2240, -197, -144));
          GetPlayer().SetAngles(0, 90, 0);
          ppmod.fire_near("trigger_once","kill",Vector(-604,1677-192),512);
          EntFire("eggbot","kill");
          EntFire("shake_chamber_move","kill");
          EntFire("sound_start_move_chamber","kill");
          EntFire("chamber_sfx_end","kill");
          EntFire("chamber_sfx.l","kill");
          EntFire("chamber_sfx.r","kill");
          EntFire("relay_chamber_move", "trigger");
          EntFire("chamber_exit","setspeed",999999, 0.07);
          EntFire("chamber_exit","open","", 0.07);
          EntFire("shake_chamber","kill");
          ppmod.fire_near("prop_button","press",Vector(-129,1102,-192),64);
          EntFire("ramp_look_trigger", "Kill");
          EntFire("ramp_up", "Trigger");
          EntFire("ramp_down", "Trigger");
          EntFire("robo_block*", "SetPlaybackRate", 1000, FrameTime()*2);
          EntFire("robo_straight*", "SetPlaybackRate", 1000, FrameTime()*2);
          EntFire("vid_arm_big*", "SetPlaybackRate", 1000, FrameTime()*2);
          EntFire("rubble_pile_on_ramp", "SetPlaybackRate", 1000, FrameTime()*2);
        }

        rev.loop <- function() {
          if(ppmod.trigger(-735.969, 1760.03, -191.969, -480.031, 1983.97, -183.969, "s4stc-end")){
            SendToConsole("fadeout 1");
            EntFire("@command", "Command", "changelevel sp_a4_laser_platform", 1);
          }
          if(ppmod.trigger(-2278.97, 159.796, -43.2654, -2200.85, 367.426, 173.505, "a4stc-entrance1")){
            EntFire("exit_door-proxy","onproxyrelay2");
            EntFire("exit_door-proxy","kill");
            EntFire("eggbot_trigger","kill");
            SendToConsole("portal_place 0 0 255.998 1600 607.969 90 -1.015 0; portal_place 0 1 -2064.205 2575.969 63.561 0 -90 0");
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(-2238,383,4),128);

            local cube = ppmod.get("cube_dropper-cube_dropper_box");
            cube.SetOrigin(Vector(-255, 1535, -136));
            cube.SetAngles(0, 0, 0);
          }
        }

      }
      reverse_maps["sp_a4_stop_the_box"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("wheatley_monitor-proxy", "Kill");
          GetPlayer().SetOrigin(Vector(905, -800, 753));
          GetPlayer().SetAngles(0, 180, 0);
          local button = Entities.FindByName(null,"button_1-button");
          ppmod.addoutput(button, "OnPressed", "door_0-door_close_relay", "Trigger");
          ppmod.addoutput(button, "OnUnPressed", "door_0-door_open_relay", "Trigger");
          EntFire("@cube_dropper", "Trigger");
          ppmod.addscript("flingroom_1_circular_catapult_1", "OnCatapulted", "rev.level.cube()");
          ppmod.get(60).Destroy(); // Lights trigger
          ppmod.get(90).Destroy(); // Animation trigger
        }

        rev.loop <- function() {
          if(ppmod.trigger(96.0312, -736, 896.031, 224.015, -484.547, 1016.01, "10eff8c89e_ppmod")){
            rev.level.enter();
          }
          if(ppmod.trigger(-943.841, 891.814, 497.531, -911.84, 964.184, 536.832, "8602279fba5_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("prop_monster_box","dissolve");
            EntFire("@command", "Command", "changelevel sp_a4_tb_catch", 1);
          }
        }

        rev.level.enter <- function() {
          local cube = ppmod.get("cube_dropper-cube_dropper_box");
          ppmod.fire(cube, "EnableMotion");
          ppmod.fire(cube, "Wake");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube_dropper-cube_dropper_box");
          cube.SetOrigin(Vector(640, 447, 535));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
          rev.level.cube <- function(){};
        }
      }
      reverse_maps["sp_a4_tb_catch"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("wheatley_monitor_1-proxy","kill");
          GetPlayer().SetOrigin(Vector(1443.341, 896.454, 144.5));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("trigger_once","kill",Vector(79.642,-1409.508,-95.974),256);
          local button = Entities.FindByClassnameNearest("prop_floor_button",Vector(705,1183,300),64);
          ppmod.addoutput(button, "OnPressed", "door_0-door_close_relay", "Trigger");
          ppmod.addoutput(button, "OnUnPressed", "door_0-door_open_relay", "Trigger");
          ppmod.get(Vector(944, 896, 320)).Destroy();
          EntFire("@cube_dropper", "Trigger");
          ppmod.addscript("cube_dropper-cube_dropper_droptrigger", "OnStartTouch", "rev.level.cube()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(866.215, 857.031, 232.985, 1089.83, 935.004, 477.794, "6ff25a3b69e_ppmod")){
            local cube = ppmod.get("cube_dropper-cube_dropper_box");
            ppmod.fire(cube, "EnableMotion");
            ppmod.fire(cube, "Wake");
          }
          if(ppmod.trigger(911.841, -1444.18, -238.469, 943.841, -1371.82, -195.43, "9232b0e219e_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("@command", "Command", "changelevel sp_a4_tb_polarity", 1);
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube_dropper-cube_dropper_box");
          cube.SetOrigin(Vector(704, 1186, 342));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
          rev.level.cube <- function(){};
        }
      }
      reverse_maps["sp_a4_tb_intro"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("monitor1-proxy","kill");
          GetPlayer().SetOrigin(Vector(2796.971, 736.488, -111.969));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("trigger_once","kill",Vector(1106.87, 417.277, -511.969),256);
          rev.level.solved <- false;
          local button = Entities.FindByName(null,"ceiling_button");
          ppmod.addoutput(button, "OnPressed", "door_0-door_close_relay", "Trigger");
          ppmod.addscript(button, "OnPressed", "rev.level.solved = false");
          ppmod.addoutput(button, "OnUnPressed", "door_0-door_open_relay", "Trigger");
          ppmod.addscript(button, "OnUnPressed", "rev.level.solved = true");
          ppmod.get(60).Destroy();
        }

        rev.loop <- function() {
          if(ppmod.trigger(2201.8, 697.031, -30.2131, 2444.63, 774.992, 179.468, "a054d051298_ppmod")){
            SendToConsole("portal_place 0 0 1664.000 512.000 543.969 90.000 179.711 0.000; portal_place 0 1 1664.000 896.000 -511.969 -90.000 -90.486 0.000");
            Entities.FindByName(null,"monster_box").SetOrigin(Vector(1664,896,-57));
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector( 2193.360, 736.154, 36.031),512);
          }
          if(!rev.level.solved && ppmod.trigger(1024.01, 258.454, -511.969, 1219.01, 351.589, -338.808, null, null, true)){
            ScriptShowHudMessageAll("This level has to be unsolved to proceed!", FrameTime());
          }
          if(ppmod.trigger(1083.82, -431.841, -654.469, 1156.18, -399.841, -620.993, "a65536527a0_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("prop_monster_box","dissolve");
            EntFire("@command", "Command", "changelevel sp_a4_intro", 1);
          }
        }
      }
      reverse_maps["sp_a4_tb_polarity"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("wheatley_monitor_1-proxy","kill");
          GetPlayer().SetOrigin(Vector(-126.516, -714.947, 112.031));
          GetPlayer().SetAngles(0, 90, 0);
          EntFire("@exit_door-close_door_rl","kill");
          EntFire("door_0-close_door_rl","kill");
          EntFire("turret_1","kill");
          ppmod.wait("rev.level.cube()", 1);
        }

        rev.loop <- function() {
          if(ppmod.trigger(-480.488, 1534.57, 0.03125, -288.031, 1789.55, 88.733, "ce92fa07aa3_ppmod")){
            EntFire("door_0-door_open_relay","trigger");
            EntFire("door_0-door_open_relay","kill");
          }
          if(ppmod.trigger(-420.183, 2447.84, -142.469, -347.816, 2479.84, -99.4298, "eeb2ff9f6a3_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("prop_monster_box","dissolve");
            EntFire("@command", "Command", "changelevel sp_a4_tb_wall_button", 1);
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("cube_dropper-cube_dropper_box");
          cube.SetOrigin(Vector(247.875, 1750.469, 18.5));
          cube.SetAngles(295, 42, 0);
        }
      }
      reverse_maps["sp_a4_tb_trust_drop"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("wheatley_monitor-proxy","kill");
          GetPlayer().SetOrigin(Vector(1131.332, 449.185, 784.031));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("trigger_once","kill",Vector(320.510,1073.010,841.245),256);
          local button = Entities.FindByName(null,"button_1-button");
          ppmod.addoutput(button, "OnPressed", "door_0-door_close_relay", "Trigger");
          ppmod.addoutput(button, "OnUnPressed", "door_0-door_open_relay", "Trigger");
          EntFire("@cube_dropper", "Trigger");
          ppmod.addscript("dropper-cube_dropper_droptrigger", "OnStartTouch", "rev.level.cube()");
          ppmod.addscript(button, "OnPressed", "rev.level.box()", 0.5);
          ppmod.get(12).Destroy(); // Exit door close trigger
          ppmod.get(73).Destroy(); // Placement helper
          EntFire("@glados", "RunScriptCode", "wheatley_jolt<-function(){}");

          SendToConsole("prop_dynamic_create props_ingame/arm_4panel.mdl");
          SendToConsole("prop_dynamic_create props_ingame/arm_4panel.mdl");
          SendToConsole("prop_dynamic_create a4_destruction/fin4_fencegrate_dyn.mdl")
        }

        rev.loop <- function() {
          if(ppmod.trigger(535.158, 409.031, 868.253, 776.927, 487.011, 1074.16, "1064189e5a2_ppmod")){
            SendToConsole("portal_place 0 0 351.998 1023.969 160.000 -0.000 -90.000 -0.000; portal_place 0 1 -192.000 448.000 928.031 -90.000 0.576 0.000");
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(528.232,447.329,932.031),512);
            local cube = ppmod.get("rev_cube");
            ppmod.fire(cube, "EnableMotion");
            ppmod.fire(cube, "Wake");
          }
          if(ppmod.trigger(283.816, 1935.84, 657.531, 356.184, 1967.84, 700.57, "a8e4926f6ab_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("prop_monster_box","dissolve");
            EntFire("@command", "Command", "changelevel sp_a4_tb_intro", 1);
          }
        }

        rev.load <- function() {
          local panel = ppmod.get("models/props_ingame/arm_4panel.mdl");
          panel.SetOrigin(Vector(384, 576, 928));
          panel.SetAngles(0, 0, 0);
          panel = Entities.Next(panel);
          panel.SetOrigin(Vector(384, 704, 928));
          panel.SetAngles(0, 0, 0);
          local grate = ppmod.get("models/a4_destruction/fin4_fencegrate_dyn.mdl");
          grate.SetOrigin(Vector(448, 640, 920));
          grate.SetAngles(0, 0, 90);
          ppmod.keyval(grate, "CollisionGroup", 1);
          ppmod.fire(grate, "SetLightingOrigin", "dropper-cube_dropper_prop");
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("dropper-cube_dropper_box");
          cube.SetOrigin(Vector(-192,448,1120));
          cube.SetAngles(0, 0, 0);
          ppmod.fire(cube, "DisableMotion");
          ppmod.keyval(cube, "Targetname", "rev_cube");
          rev.level.cube <- function(){};
        }

        rev.level.box <- function() {
          local cube = ppmod.get("rev_cube");
          ppmod.fire(cube, "BecomeBox");
          ppmod.keyval(cube, "Targetname", "dropper-cube_dropper_box");
          rev.level.box <- function(){};
        }
      }
      reverse_maps["sp_a4_tb_wall_button"] <- function() {
        rev.setup <- function() {
          EntFire("departure_elevator-in_elevator","kill");
          EntFire("departure_elevator-elevator_playerclip","kill");
          EntFire("departure_elevator-elevator_1_body", "kill");
          EntFire("@transition_from_map", "kill");
          EntFire("wheatley_monitor-proxy","kill");
          GetPlayer().SetOrigin(Vector(1291.287, 960.062, -15.969));
          GetPlayer().SetAngles(0, 180, 0);
          ppmod.fire_near("trigger_once","kill",Vector(159.686, 2095.87, 0.03125),256);
          local button = ppmod.get("button_1-button");
          ppmod.addoutput(button, "OnPressed", "door_0-door_close_relay", "Trigger");
          ppmod.addoutput(button, "OnUnPressed", "door_0-door_open_relay", "Trigger");
          EntFire("wall_collapse_sfx", "kill");
          EntFire("sound_start_move_chamber", "kill");
          EntFire("sound_warmup_move_chamber", "kill");
          EntFire("sound_spark", "kill");
          EntFire("sound_chamber_scrape1", "kill");
          EntFire("sound_chamber_scrape2", "kill");
          EntFire("sound_chamber_impact1", "kill");
          EntFire("sound_chamber_impact2", "kill");
          EntFire("shake_chamber","kill");
          EntFire("shake_chamber_move","kill");
          EntFire("shake_chamber_first_impact","kill");
          EntFire("move_wall", "open");
          EntFire("move_wall", "setspeed", 999999);
          EntFire("rubble_dynamic","enable");
          for(i <- 1; i <= 12; i++) EntFire("wallPanel_"+i,"kill");
          ppmod.fire_near("trigger_once","kill",Vector(31.969,1681.794,0.031),256);
          EntFire("AutoInstance2-@cube_dropper", "Trigger");
          ppmod.addscript("AutoInstance2-cube_dropper_droptrigger", "OnStartTouch", "rev.level.cube()");
        }

        rev.loop <- function() {
          if(ppmod.trigger(694.494, 921.031, 60.4047, 948.699, 999.032, 256.798, "tbw-entrance")){
            SendToConsole("portal_place 0 0 32.000 1535.969 320 0 -90 0; portal_place 0 1 -471.969 960 446.469 0 0 0");
            ppmod.fire_near("trigger_portal_cleanser","disable",Vector(687.893,954.578,132.031),512);
            EntFire("tractorbeam_emitter", "enable");
            local cube = ppmod.get("AutoInstance2-cube_dropper_box");
            ppmod.fire(cube, "EnableMotion");
            ppmod.fire(cube, "Wake");
            ppmod.fire("AutoInstance2-cube_dropper_box", "BecomeBox", "", 3);
          }
          if(ppmod.trigger(911.841, 2075.82, -142.469, 943.841, 2148.18, -112.906, "cb63e7989ac_ppmod")){
            SendToConsole("fadeout 1");
            EntFire("arrival_elevator-close", "trigger");
            EntFire("prop_monster_box","dissolve");
            EntFire("@command", "Command", "changelevel sp_a4_tb_trust_drop", 1);
          }
        }

        rev.level.cube <- function() {
          local cube = ppmod.get("AutoInstance2-cube_dropper_box");
          cube.SetOrigin(Vector(488, 960, 455));
          cube.SetAngles(0, 90, 0);
          ppmod.fire(cube, "DisableMotion");
          rev.level.cube <- function(){};
        }
      }
      reverse_maps[GetMapName()]();
      rev.setup();
      EntFire("func_areaportal*", "Open");
      ppmod.keyval("func_areaportal*", "Targetname", "");
      SendToConsole("developer 1");
      SendToConsole("con_drawnotify 0");
      SendToConsole("map_wants_save_disable 0");
      SendToConsole("snd_setmixer potatosVO vol .001; snd_setmixer gladosVO vol .001; snd_setmixer announcerVO vol .001; snd_setmixer wheatleyVO vol .001; snd_setmixer caveVO vol .001; snd_setmixer coreVO vol .001");
      if("loop" in rev) ppmod.interval("rev.loop()", 0);
      if("load" in rev) SendToConsole("script rev.load()");
      if(ppmod.get("challenge_mode_end_node")) {
        EntFire("challenge_mode_end_node", "Kill");
        SendToConsole("sv_cheats 1");
      }

    }

  }

}

// Stops P2SM from screaming about missing functions.
local nfunc = function(){};
AddModeFunctions("reverse", nfunc, nfunc, nfunc, nfunc);
