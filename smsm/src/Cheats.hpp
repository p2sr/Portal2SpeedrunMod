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