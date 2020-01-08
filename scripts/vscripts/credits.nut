CREDITS_TEXT <-
"Mod created by:\n" +
"Krzyhau\n" +
"\n" +
"Special thanks:\n" +
"Blenderiste09 - chapter 9 scripts\n" +
"Betsruner - beta testing, sponsoring\n" +
"Rex - beta testing, sponsoring\n" +
"Can't Even - beta testing\n"



//SUBTITLES_Y <- -1

function StartCredits(){
    //EntFire("message", "SetText", CREDITS_TEXT)
    //EntFire("message2", "SetText", CREDITS_TEXT) 
    //CreditsTextLoop()
}

function CreditsTextLoop(){
    //EntFire("message", "SetPosY", SUBTITLES_Y, 0.02)
    //EntFire("message", "Display", 0, 0.02)
    //EntFire("message2", "SetPosY", SUBTITLES_Y, 0.04)
    //EntFire("message2", "Display", 0, 0.04)
    //EntFire(self.GetName(), "RunScriptCode", "CreditsTextLoop()", 0.04)
}



function CreditsThink(){
    local camera = Entities.FindByName(null,"camera");

    local cameraPos = camera.GetOrigin()
    cameraPos.z -= 0.5;
    camera.SetAbsOrigin(cameraPos)

    return 0.01;
}