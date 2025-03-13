// If you're here to read the code, I'd suggest looking at the Spplice repository instead. This is messy.

if("ppmod" in this) return;
::ppmod <- {};
::min <- function(a, b) return a > b ? b : a;
::max <- function(a, b) return a < b ? b : a;
::round <- function(a, b = 0) return floor(a * (b = pow(10, b)) + 0.5) / b;

ppmod.fire <- function(ent, action = "Use", value = "", delay = 0, activator = null, caller = null) {
  if(typeof ent == "string") EntFire(ent, action, value, delay, activator);
  else EntFireByHandle(ent, action, value.tostring(), delay, activator, caller);
}

ppmod.keyval <- function(ent, key, val) {
  if(typeof ent == "string") {
    for(local curr = ppmod.get(ent); curr; curr = ppmod.get(ent, curr)) {
      ppmod.keyval(curr, key, val);
    }
  } else switch (typeof val) {
    case "integer":
    case "bool":
      ent.__KeyValueFromInt(key, val.tointeger());
      break;
    case "float":
      ent.__KeyValueFromFloat(key, val);
      break;
    case "Vector":
      ent.__KeyValueFromVector(key, val);
      break;
    default:
      ent.__KeyValueFromString(key, val.tostring());
  }
}

ppmod.addoutput <- function(ent, output, target, input = "Use", value = "", delay = 0, max = -1) {
  if(typeof target == "instance") {
    if(!target.GetName().len()) target.__KeyValueFromString("Targetname", UniqueString("noname"));
    target = target.GetName();
  }
  ppmod.keyval(ent, output, target+"\x1B"+input+"\x1B"+value+"\x1B"+delay+"\x1B"+max);
}

ppmod.scrq <- {};
ppmod.scrq_add <- function(scr) {
  local qid = UniqueString();
  if(typeof scr == "string") scr = compilestring(scr);
  ppmod.scrq[qid] <- scr;
  return { id = qid, name = "ppmod.scrq[\"" + qid + "\"]" };
}

ppmod.addscript <- function(ent, output, scr = "", delay = 0, max = -1, del = false) {
  if(typeof scr == "function")
    if(!del) scr = ppmod.scrq_add(scr).name + "()";
    else scr = "(delete " + ppmod.scrq_add(scr).name + ")()";
  ppmod.keyval(ent, output, "!self\x001BRunScriptCode\x1B"+scr+"\x1B"+delay+"\x1B"+max);
}

ppmod.wait <- function(scr, sec, name = null) {
  local relay = Entities.CreateByClassname("logic_relay");
  if(name) relay.__KeyValueFromString("Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  EntFireByHandle(relay, "Trigger", "", sec, null, null);
  relay.__KeyValueFromInt("SpawnFlags", 1);
  return relay;
}

ppmod.interval <- function(scr, sec = 0, name = null) {
  if(!name) name = scr.tostring();
  local timer = Entities.CreateByClassname("logic_timer");
  timer.__KeyValueFromString("Targetname", name);
  ppmod.addscript(timer, "OnTimer", scr);
  EntFireByHandle(timer, "RefireTime", sec.tostring(), 0, null, null);
  EntFireByHandle(timer, "Enable", "", 0, null, null);
  return timer;
}

ppmod.once <- function(scr, name = null) {
  if(!name) name = scr.tostring();
  if(Entities.FindByName(null, name)) return;
  local relay = Entities.CreateByClassname("logic_relay");
  relay.__KeyValueFromString("Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  EntFireByHandle(relay, "Trigger", "", 0, null, null);
  return relay;
}

ppmod.get <- function(key, ent = null, arg = 1) {
  local fnd = null;
  switch (typeof key) {
    case "string":
      if(fnd = Entities.FindByName(ent, key)) return fnd;
      if(fnd = Entities.FindByClassname(ent, key)) return fnd;
      return Entities.FindByModel(ent, key);
    case "Vector":
      if(typeof ent != "string") return Entities.FindInSphere(ent, key, arg);
      if(fnd = Entities.FindByClassnameNearest(ent, key, arg)) return fnd;
      return Entities.FindByNameNearest(ent, key, arg);
    case "integer":
      while((ent = Entities.Next(ent)).entindex() != key);
      return ent;
    case "instance":
      return Entities.Next(key);
    default: return null;
  }
}

ppmod.prev <- function(key, ent = null, arg = 1) {
  local curr = null, prev = null;
  while((curr = ppmod.get(key, curr, arg)) != ent) prev = curr;
  return prev;
}

ppmod.player <- {
  enable = function(func = function(){}) {
    proxy <- Entities.FindByClassname(null, "logic_playerproxy");
    if(!proxy) proxy = Entities.CreateByClassname("logic_playerproxy");
    eyes <- Entities.CreateByClassname("logic_measure_movement");
    eyes.__KeyValueFromInt("MeasureType", 1);
    eyes.__KeyValueFromString("Targetname", "ppmod_eyes");
    eyes.__KeyValueFromString("TargetReference", "ppmod_eyes");
    eyes.__KeyValueFromString("Target", "ppmod_eyes");
    EntFireByHandle(eyes, "SetMeasureReference", "ppmod_eyes", 0, null, null);
    EntFireByHandle(eyes, "SetMeasureTarget", "!player", 0, null, null);
    EntFireByHandle(eyes, "Enable", "", 0, null, null);
    eyes_vec <- function() {
      local ang = eyes.GetAngles() * (PI / 180);
      return Vector(cos(ang.y) * cos(ang.x), sin(ang.y) * cos(ang.x), -sin(ang.x));
    }
    landrl <- Entities.CreateByClassname("logic_relay");
    ppmod.player.surface();
    gameui <- Entities.CreateByClassname("game_ui");
    gameui.__KeyValueFromString("Targetname", "ppmod_gameui");
    gameui.__KeyValueFromInt("FieldOfView", -1);
    EntFireByHandle(gameui, "Activate", "", 0, GetPlayer(), null);
    local script = ppmod.scrq_add(func).name;
    EntFireByHandle(proxy, "RunScriptCode", "(delete " + script + ")()", 0, null, null);
  }
  surface = function(ent = null) {
    if(ent == null) {
      EntFire("ppmod_surface", "Kill");
      ppmod.give("env_player_surface_trigger", ppmod.player.surface);
    } else {
      EntFireByHandle(ppmod.player.landrl, "Trigger", "", 0, null, null);
      ent.__KeyValueFromInt("GameMaterial", 0);
      ent.__KeyValueFromString("Targetname", "ppmod_surface");
      ent.__KeyValueFromString("OnSurfaceChangedFromTarget", "!self\x001BRunScriptCode\x001Bppmod.player.surface()\x001B0\x001B-1");
    }
  }
  holding = function(func) {
    local filter = Entities.CreateByClassname("filter_player_held");
    local relay = Entities.CreateByClassname("logic_relay");
    local script = ppmod.scrq_add(func).name;
    local name = UniqueString("ppmod_holding");
    filter.__KeyValueFromString("Targetname", name);
    filter.__KeyValueFromString("OnPass", "!self\x001BRunScriptCode\x001B(delete " + script + ")(true)\x001B0\x001B1");
    filter.__KeyValueFromString("OnPass", "!self\x001BKill\x1B\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser1", name + "\x001BRunScriptCode\x001B(delete " + script + ")(false)\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser1", "!self\x001BOnUser2\x1B\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser2", "!self\x001BKill\x1B\x001B0\x001B1");
    for(local ent = Entities.First(); ent; ent = Entities.Next(ent)) {
      EntFireByHandle(filter, "TestActivator", "", 0, ent, null);
    }
    EntFireByHandle(relay, "FireUser1", "", 0, null, null);
    EntFireByHandle(relay, "Kill", "", 0, null, null);
  }
  jump = function(scr) { ppmod.addscript(proxy, "OnJump", scr) }
  land = function(scr) { ppmod.addscript(landrl, "OnTrigger", scr) }
  duck = function(scr) { ppmod.addscript(proxy, "OnDuck", scr) }
  unduck = function(scr) { ppmod.addscript(proxy, "OnUnDuck", scr) }
  input = function(str, scr) {
    if(str[0] == '+') str = "pressed" + str.slice(1);
    else str = "unpressed" + str.slice(1);
    ppmod.addscript(gameui, str, scr);
  }
  movesim = function(move, ftime = null, accel = 10, fric = 0, ground = Vector(0, 0, -1), grav = Vector(0, 0, -600), eyes = null) {
    if(ftime == null) ftime = FrameTime();
    if(eyes == null) eyes = ppmod.player.eyes;
    local vel = GetPlayer().GetVelocity();
    local mask = Vector(fabs(ground.x), fabs(ground.y), fabs(ground.z));

    if(fric > 0) {
      local veldir = Vector(vel.x, vel.y, vel.z);
      local absvel = veldir.Norm();
      if(absvel >= 100) {
        vel *= 1 - ftime * fric;
      } else if(fric / 0.6 < absvel) {
        vel -= veldir * (ftime * 400);
      } else if(absvel > 0) {
        vel = Vector(vel.x * mask.x, vel.x * mask.y, vel.x * mask.z);
      }
    }

    local forward = eyes.GetForwardVector();
    local left = eyes.GetLeftVector();
    forward -= Vector(forward.x * mask.x, forward.y * mask.y, forward.z * mask.z);
    left -= Vector(left.x * mask.x, left.y * mask.y, left.z * mask.z);

    forward.Norm();
    left.Norm();

    local wishvel = Vector();
    wishvel.x = forward.x * move.x + left.x * move.y;
    wishvel.y = forward.y * move.x + left.y * move.y;
    wishvel.z = forward.z * move.x + left.z * move.y;
    wishvel -= Vector(wishvel.x * mask.x, wishvel.y * mask.y, wishvel.z * mask.z);
    local wishspeed = wishvel.Norm();

    local vertvel = Vector(vel.x * mask.x, vel.y * mask.y, vel.z * mask.z);
    vel -= vertvel;
    local currspeed = vel.Dot(wishvel);

    local addspeed = wishspeed - currspeed;
    local accelspeed = accel * ftime * wishspeed;
    if(accelspeed > addspeed) accelspeed = addspeed;

    local finalvel = vel + wishvel * accelspeed + vertvel + grav * ftime;

    local relay = Entities.FindByName(null, "ppmod_movesim_relay");
    if(relay) {
      GetPlayer().SetVelocity(finalvel);
      EntFireByHandle(relay, "CancelPending", "", 0, null, null);
      EntFireByHandle(relay, "Trigger", "", ftime, null, null);
      local gravtrig = Entities.FindByName(null, "ppmod_movesim_gravtrig");
      gravtrig.SetAbsOrigin(GetPlayer().GetCenter());
    } else {
      ppmod.give("trigger_gravity", function(gravtrig, vel = finalvel, time = ftime + FrameTime()) {
        GetPlayer().SetVelocity(vel);
        ppmod.trigger(GetPlayer().GetCenter() + Vector(256), Vector(64, 64, 64), gravtrig);
        gravtrig.__KeyValueFromString("Targetname", "ppmod_movesim_gravtrig");
        gravtrig.__KeyValueFromFloat("Gravity", 0.000001);
        local relay = Entities.CreateByClassname("logic_relay");
        relay.__KeyValueFromInt("SpawnFlags", 2);
        relay.__KeyValueFromString("Targetname", "ppmod_movesim_relay");
        relay.__KeyValueFromString("OnTrigger", "!self\x001BKill\x1B\x001B"+time+"\x001B-1");
        ppmod.addscript(relay, "OnTrigger", function(gravtrig = gravtrig) {
          gravtrig.SetAbsOrigin(GetPlayer().GetOrigin() + Vector(256));
          EntFire("ppmod_movesim_gravtrig", "Kill", "", FrameTime());
        }, time);
        EntFireByHandle(relay, "Trigger", "", 0, null, null);
      });
    }
  }
}

ppmod.brush <- function(pos, size, type = "func_brush", ang = Vector()) {
  local brush = type;
  if(typeof type == "string") brush = Entities.CreateByClassname(type);
  brush.SetAbsOrigin(pos);
  brush.SetAngles(ang.x, ang.y, ang.z);
  brush.SetSize(Vector() - size, size);
  brush.__KeyValueFromInt("Solid", 3);
  return brush;
}

ppmod.trigger <- function(pos, size, type = "once", ang = Vector()) {
  if(typeof type == "string") type = "trigger_" + type;
  local trigger = ppmod.brush(pos, size, type, ang);
  trigger.__KeyValueFromInt("CollisionGroup", 1);
  trigger.__KeyValueFromInt("SpawnFlags", 1);
  if(type == "trigger_once") trigger.__KeyValueFromString("OnStartTouch", "!self\x001BKill\x1B\x001B0\x001B1");
  EntFireByHandle(trigger, "Enable", "", 0, null, null);
  return trigger;
}

ppmod.texture <- function(tex = "", pos = Vector(), ang = Vector(90), simple = 1, far = 16) {
  local texture = Entities.CreateByClassname("env_projectedtexture");
  texture.SetAbsOrigin(pos);
  texture.SetAngles(ang.x, ang.y, ang.z);
  texture.__KeyValueFromInt("FarZ", far);
  texture.__KeyValueFromInt("SimpleProjection", simple.tointeger());
  texture.__KeyValueFromString("TextureName", tex);
  return texture;
}

ppmod.decal <- function(tex, pos, ang = Vector(90)) {
  local decal = Entities.CreateByClassname("infodecal");
  decal.SetAbsOrigin(pos);
  decal.SetAngles(ang.x, ang.y, ang.z);
  decal.__KeyValueFromString("TextureName", tex);
  EntFireByHandle(decal, "Activate", "", 0, null, null);
  return decal;
}

ppmod.create <- function(cmd, func, key = null) {
  if(!key) switch (cmd.slice(0, min(cmd.len(), 17))) {
    case "ent_create_portal": key = "cube"; break;
    case "ent_create_paint_": key = "prop_paint_bomb"; break;
    default:
      if(cmd.find(" ")) key = cmd.slice(cmd.find(" ")+1);
      else if(cmd.slice(-4) == ".mdl") key = cmd, cmd = "prop_dynamic_create " + cmd;
      else key = cmd, cmd = "ent_create " + cmd;
  }
  SendToConsole(cmd);
  if(key.slice(-4) == ".mdl") key = "models/" + key;
  local getstr = "ppmod.prev(\"" + key + "\")";
  local qstr = scrq_add(func).name;
  SendToConsole("script (delete " + qstr + ")(" + getstr + ")");
}

ppmod.give <- function(key, func, pos = null) {
  if(pos) return ppmod.give("npc_maker", function(e, k = key, f = func, p = pos) {
    e.SetAbsOrigin(p);
    e.__KeyValueFromString("NPCType", k);
    k = UniqueString("ppmod_give");
    e.__KeyValueFromString("NPCTargetname", k);
    local getstr = ")(Entities.FindByName(null, \"" + k + "\"))";
    local script = ppmod.scrq_add(f).name + getstr;
    e.__KeyValueFromString("OnSpawnNPC", k + "\x001BRunScriptCode\x001B(delete " + script + "\x001B0\x001B1");
    e.__KeyValueFromString("OnSpawnNPC", "!self\x001BKill\x1B\x001B0\x001B1");
  });
  local player = Entities.FindByClassname(null, "player");
  local equip = Entities.CreateByClassname("game_player_equip");
  equip.__KeyValueFromInt(key, 1);
  EntFireByHandle(equip, "Use", "", 0, player, null);
  local getstr = ")(ppmod.prev(\"" + key + "\"))";
  local script = "(delete " + scrq_add(func).name + getstr;
  EntFireByHandle(equip, "RunScriptCode", script, 0, null, null);
  EntFireByHandle(equip, "Kill", "", 0, null, null);
}

ppmod.text <- function(text = "", x = -1, y = -1) {
  local ent = Entities.CreateByClassname("game_text");
  ent.__KeyValueFromString("Message", text);
  ent.__KeyValueFromString("Color", "255 255 255");
  ent.__KeyValueFromFloat("X", x);
  ent.__KeyValueFromFloat("Y", y);
  return {
    GetEntity = function(ent = ent) { return ent },
    SetPosition = function(x, y, ent = ent) {
      ent.__KeyValueFromFloat("X", x);
      ent.__KeyValueFromFloat("Y", y);
    },
    SetText = function(text, ent = ent) {
      ent.__KeyValueFromString("Message", text);
    },
    SetChannel = function(ch, ent = ent) {
      ent.__KeyValueFromInt("Channel", ch);
    },
    SetColor = function(c1, c2 = null, ent = ent) {
      ent.__KeyValueFromString("Color", c1);
      if(c2) ent.__KeyValueFromString("Color2", c2);
    },
    SetFade = function(fin, fout, fx = false, ent = ent) {
      ent.__KeyValueFromFloat("FadeIn", fin);
      ent.__KeyValueFromFloat("FXTime", fin);
      ent.__KeyValueFromFloat("FadeOut", fout);
      if(fx) ent.__KeyValueFromInt("Effect", 2);
      else ent.__KeyValueFromInt("Effect", 0);
    },
    Display = function(hold = null, player = null, ent = ent) {
      if(!hold) hold = FrameTime();
      ent.__KeyValueFromFloat("HoldTime", hold);
      if(player) ent.__KeyValueFromInt("SpawnFlags", 0);
      else ent.__KeyValueFromInt("SpawnFlags", 1);
      EntFireByHandle(ent, "Display", "", 0, player, null);
    }
  };
}

ppmod.ray <- function(start, end, ent = null, world = true, ray = null) {

  if(!ent) if(world) return TraceLine(start, end, null);
  else return 1.0;

  local len, div;
  if(!ray) {
    local dir = end - start;
    len = dir.Norm();
    div = [1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z];
  } else {
    len = ray[0];
    div = ray[1];
  }

  if(typeof ent == "array") {
    local lowest = 1.0;
    for(local i = 0; i < ent.len(); i++) {
      local curr = ppmod.ray(start, end, ent[i], false, [len, div]);
      if(curr < lowest) lowest = curr;
    }
    if(world) return min(lowest, TraceLine(start, end, null));
    return lowest;
  } else if(typeof ent == "string") {
    local lowest = 1.0;
    for(local i = ppmod.get(ent); i; i = ppmod.get(ent, i)) {
      local curr = ppmod.ray(start, end, i, false, [len, div]);
      if(curr < lowest) lowest = curr;
    }
    if(world) return min(lowest, TraceLine(start, end, null));
    return lowest;
  }

  local pos = ent.GetOrigin();
  local ang = ent.GetAngles() * (PI / 180);

  local c1 = cos(ang.z);
  local s1 = sin(ang.z);
  local c2 = cos(ang.x);
  local s2 = sin(ang.x);
  local c3 = cos(ang.y);
  local s3 = sin(ang.y);

  local matrix = [
    [c2 * c3, c3 * s1 * s2 - c1 * s3, s1 * s3 + c1 * c3 * s2],
    [c2 * s3, c1 * c3 + s1 * s2 * s3, c1 * s2 * s3 - c3 * s1],
    [-s2, c2 * s1, c1 * c2]
  ];

  local mins = ent.GetBoundingMins();
  local maxs = ent.GetBoundingMaxs();
  mins = [mins.x, mins.y, mins.z];
  maxs = [maxs.x, maxs.y, maxs.z];

  local bmin = [pos.x, pos.y, pos.z];
  local bmax = [pos.x, pos.y, pos.z];
  local a, b;

  for(local i = 0; i < 3; i++) {
    for(local j = 0; j < 3; j++) {
      a = (matrix[i][j] * mins[j]);
      b = (matrix[i][j] * maxs[j]);
      if(a < b) {
        bmin[i] += a;
        bmax[i] += b;
      } else {
        bmin[i] += b;
        bmax[i] += a;
      }
    }
  }

  if (
    start.x > bmin[0] && start.x < bmax[0] &&
    start.y > bmin[1] && start.y < bmax[1] &&
    start.z > bmin[2] && start.z < bmax[2]
  ) return 0;

  start = [start.x, start.y, start.z];

  local tmin = [0.0, 0.0, 0.0];
  local tmax = [0.0, 0.0, 0.0];

  for(local i = 0; i < 3; i++) {
    if(div[i] >= 0) {
      tmin[i] = (bmin[i] - start[i]) * div[i];
      tmax[i] = (bmax[i] - start[i]) * div[i];
    } else {
      tmin[i] = (bmax[i] - start[i]) * div[i];
      tmax[i] = (bmin[i] - start[i]) * div[i];
    }
    if(tmin[0] > tmax[i] || tmin[i] > tmax[0]) return 1.0;
    if(tmin[i] > tmin[0]) tmin[0] = tmin[i];
    if(tmax[i] < tmax[0]) tmax[0] = tmax[i];
  }

  if(tmin[0] < 0) tmin[0] = 1.0;
  else tmin[0] /= len;
  if(world) return min(tmin[0], TraceLine(start, end, null));
  return tmin[0];

}

if(!("smo" in this)) {

  printl("\n=== Loading Odyssey mod...");
	printl("=== Version: release-1.1, ppmod3\n");

  ::smo <- {};
  smo.level <- {};
  smo.debug <- false;
  smo.auto <- Entities.CreateByClassname("logic_auto");
  ppmod.addscript(smo.auto, "OnMapTransition", "smo.spawn()");
  ppmod.addscript(smo.auto, "OnNewGame", "smo.spawn()");

}

smo.spawn <- function() {

  SendToConsole("hud_saytext_time 0");
  SendToConsole("sv_cheats 1");
  SendToConsole("r_maxdlights 128");

  ppmod.wait(function () {
    SendToConsole("hud_saytext_time 12");
  }, 13);

smo.move <- {
  pound = false,
  air = false,
  prev = 0,
  jumps = 0,
  ducking = false,
  using = false,
  rmjump = null,
  rmpound = null,
  ljump = false,
  diving = false,
  walldir = null,
  rolltime = 0,
  rollvel = 0,
  safepos1 = Vector(),
  safepos2 = Vector(),
  canstuck = true,
  stucki = 0,
  capjumped = false,
  bonk = false
};

smo.move.setup <- function() {
  ppmod.player.enable();
  local auto = Entities.CreateByClassname("logic_auto");
  ppmod.addscript(smo.auto, "OnMapSpawn", "SendToConsole(\"prevent_crouch_jump 0\")");
  SendToConsole("prevent_crouch_jump 0");
  local pos = GetPlayer().GetOrigin();

  ppmod.player.jump("smo.move.jump()");
  ppmod.player.duck("smo.move.duck()");

  // Ground detection
  ppmod.wait(function() {
    ppmod.interval(function() {
      local vel = GetPlayer().GetVelocity();
      if (smo.move.prev <= 0 && vel.z == 0 && smo.move.air) smo.move.land();
      else if (smo.move.prev != 0 && vel.z != 0) smo.move.float();
      smo.move.prev = vel.z;
    });
  }, FrameTime() * 2);

  ppmod.player.duck("if (!smo.cap.captured) smo.move.ducking = true");
  ppmod.player.unduck("smo.move.ducking = false");

  smo.move.gameui <- {
    moveleft = false,
    moveright = false,
    forward = false,
    back = false,
    attack = false,
    attack2 = false
  };
  foreach (key, val in smo.move.gameui) {
    ppmod.player.input("+" + key, "smo.move.gameui." + key + " = true");
    ppmod.player.input("-" + key, "smo.move.gameui." + key + " = false");
  }

  smo.move.speedmod <- Entities.CreateByClassname("player_speedmod");
  ppmod.keyval(smo.move.speedmod, "SpawnFlags", 0);

  // Horrible way of doing this. Will replace as soon as I can.
  SendToConsole("alias +use \"script smo.move.use()\"");
  SendToConsole("alias -use \"script smo.move.unuse()\"");

  // SLA softlock prevention
  SendToConsole("-jump");
  smo.move.speed(175);
  ppmod.addscript(smo.auto, "OnLoadGame", function() {
    SendToConsole("-jump");
    smo.move.speed(175);
  });

  // SendToConsole("sv_noclipspeed 0");
  // ppmod.interval("smo.move.stuck()", FrameTime() * 2);
  // SendToConsole("alias smo_noclip \"script smo.move.noclip()\"");

  if (smo.debug) ppmod.interval("smo.move.debug()");
}

smo.move.debug <- function() {
  local dbg = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
  dbg += "jumps: " + smo.move.jumps + "\n";
  dbg += "pound: " + smo.move.pound + "\n";
  local wall = false;
  if (smo.move.walldir) wall = true;
  dbg += "wall: " + wall + "\n";
  local wallcheck = false;
  if (ppmod.get("smo_wallcheck")) wallcheck = true;
  dbg += "wallcheck: " + wallcheck + "\n";
  dbg += "capent: " + smo.cap.ent.GetOrigin().ToKVString().slice(0, -2);
  ScriptShowHudMessageAll(dbg, FrameTime());
}

smo.move.speed <- function(speed) {
  SendToConsole("cl_forwardspeed " + speed);
  SendToConsole("cl_sidespeed " + speed);
  SendToConsole("cl_backspeed " + speed);
  if (speed == 175) {
    SendToConsole("-duck");
    smo.move.ducking = false;
  } else {
    SendToConsole("+duck");
  }
}

smo.move.jump <- function() {
  // Walljump
  if (smo.move.walldir) {
    local vel = smo.move.walldir * -200;
    vel.z = 200;
    GetPlayer().SetVelocity(vel);
    smo.move.walldir = null;
    smo.move.capjumped = true;
    smo.move.jumps = 0;
  }

  if (smo.move.air || smo.cap.captured || smo.move.bonk) return;
  smo.move.air = true;

  // Double and triple jump
  smo.move.jumps ++;
  if (smo.move.jumps > 0) {
    if (smo.move.rmjump && smo.move.rmjump.IsValid()) smo.move.rmjump.Destroy();
    smo.move.rmjump = null;
  }
  if (smo.move.jumps == 3) {
    local vel = GetPlayer().GetVelocity();
    if (abs(vel.x) + abs(vel.y) >= 174) {
      GetPlayer().SetVelocity(Vector(vel.x, vel.y, 450));
      smo.move.jumps = 0;
    } else smo.move.jumps = 1;
  }
  if (smo.move.jumps == 2) {
    local vel = GetPlayer().GetVelocity();
    GetPlayer().SetVelocity(Vector(vel.x, vel.y, 220));
  }

  // Ground pound jump
  if (smo.move.pound) {
    GetPlayer().SetVelocity(Vector(0, 0, 400));
    if (smo.move.rmpound && smo.move.rmpound.IsValid()) smo.move.rmpound.Destroy();
    smo.move.rmpound = null;
    smo.move.pound = false;
    smo.move.speed(175);
    if (smo.move.rmjump && smo.move.rmjump.IsValid()) smo.move.rmjump.Destroy();
    smo.move.rmjump = null;
    smo.move.jumps = 0;
  }

  // Backflip or longjump
  if (smo.move.ducking) {
    local pos = GetPlayer().GetOrigin();
    local vel = GetPlayer().GetVelocity();
    local vec = ppmod.player.eyes_vec();
    local len = -100;
    if (abs(vel.x) + abs(vel.y) < 100) { // Backflip
      vec.z = 0;
      vec.Norm();
      vec.z = 400.0 / len;
    } else { // Longjump
      vec.z = 0;
      vec.Norm();
      len = 400;
      vec.z = 200.0 / len;
      smo.move.jumps = 0;
      smo.move.ljump = true;
    }
    GetPlayer().SetVelocity(vec * len);
    if (smo.move.jumps == 2) smo.move.jumps = 1;
  }
}

smo.move.float <- function() {

  // Walljump check
  if (!ppmod.get("smo_wallcheck") && !ppmod.get("smo_wallcheck_cooldown")) {
    ppmod.wait(function() {
      ppmod.interval("smo.move.wallcheck()", 0, "smo_wallcheck");
    }, 0.2, "smo_wallcheck_cooldown");
    ppmod.wait(function(){}, 0.3, "smo_wallcheck_cooldown");
  }

  smo.move.air = true;

}

smo.move.land <- function() {
  if (smo.move.air && smo.move.jumps > 0) {
    if (smo.move.rmjump && smo.move.rmjump.IsValid()) smo.move.rmjump.Destroy();
    smo.move.rmjump = ppmod.wait("smo.move.jumps = 0; smo.move.rmjump = null", 0.2);
  }
  if (smo.move.pound || smo.move.bonk) {
    smo.move.rollvel = 300;
    if (smo.move.rmpound && smo.move.rmpound.IsValid()) smo.move.rmpound.Destroy();
    smo.move.rmpound = ppmod.wait(function() {
      smo.move.bonk = false;
      smo.move.pound = false;
      smo.move.speed(175);
    }, 0.7);
  }
  smo.move.air = false;
  smo.move.ljump = false;
  smo.move.diving = false;
  smo.move.capjumped = false;
  local wallcheck = ppmod.get("smo_wallcheck");
  if (wallcheck && wallcheck.IsValid()) wallcheck.Destroy();
  ppmod.wait("smo.move.walldir = null", FrameTime());
}

smo.move.duck <- function() {
  if (smo.move.air && !smo.move.ljump && !smo.move.diving) { // Ground pound
    smo.move.pound = true;
    ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
    ppmod.fire(smo.move.speedmod, "ModifySpeed", 1, 0.3);
    GetPlayer().SetVelocity(Vector(0, 0, -500));
    smo.move.speed(0);
    smo.move.jumps = 0;
    ppmod.wait(function() {
      if (GetPlayer().GetVelocity().z == 0) smo.move.land();
    }, 0.3);
  }
  // Leave capture
  if (smo.cap.captured) {
    local ent = smo.cap.captured;
    smo.cap.cam_leave();
    smo.cap.leavefunc(ent);
    smo.cap.leavefunc = function(e) {};
  }
}

// Wall proximity check
smo.move.wallcheck <- function() {
  if (smo.move.pound) return;
  local pos = GetPlayer().EyePosition();
  local vel = GetPlayer().GetVelocity();
  local vec = smo.move.walldir;
  if (!vec) vec = ppmod.player.eyes_vec();
  else {
    vel.z += 5;
    GetPlayer().SetVelocity(vel);
  }
  vec.z = 0;
  vec.Norm();
  local frac = TraceLine(pos, pos + vec * 23, GetPlayer());
  if (frac != 1){
    if (ppmod.get(pos + vec * frac * 23, "prop_portal", 54)) return;
    if (smo.move.ljump || smo.move.diving) { // Dive bonk
      GetPlayer().SetVelocity(vec * -50);
      smo.move.speed(0);
      smo.move.bonk = true;
      return;
    }
    if (!smo.move.walldir) {
      if (vel.z < 0) vel.z = 0;
      GetPlayer().SetVelocity(vel);
    }
    smo.move.walldir = vec;
  } else smo.move.walldir = null;
}

smo.move.use <- function() {

  if (smo.move.bonk) return;

  if ("moon" in smo) {
    if (smo.moon.odyssey.enabled > 1) {
      smo.moon.odyssey.list();
      return;
    }
  }

  smo.move.using = true;

  local rollinterval = ppmod.get("smo_roll");
  if (smo.move.ducking && (!smo.move.air || rollinterval)) { // Roll

    smo.move.rolltime = 0;
    smo.move.rollvel = min(300, smo.move.rollvel + 50);
    if (!rollinterval) {
      ppmod.interval("smo.move.roll()", 0, "smo_roll");
    }

  } else if (smo.move.pound && smo.move.air) { // Dive

    ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
    local vec = ppmod.player.eyes_vec();
    vec.z = 0;
    vec.Norm();
    vec = vec * 350 + Vector(0, 0, 150);
    GetPlayer().SetVelocity(vec);
    if (smo.move.rmpound && smo.move.rmpound.IsValid()) smo.move.rmpound.Destroy();
    smo.move.rmpound = null;
    smo.move.pound = false;
    smo.move.speed(175);
    smo.move.diving = true;

  } else smo.cap.use();

}
smo.move.unuse <- function() {
  smo.move.using = false;
  smo.cap.unuse();
}

smo.move.roll <- function() {
  /* if (smo.move.air) {
    SendToConsole("cl_forwardspeed 0");
    SendToConsole("cl_sidespeed 0");
    SendToConsole("cl_backspeed 0");
    ppmod.fire(smo.move.brick, "Enable");
    return;
  } */
  if (smo.move.ljump) return;
  local vel = GetPlayer().GetVelocity();
  local rvel = smo.move.rollvel;
  local vec = ppmod.player.eyes_vec();
  if (smo.move.rolltime != 0 && (vel.x == 0 || vel.y == 0) && vec.z != 0) smo.move.rolltime = 50;
  vec.z = 0;
  vec.Norm();
  vec *= rvel - smo.move.rolltime * rvel / 50;
  GetPlayer().SetVelocity(Vector(vec.x, vec.y, vel.z));
  if (++smo.move.rolltime >= 50 || !smo.move.ducking) {
    smo.move.rollvel = 0;
    ppmod.get("smo_roll").Destroy();
  }
}

smo.move.capjump <- function(ent) {
  ppmod.wait("smo.cap.back()", 0.4);
  if (smo.move.capjumped) return;
  if (smo.move.air) smo.move.capjumped = true;
  smo.move.ljump = false;
  smo.move.diving = false;

  SendToConsole("+jump");
  ppmod.wait("SendToConsole(\"-jump\")", FrameTime());
  local vel = GetPlayer().GetVelocity();
  if (smo.move.air) vel *= 0.5;
  vel.z = 200;
  GetPlayer().SetVelocity(vel);

  local loop = ppmod.get("smo_capfly_stall");
  if (loop && loop.IsValid()) loop.Destroy();
}

// ********************************
//         Stuck prevention
// ********************************

smo.move.safetp <- function(pos) {

  GetPlayer().SetOrigin(pos);

  SendToConsole("setpos_exact "+pos.x+" "+pos.y+" "+pos.z);
  SendToConsole("setang -90 0");
  SendToConsole("noclip 1");
  SendToConsole("noclip 0");
  SendToConsole("setang 90 0");
  SendToConsole("noclip 1");
  SendToConsole("noclip 0");
  SendToConsole("debug_fixmyposition");

  local ang = ppmod.player.eyes.GetAngles();
  SendToConsole("setang "+ang.x+" "+ang.y+" "+ang.z);

}
  
smo.cap <- {
  ent = null,
  offset = Vector(0, 0, 5),
  scale = 3,
  captured = null,
  leavefunc = function(e) {},
  to = null,
  currcore = 1
};

smo.cap.setup <- function() {

  smo.cap.create();

  // Prevents SLA bugs from captures
  SendToConsole("crosshair 1");
  ppmod.addscript(smo.auto, "OnLoadGame", function() {
    if (!smo.cap.captured) SendToConsole("crosshair 1");
    if (ppmod.get("smo_cam_pos") && ppmod.get("smo_cam_pos").IsValid()) {
      smo.cap.cam(smo.cap.captured);
      ppmod.wait(function() {
        SendToConsole("thirdperson");
      }, FrameTime() * 3);
    }
  });

  ppmod.give("filter_damage_type", function(ent) {
    ppmod.keyval(ent, "Targetname", "smo_godfilter");
    ppmod.keyval(ent, "filter_damage_type", 32);
    smo.cap.dmgfilter <- ent;
  });

}

smo.cap.create <- function(func = function(){}) {
  ppmod.create("player/items/eggbot/eggbot_beanie.mdl", function(ent, func = func) {
    ent.SetOrigin(GetPlayer().GetOrigin());
    ent.SetAngles(0, 90, 0);
    ppmod.keyval(ent, "Targetname", "smo_cap");
    ppmod.keyval(ent, "CollisionGroup", 1);
    ppmod.keyval(ent, "ModelScale", smo.cap.scale);
    ppmod.fire(ent, "DisableDraw");
    smo.cap.ent = ent;
    func();
  });
}

smo.cap.spectate <- function(enable) {
  if (enable) {
    ppmod.keyval("weapon_portalgun", "CanFirePortal1", 0);
    ppmod.keyval("weapon_portalgun", "CanFirePortal2", 0);
    ppmod.fire("viewmodel", "DisableDraw");
    ppmod.fire(GetPlayer(), "SetDamageFilter", "smo_godfilter");
    SendToConsole("crosshair 0");
  } else {
    if (GetMapName().slice(4, 5) == "1") {
      ppmod.keyval("weapon_portalgun", "CanFirePortal2", 0);
    } else ppmod.keyval("weapon_portalgun", "CanFirePortal2", 1);
    ppmod.keyval("weapon_portalgun", "CanFirePortal1", 1);
    ppmod.fire("viewmodel", "EnableDraw");
    ppmod.fire(GetPlayer(), "SetDamageFilter", "");
    SendToConsole("crosshair 1");
  }
}

smo.cap.use <- function() {
  if (smo.cap.to) return;
  local pos = GetPlayer().EyePosition() + Vector(0, 0, 3) + smo.cap.offset;
  local vec = ppmod.player.eyes_vec() * 256;
  local frac = TraceLine(pos, pos + vec, GetPlayer());
  if (frac <= 0.25) return;
  smo.cap.to = pos + vec * frac + smo.cap.offset;
  if (smo.debug) DebugDrawLine(pos, to, 255, 0, 0, false, 5);
  smo.move.ljump = false;

  smo.cap.ent.SetOrigin(pos);
  ppmod.fire(smo.cap.ent, "EnableDraw");
  ppmod.interval("smo.cap.fly()", 0, "smo_capfly");
}

smo.cap.unuse <- function() {

}

smo.cap.fly <- function() {
  local pos = smo.cap.ent.GetOrigin();
  local ang = smo.cap.ent.GetAngles();
  local vec = smo.cap.to - pos;
  local speed = 20;
  vec.Norm();
  smo.cap.ent.SetAngles(0, (ang.y - 30) % 360, 0);
  if (smo.cap.find(pos, speed)) {
    local loop = ppmod.get("smo_capfly");
    if (loop && loop.IsValid()) loop.Destroy();
    return;
  }
  if ((smo.cap.to - pos).Length() < speed * 2) {
    smo.cap.flystall();
    local loop = ppmod.get("smo_capfly");
    if (loop && loop.IsValid()) loop.Destroy();
    return;
  }
  smo.cap.ent.SetAbsOrigin(pos + vec * speed);
}
smo.cap.flystall <- function() {
  //ppmod.keyval(smo.cap.ent, "ModelScale", smo.cap.scale + 0.5);
  local stallcd = Entities.CreateByClassname("logic_relay");
  ppmod.fire(stallcd, "Kill", "", 0.5);

  ppmod.interval(function(cd = stallcd) {
    if (!smo.move.using && (!cd || !cd.IsValid())) {
      local loop = ppmod.get("smo_capfly_stall");
      if (loop && loop.IsValid()) loop.Destroy();
      ppmod.fire("smo_capfly_stall_timeout", "Kill");
      smo.cap.back();
    } else {
      local pos = smo.cap.ent.GetOrigin();
      local ang = smo.cap.ent.GetAngles();
      smo.cap.ent.SetAngles(0, (ang.y - 30) % 360, 0);
      if (smo.cap.find(pos, 0)) {
        local loop = ppmod.get("smo_capfly_stall");
        if (loop && loop.IsValid()) loop.Destroy();
        ppmod.fire("smo_capfly_stall_timeout", "Kill");
      }
    }
  }, 0, "smo_capfly_stall");

  local timeout = ppmod.wait(function() {
    local loop = ppmod.get("smo_capfly_stall");
    if (loop && loop.IsValid()) {
      local loop = ppmod.get("smo_capfly_stall");
      if (loop && loop.IsValid()) loop.Destroy();
      smo.cap.back();
    }
  }, 1.5);
  ppmod.keyval(timeout, "Targetname", "smo_capfly_stall_timeout");

}
smo.cap.flyrev <- function() {
  local pos = smo.cap.ent.GetOrigin();
  local ang = smo.cap.ent.GetAngles();
  local vec = smo.cap.to - pos;
  local speed = 20;
  vec.Norm();
  smo.cap.ent.SetAbsOrigin(pos + vec * speed);
  smo.cap.ent.SetAngles(0, (ang.y - 30) % 360, 0);
  /* if (smo.cap.find(pos, speed)) {
    if (ppmod.get("smo_capfly_rev")) {
      ppmod.get("smo_capfly_rev").Destroy();
    }
    return;
  } */
  if ((smo.cap.to - (pos + vec * speed)).Length() < speed) {
    ppmod.fire(smo.cap.ent, "DisableDraw");
    if (ppmod.get("smo_capfly_rev")) {
      ppmod.get("smo_capfly_rev").Destroy();
    }
    smo.cap.to = null;
  }
}

smo.cap.back <- function() {
  ppmod.keyval(smo.cap.ent, "ModelScale", smo.cap.scale);
  ppmod.fire(smo.cap.ent, "EnableDraw");
  smo.cap.to = GetPlayer().GetOrigin() + Vector(0, 0, 72) + smo.cap.offset;
  /* EntFire("smo_capjump_trigger", "Kill"); */
  ppmod.interval("smo.cap.flyrev()", 0, "smo_capfly_rev");
}

smo.cap.find <- function(pos, speed) {
  pos -= smo.cap.offset;
  local offset = Vector();
  local radius = 32 + speed / 2;
  local ent = null;
  local func = null;

  if (ent = ppmod.get(pos, "prop_weighted_cube", radius)) func = smo.cap.physprop;
  else if (ent = ppmod.get(pos, "prop_physics", radius)) func = smo.cap.physprop;
  else if (ent = ppmod.get(pos, "prop_physics_override", radius)) func = smo.cap.physprop;
  else if (ent = ppmod.get(pos, "prop_exploding_futbol", radius)) func = smo.cap.physprop;
  else if (ent = ppmod.get(pos, "prop_monster_box", radius)) func = smo.cap.monster;
  else if (ent = ppmod.get(pos, "npc_security_camera", radius)) func = smo.cap.wallcam;
  else if (ent = ppmod.get(pos, "npc_personality_core", radius)) func = smo.cap.core;
  else if (ent = ppmod.get(pos, "npc_portal_turret_floor", radius)) func = smo.cap.turret;
  else if (ent = ppmod.get(pos, "func_button", radius)) func = smo.cap.button;
  else if (ent = ppmod.get(pos - Vector(0, 0, 22), "prop_button", radius)) func = smo.cap.button, offset = Vector(0, 0, 22);
  else if (ent = ppmod.get(pos - Vector(0, 0, 22), "prop_under_button", radius)) func = smo.cap.button, offset = Vector(0, 0, 22);
  else if (ent = ppmod.get(pos + Vector(0, 0, 15), "prop_floor_button", radius)) func = smo.cap.floorbutton, offset = Vector(0, 0, 15);
  else if (ent = ppmod.get(pos + Vector(0, 0, 15), "prop_under_floor_button", radius)) func = smo.cap.underfloorbutton, offset = Vector(0, 0, 15);
  else if (ent = ppmod.get(pos, "trigger_catapult", radius)) func = smo.cap.catapult;
  else if (speed == 0 && (ent = ppmod.get(pos - Vector(0, 0, 28), "player", 40))) func = smo.move.capjump, offset = Vector(0, 0, 28);

  if (func /*&& TraceLine(pos, ent.GetOrigin() + offset, GetPlayer()) == 1*/) {
    if (func == smo.cap.catapult) {
      local plate = null;
      while (plate = Entities.FindInSphere(plate, ent.GetOrigin(), 128)) {
        if (plate.GetModelName() == "models/props/faith_plate.mdl") {
          func(ent);
          break;
        }
      }
      if (!plate) return false;
    } else func(ent);
    ppmod.keyval(smo.cap.ent, "ModelScale", smo.cap.scale);
    return ent;
  } else return false;

}

smo.cap.cam <- function(ent) {
  SendToConsole("thirdperson");
  /* SendToConsole("cam_ideallag 20");
  ppmod.wait("SendToConsole(\"cam_ideallag 0\")", 0.5); */
  EntFire("!player", "DisableDraw");
  GetPlayer().SetVelocity(Vector());
  ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
  ppmod.keyval("!player", "MoveType", 8);

  ppmod.fire(ent, "AddOutput", "Targetname " + ent.GetName(), FrameTime());
  local tmpname = UniqueString("smo_cam_ent");
  ppmod.keyval(ent, "Targetname", tmpname);

  local mirror = Entities.CreateByClassname("logic_measure_movement");
  ppmod.keyval(mirror, "MeasureType", 0);
  ppmod.keyval(mirror, "Targetname", "smo_cam_pos");
  ppmod.keyval(mirror, "TargetReference", "smo_cam_pos");
  ppmod.fire(mirror, "SetMeasureReference", "smo_cam_pos");
  ppmod.fire(mirror, "SetMeasureTarget", tmpname);
  ppmod.keyval(mirror, "Target", "!player");
  ppmod.fire(mirror, "Enable");
  smo.cap.captured = ent;

  smo.cap.spectate(true);
  smo.move.canstuck = false;
}
smo.cap.cam_leave <- function() {
  SendToConsole("firstperson");
  EntFire("!player", "EnableDraw");
  ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
  ppmod.keyval("!player", "MoveType", 2);
  EntFire("smo_cam_pos", "Kill");
  ppmod.fire(smo.cap.ent, "DisableDraw");
  smo.cap.captured = null;
  smo.cap.back();

  smo.cap.spectate(false);
  ppmod.wait("smo.move.canstuck = true", FrameTime() * 2);
}

// ********************************
//         Capture behavior
// ********************************

smo.cap.physprop <- function(ent) {
  local pos = ent.GetOrigin();
  local ang = ent.GetAngles();
  local maxz = ent.GetBoundingMaxs().z;
  smo.cap.ent.SetOrigin(pos + smo.cap.offset + Vector(0, 0, maxz));
  ang.x %= 90;
  if (ang.x > 45) ang.x -= 90;
  if (ang.x < -45) ang.x += 90;
  ppmod.keyval(ent, "CollisionGroup", 23);
  smo.cap.cam(ent);
  smo.cap.ent.SetAngles(ang.x, ang.y, 0);
  ppmod.fire(smo.cap.ent, "SetParent", ent.GetName());
  smo.move.speed(175);

  local push = Entities.CreateByClassname("point_push");
  ppmod.keyval(push, "Targetname", "smo_cube_push");
  ppmod.keyval(push, "SpawnFlags", 22);
  ppmod.keyval(push, "Radius", 1);
  ppmod.fire(push, "Enable");

  ppmod.interval(function(push = push) {
    if (!smo.cap.captured) return;
    if (!smo.cap.captured.IsValid()) {
      smo.cap.create(function() {
        smo.move.duck();
      });
      return;
    }

    local ang = ppmod.player.eyes.GetAngles();
    local pos = smo.cap.captured.GetOrigin();
    local input = smo.move.gameui;
    local offset = 0;

    local enable = false;
    foreach(val in input) if (val) enable = true;
    if (input.moveleft) offset += 90;
    if (input.moveright) offset -= 90;
    if (input.back) {
      if (input.moveleft) offset += 45;
      if (input.moveright) offset -= 45;
      if (!offset && !input.forward) offset = 180;
    }
    if (input.forward) {
      if (input.moveleft) offset -= 45;
      if (input.moveright) offset += 45;
    }

    if (enable) ppmod.keyval(push, "Magnitude", 13);
    else ppmod.keyval(push, "Magnitude", 0);
    push.SetAngles(0, ang.y + offset, 0);
    push.SetOrigin(pos);

    ppmod.fire(smo.cap.captured, "Wake");
    ppmod.fire(smo.cap.captured, "EnableMotion");

    if (smo.cap.captured.GetModelName() == "models/props/reflection_cube.mdl") {
      local cang = smo.cap.captured.GetAngles();
      ppmod.keyval(smo.cap.captured, "Angles", cang.x+" "+ang.y+" "+cang.z);
    }
  }, 0, "smo_cube_update");

  smo.cap.leavefunc = function(ent) {
    EntFire("smo_cube_update", "Kill");
    EntFire("smo_cube_push", "Kill");
    ppmod.fire(smo.cap.ent, "ClearParent");

    if (!ent.IsValid()) {
      smo.move.safetp(GetPlayer().GetOrigin());
      return;
    }

    ppmod.keyval(ent, "CollisionGroup", 24);
    local pos = ent.GetOrigin();
    local maxz = ent.GetBoundingMaxs().z;
    smo.move.safetp(pos + Vector(0, 0, maxz + 5));

    if (ent.GetModelName() == "models/props/reflection_cube.mdl") {
      local ang = ppmod.player.eyes.GetAngles();
      local cang = ent.GetAngles();
      ent.SetAngles(cang.x, ang.y, cang.z);
    }
  }
}

smo.cap.button <- function(ent) {
  ppmod.fire(ent, "Press");
  smo.cap.back();
}
smo.cap.floorbutton <- function(ent) {
  ppmod.fire(ent, "SetAnimation", "down");
  ppmod.fire(ent, "SetAnimation", "up", FrameTime() * 2);
  ppmod.addoutput(ent, "OnPressed", "!self", "SetAnimation", "down");
  ppmod.addoutput(ent, "OnUnpressed", "!self", "SetAnimation", "up");
  smo.cap.back();
}
smo.cap.underfloorbutton <- function(ent) {
  ppmod.fire(ent, "SetAnimation", "press");
  ppmod.fire(ent, "SetAnimation", "release", FrameTime() * 2);
  ppmod.addoutput(ent, "OnPressed", "!self", "SetAnimation", "press");
  ppmod.addoutput(ent, "OnUnpressed", "!self", "SetAnimation", "release");
  smo.cap.back();
}

smo.cap.catapult <- function(ent) {
  if (!ent || !ent.IsValid()) return;
  smo.cap.back();
  ppmod.create("prop_physics_create gibs/glass_break_b1_gib25.mdl", function(prop, ent = ent) {
    ppmod.fire(prop, "Kill");
    prop.SetOrigin(ent.GetOrigin());
  });
}

smo.cap.wallcam <- function(ent) {
  local pos = ent.GetOrigin();
  pos.x = round(pos.x, 3);
  pos.y = round(pos.y, 3);
  pos.z = round(pos.z, 3);
  local ang = ent.GetAngles();

  if ( pos.z % 1 != 0 && (pos.x % 1 != 0 || pos.y % 1 != 0) ) {
    ppmod.fire(ent, "Ragdoll");
    smo.cap.physprop(ent);
    return;
  }

  local offset = Vector(cos(ang.y) * 20, sin(ang.y) * 20, -100);
  GetPlayer().SetOrigin(pos + offset);
  GetPlayer().SetAngles(ang.x, ang.y, 0);

  ppmod.fire(ent, "Enable");
  ppmod.fire(ent, "DisableDraw");
  ppmod.fire(smo.cap.ent, "DisableDraw");
  ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
  ppmod.keyval("!player", "MoveType", 8);
  smo.cap.captured = ent;
  smo.cap.spectate(true);
  smo.move.canstuck = false;

  smo.cap.leavefunc = function(ent) {
    ppmod.fire(ent, "EnableDraw");
    ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
    ppmod.keyval("!player", "MoveType", 2);
    local pos = ent.GetOrigin();
    local ang = ent.GetAngles();
    local offset = Vector(cos(ang.y) * 32, sin(ang.y) * 32, -136);
    smo.move.safetp(pos + offset);
    smo.cap.spectate(false);
    ppmod.wait("smo.move.canstuck = true", FrameTime() * 2);
  }
}

smo.cap.core <- function(ent) {
  if (!ent.GetMoveParent()) {
    ppmod.fire(ent, "ForcePickup");
    smo.cap.back();
    return;
  }

  if (GetMapName() == "sp_a4_finale4") {

    if (ent.GetName().slice(6).tointeger() >= smo.cap.currcore) {
      
      ppmod.fire(ent, "ClearParent");
      ppmod.fire(ent, "EnableMotion");
      ppmod.fire(ent, "Wake");
      smo.cap.currcore ++;

    }

    smo.cap.back();
    return;

  }

  local ang = ent.GetAngles();
  GetPlayer().SetAngles(ang.x, ang.y + 90, 0);

  ppmod.interval(function(ent = ent) {
    local pos = ent.GetOrigin();
    local offset = Vector(0, 0, -36);
    GetPlayer().SetAbsOrigin(pos + offset);
  }, 0, "smo_cap_core_pos");

  ppmod.fire(ent, "DisableDraw");
  ppmod.fire(smo.cap.ent, "DisableDraw");
  ppmod.keyval(ent, "CollisionGroup", 2);
  ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
  ppmod.keyval("!player", "MoveType", 8);
  smo.cap.captured = ent;
  smo.cap.spectate(true);
  smo.move.canstuck = false;

  smo.cap.leavefunc = function(ent) {
    ppmod.fire(ent, "EnableDraw");
    ppmod.keyval(ent, "CollisionGroup", 0);
    ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
    ppmod.keyval("!player", "MoveType", 2);
    local pos = ent.GetOrigin();
    local ang = ent.GetAngles();
    local offset = Vector(0, 0, 32);
    smo.move.safetp(pos + offset);
    smo.cap.spectate(false);
    ppmod.wait("smo.move.canstuck = true", FrameTime() * 2);
    ppmod.get("smo_cap_core_pos").Destroy();
    if (!ent.GetMoveParent()) {
      local pang = GetPlayer().GetAngles();
      ent.SetAngles(pang.x, pang.y - 90, 0);
    }
  }
}

smo.cap.turret <- function(ent) {

  if (ent.GetName() == "initial_template_turret") {

    ppmod.fire(ent, "Use", "", 0, GetPlayer());
    ppmod.fire(ent, "SelfDestructImmediately");

    EntFire("@BringDefectiveTurret_trigger", "Kill");
    EntFire("player_in_scanner_trigger", "Kill");
    EntFire("scanner_screen_script", "RunScriptCode", "TemplateTurretBroken()");
    EntFire("control_room_blocking_doors", "TurnOn");
    EntFire("control_room_blocking_doors", "EnableCollision");
    EntFire("catch_turret_nag_timer", "Kill");
    EntFire("template_scanner_1_relay", "Enable");
    EntFire("switch_turret_acceptance_relay", "Trigger");
    EntFire("turrets_offline_relay", "Trigger");

    smo.cap.back();
    return;

  }

  local ang = ent.GetAngles();
  GetPlayer().SetAngles(0, ang.y, 0);

  local target = Entities.CreateByClassname("info_target");
  ppmod.keyval(target, "Targetname", "smo_turret_target");

  if (ent.GetModelName() != "models/npcs/turret/turret_skeleton.mdl") {
    ppmod.interval(function(ent = ent, target = target) {

      if (!ent) return;
      if (!ent.IsValid()) {
        smo.cap.create(function() {
          smo.move.duck();
        });
        return;
      }

      local pos = ent.GetOrigin();
      local offset = Vector(0, 0, -26);
      GetPlayer().SetAbsOrigin(pos + offset);

      local eyepos = GetPlayer().EyePosition();
      local vec = ppmod.player.eyes_vec();
      target.SetOrigin(eyepos + vec * 256);

      if (smo.move.gameui.attack) {
        ppmod.fire(ent, "FireBullet", "smo_turret_target");
      }

    }, 0, "smo_turret_loop");
  }

  ppmod.fire(ent, "DisableDraw");
  ppmod.fire(smo.cap.ent, "DisableDraw");
  ppmod.keyval(ent, "CollisionGroup", 2);
  ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
  ppmod.keyval(GetPlayer(), "MoveType", 8);
  ppmod.fire(ent, "EnableGagging");
  smo.cap.captured = ent;
  smo.cap.spectate(true);

  smo.cap.leavefunc = function(ent) {
    if (ent && ent.IsValid()) {
      ppmod.fire(ent, "EnableDraw");
      ppmod.fire(ent, "DisableGagging");
      ppmod.keyval(ent, "CollisionGroup", 0);
    }
    ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
    ppmod.keyval(GetPlayer(), "MoveType", 2);
    ppmod.fire("smo_turret_loop", "Kill");
    ppmod.fire("smo_turret_target", "Kill");
    local pos = ent.GetOrigin();
    local ang = ent.GetAngles();
    local offset = Vector(0, 0, 60);
    smo.move.safetp(pos + offset);
    smo.cap.spectate(false);
  }
}

smo.cap.monster <- function(ent) {
  ent.SetVelocity(Vector());
  ppmod.keyval(ent, "MoveType", 8);
  ppmod.keyval(ent, "CollisionGroup", 1);
  ppmod.fire(ent, "BecomeBox");
  ppmod.give("prop_weighted_cube", function(cube, ent = ent) {
    ppmod.keyval(cube, "Targetname", "smo_monster_ghostbox");
    local pos = ent.GetOrigin();
    ent.SetAngles(0, 0, 0);
    cube.SetOrigin(pos);
    cube.SetAngles(0, 0, 0);

    local push = Entities.CreateByClassname("point_push");
    ppmod.keyval(push, "Targetname", "smo_monster_push");
    ppmod.keyval(push, "SpawnFlags", 22);
    ppmod.keyval(push, "Radius", 1);
    ppmod.fire(push, "Enable");

    ppmod.fire(ent, "DisableMotion");
    ppmod.fire(cube, "DisableDraw");
    ppmod.keyval(cube, "CollisionGroup", 23);
    smo.cap.cam(cube);
    // ppmod.fire(ent, "SetParent", "smo_monster_ghostbox");
    // ppmod.fire(smo.cap.ent, "SetParent", ent.GetName());
    smo.move.speed(175);

    ppmod.interval(function(cube = cube, ent = ent, push = push) {
      if (!smo.cap.captured) return;
      if (!smo.cap.captured.IsValid()) {
        smo.cap.create(function() {
          smo.move.duck();
        });
        return;
      }

      local pos = cube.GetOrigin();
      local ang = ppmod.player.eyes.GetAngles();
      ppmod.keyval(ent, "Angles", "0 "+ang.y+" 0");
      ppmod.keyval(cube, "Angles", "0 "+ang.y+" 0");
      ppmod.fire(ent, "BecomeMonster");
      smo.cap.ent.SetAbsOrigin(pos + smo.cap.offset + Vector(0, 0, 36));
      smo.cap.ent.SetAngles(0, ang.y, 0);
      ent.SetOrigin(pos);
      push.SetOrigin(pos);
      push.SetAngles(-45, ang.y, 0);
    }, 0, "smo_monster_update");

    ppmod.interval(function(push = push) {
      ppmod.fire(push, "AddOutput", "Magnitude 20");
      ppmod.fire(push, "AddOutput", "Magnitude 0", 0.2);
    }, 1, "smo_monster_push_loop");

    smo.cap.leavefunc = function(cube, ent = ent) {
      ppmod.fire(ent, "EnableMotion");
      ppmod.keyval(ent, "MoveType", 6);
      ppmod.keyval(ent, "CollisionGroup", 24);
      ppmod.fire(cube, "Kill", FrameTime());
      ppmod.fire("smo_monster_update", "Kill");
      ppmod.fire("smo_monster_push", "Kill");
      ppmod.fire("smo_monster_push_loop", "Kill");
      local pos = cube.GetOrigin();
      local ang = cube.GetAngles();
      ent.SetVelocity(Vector());
      smo.move.safetp(pos + Vector(0, 0, 41));
      GetPlayer().SetOrigin(pos + Vector(0, 0, 45));
      ppmod.fire(ent, "BecomeBox");
      ppmod.fire(ent, "SetLocalOrigin", pos.x+" "+pos.y+" "+pos.z);
      ppmod.fire(ent, "SetLocalAngles", "0 "+ang.y+" 0");
    }
  });
}

smo.moonlist <- [

  // CHAPTER 1 - 40 moons

  // { pos = Vector(-1450, 4406, 3040), name = "A Faithful Leap", map = "sp_a1_intro1" },
  { pos = Vector(-688, 3951, 2687), name = "Our First Power Moon", map = "sp_a1_intro1" },

  { pos = Vector(-320, -36, 190), name = "Overlooking the Carousel", map = "sp_a1_intro2" },
  { pos = Vector(-298, -512, 310), name = "Above the Chamber Sign", map = "sp_a1_intro2" },
  { pos = Vector(-425, 326, 576), name = "Right Below the Sky", map = "sp_a1_intro2" },

  { pos = Vector(-246, -646, 1214), name = "Behind and Above the Entrance", map = "sp_a1_intro3" },
  { pos = Vector(70, 500, 1000), name = "Came Back for This", map = "sp_a1_intro3" },
  { pos = Vector(243, 2152, -415), name = "Covered by the Scribbles", map = "sp_a1_intro3" },
  { pos = Vector(143, 1037, 1268), name = "Next to the Broken Pedestal", map = "sp_a1_intro3" },
  { pos = Vector(-154, 1129, 44), name = "Above the Flooded Alley", map = "sp_a1_intro3" },
  { pos = Vector(-485, 2579, -171), name = "Tightly Fit Between the Rubble", map = "sp_a1_intro3" },
  { pos = Vector(-698, 1737, 121), name = "In the Ceiling of the Office", map = "sp_a1_intro3" },

  { pos = Vector(4, 64, 555), name = "Where the Cubes Drop", map = "sp_a1_intro4" },
  { pos = Vector(422, 161, 184), name = "Above the Airlock Door", map = "sp_a1_intro4" },
  { pos = Vector(850, -820, 294), name = "Among the Beans", map = "sp_a1_intro4" },

  { pos = Vector(-469, -417, 1079), name = "Following the Sounds of Rain", map = "sp_a1_intro5" },
  { pos = Vector(-422, 0, 403), name = "Behind the Static Portal", map = "sp_a1_intro5" },
  { pos = Vector(112, -112, 1341), name = "The Highest Point", map = "sp_a1_intro5" },
  { pos = Vector(380, 64, 1162), name = "A Giant Hole in the Ceiling", map = "sp_a1_intro5" },
  { pos = Vector(515, 0, 13), name = "In the Middle of Deadly Goo", map = "sp_a1_intro5" },

  { pos = Vector(-68, -448, 453), name = "Inside a Hollow Wall", map = "sp_a1_intro6" },
  { pos = Vector(419, -215, 972), name = "On an Overgrown Pipe", map = "sp_a1_intro6" },
  { pos = Vector(651, 0, 680), name = "Sealed in the Airlock Ceiling", map = "sp_a1_intro6" },
  { pos = Vector(1914, 386, 1065), name = "Above the Collapsed Debris", map = "sp_a1_intro6" },
  { pos = Vector(1792, 512, 677), name = "A Pocket in the Wall", map = "sp_a1_intro6" },
  { pos = Vector(3334, -9, 676), name = "Cooling the Elevator Room", map = "sp_a1_intro6" },

  { pos = Vector(-808, 213, 1369), name = "By the Obstructed Exit", map = "sp_a1_intro7" },
  { pos = Vector(-864, -1182, 1419), name = "Observing the Observers", map = "sp_a1_intro7" },
  { pos = Vector(-1344, -416, 1536), name = "On a Rail", map = "sp_a1_intro7" },
  { pos = Vector(-2913, -367, 1528), name = "Supervising Pneumatic Delivery", map = "sp_a1_intro7" },

  { pos = Vector(8772, 565, 830), name = "Peeking into HER Chamber", map = "sp_a1_wakeup" },
  { pos = Vector(9326, 1225, 1320), name = "Atop the Spinning Rings", map = "sp_a1_wakeup" },
  { pos = Vector(10817, 1010, -2), name = "On a Crumbled Catwalk", map = "sp_a1_wakeup" },
  { pos = Vector(8960, 1300, -160), name = "Going Off the Beaten Catwalk", map = "sp_a1_wakeup" }, 
  { pos = Vector(8977, 1088, 136), name = "Powerup Initiated", map = "sp_a1_wakeup" },

  { pos = Vector(-1953, 431, -10102), name = "A Staircase of Bumps", map = "sp_a2_intro" },
  { pos = Vector(-1535, 352, -10705), name = "Overlooking The Dual Portal Device", map = "sp_a2_intro" },
  { pos = Vector(-39, -488, -10583), name = "Behind the Angled Panel", map = "sp_a2_intro" },
  { pos = Vector(895, 0, -10728), name = "Squeezed Through the Gap", map = "sp_a2_intro" },
  { pos = Vector(256, -56, -10597), name = "On top of the Pellet Catcher", map = "sp_a2_intro" },
  { pos = Vector(-545, 719, -10716), name = "Highly Inconvenient Arms", map = "sp_a2_intro" },

  // CHAPTER 2 - 36 moons

  { pos = Vector(225, 267, 7), name = "Hole in the Shaking Wall", map = "sp_a2_laser_intro" },
  { pos = Vector(319, -107, 174), name = "Above the Exit Lift", map = "sp_a2_laser_intro" },
  { pos = Vector(1, 128, 312), name = "Behind the Laser Emitter", map = "sp_a2_laser_intro" },

  { pos = Vector(-142, 689, -39), name = "He's Still Alive", map = "sp_a2_laser_stairs" },
  { pos = Vector(-44, 120, 237), name = "Atop a Tilted Beam", map = "sp_a2_laser_stairs" },
  { pos = Vector(480, -578, 324), name = "Behind the Crooked Panels", map = "sp_a2_laser_stairs" },
  { pos = Vector(-656, -440, 819), name = "Above the Chamber Sign", map = "sp_a2_laser_stairs" },

  { pos = Vector(543, -1270, 1074), name = "Breaking the Artificial Landscape", map = "sp_a2_dual_lasers" },
  { pos = Vector(448, -378, 760), name = "85.2 FM", map = "sp_a2_dual_lasers" },
  { pos = Vector(170, -113, 1220), name = "A Blocked Off Ceiling", map = "sp_a2_dual_lasers" },
  { pos = Vector(-292, 130, 944), name = "Faster Than the Panels", map = "sp_a2_dual_lasers" },

  { pos = Vector(2783, -1699, 677), name = "Imitating a Cube", map = "sp_a2_laser_over_goo" },
  { pos = Vector(3458, -1643, 252), name = "A Dead End Tube", map = "sp_a2_laser_over_goo" },
  { pos = Vector(3355, -1955, 70), name = "Some Space in the Wall", map = "sp_a2_laser_over_goo" },
  { pos = Vector(3808, -1664, 797), name = "Climbing the Dropdown", map = "sp_a2_laser_over_goo" },
  { pos = Vector(3520, -1663, -76), name = "Under Your Nose", map = "sp_a2_laser_over_goo" },
  { pos = Vector(3140, -1779, 199), name = "Hole in the Wall", map = "sp_a2_laser_over_goo" },

  { pos = Vector(256, -1493, -95), name = "Quick Enough to get Stuck", map = "sp_a2_catapult_intro" }, // softlock spot
  { pos = Vector(-63, -929, -515), name = "Hold the Door", map = "sp_a2_catapult_intro" },
  { pos = Vector(596, 34, 309), name = "On the Slanted Wall", map = "sp_a2_catapult_intro" },
  { pos = Vector(512, 672, 553), name = "In the Ceiling Pocket", map = "sp_a2_catapult_intro" },
  { pos = Vector(-877, -352, -341), name = "Behind the Collapsing Panels", map = "sp_a2_catapult_intro" },
  { pos = Vector(562, -355, -511), name = "By a Sneaky Pillar", map = "sp_a2_catapult_intro" },

  { pos = Vector(-126, 576, 718), name = "Where the Panels Drop", map = "sp_a2_trust_fling" },
  { pos = Vector(69, 1303, -346), name = "Guarding the Button from Behind", map = "sp_a2_trust_fling" },
  { pos = Vector(-1152, 1280, -202), name = "Below the Exit Bridge", map = "sp_a2_trust_fling" },
  { pos = Vector(-1601, 1383, -210), name = "Keeping the Panels Open", map = "sp_a2_trust_fling" },
  { pos = Vector(2064, -60, 230), name = "Hoopy the Hoop", map = "sp_a2_trust_fling" },

  { pos = Vector(523, -384, -436), name = "Making Your Own Way Up", map = "sp_a2_pit_flings" },
  { pos = Vector(132, 86, 434), name = "X Marks the Spot", map = "sp_a2_pit_flings" },
  { pos = Vector(352, 216, -553), name = "Protected by Wheatley", map = "sp_a2_pit_flings" },
  { pos = Vector(384, 320, 0), name = "Wrong Texture, Valve", map = "sp_a2_pit_flings" },

  { pos = Vector(-982, -129, -960), name = "Leaping Past a Trigger", map = "sp_a2_fizzler_intro" }, // under the elevator
  { pos = Vector(480, -768, 320), name = "Across the Observation Room", map = "sp_a2_fizzler_intro" },
  { pos = Vector(-223, -126, 112), name = "On Top of the Entrance", map = "sp_a2_fizzler_intro" },
  { pos = Vector(-64, -386, 464), name = "A Lonely Tile", map = "sp_a2_fizzler_intro" },

  // CHAPTER 3 - 38 moons

  { pos = Vector(-1566, 1821, 648), name = "Fluorescent Sunbathing", map = "sp_a2_sphere_peek" },
  { pos = Vector(-1909, 1168, 584), name = "A Tough Climb for Wheatley", map = "sp_a2_sphere_peek" },
  { pos = Vector(-1712, 1026, -38), name = "Atop the Raging Panels", map = "sp_a2_sphere_peek" },
  { pos = Vector(-543, 1281, 320), name = "Racing the Stairs", map = "sp_a2_sphere_peek" },
  { pos = Vector(-971, 1982, 640), name = "On a Lonely Hanging Arm", map = "sp_a2_sphere_peek" },

  { pos = Vector(3360, 1152, 586), name = "Corner Across the Observation Room", map = "sp_a2_ricochet" },
  { pos = Vector(1186, 1151, -215), name = "Next to the Dropper", map = "sp_a2_ricochet" },
  { pos = Vector(2038, 1150, -73), name = "Above the Unextended Panels", map = "sp_a2_ricochet" },
  { pos = Vector(2464, 1149, -1032), name = "Behind the Flipping Panels", map = "sp_a2_ricochet" },
  { pos = Vector(2954, 859, -121), name = "On a Stray Rod", map = "sp_a2_ricochet" },

  { pos = Vector(-527, 448, 186), name = "Thinking Outside the Elevator", map = "sp_a2_bridge_intro" },
  { pos = Vector(560, -767, 152), name = "Seeing Not With My Eyes", map = "sp_a2_bridge_intro" },
  { pos = Vector(510, 32, 262), name = "By the Looping Cube", map = "sp_a2_bridge_intro" },

  { pos = Vector(-545, -640, 1333), name = "A Box Above the Entrance", map = "sp_a2_bridge_the_gap" },
  { pos = Vector(-76, -731, 1532), name = "A Useless Dead End Beam", map = "sp_a2_bridge_the_gap" },
  { pos = Vector(-133, -205, 769), name = "Not the Safest Place To Be", map = "sp_a2_bridge_the_gap" },
  { pos = Vector(-123, -181, 1734), name = "There is no Magic", map = "sp_a2_bridge_the_gap" },
  { pos = Vector(-127, -950, 762), name = "Where the Cubes Sink", map = "sp_a2_bridge_the_gap" },

  { pos = Vector(641, -1233, 28), name = "Cute Window to the Turrets", map = "sp_a2_turret_intro" },
  { pos = Vector(844, -1136, 244), name = "Squeezed under the Beam", map = "sp_a2_turret_intro" },
  { pos = Vector(719, -181, 0), name = "An Imperfect Crossfire", map = "sp_a2_turret_intro" },
  { pos = Vector(362, 414, 502), name = "A Pocket of Debris", map = "sp_a2_turret_intro" }, // exit hallway, above debris 
  { pos = Vector(707, 1088, 194), name = "The Alternative Getaway", map = "sp_a2_turret_intro" },

  { pos = Vector(-209, -470, 220), name = "Highly Unstable Ceiling Panels", map = "sp_a2_laser_relays" },
  { pos = Vector(1745, -703, 2), name = "Right Behind You", map = "sp_a2_laser_relays" },
  { pos = Vector(-255, -192, 39), name = "The Alternative Entrance", map = "sp_a2_laser_relays" },

  { pos = Vector(-833, -895, 190), name = "Yet Another Pocket on a Door", map = "sp_a2_turret_blocker" },
  { pos = Vector(-352, 415, 408), name = "On It's Own Pedestal", map = "sp_a2_turret_blocker" },
  { pos = Vector(64, -126, 139), name = "Guarding the Cube", map = "sp_a2_turret_blocker" },
  { pos = Vector(736, -229, 459), name = "Watching from Afar", map = "sp_a2_turret_blocker" }, // corner of chamber
  { pos = Vector(-289, -800, 64), name = "The Fifth Wheel", map = "sp_a2_turret_blocker" },

  { pos = Vector(304, -635, 160), name = "Turret Opera", map = "sp_a2_laser_vs_turret" },
  { pos = Vector(128, 447, 409), name = "Overlooking the Turret Array", map = "sp_a2_laser_vs_turret" },
  { pos = Vector(1217, -482, -562), name = "A Secret Catwalk to the Opera", map = "sp_a2_laser_vs_turret" },

  { pos = Vector(-214, -477, 812), name = "Atop the Staircase to Rattman", map = "sp_a2_pull_the_rug" }, // on top of rattman den staircase
  { pos = Vector(-60, 55, 247), name = "Across the Exit Lift", map = "sp_a2_pull_the_rug" },
  { pos = Vector(131, -1104, 552), name = "Guarded by Rattman's Ghost", map = "sp_a2_pull_the_rug" },
  { pos = Vector(100, -556, 284), name = "Peeking Into a Broken Window", map = "sp_a2_pull_the_rug" },

  // CHAPTER 4 - 25 moons

  { pos = Vector(-1375, 255, -2468), name = "Dane Skip", map = "sp_a2_column_blocker" },
  { pos = Vector(-96, -670, 101), name = "In Front of the Fake Door", map = "sp_a2_column_blocker" },
  { pos = Vector(996, 384, 401), name = "A Pocket in the Wall", map = "sp_a2_column_blocker" },
  { pos = Vector(384, 1274, 54), name = "Under the Blocked Off Ramp", map = "sp_a2_column_blocker" },
  { pos = Vector(260, 7, 579), name = "Another Pointless Rod", map = "sp_a2_column_blocker" },
  { pos = Vector(-192, 1057, 140), name = "Atop a Lonely Turret", map = "sp_a2_column_blocker" },

  { pos = Vector(483, -1024, 550), name = "Overlooking the Chain", map = "sp_a2_laser_chaining" },
  { pos = Vector(-433, -992, 704), name = "The First Link", map = "sp_a2_laser_chaining" },
  { pos = Vector(127, 64, 695), name = "A Slightly Higher Ceiling", map = "sp_a2_laser_chaining" },
  { pos = Vector(672, 544, 256), name = "A Group Assasination", map = "sp_a2_laser_chaining" },
  { pos = Vector(319, 256, -194), name = "Outspeeding the Ramp", map = "sp_a2_laser_chaining" },

  { pos = Vector(8160, -5104, 128), name = "Ridiculously High Catwalk Blocker", map = "sp_a2_triple_laser" },
  { pos = Vector(8220, -5904, 33), name = "Behind the Laser Emitter", map = "sp_a2_triple_laser" },
  { pos = Vector(7343, -5248, 139), name = "Ring Around the Rosie", map = "sp_a2_triple_laser" },
  { pos = Vector(6495, -5375, 338), name = "Where the Elevator Came From", map = "sp_a2_triple_laser" },

  { pos = Vector(-9697, -2014, -54), name = "Swimming in a Goo Pool", map = "sp_a2_bts1" },
  { pos = Vector(-3488, -2112, 33), name = "This Wasn't Here Before", map = "sp_a2_bts1" },
  { pos = Vector(-3199, -1279, 20), name = "A Behind The Scenes View", map = "sp_a2_bts1" },
  { pos = Vector(-1797, -749, 283), name = "Pneumatically Controlled Escape", map = "sp_a2_bts1" },
  { pos = Vector(32, 199, 72), name = "Where's the Deer?", map = "sp_a2_bts1" },

  { pos = Vector(642, -4929, 256), name = "It's All an Illusion", map = "sp_a2_bts2" },
  { pos = Vector(1025, -3266, 112), name = "Predicting the Trap", map = "sp_a2_bts2" },
  { pos = Vector(896, -2205, -22), name = "The Biggest Room For the Smallest Turret", map = "sp_a2_bts2" },
  { pos = Vector(1827, 200, 400), name = "Insisting on the Wrong Path", map = "sp_a2_bts2" },
  { pos = Vector(1174, 1181, 240), name = "Outmaneuvering the Crushing Walls", map = "sp_a2_bts2" },

  // CHAPTER 5 - 24 moons

  { pos = Vector(4852, 3839, 640), name = "Atop the Storage Grid", map = "sp_a2_bts3" },
  { pos = Vector(4724, -1153, 276), name = "An Organized Mess", map = "sp_a2_bts3" },
  { pos = Vector(6017, 753, 128), name = "In the Eyes of a Turret", map = "sp_a2_bts3" },
  { pos = Vector(6978, 1265, 428), name = "Inefficient Tiling", map = "sp_a2_bts3" },
  { pos = Vector(6528, 3007, -232), name = "Where the Cutouts Get Made", map = "sp_a2_bts3" },
  { pos = Vector(9789, 3008, -256), name = "Where the Cutouts Get Cut", map = "sp_a2_bts3" },
  { pos = Vector(9152, 3807, 154), name = "Nepotism", map = "sp_a2_bts3" },
  { pos = Vector(8448, 7008, -306), name = "Where the Cutouts Get Sent", map = "sp_a2_bts3" },
  { pos = Vector(7480, 5059, -2375), name = "See You At the Bottom", map = "sp_a2_bts3" },

  { pos = Vector(1804, -3451, 7420), name = "A Beam of Dead End Cables", map = "sp_a2_bts4" },
  { pos = Vector(2372, -4385, 7292), name = "He's Different", map = "sp_a2_bts4" },
  { pos = Vector(1313, -6080, 6244), name = "Not Even That Hot", map = "sp_a2_bts4" },
  { pos = Vector(-1307, -7561, 6724), name = "An Important Presentation", map = "sp_a2_bts4" },
  { pos = Vector(-3134, -7159, 6272), name = "Not This Way", map = "sp_a2_bts4" },

  { pos = Vector(3577, -1728, 3636), name = "Atop the First Toxin Pipe", map = "sp_a2_bts5" },
  { pos = Vector(3207, 1280, 3979), name = "Where the Panels Fall", map = "sp_a2_bts5" },
  { pos = Vector(2685, 1473, 3846), name = "Simulated Pain", map = "sp_a2_bts5" },
  { pos = Vector(2707, 179, 4508), name = "Neurotoxin Control Panel", map = "sp_a2_bts5" },

  { pos = Vector(220, 3001, 297), name = "An Alternative Path", map = "sp_a2_core" },
  { pos = Vector(169, 1793, -76), name = "The Start of a Broken Bridge", map = "sp_a2_core" },
  { pos = Vector(197, 907, -96), name = "The End of a Broken Bridge", map = "sp_a2_core" },
  { pos = Vector(-1004, 0, 312), name = "Atop The Gate to HER Chamber", map = "sp_a2_core" },
  { pos = Vector(0, -1280, 158), name = "Do It, Press the Button!", map = "sp_a2_core" },
  { pos = Vector(336, -11, -211), name = "Believe Me, It'll Hurt", map = "sp_a2_core" },

  // CHAPTER 6 - 37 moons

  { pos = Vector(-1100, 1000, 4500), name = "Nice View From Up Here", map = "sp_a3_01" },
  { pos = Vector(-871, -1304, 367), name = "An Eerie Fire", map = "sp_a3_01" },
  { pos = Vector(-543, 1101, 1530), name = "Overlooking the Ancient Wreckage", map = "sp_a3_01" },
  { pos = Vector(-579, 2665, 453), name = "KEEP OUT", map = "sp_a3_01" },
  { pos = Vector(254, 1340, 389), name = "A Desolate Ring of Debris", map = "sp_a3_01" },
  { pos = Vector(961, 5149, 45), name = "Keeping Out by Keeping Above", map = "sp_a3_01" },
  { pos = Vector(5729, 4632, -504), name = "Anticlimactic Reveal", map = "sp_a3_01" },

  { pos = Vector(-9500, 100, -3000), name = "Barely Within Reach", map = "sp_a3_03" }, 
  { pos = Vector(-6850, 708, -4590), name = "Brighter Than the Rest", map = "sp_a3_03" },
  { pos = Vector(-5150, 2275, -1430), name = "Atop the Gel Barrels", map = "sp_a3_03" }, 
  { pos = Vector(-4070, -866, -3800), name = "The Tunnels of a Salt Mine", map = "sp_a3_03" }, 
  { pos = Vector(-6080, -2432, -4992), name = "An Echoey Stroll Back", map = "sp_a3_03" },
  { pos = Vector(-8735, 706, -4964), name = "Who's Ready to Make Some Science", map = "sp_a3_03" },
  { pos = Vector(-6780, 1072, -4696), name = "Missing Trophies", map = "sp_a3_03" },
  { pos = Vector(-3211, 2148, -2612), name = "Atop the Gel Pump Filters", map = "sp_a3_03" },

  { pos = Vector(-61, 615, -119), name = "Our First Mobility Gel", map = "sp_a3_jump_intro" },
  { pos = Vector(150, 280, 600), name = "A Tricky Corner Behind the Supports", map = "sp_a3_jump_intro" },
  { pos = Vector(-1721, 563, 912), name = "Inside the Office", map = "sp_a3_jump_intro" },
  { pos = Vector(-1750, 560, 820), name = "Not Inside the Office", map = "sp_a3_jump_intro" }, 
  { pos = Vector(-960, 144, 1975), name = "Atop the Tallest Beam", map = "sp_a3_jump_intro" },
  { pos = Vector(-1343, 1027, 1824), name = "Above the Test Chamber Ceiling", map = "sp_a3_jump_intro" },

  { pos = Vector(-1230, 865, 200), name = "An Abandoned Puzzle Piece", map = "sp_a3_bomb_flings" }, 
  { pos = Vector(530, 1335, 960), name = "The Vents With No Start", map = "sp_a3_bomb_flings" },
  { pos = Vector(-1224, 41, -663), name = "Above the Entrance Elevator", map = "sp_a3_bomb_flings" },
  { pos = Vector(-276, 238, 33), name = "Not Making Up Your Own Rules", map = "sp_a3_bomb_flings" },
  { pos = Vector(-489, -620, 677), name = "Watching From Outside the Chamber", map = "sp_a3_bomb_flings" },

  { pos = Vector(1090, -1610, 1600), name = "An Unstable Plank", map = "sp_a3_crazy_box" },
  { pos = Vector(630, -700, 2280), name = "Atop the Exit Lift", map = "sp_a3_crazy_box" },
  { pos = Vector(2321, -1377, 943), name = "The Barrier Between Chambers", map = "sp_a3_crazy_box" },
  { pos = Vector(1541, -1072, 550), name = "On Top of the Chambers", map = "sp_a3_crazy_box" },
  { pos = Vector(1208, 817, 1538), name = "On Toppest of the Chambers", map = "sp_a3_crazy_box" },

  { pos = Vector(-1342, -2753, -5840), name = "Hiding in the Machinery", map = "sp_a3_transition01" },
  { pos = Vector(-2871, 557, -4252), name = "Atop the Control Room", map = "sp_a3_transition01" },
  { pos = Vector(-3612, 864, -4816), name = "In the Abandoned Offices", map = "sp_a3_transition01" },
  { pos = Vector(-1513, -2003, -3941), name = "Balancing Across the Pipes", map = "sp_a3_transition01" },
  { pos = Vector(-5007, 722, -4024), name = "A Space-Warping Icebreaker", map = "sp_a3_transition01" },
  { pos = Vector(-3717, -16, -5930), name = "Pretty Dark Up Here", map = "sp_a3_transition01" },

  // CHAPTER 7 - 33 moons

  { pos = Vector(-1600, -910, 1000), name = "Where the Propulsion Gel Flows", map = "sp_a3_speed_ramp" },
  { pos = Vector(1100, -110, 1120), name = "Overseeing the Fling From Above", map = "sp_a3_speed_ramp" },
  { pos = Vector(53, 384, -8), name = "Under the Speed Ramp", map = "sp_a3_speed_ramp" },
  { pos = Vector(-961, 1665, 146), name = "A Dropper With No Cube Under", map = "sp_a3_speed_ramp" },
  { pos = Vector(-560, -175, 512), name = "Why Does She Know This Woman", map = "sp_a3_speed_ramp" },
  { pos = Vector(-962, 178, 954), name = "Across the Strange Button", map = "sp_a3_speed_ramp" },
  { pos = Vector(392, -248, 408), name = "An Oddly Shaped Vent", map = "sp_a3_speed_ramp" },

  { pos = Vector(1016, -506, 25), name = "Nearly Collapsing Lights", map = "sp_a3_speed_flings" },
  { pos = Vector(2522, 783, 748), name = "King of the Pipes", map = "sp_a3_speed_flings" },
  { pos = Vector(2811, -115, -476), name = "Blue Moon Under the Blue Gel", map = "sp_a3_speed_flings" },
  { pos = Vector(1087, 384, -64), name = "Highly Turbulent Landing", map = "sp_a3_speed_flings" },
  { pos = Vector(2176, 1646, -249), name = "On the Tail of the Flipper", map = "sp_a3_speed_flings" },
  { pos = Vector(513, 1154, 671), name = "On the Exit Sign", map = "sp_a3_speed_flings" },

  { pos = Vector(3360, 160, -2880), name = "Behind the Receptionist", map = "sp_a3_portal_intro" },
  { pos = Vector(2028, -951, -2428), name = "Pipe Under the Floor", map = "sp_a3_portal_intro" },
  { pos = Vector(2314, 1088, -1780), name = "Propulsion Pump Control Input Flow", map = "sp_a3_portal_intro" },
  { pos = Vector(1438, 1084, -1125), name = "Behind the Heavy Crushers", map = "sp_a3_portal_intro" }, 
  { pos = Vector(444, -588, 1440), name = "Routing Up the Conversion Gel", map = "sp_a3_portal_intro" },
  { pos = Vector(3584, 158, 6000), name = "Reward After a Tall Climb", map = "sp_a3_portal_intro" },
  { pos = Vector(1341, 2257, -1985), name = "Working Hard on Pump 02", map = "sp_a3_portal_intro" },
  { pos = Vector(2151, 740, -1642), name = "It Flew Off!", map = "sp_a3_portal_intro" },
  { pos = Vector(1727, -1408, -1307), name = "Paper Thin Walls", map = "sp_a3_portal_intro" },
  { pos = Vector(-289, -544, 825), name = "A Profoundly Useless Pole", map = "sp_a3_portal_intro" },
  { pos = Vector(2944, -191, 720), name = "Intermediary Volunteer Checking", map = "sp_a3_portal_intro" },

  { pos = Vector(-300, 976, -2100), name = "A Mislabelled Pipe Cutting Into the Wall", map = "sp_a3_end" },
  { pos = Vector(-1480, 526, -2330), name = "Sneakily Hiding Behind the Pipe", map = "sp_a3_end" },
  { pos = Vector(-1000, -1144, 3080), name = "Keep Out, They Said", map = "sp_a3_end" },
  { pos = Vector(232, 269, -5010), name = "Holding Up the Gel Tub", map = "sp_a3_end" },
  { pos = Vector(532, 256, -3792), name = "Behind the Bouncy Plate", map = "sp_a3_end" },
  { pos = Vector(-1456, 592, -3012), name = "A Corner Just Under Eye Level", map = "sp_a3_end" }
  { pos = Vector(-863, -15, -1635), name = "Ventilating", map = "sp_a3_end" },
  { pos = Vector(-1121, -344, 1540), name = "Know Your Paradoxes", map = "sp_a3_end" },
  { pos = Vector(-2657, -482, 1191), name = "A Gel Barrel in the Dark", map = "sp_a3_end" },

  // CHAPTER 8 - 36 moons

  { pos = Vector(-320, 127, 440), name = "Blanketed By a Strange Tube", map = "sp_a4_intro" },
  { pos = Vector(730, -189, 210), name = "Between Two Types of Vents", map = "sp_a4_intro" }
  { pos = Vector(2145, 34, 700), name = "Now, Do It Again!", map = "sp_a4_intro" },
  { pos = Vector(1113, -336, 696), name = "Observation Staircase", map = "sp_a4_intro" },

  { pos = Vector(1664, 512, -168), name = "Our First Excursion Funnel", map = "sp_a4_tb_intro" },
  { pos = Vector(1983, 128, 517), name = "Keeping the Cube Company", map = "sp_a4_tb_intro" },
  { pos = Vector(1506, 852, 448), name = "An Ominous Pellet Launcher", map = "sp_a4_tb_intro" },

  { pos = Vector(366, 941, -198), name = "Bordering the Bottomless Void", map = "sp_a4_tb_trust_drop" },
  { pos = Vector(256, 332, 812), name = "Behind the Exit Bridge", map = "sp_a4_tb_trust_drop" },
  { pos = Vector(-125, 625, 305), name = "An Unevenly Balanced Block", map = "sp_a4_tb_trust_drop" },

  { pos = Vector(-680, 1580, 570), name = "Racing the Moving Chamber", map = "sp_a4_tb_wall_button" },
  { pos = Vector(543, 959, 0), name = "Crawling In With a Helper", map = "sp_a4_tb_wall_button" },
  { pos = Vector(-674, 1408, 155), name = "Right on Target", map = "sp_a4_tb_wall_button" },

  { pos = Vector(244, 2696, 768), name = "Sniping the Turret From Afar", map = "sp_a4_tb_polarity" },
  { pos = Vector(-575, 800, 128), name = "Behind the Messy Panels", map = "sp_a4_tb_polarity" },
  { pos = Vector(-241, 944, 411), name = "Atop the Hanging Arms", map = "sp_a4_tb_polarity" },

  { pos = Vector(-682, -484, 410), name = "Following the Prop Flow", map = "sp_a4_tb_catch" },
  { pos = Vector(-472, 352, 541), name = "On the Misplaced Pellet Launcher", map = "sp_a4_tb_catch" },
  { pos = Vector(-469, 992, 192), name = "Under the Angled Panels", map = "sp_a4_tb_catch" },

  { pos = Vector(-223, -579, 1232), name = "Behind a Moron's Face", map = "sp_a4_stop_the_box" },
  { pos = Vector(642, -223, 803), name = "Under the Floor-Level Catwalk", map = "sp_a4_stop_the_box" },
  { pos = Vector(-771, 318, 810), name = "A Different Faith Plate", map = "sp_a4_stop_the_box" },

  { pos = Vector(308, -81, 786), name = "Above a Wall-Breaking Tube", map = "sp_a4_laser_catapult" },
  { pos = Vector(512, 269, 448), name = "Close to the Funnel Emitter", map = "sp_a4_laser_catapult" },
  { pos = Vector(126, -793, 695), name = "Lit by the Observation Room", map = "sp_a4_laser_catapult" },

  { pos = Vector(-420, -2434, 810), name = "Atop the Diagonal Tubes", map = "sp_a4_laser_platform" }
  { pos = Vector(378, -1922, 696), name = "Flying Freely in the Middle", map = "sp_a4_laser_platform" },
  { pos = Vector(-66, -1138, 672), name = "A Concealed Lamp", map = "sp_a4_laser_platform" },
  { pos = Vector(944, -2435, 426), name = "On the Observation Room Edge", map = "sp_a4_laser_platform" },
  { pos = Vector(636, -609, 17), name = "Curve It Around the Funnel", map = "sp_a4_laser_platform" },
  { pos = Vector(2674, -526, -2048), name = "A Rocky Landing", map = "sp_a4_laser_platform" },
  { pos = Vector(2648, -1580, -2024), name = "Nope, It's Not Solid", map = "sp_a4_laser_platform" },

  { pos = Vector(255, 1376, 480), name = "Catching the Gel Flow", map = "sp_a4_speed_tb_catch" },
  { pos = Vector(-2335, 560, 272), name = "All That Remains of a Ceiling", map = "sp_a4_speed_tb_catch" },
  { pos = Vector(-2689, 2196, 8), name = "Backtracking on the Catwalk", map = "sp_a4_speed_tb_catch" },

  { pos = Vector(1660, -64, 400), name = "On the Roof of the Entrance", map = "sp_a4_jump_polarity" },
  { pos = Vector(927, -482, 292), name = "Behind the Extending Panel", map = "sp_a4_jump_polarity" },
  { pos = Vector(1415, 1023, 295), name = "Under the Funnel-Conducting Tile", map = "sp_a4_jump_polarity" },
  { pos = Vector(1279, 555, 544), name = "A Small but Cozy Observation Room", map = "sp_a4_jump_polarity" },

  // CHAPTER 9

  { pos = Vector(-3711, -7424, 155), name = "It's a Decoy Button!", map = "sp_a4_finale1" },
  { pos = Vector(-4855, -4306, -633), name = "Deviating From the Trajectory", map = "sp_a4_finale1" },
  { pos = Vector(-5536, -2472, -938), name = "Funnelophobia", map = "sp_a4_finale1" },
  { pos = Vector(-8928, -2049, -260), name = "The Part Where He Kills You", map = "sp_a4_finale1" },
  { pos = Vector(-13036, -2271, 749), name = "An Incredibly Strong Light", map = "sp_a4_finale1" },

  { pos = Vector(-679, 320, 18), name = "You Get All the Panels 'Cept For This One", map = "sp_a4_finale2" },
  { pos = Vector(495, 192, 28), name = "Spinny Blade Wall!", map = "sp_a4_finale2" },
  { pos = Vector(252, -847, -459), name = "Mashy Spike Plate Evaded", map = "sp_a4_finale2" },
  { pos = Vector(-2975, -1058, -108), name = "Overseeing the Turret Predicament", map = "sp_a4_finale2" },

  { pos = Vector(693, -354, -261), name = "Viable Death Option", map = "sp_a4_finale3" },
  { pos = Vector(-575, 119, -297), name = "A Bygone Catwalk", map = "sp_a4_finale3" },
  { pos = Vector(980, 3478, 384), name = "Following Your Final Funnel Ride", map = "sp_a4_finale3" },

  { pos = Vector(0, -48, -140), name = "Revenge", map = "sp_a4_finale4" },

];

smo.moon <- {
  mdl = "moon.mdl",
  size = 0.5,
  ang = 0,
  table = [],
  char = "•",
  bgstr = " Moons: ",
  str = "",
  chapternum = 0
};

smo.moon.setup <- function() {

  local storage = GetPlayer().GetName();

  if (storage.len() != 0) {

    smo.moon.odyssey.enabled = storage[0] == 'T' ? 1 : 0;

    for (local i = 1; i < storage.len(); i ++) {
      if (storage[i] == '1') smo.moon.table.push(i-1);
    }

  }
  
  foreach (curr in smo.moon.table) {
    if (smo.moonlist[curr].map == GetMapName().tolower()) {
      smo.moon.str += smo.moon.char;
    }
  }

  foreach (index, curr in smo.moonlist) {
    if (curr.map == GetMapName().tolower()) {
      smo.moon.create(index);
    }
  }

  foreach (index, chapter in smo.moon.chapters) {
    foreach (map in chapter) {

      if (map == GetMapName().tolower()) {
        smo.moon.chapternum = index;
      }

    }
  }

  local txt_bg = ppmod.text("", 0, 1);
  txt_bg.SetColor("70 70 70");
  txt_bg.SetChannel(5);

  local txt_fg = ppmod.text("", 0, 1);
  txt_fg.SetColor("100 150 200");

  ppmod.interval(function(txt = [txt_fg, txt_bg]) {

    if (smo.moon.bgstr.len() <= 8) return;

    txt[0].SetText(" Moons: " + smo.moon.str);
    txt[0].Display();
    txt[1].SetText(smo.moon.bgstr);
    txt[1].Display();

    smo.moon.ang = (smo.moon.ang + 7) % 360;
    
  }, 0, "smo_moon_interval");

  ppmod.wait(function() {

    local endtrig = null;

    switch (GetMapName().tolower()) {

      case "sp_a1_intro7" : endtrig = ppmod.trigger(Vector(-2208, 244, 1279), Vector(96, 29, 63)); break;
      case "sp_a1_wakeup" : endtrig = ppmod.trigger(Vector(10381, 1212, 313), Vector(110, 127, 42)); break;
      case "sp_a2_bts1" : endtrig = ppmod.trigger(Vector(831, -1206, 151), Vector(65, 54, 215)); break;
      case "sp_a2_bts2" : endtrig = ppmod.trigger(Vector(2208, 1725, 728), Vector(64, 50, 103)); break;
      case "sp_a2_bts3" : endtrig = ppmod.trigger(Vector(5954, 4792, -1662), Vector(62, 54, 130)); break;
      case "sp_a2_bts4" : endtrig = ppmod.trigger(Vector(-3911, -7233, 6432), Vector(51, 63, 160)); break;
      case "sp_a2_bts5" : endtrig = ppmod.trigger(Vector(2472, 672, 4417), Vector(17, 32, 65)); break;
      case "sp_a2_core" : endtrig = ppmod.trigger(Vector(1, 304, -9752), Vector(81, 81, 233)); break;
      case "sp_a3_01"   : endtrig = ppmod.trigger(Vector(5860, 4524, -419), Vector(84, 76, 85)); break;
      case "sp_a3_portal_intro"   : endtrig = ppmod.trigger(Vector(3839, 239, 5694), Vector(64, 31, 62)); break;
      case "sp_a4_laser_platform" : endtrig = ppmod.trigger(Vector(3472, -1055, -2437), Vector(110, 127, 42)); break;

    }

    if (!endtrig) {

      local ent = null, elevatordist = 0, lastelevator = null, trigz = 1024;
      while (ent = ppmod.get("models/elevator/elevator_b.mdl", ent)) {

        local dist = (GetPlayer().GetOrigin() - ent.GetOrigin()).LengthSqr();
        if (dist >= elevatordist) {
          elevatordist = dist;
          lastelevator = ent;
        } 

      }

      while (ent = ppmod.get("models/props_underground/elevator_a.mdl", ent)) {

        local dist = (GetPlayer().GetOrigin() - ent.GetOrigin()).LengthSqr();
        if (dist >= elevatordist) {
          elevatordist = dist;
          lastelevator = ent;
          trigz = 128;
        }

      }

      if (lastelevator) {
        endtrig = ppmod.trigger(lastelevator.GetCenter(), Vector(128, 128, trigz));
        ppmod.fire(endtrig, "SetParent", lastelevator.GetName());
      }

    }

    if (endtrig && endtrig.IsValid()) {
      ppmod.addscript(endtrig, "OnStartTouch", "smo.moon.odyssey.check()");
    }

  }, 1);


}

smo.moon.create <- function(id) {

  smo.moon.bgstr += smo.moon.char;

  foreach (curr in smo.moon.table) {
    if (curr == id) return;
  }

  local pos = smo.moonlist[id].pos;
  local title = smo.moonlist[id].name;
  local name = "smo_moon_" + id + "_";

  ppmod.create(smo.moon.mdl, function(prop, id = id, name = name) {

    local pos = smo.moonlist[id].pos;
    local title = smo.moonlist[id].name;

    prop.SetOrigin(pos + Vector(0, 0, 32));
    prop.SetAngles(0, 0, 0);

    ppmod.keyval(prop, "Targetname", name + "prop");
    ppmod.keyval(prop, "CollisionGroup", 1);
    ppmod.keyval(prop, "ModelScale", smo.moon.size);
    ppmod.fire(prop, "Color", "100 150 200");

    ppmod.interval(function(prop = prop) {
      prop.SetAngles(0, smo.moon.ang, 0);
    }, 0, name + "rotate");

    local trigger = ppmod.trigger(pos + Vector(0, 0, 20), Vector(20, 20, 20));
    ppmod.keyval(trigger, "Targetname", name + "trigger");
    ppmod.addscript(trigger, "OnStartTouch", "smo.moon.collect(" + id + ")");

    local txt = ppmod.text("YOU GOT A MOON!", -1, 0.6);
    txt.SetFade(0.3, 0.3);
    txt.SetChannel(3);
    ppmod.keyval(txt.GetEntity(), "Targetname", name + "text");
    ppmod.keyval(txt.GetEntity(), "HoldTime", 5);

    txt = ppmod.text(" ______________________\n" + title, -1, 0.627);
    txt.SetFade(0.3, 0.3);
    txt.SetChannel(1);
    ppmod.keyval(txt.GetEntity(), "Targetname", name + "text");
    ppmod.keyval(txt.GetEntity(), "HoldTime", 5);

    txt = ppmod.text("______________________", -1, 0.627);
    txt.SetFade(0.3, 0.3);
    txt.SetChannel(4);
    ppmod.keyval(txt.GetEntity(), "Targetname", name + "text");
    ppmod.keyval(txt.GetEntity(), "HoldTime", 5);

    ppmod.give("light_dynamic", function (ent, id = id, name = name) {

      local pos = smo.moonlist[id].pos;
      local title = smo.moonlist[id].name;

      ent.SetOrigin(pos + Vector(24, 0, 32));
      ent.SetAngles(0, 0, 0);

      ppmod.keyval(ent, "Targetname", name + "smo_dlight");
      ppmod.keyval(ent, "SpawnFlags", 1);
      ppmod.keyval(ent, "_light", "100 150 200");
      ppmod.keyval(ent, "brightness", 2);
      ppmod.keyval(ent, "distance", 128);

      ppmod.fire(ent, "SetParent", name + "prop");
      ppmod.fire(ent, "TurnOn");

    });

    ppmod.give("light_dynamic", function (ent, id = id, name = name) {

      local pos = smo.moonlist[id].pos;
      local title = smo.moonlist[id].name;

      ent.SetOrigin(pos + Vector(-24, 0, 32));
      ent.SetAngles(0, 0, 0);

      ppmod.keyval(ent, "Targetname", name + "smo_dlight");
      ppmod.keyval(ent, "SpawnFlags", 1);
      ppmod.keyval(ent, "_light", "100 150 200");
      ppmod.keyval(ent, "brightness", 2);
      ppmod.keyval(ent, "distance", 128);

      ppmod.fire(ent, "SetParent", name + "prop");
      ppmod.fire(ent, "TurnOn");

    });

    ppmod.interval(function(name = name) {
      EntFire(name + "smo_dlight", "TurnOn");
    }, 0, name + "smo_dlight_interval");

  });

}

smo.moon.collect <- function(id) {

  local spawner = ppmod.get("info_player_start").GetOrigin();
  local lightpos = spawner.x+" "+spawner.y+" "+(spawner.z + 32);
  local name = "smo_moon_" + id + "_";

  EntFire(name + "text", "Display");
  EntFire(name + "smo_dlight", "ClearParent");
  EntFire(name + "smo_dlight", "SetLocalOrigin", lightpos);
  EntFire(name + "smo_dlight_interval", "Kill");
  EntFire(name + "prop", "FadeAndKill");
  EntFire(name + "rotate", "Kill");

  EntFire("smo_cap", "DisableDraw");

  smo.moon.str += smo.moon.char;

  smo.moon.table.push(id);

  local storage = smo.moon.odyssey.enabled == 1 ? "T" : "F";
  for (local i = 0; i < smo.moonlist.len(); i ++) storage += "0";

  for (local i = 0; i < smo.moon.table.len(); i ++) {
    storage = storage.slice(0, smo.moon.table[i] + 1) + "1" + storage.slice(smo.moon.table[i] + 2);
  }

  ppmod.keyval(GetPlayer(), "Targetname", storage);

}

smo.moon.chapters <- [
  [
    "sp_a1_intro1",
    "sp_a1_intro2",
    "sp_a1_intro3",
    "sp_a1_intro4",
    "sp_a1_intro5",
    "sp_a1_intro6",
    "sp_a1_intro7",
    "sp_a1_wakeup",
    "sp_a2_intro",
  ],
  [
    "sp_a2_laser_intro",
    "sp_a2_laser_stairs",
    "sp_a2_dual_lasers",
    "sp_a2_laser_over_goo",
    "sp_a2_catapult_intro",
    "sp_a2_trust_fling",
    "sp_a2_pit_flings",
    "sp_a2_fizzler_intro"
  ],
  [
    "sp_a2_sphere_peek",
    "sp_a2_ricochet",
    "sp_a2_bridge_intro",
    "sp_a2_bridge_the_gap",
    "sp_a2_turret_intro",
    "sp_a2_laser_relays",
    "sp_a2_turret_blocker",
    "sp_a2_laser_vs_turret",
    "sp_a2_pull_the_rug"
  ],
  [
    "sp_a2_column_blocker",
    "sp_a2_laser_chaining",
    "sp_a2_triple_laser",
    "sp_a2_bts1",
    "sp_a2_bts2"
  ],
  [
    "sp_a2_bts3",
    "sp_a2_bts4",
    "sp_a2_bts5",
    "sp_a2_bts6",
    "sp_a2_core"
  ],
  [
    "sp_a3_00",
    "sp_a3_01",
    "sp_a3_03",
    "sp_a3_jump_intro",
    "sp_a3_bomb_flings",
    "sp_a3_crazy_box",
    "sp_a3_transition01"
  ],
  [
    "sp_a3_speed_ramp",
    "sp_a3_speed_flings",
    "sp_a3_portal_intro",
    "sp_a3_end"
  ],
  [
    "sp_a4_intro",
    "sp_a4_tb_intro",
    "sp_a4_tb_trust_drop",
    "sp_a4_tb_wall_button",
    "sp_a4_tb_polarity",
    "sp_a4_tb_catch",
    "sp_a4_stop_the_box",
    "sp_a4_laser_catapult",
    "sp_a4_laser_platform",
    "sp_a4_speed_catch",
    "sp_a4_jump_polarity"
  ],
  [
    "sp_a4_finale1",
    "sp_a4_finale2",
    "sp_a4_finale3",
    "sp_a4_finale4"
  ]
];
smo.moon.levels <- [
  [
    "Container Ride",
    "Portal Carousel",
    "Portal Gun",
    "Smooth Jazz",
    "Cube Momentum",
    "Future Starter",
    "Secret Panel",
    "Wakeup",
    "Incinerator"
  ],
  [
    "Laser Intro",
    "Laser Stairs",
    "Dual Lasers",
    "Laser Over Goo",
    "Catapult Intro",
    "Trust Fling",
    "Pit Flings",
    "Fizzler Intro"
  ],
  [
    "Ceiling Catapult",
    "Ricochet",
    "Bridge Intro",
    "Bridge the Gap",
    "Turret Intro",
    "Laser Relays",
    "Turret Blocker",
    "Laser vs Turret",
    "Pull the Rug"
  ],
  [
    "Column Blocker",
    "Laser Chaining",
    "Triple Laser",
    "Jail Break",
    "Escape"
  ],
  [
    "Turret Factory",
    "Turret Sabotage",
    "Neurotoxin Sabotage",
    "Tube Ride",
    "Core"
  ],
  [
    "Long Fall",
    "Underground",
    "Cave Johnson",
    "Repulsion Intro",
    "Bomb Flings",
    "Crazy Box",
    "PotatOS"
  ],
  [
    "Propulsion Intro",
    "Propulsion Flings",
    "Conversion Intro",
    "Three Gels"
  ],
  [
    "Test",
    "Funnel Intro",
    "Ceiling Button",
    "Wall Button",
    "Polarity",
    "Funnel Catch",
    "Stop the Box",
    "Laser Catapult",
    "Laser Platform",
    "Propulsion Catch",
    "Repulsion Polarity"
  ],
  [
    "Finale 1",
    "Finale 2",
    "Finale 3",
    "Finale 4"
  ]
];

smo.moon.required <- [
  10,
  25,
  35,
  50,
  60,
  75,
  85,
  100,
  100
];

smo.moon.odyssey <- {

  currchapter = 0,
  enabled = 0,
  chaptertext = null,

  count = function () {

    local totalcount = 0, havecount = 0, found = false;

    foreach (map in smo.moon.chapters[smo.moon.odyssey.currchapter]) {

      foreach (id, moon in smo.moonlist) {
        if (moon.map == map) {

          totalcount ++;

          foreach (collected in smo.moon.table) {
            if (id == collected) {
              havecount ++;
              break;
            }
          }

        }
      }

    }

    return [totalcount, havecount];

  },

  textoffset = 1.1,
  textvelocity = -0.08,
  statstext = null,

  show = function() {

    smo.moon.odyssey.currchapter = smo.moon.chapternum;

    smo.moon.odyssey.enabled = 1;

    ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);

    EntFire("smo_moon_interval", "Kill");
    SendToConsole("fadeout 0.5 30 30 30 0");

    ppmod.wait(function() {

      smo.moon.odyssey.chaptertext = ppmod.text("Chapter " + (smo.moon.chapternum + 1), -1, 0.1);
      smo.moon.odyssey.chaptertext.SetChannel(3);

      ppmod.interval(function() {
        smo.moon.odyssey.chaptertext.Display();
      }, 0, "smo_moon_chaptertext_interval");

      ppmod.interval(function() {
        
        smo.moon.odyssey.textvelocity *= 0.9;
        smo.moon.odyssey.textoffset += smo.moon.odyssey.textvelocity;
        smo.moon.odyssey.chaptertext.SetPosition(-1, smo.moon.odyssey.textoffset);

        if (smo.moon.odyssey.textoffset < 0.382) {

          ppmod.get("smo_moon_textanim_interval").Destroy();

          local count = smo.moon.odyssey.count();

          local dialogue;
          local remaining = smo.moon.required[smo.moon.chapternum] - smo.moon.table.len();

          if (GetMapName().tolower() == "sp_a4_finale4") {

            remaining = smo.moonlist.len() - smo.moon.table.len();
            if (remaining > 0) {
              dialogue = "You have collected " + smo.moon.table.len() + " out of the " + smo.moonlist.len() + " total moons" +
              "\nEvery chapter is now unlocked\nFeel free to go back to collect the remaining " + remaining + " moons";
            } else {
              dialogue = "Congratulations!\nYou have collected all " + smo.moonlist.len() + "moons\nThank you for playing!";
            }

          } else if (remaining > 0) {
            dialogue = "The Odyssey needs " + remaining + " more moons";
          } else {
            dialogue = "The Odyssey is ready to go";
          }

          smo.moon.odyssey.statstext = ppmod.text(
            "Odyssey: " + smo.moon.table.len() + " / " + smo.moon.required[smo.moon.chapternum] +
            "\nIn this chapter: " + count[1] + " / " + count[0] +
            "\n\n" + dialogue +
            "\nPress the use key to select a level",
            -1, 0.47
          );

          smo.moon.odyssey.statstext.SetChannel(2);
          smo.moon.odyssey.statstext.SetFade(0.5, 0);
          smo.moon.odyssey.statstext.Display(86400);
          
          smo.moon.odyssey.enabled = 2;

        }

      }, 0, "smo_moon_textanim_interval");

    }, 0.7);

  },

  selected = 0,
  listanim = 0,
  listmove = false,
  list = function() {

    if (smo.moon.odyssey.enabled == 3) {

      local required = 0;
      if (smo.moon.chapternum > 0) required = smo.moon.required[smo.moon.chapternum - 1];

      if (

        required <= smo.moon.table.len() &&
        GetMapName().tolower() != smo.moon.chapters[smo.moon.chapternum][smo.moon.odyssey.selected]
        
      ) {

        local storage = smo.moon.odyssey.currchapter == smo.moon.chapternum ? "T" : "F";
        for (local i = 0; i < smo.moonlist.len(); i ++) storage += "0";

        for (local i = 0; i < smo.moon.table.len(); i ++) {
          storage = storage.slice(0, smo.moon.table[i] + 1) + "1" + storage.slice(smo.moon.table[i] + 2);
        }

        ppmod.keyval(GetPlayer(), "Targetname", storage);

        local landmark = ppmod.get("info_landmark_exit");
        if (landmark) GetPlayer().SetOrigin(landmark.GetOrigin());
        
        ppmod.fire("weapon_portalgun", "Kill");

        ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);

        local changelevel = Entities.CreateByClassname("point_changelevel");
        ppmod.fire(changelevel, "ChangeLevel", smo.moon.chapters[smo.moon.chapternum][smo.moon.odyssey.selected]);

      }

      return;

    }
    smo.moon.odyssey.enabled = 3;

    smo.moon.odyssey.statstext.SetFade(0, 0.25);
    smo.moon.odyssey.statstext.Display();

    ppmod.wait(function() {

      foreach (index, map in smo.moon.chapters[smo.moon.chapternum]) {
        if (map == GetMapName().tolower()) {
          smo.moon.odyssey.selected = index;
          break;
        }
      }

      smo.moon.odyssey.statstext.SetText("Use movement keys to select a level\nPress the use key to confirm selection");

      smo.moon.odyssey.statstext.SetFade(0.5, 0);
      smo.moon.odyssey.statstext.Display(86400);

      local required = 0;
      if (smo.moon.chapternum > 0) required = smo.moon.required[smo.moon.chapternum - 1];

      local text = ppmod.text(smo.moon.levels[smo.moon.chapternum][smo.moon.odyssey.selected], -1, 0.6);
      text.SetColor("75 75 75");
      text.SetFade(0.5, 0);
      text.Display();

      ppmod.wait(function(text = text) {

        text.SetFade(0, 0);

        ppmod.interval(function(text = text) {

          if (smo.moon.odyssey.listanim == 0 && !smo.moon.odyssey.listmove) {

            if (smo.move.gameui.moveleft) {

              smo.moon.odyssey.listanim = -15;
              smo.moon.odyssey.listmove = true;

            } else if (smo.move.gameui.moveright) {

              smo.moon.odyssey.listanim = 15;
              smo.moon.odyssey.listmove = true;

            }

          }

          local listanim = smo.moon.odyssey.listanim;

          local paddingL = "";
          local paddingR = "";

          if (listanim > 0) {

            if (smo.moon.odyssey.listmove) {

              for (local i = pow(15 - listanim, 1.6); i > 0; i --) paddingR += " ";

              if (listanim == 1) {

                smo.moon.odyssey.listanim = -15;
                smo.moon.odyssey.listmove = false;

                if (smo.moon.odyssey.selected == smo.moon.levels[smo.moon.chapternum].len() - 1) {
                  if (smo.moon.chapternum == 8) smo.moon.chapternum = 0;
                  else smo.moon.chapternum ++;
                  smo.moon.odyssey.selected = 0;
                } else smo.moon.odyssey.selected ++;

                smo.moon.odyssey.chaptertext.SetText("Chapter " + (smo.moon.chapternum + 1));

              } else smo.moon.odyssey.listanim --;

            } else {

              for (local i = pow(listanim, 1.6); i > 0; i --) paddingR += " ";
              smo.moon.odyssey.listanim --;

            }

          } else if (listanim < 0) {

            if (smo.moon.odyssey.listmove) {

              for (local i = pow(15 + listanim, 1.6); i > 0; i --) paddingL += " ";

              if (listanim == -1) {

                smo.moon.odyssey.listanim = 15;
                smo.moon.odyssey.listmove = false;

                if (smo.moon.odyssey.selected == 0) {
                  if (smo.moon.chapternum == 0) smo.moon.chapternum = 8;
                  else smo.moon.chapternum --;
                  smo.moon.odyssey.selected = smo.moon.levels[smo.moon.chapternum].len() - 1;
                } else smo.moon.odyssey.selected --;

                smo.moon.odyssey.chaptertext.SetText("Chapter " + (smo.moon.chapternum + 1));

              } else smo.moon.odyssey.listanim ++;

            } else {

              for (local i = pow(-listanim, 1.6); i > 0; i --) paddingL += " ";
              smo.moon.odyssey.listanim ++;

            }

          }

          local required = 0;
          if (smo.moon.chapternum > 0) required = smo.moon.required[smo.moon.chapternum - 1];

          local step = 17;
          if (
            required > smo.moon.table.len() ||
            GetMapName().tolower() == smo.moon.chapters[smo.moon.chapternum][smo.moon.odyssey.selected]
          ) {
            step = 5;
          }

          local brightness = step * (abs(smo.moon.odyssey.listanim));
          if (!smo.moon.odyssey.listmove) brightness = step * 15 - brightness;
          
          text.SetColor(brightness+" "+brightness+" "+brightness);

          text.SetText(paddingL + smo.moon.levels[smo.moon.chapternum][smo.moon.odyssey.selected] + paddingR);
          text.Display();

        });

      }, 0.5);

    }, 0.5);

  },
  
  check = function () {

    if (smo.moon.odyssey.enabled) {
      
      smo.moon.odyssey.show();

    } else {

      local chapter = smo.moon.chapters[smo.moon.chapternum];
      if (chapter[chapter.len() - 1] == GetMapName().tolower()) {
        smo.moon.odyssey.show();
      }

    }

  }

}

smo.moon.setcount <- function(amount) {

  local storage = smo.moon.odyssey.enabled == 1 ? "T" : "F";

  for (local i = 0; i < amount; i ++) {
    storage += "1";
    smo.moon.table.push(i);
  }

  ppmod.keyval(GetPlayer(), "Targetname", storage);

}

  smo.move.setup();
  smo.cap.setup();
  smo.moon.setup();

  try {
    local mapscripts = {
      sp_a4_finale4 = function () {
        smo.setup <- function() {
          ppmod.addscript("moon_portal_detector", "OnStartTouchPortal", "smo.moon.odyssey.show()");
        }
      },
      sp_a1_intro3 = function () {
        smo.setup <- function() {
          EntFire("backtrack_brush", "Kill");
        }
      },
      sp_a2_turret_intro = function () {
        smo.setup <- function() {
  
          ppmod.give("npc_security_camera", function (ent) {

            ent.SetOrigin(Vector(640.5, 638.5, 102.5));
            ent.SetAngles(0, 0, 0);

            ppmod.fire(ent, "Wake");

          });

        }
      },
      sp_a2_laser_stairs = function () {
        smo.setup <- function() {

          local panelTrig = ppmod.trigger(Vector(-148, 693, -31), Vector(36, 27, 65));
          ppmod.addscript(panelTrig, "OnStartTouch", function() {
            ppmod.fire("robot_eyepeek_07", "SetAnimation", "eyepeek_07open");
            ppmod.fire("robot_eyepeek_08", "SetAnimation", "eyepeek_08open");
            ppmod.fire("robot_eyepeek_07", "SetDefaultAnimation", "eyepeek_07open_idle", 1);
            ppmod.fire("robot_eyepeek_08", "SetDefaultAnimation", "eyepeek_08open_idle", 1);
          });

        }
      },
      sp_a2_fizzler_intro = function () {
        smo.setup <- function() {
  
          local eleTrig = ppmod.trigger(Vector(-981, -128, -960), Vector(16, 16, 4));
          ppmod.addscript(eleTrig, "OnStartTouch", function() {

            local push = Entities.CreateByClassname("point_push");
            ppmod.keyval(push, "Targetname", "smo_elevator_push");
            ppmod.keyval(push, "Magnitude", 200);
            ppmod.keyval(push, "SpawnFlags", 12);
            ppmod.keyval(push, "Radius", 32);
            ppmod.fire(push, "Enable");
            push.SetOrigin(Vector(-982, -129, -960));

            local elevator = ppmod.get("arrival_elevator-elevator_1");

            ppmod.interval(function(elevator = elevator) {

              local pos = elevator.GetOrigin();
              elevator.SetAbsOrigin(pos + Vector(0, 0, -15));

              if (pos.z < -855) {

                ppmod.get("smo_elevator_down_interval").Destroy();

                ppmod.fire("smo_elevator_push", "Kill");

                local trig = ppmod.trigger(Vector(-1016, -128, -893), Vector(17, 16, 38));
                ppmod.addscript(trig, "OnStartTouch", function(elevator = elevator) {

                  ppmod.fire(smo.move.speedmod, "ModifySpeed", 0);
                  ppmod.keyval("!player", "MoveType", 8);

                  ppmod.interval(function(elevator = elevator) {

                    local epos = elevator.GetOrigin();
                    local ppos = GetPlayer().GetOrigin();

                    elevator.SetAbsOrigin(epos + Vector(0, 0, 15));
                    GetPlayer().SetAbsOrigin(ppos + Vector(0, 0, 15));

                    if (epos.z > -162) {
                      
                      ppmod.get("smo_elevator_up_interval").Destroy();

                      ppmod.fire(smo.move.speedmod, "ModifySpeed", 1);
                      ppmod.keyval("!player", "MoveType", 2);
                    
                    }

                  }, 0, "smo_elevator_up_interval");

                })

              }

            }, 0, "smo_elevator_down_interval");

          });

        }
      },
      sp_a1_intro2 = function () {
        smo.setup <- function() {
          EntFire("block_boxes", "Kill");
        }
      }
    }
    if (GetMapName().tolower() in mapscripts) mapscripts[GetMapName().tolower()]();
    if ("setup" in smo) smo.setup();
    if ("con" in smo) SendToConsole("script smo.con()");
  } catch (e) {
    printl(e);
  }

  switch (GetMapName().tolower()) {

    case "sp_a1_intro1" : EntFire("viewmodel", "DisableDraw"); break;
    case "sp_a1_intro2" : EntFire("viewmodel", "DisableDraw"); break;
    case "sp_a1_intro3" : EntFire("viewmodel", "DisableDraw"); break;
    case "sp_a2_intro"  : EntFire("viewmodel", "DisableDraw"); break;
    default : EntFire("viewmodel", "EnableDraw");

  } 

  ppmod.addoutput("weapon_portalgun", "OnPlayerPickup", "viewmodel", "EnableDraw");

}

// Stops P2SM from screaming about missing functions.
local nfunc = function(){};
AddModeFunctions("smo", nfunc, nfunc, nfunc, nfunc);
