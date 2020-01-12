#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class Server : public Module {
public:

public:
    Server();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("server"); }
};

extern Server* server;
