THANKS_ZPOS <- 0;

function CreditsThink(){
    if(THANKS_ZPOS==0){
        local thanks = Entities.FindByName(null,"THANKS");
        THANKS_ZPOS = thanks.GetOrigin().z;
    }

    local camera = Entities.FindByName(null,"camera");

    local cameraPos = camera.GetOrigin()
    if(cameraPos.z>THANKS_ZPOS)cameraPos.z -= 0.5;
    camera.SetAbsOrigin(cameraPos)

    return 0.01;
}