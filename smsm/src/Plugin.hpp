#pragma once
#include "Utils.hpp"

#define SMSM_SIGNATURE "Speedrun Mod was a mistake."

// CServerPlugin
#define CServerPlugin_m_Size 16
#define CServerPlugin_m_Plugins 4

class Plugin {
public:
    CPlugin* ptr;
    int index;

public:
    Plugin();
};
