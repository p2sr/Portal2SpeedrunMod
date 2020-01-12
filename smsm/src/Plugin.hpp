#pragma once
#include "Utils.hpp"

#define SMSM_SIGNATURE \
    new char[28] { 83, 112, 101, 101, 100, 114, 117, 110, 32, 77, 111, 100, 32, 119, 97, 115, 32, 97, 32, 109, 105, 115, 116, 97, 107, 101, 46, 00 }

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
