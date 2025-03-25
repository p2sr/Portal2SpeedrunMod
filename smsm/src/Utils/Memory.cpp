#include "Memory.hpp"

#include <cstring>
#include <memory>
#include <vector>

#ifdef _WIN32
#include <tchar.h>
#include <windows.h>
// Last
#include <psapi.h>
#else
#include <cstdint>
#include <dlfcn.h>
#include <link.h>
#include <sys/uio.h>
#include <unistd.h>
#endif

#define INRANGE(x, a, b) (x >= a && x <= b)
#define getBits(x) (INRANGE((x & (~0x20)), 'A', 'F') ? ((x & (~0x20)) - 'A' + 0xA) : (INRANGE(x, '0', '9') ? x - '0' : 0))
#define getByte(x) (getBits(x[0]) << 4 | getBits(x[1]))

std::vector<Memory::ModuleInfo> Memory::moduleList;

bool Memory::TryGetModule(const char* moduleName, Memory::ModuleInfo* info)
{
    if (Memory::moduleList.empty()) {
#ifdef _WIN32
        HMODULE hMods[1024];
        HANDLE pHandle = GetCurrentProcess();
        DWORD cbNeeded;
        if (EnumProcessModules(pHandle, hMods, sizeof(hMods), &cbNeeded)) {
            for (unsigned i = 0; i < (cbNeeded / sizeof(HMODULE)); ++i) {
                char buffer[MAX_PATH];
                if (!GetModuleFileName(hMods[i], buffer, sizeof(buffer)))
                    continue;

                auto modinfo = MODULEINFO();
                if (!GetModuleInformation(pHandle, hMods[i], &modinfo, sizeof(modinfo)))
                    continue;

                auto module = ModuleInfo();

                auto temp = std::string(buffer);
                auto index = temp.find_last_of("\\/");
                temp = temp.substr(index + 1, temp.length() - index);

                snprintf(module.name, sizeof(module.name), "%s", temp.c_str());
                module.base = (uintptr_t)modinfo.lpBaseOfDll;
                module.size = (uintptr_t)modinfo.SizeOfImage;
                snprintf(module.path, sizeof(module.path), "%s", buffer);

                Memory::moduleList.push_back(module);
            }
        }

#else
        dl_iterate_phdr([](struct dl_phdr_info* info, size_t, void*) {
            std::string temp = std::string(info->dlpi_name);
            int index = temp.find_last_of("\\/");
            temp = temp.substr(index + 1, temp.length() - index);

            for (int i = 0; i < info->dlpi_phnum; ++i) {
                // FIXME: we really want data segments too! but +x is more important
                if (info->dlpi_phdr[i].p_flags & 1) { // execute
                    Memory::ModuleInfo module;
                    module.base = info->dlpi_addr + info->dlpi_phdr[i].p_vaddr;
                    module.size = info->dlpi_phdr[i].p_memsz;
                    std::strncpy(module.name, temp.c_str(), sizeof(module.name));
                    std::strncpy(module.path, info->dlpi_name, sizeof(module.path));
                    Memory::moduleList.push_back(module);
                    break;
                }
            }

            return 0;
        },
            nullptr);
#endif
    }

    for (Memory::ModuleInfo& item : Memory::moduleList) {
        if (!std::strcmp(item.name, moduleName)) {
            if (info) {
                *info = item;
            }
            return true;
        }
    }

    return false;
}

const char* Memory::GetModulePath(const char* moduleName)
{
    auto info = Memory::ModuleInfo();
    return (Memory::TryGetModule(moduleName, &info)) ? std::string(info.path).c_str() : nullptr;
}
void* Memory::GetModuleHandleByName(const char* moduleName)
{
    auto info = Memory::ModuleInfo();
#ifdef _WIN32
    return (Memory::TryGetModule(moduleName, &info)) ? GetModuleHandleA(info.path) : nullptr;
#else
    return (TryGetModule(moduleName, &info)) ? dlopen(info.path, RTLD_NOLOAD | RTLD_NOW) : nullptr;
#endif
}
void Memory::CloseModuleHandle(void* moduleHandle)
{
#ifndef _WIN32
    dlclose(moduleHandle);
#endif
}
std::string Memory::GetProcessName()
{
#ifdef _WIN32
    char temp[MAX_PATH];
    GetModuleFileName(NULL, temp, sizeof(temp));
#else
    char link[32];
    char temp[MAX_PATH] = { 0 };
    sprintf(link, "/proc/%d/exe", getpid());
    readlink(link, temp, sizeof(temp));
#endif

    auto proc = std::string(temp);
    auto index = proc.find_last_of("\\/");
    proc = proc.substr(index + 1, proc.length() - index);

    return proc;
}

uintptr_t Memory::FindAddress(const uintptr_t start, const uintptr_t end, const char* target)
{
    const char* pattern = target;
    uintptr_t result = 0;

    for (auto position = start; position < end; ++position) {
        if (!*pattern)
            return result;

        auto match = *reinterpret_cast<const uint8_t*>(pattern);
        auto byte = *reinterpret_cast<const uint8_t*>(position);

        if (match == '\?' || byte == getByte(pattern)) {
            if (!result)
                result = position;

            if (!pattern[2])
                return result;

            pattern += (match != '\?') ? 3 : 2;
        } else {
            pattern = target;
            result = 0;
        }
    }
    return 0;
}
uintptr_t Memory::Scan(const char* moduleName, const char* pattern, int offset)
{
    uintptr_t result = 0;

    auto info = Memory::ModuleInfo();
    if (Memory::TryGetModule(moduleName, &info)) {
        auto start = uintptr_t(info.base);
        auto end = start + info.size;
        result = FindAddress(start, end, pattern);
        if (result) {
            result += offset;
        }
    }
    return result;
}

#ifdef _WIN32
Memory::Patch::~Patch()
{
    if (this->original) {
        this->Restore();
        delete this->original;
        this->original = nullptr;
    }
}
bool Memory::Patch::Execute(uintptr_t location, unsigned char* bytes)
{
    this->location = location;
    this->size = sizeof(bytes) / sizeof(bytes[0]) - 1;
    this->original = new unsigned char[this->size];

    for (size_t i = 0; i < this->size; i++) {
        if (!ReadProcessMemory(GetCurrentProcess(),
                reinterpret_cast<LPVOID>(this->location + i),
                &this->original[i],
                1,
                0)) {
            return false;
        }
    }

    for (size_t i = 0; i < this->size; i++) {
        if (!WriteProcessMemory(GetCurrentProcess(),
                reinterpret_cast<LPVOID>(this->location + i),
                &bytes[i],
                1,
                0)) {
            return false;
        }
    }
    return true;
}
bool Memory::Patch::Restore()
{
    if (this->location && this->original) {
        for (size_t i = 0; i < this->size; i++) {
            if (!WriteProcessMemory(GetCurrentProcess(),
                    reinterpret_cast<LPVOID>(this->location + i),
                    &this->original[i],
                    1,
                    0)) {
                return false;
            }
        }
        return true;
    }
    return false;
}
#endif
