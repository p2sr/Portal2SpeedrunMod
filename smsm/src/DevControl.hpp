#pragma once

#include "Variable.hpp"

extern Variable developer;
extern Variable contimes;
extern Variable phys_penetration_error_time;

class DevControl{
public:
    void RemoveAccess();
    void PatchStrings();
    void SetMode(int mode);
    void SetParam(int param);
    void ApplyConvars();
    void LockDeveloper();
    void UnlockDeveloper();
    DevControl();

    int GetMode();
    int GetParam();
private:
    int lastMode;
    int lastParam;
};

extern DevControl devcontrol;