#pragma once
#include "Command.hpp"
#include "Variable.hpp"

class Cheats {
public:
    void Init();
    void Shutdown();
};

extern Command sm_mode;
extern Command sm_param;

extern Variable sv_transition_fade_time;
extern Variable ui_loadingscreen_transition_time;
extern Variable ui_loadingscreen_fadein_time;
extern Variable ui_loadingscreen_mintransition_time;