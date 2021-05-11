#pragma once

#define _GAME_PATH(x) #x

#ifdef _WIN32
#define MODULE_EXTENSION ".dll"
// clang-format off
#define GAME_PATH(x) _GAME_PATH(Games/Windows/##x.hpp)
// clang-format on
#define __func __thiscall
#define DLL_EXPORT extern "C" __declspec(dllexport)

#define DECL_DETOUR(name, ...)                                  \
    using _##name = int(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                        \
    static int __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__);
#define DECL_DETOUR_T(type, name, ...)                           \
    using _##name = type(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                         \
    static type __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__);
#define DECL_DETOUR_B(name, ...)                                \
    using _##name = int(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                        \
    static _##name name##Base;                                  \
    static int __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__);

#define DETOUR(name, ...) \
    int __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__)
#define DETOUR_T(type, name, ...) \
    type __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__)
#define DETOUR_B(name, ...) \
    int __fastcall name##_Hook(void* thisptr, int edx, ##__VA_ARGS__)
#else
#define MODULE_EXTENSION ".so"
// clang-format off
#define GAME_PATH(x) _GAME_PATH(Games/Linux/x.hpp)
// clang-format on
#define __func __attribute__((__cdecl__))
#define __cdecl __attribute__((__cdecl__))
#define __stdcall __attribute__((__stdcall__))
#define __fastcall __attribute__((__fastcall__))
#define DLL_EXPORT extern "C" __attribute__((visibility("default")))

#define DECL_DETOUR(name, ...)                                  \
    using _##name = int(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                        \
    static int __func name##_Hook(void* thisptr, ##__VA_ARGS__);
#define DECL_DETOUR_T(type, name, ...)                           \
    using _##name = type(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                         \
    static type __func name##_Hook(void* thisptr, ##__VA_ARGS__);
#define DECL_DETOUR_B(name, ...)                                \
    using _##name = int(__func*)(void* thisptr, ##__VA_ARGS__); \
    static _##name name;                                        \
    static _##name name##Base;                                  \
    static int __func name##_Hook(void* thisptr, ##__VA_ARGS__);

#define DETOUR(name, ...) \
    int __func name##_Hook(void* thisptr, ##__VA_ARGS__)
#define DETOUR_T(type, name, ...) \
    type __func name##_Hook(void* thisptr, ##__VA_ARGS__)
#define DETOUR_B(name, ...) \
    int __func name##_Hook(void* thisptr, ##__VA_ARGS__)
#endif

#define DECL_DETOUR_STD(type, name, ...)             \
    using _##name = type(__stdcall*)(__VA_ARGS__); \
    static _##name name;                             \
    static type __stdcall name##_Hook(__VA_ARGS__);
#define DETOUR_STD(type, name, ...) \
    type __stdcall name##_Hook(__VA_ARGS__)
