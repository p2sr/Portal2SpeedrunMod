#pragma once
#include "Module.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Command.hpp"

class MaterialSystem : public Module {
public:
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("materialsystem"); }
};

extern MaterialSystem* materialSystem;
