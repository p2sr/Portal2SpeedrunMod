#pragma once
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cstdint>
#include <cstring>

#ifdef _WIN32
#define __funcc __thiscall
#define ALIGNED(x) __declspec(align(x))
#define strdup _strdup
#else
#define __funcc __attribute__((__cdecl__))
#define ALIGNED(x) __attribute__((aligned(x)))
#define __cdecl __attribute__((__cdecl__))
#endif

struct Vector {
    float x, y, z;
    Vector() : x(0), y(0), z(0) {};
    Vector(float x, float y, float z) { this->x = x; this->y = y;  this->z = z; };
    inline float Length()
    {
        return std::sqrt(x * x + y * y + z * z);
    }
    inline float Length2D()
    {
        return std::sqrt(x * x + y * y);
    }
    inline Vector operator*(float fl)
    {
        Vector res;
        res.x = x * fl;
        res.y = y * fl;
        res.z = z * fl;
        return res;
    }
    inline Vector operator+(Vector vec)
    {
        Vector res;
        res.x = x + vec.x;
        res.y = y + vec.y;
        res.z = z + vec.z;
        return res;
    }
    inline float& operator[](int i)
    {
        return ((float*)this)[i];
    }
    inline float operator[](int i) const
    {
        return ((float*)this)[i];
    }
    inline float operator*(Vector vec) 
    {
        return x*vec.x + y*vec.y + z*vec.z;
    }
    inline Vector operator^(Vector vec) 
    {
        Vector res;
        res.x = y * vec.z - z * vec.y;
        res.y = z * vec.x - x * vec.z;
        res.z = x * vec.y - y * vec.x;
        return res;
    }
};

struct QAngle {
    float x, y, z;
};

struct Color {
    Color()
    {
        *((int*)this) = 255;
    }
    Color(int _r, int _g, int _b)
    {
        SetColor(_r, _g, _b, 255);
    }
    Color(int _r, int _g, int _b, int _a)
    {
        SetColor(_r, _g, _b, _a);
    }
    void SetColor(int _r, int _g, int _b, int _a = 255)
    {
        _color[0] = (unsigned char)_r;
        _color[1] = (unsigned char)_g;
        _color[2] = (unsigned char)_b;
        _color[3] = (unsigned char)_a;
    }
    inline int r() const { return _color[0]; }
    inline int g() const { return _color[1]; }
    inline int b() const { return _color[2]; }
    inline int a() const { return _color[3]; }
    unsigned char _color[4];
};

enum TextColor {
    COLOR_NORMAL = 1, // 255, 178.5, 0.0, 255
    COLOR_USEOLDCOLORS = 2, // 255, 178.5, 0.0, 255
    COLOR_PLAYERNAME = 3, // 204, 204, 204, 255
    COLOR_LOCATION = 4, // 153, 255, 153, 255
    COLOR_ACHIEVEMENT = 5, // 64, 255, 64, 255
    COLOR_MAX
};

#define FCVAR_DEVELOPMENTONLY (1 << 1)
#define FCVAR_HIDDEN (1 << 4)
#define FCVAR_NOTIFY (1 << 8)
#define FCVAR_NEVER_AS_STRING (1 << 12)
#define FCVAR_CHEAT (1 << 14)

#define COMMAND_COMPLETION_MAXITEMS 64
#define COMMAND_COMPLETION_ITEM_LENGTH 64

struct CCommand;
class ConCommandBase;

using _CommandCallback = void (*)(const CCommand& args);
using _CommandCompletionCallback = int (*)(const char* partial, char commands[COMMAND_COMPLETION_MAXITEMS][COMMAND_COMPLETION_ITEM_LENGTH]);
using _InternalSetValue = void(__funcc*)(void* thisptr, const char* value);
using _InternalSetFloatValue = void(__funcc*)(void* thisptr, float value);
using _InternalSetIntValue = void(__funcc*)(void* thisptr, int value);
using _RegisterConCommand = void(__funcc*)(void* thisptr, ConCommandBase* pCommandBase);
using _UnregisterConCommand = void(__funcc*)(void* thisptr, ConCommandBase* pCommandBase);
using _FindCommandBase = void*(__funcc*)(void* thisptr, const char* name);
using _AutoCompletionFunc = int(__funcc*)(void* thisptr, char const* partial, char commands[COMMAND_COMPLETION_MAXITEMS][COMMAND_COMPLETION_ITEM_LENGTH]);

class ConCommandBase {
public:
    void* ConCommandBase_VTable; // 0
    ConCommandBase* m_pNext; // 4
    bool m_bRegistered; // 8
    const char* m_pszName; // 12
    const char* m_pszHelpString; // 16
    int m_nFlags; // 20

public:
    ConCommandBase()
        : ConCommandBase_VTable(nullptr)
        , m_pNext(nullptr)
        , m_bRegistered(false)
        , m_pszName(nullptr)
        , m_pszHelpString(nullptr)
        , m_nFlags(0)
    {
    }
};

struct CCommand {
    enum {
        COMMAND_MAX_ARGC = 64,
        COMMAND_MAX_LENGTH = 512
    };
    int m_nArgc;
    int m_nArgv0Size;
    char m_pArgSBuffer[COMMAND_MAX_LENGTH];
    char m_pArgvBuffer[COMMAND_MAX_LENGTH];
    const char* m_ppArgv[COMMAND_MAX_ARGC];

    int ArgC() const
    {
        return this->m_nArgc;
    }
    const char* Arg(int nIndex) const
    {
        return this->m_ppArgv[nIndex];
    }
    const char* operator[](int nIndex) const
    {
        return Arg(nIndex);
    }
};

class ConCommand : public ConCommandBase {
public:
    union {
        void* m_fnCommandCallbackV1;
        _CommandCallback m_fnCommandCallback;
        void* m_pCommandCallback;
    };

    union {
        _CommandCompletionCallback m_fnCompletionCallback;
        void* m_pCommandCompletionCallback;
    };

    bool m_bHasCompletionCallback : 1;
    bool m_bUsingNewCommandCallback : 1;
    bool m_bUsingCommandCallbackInterface : 1;

public:
    ConCommand()
        : ConCommandBase()
        , m_fnCommandCallbackV1(nullptr)
        , m_fnCompletionCallback(nullptr)
    {
    }
};

class ConVar : public ConCommandBase {
public:
    void* ConVar_VTable; // 24
    ConVar* m_pParent; // 28
    const char* m_pszDefaultValue; // 32
    char* m_pszString; // 36
    int m_StringLength; // 40
    float m_fValue; // 44
    int m_nValue; // 48
    bool m_bHasMin; // 52
    float m_fMinVal; // 56
    bool m_bHasMax; // 60
    float m_fMaxVal; // 64
    void* m_fnChangeCallback; // 68

public:
    ConVar()
        : ConCommandBase()
        , ConVar_VTable(nullptr)
        , m_pParent(nullptr)
        , m_pszDefaultValue(nullptr)
        , m_pszString(nullptr)
        , m_StringLength(0)
        , m_fValue(0)
        , m_nValue(0)
        , m_bHasMin(0)
        , m_fMinVal(0)
        , m_bHasMax(0)
        , m_fMaxVal(0)
        , m_fnChangeCallback(nullptr)
    {
    }
    ~ConVar()
    {
        if (this->m_pszString) {
            delete[] this->m_pszString;
            this->m_pszString = nullptr;
        }
    }
};

class ConVar2 : public ConVar {
public:
    // CUtlVector<FnChangeCallback_t> m_fnChangeCallback
    // CUtlMemory<FnChangeCallback_t> m_Memory
    int m_nAllocationCount; // 72
    int m_nGrowSize; // 76
    int m_Size; // 80
    void* m_pElements; // 84

public:
    ConVar2()
        : ConVar()
        , m_nAllocationCount(0)
        , m_nGrowSize(0)
        , m_Size(0)
        , m_pElements(nullptr)
    {
    }
};

enum SignonState {
    None = 0,
    Challenge = 1,
    Connected = 2,
    New = 3,
    Prespawn = 4,
    Spawn = 5,
    Full = 6,
    Changelevel = 7
};

struct CUserCmd {
    void* VMT; // 0
    int command_number; // 4
    int tick_count; // 8
    QAngle viewangles; // 12, 16, 20
    float forwardmove; // 24
    float sidemove; // 28
    float upmove; // 32
    int buttons; // 36
    unsigned char impulse; // 40
    int weaponselect; // 44
    int weaponsubtype; // 48
    int random_seed; // 52
    short mousedx; // 56
    short mousedy; // 58
    bool hasbeenpredicted; // 60
};

class CMoveData {
public:
    bool m_bFirstRunOfFunctions : 1; // 0
    bool m_bGameCodeMovedPlayer : 1; // 2
    void* m_nPlayerHandle; // 4
    int m_nImpulseCommand; // 8
    QAngle m_vecViewAngles; // 12, 16, 20
    QAngle m_vecAbsViewAngles; // 24, 28, 32
    int m_nButtons; // 36
    int m_nOldButtons; // 40
    float m_flForwardMove; // 44
    float m_flSideMove; // 48
    float m_flUpMove; // 52
    float m_flMaxSpeed; // 56
    float m_flClientMaxSpeed; // 60
    Vector m_vecVelocity; // 64, 68, 72
    QAngle m_vecAngles; // 76, 80, 84
    QAngle m_vecOldAngles; // 88, 92, 96
    float m_outStepHeight; // 100
    Vector m_outWishVel; // 104, 108, 112
    Vector m_outJumpVel; // 116, 120, 124
    Vector m_vecConstraintCenter; // 128, 132, 136
    float m_flConstraintRadius; // 140
    float m_flConstraintWidth; // 144
    float m_flConstraintSpeedFactor; // 148
    float m_unknown;
    Vector m_vecAbsOrigin; // 156
};

class CHLMoveData : public CMoveData {
public:
    bool m_bIsSprinting;
};

#define IN_ATTACK (1 << 0)
#define IN_JUMP (1 << 1)
#define IN_DUCK (1 << 2)
#define IN_FORWARD (1 << 3)
#define IN_BACK (1 << 4)
#define IN_USE (1 << 5)
#define IN_MOVELEFT (1 << 9)
#define IN_MOVERIGHT (1 << 10)
#define IN_ATTACK2 (1 << 11)
#define IN_RELOAD (1 << 13)
#define IN_SPEED (1 << 17)

#define FL_ONGROUND (1 << 0)
#define FL_DUCKING (1 << 1)
#define FL_FROZEN (1 << 5)
#define FL_ATCONTROLS (1 << 6)

#define WL_Feet 1
#define WL_Waist 2

#define MOVETYPE_LADDER 9
#define MOVETYPE_NOCLIP 8

typedef enum {
    HS_NEW_GAME = 0,
    HS_LOAD_GAME = 1,
    HS_CHANGE_LEVEL_SP = 2,
    HS_CHANGE_LEVEL_MP = 3,
    HS_RUN = 4,
    HS_GAME_SHUTDOWN = 5,
    HS_SHUTDOWN = 6,
    HS_RESTART = 7
} HOSTSTATES;

struct CHostState {
    HOSTSTATES m_currentState; // 0
    HOSTSTATES m_nextState; // 4
    Vector m_vecLocation; // 8, 12, 16
    QAngle m_angLocation; // 20, 24, 28
    char m_levelName[256]; // 32
    char m_landmarkName[256]; // 288
    char m_saveName[256]; // 544
    float m_flShortFrameTime; // 800
    bool m_activeGame; // 804
    bool m_bRememberLocation; // 805
    bool m_bBackgroundLevel; // 806
    bool m_bWaitingForConnection; // 807
};

#define INTERFACEVERSION_ISERVERPLUGINCALLBACKS "ISERVERPLUGINCALLBACKS002"

typedef void* (*CreateInterfaceFn)(const char* pName, int* pReturnCode);
typedef void* (*InstantiateInterfaceFn)();

struct InterfaceReg {
    InstantiateInterfaceFn m_CreateFn;
    const char* m_pName;
    InterfaceReg* m_pNext;
    static InterfaceReg* s_pInterfaceRegs;

    InterfaceReg(InstantiateInterfaceFn fn, const char* pName)
        : m_pName(pName)
    {
        m_CreateFn = fn;
        m_pNext = s_pInterfaceRegs;
        s_pInterfaceRegs = this;
    }
};

class IServerPluginCallbacks {
public:
    virtual bool Load(CreateInterfaceFn interfaceFactory, CreateInterfaceFn gameServerFactory) = 0;
    virtual void Unload() = 0;
    virtual void Pause() = 0;
    virtual void UnPause() = 0;
    virtual const char* GetPluginDescription() = 0;
    virtual void LevelInit(char const* pMapName) = 0;
    virtual void ServerActivate(void* pEdictList, int edictCount, int clientMax) = 0;
    virtual void GameFrame(bool simulating) = 0;
    virtual void LevelShutdown() = 0;
    virtual void ClientFullyConnect(void* pEdict) = 0;
    virtual void ClientActive(void* pEntity) = 0;
    virtual void ClientDisconnect(void* pEntity) = 0;
    virtual void ClientPutInServer(void* pEntity, char const* playername) = 0;
    virtual void SetCommandClient(int index) = 0;
    virtual void ClientSettingsChanged(void* pEdict) = 0;
    virtual int ClientConnect(bool* bAllowConnect, void* pEntity, const char* pszName, const char* pszAddress, char* reject, int maxrejectlen) = 0;
    virtual int ClientCommand(void* pEntity, const void*& args) = 0;
    virtual int NetworkIDValidated(const char* pszUserName, const char* pszNetworkID) = 0;
    virtual void OnQueryCvarValueFinished(int iCookie, void* pPlayerEntity, int eStatus, const char* pCvarName, const char* pCvarValue) = 0;
    virtual void OnEdictAllocated(void* edict) = 0;
    virtual void OnEdictFreed(const void* edict) = 0;
};

struct CPlugin {
    char m_szName[128]; //0
    bool m_bDisable; // 128
    IServerPluginCallbacks* m_pPlugin; // 132
    int m_iPluginInterfaceVersion; // 136
    void* m_pPluginModule; // 140
};

#define EXPOSE_INTERFACE_FN(functionName, interfaceName, versionName) \
    static InterfaceReg __g_Create##interfaceName##_reg(functionName, versionName);

#define EXPOSE_INTERFACE(className, interfaceName, versionName)                                           \
    static void* __Create##className##_interface() { return static_cast<interfaceName*>(new className); } \
    static InterfaceReg __g_Create##className##_reg(__Create##className##_interface, versionName);

#define EXPOSE_SINGLE_INTERFACE_GLOBALVAR(className, interfaceName, versionName, globalVarName)                           \
    static void* __Create##className##interfaceName##_interface() { return static_cast<interfaceName*>(&globalVarName); } \
    static InterfaceReg __g_Create##className##interfaceName##_reg(__Create##className##interfaceName##_interface, versionName);

#define EXPOSE_SINGLE_INTERFACE(className, interfaceName, versionName) \
    static className __g_##className##_singleton;                      \
    EXPOSE_SINGLE_INTERFACE_GLOBALVAR(className, interfaceName, versionName, __g_##className##_singleton)

struct CEventAction {
    const char* m_iTarget; // 0
    const char* m_iTargetInput; // 4
    const char* m_iParameter; // 8
    float m_flDelay; // 12
    int m_nTimesToFire; // 16
    int m_iIDStamp; //20
    CEventAction* m_pNext; // 24
};

struct EventQueuePrioritizedEvent_t {
    float m_flFireTime; // 0
    char* m_iTarget; // 4
    char* m_iTargetInput; // 8
    int m_pActivator; // 12
    int m_pCaller; // 16
    int m_iOutputID; // 20
    int m_pEntTarget; // 24
    char m_VariantValue[20]; // 28
    EventQueuePrioritizedEvent_t* m_pNext; // 48
    EventQueuePrioritizedEvent_t* m_pPrev; // 52
};

struct CEventQueue {
    EventQueuePrioritizedEvent_t m_Events; // 0
    int m_iListCount; // 56
};

struct CGlobalVarsBase {
    float realtime; // 0
    int framecount; // 4
    float absoluteframetime; // 8
    float curtime; // 12
    float frametime; // 16
    int maxClients; // 20
    int tickcount; // 24
    float interval_per_tick; // 28
    float interpolation_amount; // 32
    int simTicksThisFrame; // 36
    int network_protocol; // 40
    void* pSaveData; // 44
    bool m_bClient; // 48
    int nTimestampNetworkingBase; // 52
    int nTimestampRandomizeWindow; // 56
};

struct CEntInfo {
    void* m_pEntity; // 0
    int m_SerialNumber; // 4
    CEntInfo* m_pPrev; // 8
    CEntInfo* m_pNext; // 12
};

struct CEntInfo2 : CEntInfo {
    void* unk1; // 16
    void* unk2; // 20
};

typedef enum {
    DPT_Int = 0,
    DPT_Float,
    DPT_Vector,
    DPT_VectorXY,
    DPT_String,
    DPT_Array,
    DPT_DataTable,
    DPT_Int64,
    DPT_NUMSendPropTypes
} SendPropType;

struct SendProp;
struct RecvProp;
struct SendTable;

typedef void (*RecvVarProxyFn)(const void* pData, void* pStruct, void* pOut);
typedef void (*ArrayLengthRecvProxyFn)(void* pStruct, int objectID, int currentArrayLength);
typedef void (*DataTableRecvVarProxyFn)(const RecvProp* pProp, void** pOut, void* pData, int objectID);
typedef void (*SendVarProxyFn)(const SendProp* pProp, const void* pStructBase, const void* pData, void* pOut, int iElement, int objectID);
typedef int (*ArrayLengthSendProxyFn)(const void* pStruct, int objectID);
typedef void* (*SendTableProxyFn)(const SendProp* pProp, const void* pStructBase, const void* pData, void* pRecipients, int objectID);

struct RecvTable {
    RecvProp* m_pProps;
    int m_nProps;
    void* m_pDecoder;
    char* m_pNetTableName;
    bool m_bInitialized;
    bool m_bInMainList;
};

struct RecvProp {
    char* m_pVarName;
    SendPropType m_RecvType;
    int m_Flags;
    int m_StringBufferSize;
    bool m_bInsideArray;
    const void* m_pExtraData;
    RecvProp* m_pArrayProp;
    ArrayLengthRecvProxyFn m_ArrayLengthProxy;
    RecvVarProxyFn m_ProxyFn;
    DataTableRecvVarProxyFn m_DataTableProxyFn;
    RecvTable* m_pDataTable;
    int m_Offset;
    int m_ElementStride;
    int m_nElements;
    const char* m_pParentArrayPropName;
};

struct SendProp {
    void* VMT; // 0
    RecvProp* m_pMatchingRecvProp; // 4
    SendPropType m_Type; // 8
    int m_nBits; // 12
    float m_fLowValue; // 16
    float m_fHighValue; // 20
    SendProp* m_pArrayProp; // 24
    ArrayLengthSendProxyFn m_ArrayLengthProxy; // 28
    int m_nElements; // 32
    int m_ElementStride; //36
    char* m_pExcludeDTName; // 40
    char* m_pParentArrayPropName; // 44
    char* m_pVarName; // 48
    float m_fHighLowMul; // 52
    int m_Flags; // 56
    SendVarProxyFn m_ProxyFn; // 60
    SendTableProxyFn m_DataTableProxyFn; // 64
    SendTable* m_pDataTable; // 68
    int m_Offset; // 72
    const void* m_pExtraData; // 76
};

struct SendProp2 {
    void* VMT; // 0
    RecvProp* m_pMatchingRecvProp; // 4
    SendPropType m_Type; // 8
    int m_nBits; // 12
    float m_fLowValue; // 16
    float m_fHighValue; // 20
    SendProp2* m_pArrayProp; // 24
    ArrayLengthSendProxyFn m_ArrayLengthProxy; // 28
    int m_nElements; // 32
    int m_ElementStride; // 36
    char* m_pExcludeDTName; // 40
    char* m_pParentArrayPropName; // 44
    char* m_pVarName; // 48
    float m_fHighLowMul; // 52
    char m_priority; // 56
    int m_Flags; // 60
    SendVarProxyFn m_ProxyFn; // 64
    SendTableProxyFn m_DataTableProxyFn; // 68
    SendTable* m_pDataTable; // 72
    int m_Offset; // 76
    const void* m_pExtraData; // 80
};

struct SendTable {
    SendProp* m_pProps;
    int m_nProps;
    char* m_pNetTableName;
    void* m_pPrecalc;
    bool m_bInitialized : 1;
    bool m_bHasBeenWritten : 1;
    bool m_bHasPropsEncodedAgainstCurrentTickCount : 1;
};

typedef void* (*CreateClientClassFn)(int entnum, int serialNum);
typedef void* (*CreateEventFn)();

struct ClientClass {
    CreateClientClassFn m_pCreateFn;
    CreateEventFn m_pCreateEventFn;
    char* m_pNetworkName;
    RecvTable* m_pRecvTable;
    ClientClass* m_pNext;
    int m_ClassID;
};

struct ServerClass {
    char* m_pNetworkName;
    SendTable* m_pTable;
    ServerClass* m_pNext;
    int m_ClassID;
    int m_InstanceBaselineIndex;
};

enum MapLoadType_t {
    MapLoad_NewGame = 0,
    MapLoad_LoadGame = 1,
    MapLoad_Transition = 2,
    MapLoad_Background = 3
};

struct CGlobalVars : CGlobalVarsBase {
    char* mapname; // 60
    int mapversion; // 64
    char* startspot; // 68
    MapLoadType_t eLoadType; // 72
    bool bMapLoadFailed; // 76
    bool deathmatch; // 80
    bool coop; // 84
    bool teamplay; // 88
    int maxEntities; // 92
};

class IGameEvent {
public:
    virtual ~IGameEvent() = default;
    virtual const char* GetName() const = 0;
    virtual bool IsReliable() const = 0;
    virtual bool IsLocal() const = 0;
    virtual bool IsEmpty(const char* key = 0) = 0;
    virtual bool GetBool(const char* key = 0, bool default_value = false) = 0;
    virtual int GetInt(const char* key = 0, int default_value = 0) = 0;
    virtual float GetFloat(const char* key = 0, float default_value = 0.0f) = 0;
    virtual const char* GetString(const char* key = 0, const char* default_value = "") = 0;
    virtual void SetBool(const char* key, bool value) = 0;
    virtual void SetInt(const char* key, int value) = 0;
    virtual void SetFloat(const char* key, float value) = 0;
    virtual void SetString(const char* key, const char* value) = 0;
};

class IGameEventListener2 {
public:
    virtual ~IGameEventListener2() = default;
    virtual void FireGameEvent(IGameEvent* event) = 0;
    virtual int GetEventDebugID() = 0;
};

static const char* EVENTS[] = {
    "player_spawn_blue",
    "player_spawn_orange"
};

#pragma region RayTracing

#define	CONTENTS_EMPTY			0		// No contents

#define	CONTENTS_SOLID			0x1		// an eye is never valid in a solid
#define	CONTENTS_WINDOW			0x2		// translucent, but not watery (glass)
#define	CONTENTS_AUX			0x4
#define	CONTENTS_GRATE			0x8		// alpha-tested "grate" textures.  Bullets/sight pass through, but solids don't
#define	CONTENTS_SLIME			0x10
#define	CONTENTS_WATER			0x20
#define	CONTENTS_BLOCKLOS		0x40	// block AI line of sight
#define CONTENTS_OPAQUE			0x80	// things that cannot be seen through (may be non-solid though)
#define	LAST_VISIBLE_CONTENTS	0x80

#define ALL_VISIBLE_CONTENTS (LAST_VISIBLE_CONTENTS | (LAST_VISIBLE_CONTENTS-1))

#define CONTENTS_TESTFOGVOLUME	0x100
#define CONTENTS_UNUSED			0x200	

// unused 
// NOTE: If it's visible, grab from the top + update LAST_VISIBLE_CONTENTS
// if not visible, then grab from the bottom.
#define CONTENTS_UNUSED6		0x400

#define CONTENTS_TEAM1			0x800	// per team contents used to differentiate collisions 
#define CONTENTS_TEAM2			0x1000	// between players and objects on different teams

// ignore CONTENTS_OPAQUE on surfaces that have SURF_NODRAW
#define CONTENTS_IGNORE_NODRAW_OPAQUE	0x2000

// hits entities which are MOVETYPE_PUSH (doors, plats, etc.)
#define CONTENTS_MOVEABLE		0x4000

// remaining contents are non-visible, and don't eat brushes
#define	CONTENTS_AREAPORTAL		0x8000

#define	CONTENTS_PLAYERCLIP		0x10000
#define	CONTENTS_MONSTERCLIP	0x20000

// currents can be added to any other contents, and may be mixed
#define	CONTENTS_CURRENT_0		0x40000
#define	CONTENTS_CURRENT_90		0x80000
#define	CONTENTS_CURRENT_180	0x100000
#define	CONTENTS_CURRENT_270	0x200000
#define	CONTENTS_CURRENT_UP		0x400000
#define	CONTENTS_CURRENT_DOWN	0x800000

#define	CONTENTS_ORIGIN			0x1000000	// removed before bsping an entity

#define	CONTENTS_MONSTER		0x2000000	// should never be on a brush, only in game
#define	CONTENTS_DEBRIS			0x4000000
#define	CONTENTS_DETAIL			0x8000000	// brushes to be added after vis leafs
#define	CONTENTS_TRANSLUCENT	0x10000000	// auto set if any surface has trans
#define	CONTENTS_LADDER			0x20000000
#define CONTENTS_HITBOX			0x40000000	// use accurate hitboxes on trace


// NOTE: These are stored in a short in the engine now.  Don't use more than 16 bits
#define	SURF_LIGHT		0x0001		// value will hold the light strength
#define	SURF_SKY2D		0x0002		// don't draw, indicates we should skylight + draw 2d sky but not draw the 3D skybox
#define	SURF_SKY		0x0004		// don't draw, but add to skybox
#define	SURF_WARP		0x0008		// turbulent water warp
#define	SURF_TRANS		0x0010
#define SURF_NOPORTAL	0x0020	// the surface can not have a portal placed on it
#define	SURF_TRIGGER	0x0040	// FIXME: This is an xbox hack to work around elimination of trigger surfaces, which breaks occluders
#define	SURF_NODRAW		0x0080	// don't bother referencing the texture

#define	SURF_HINT		0x0100	// make a primary bsp splitter

#define	SURF_SKIP		0x0200	// completely ignore, allowing non-closed brushes
#define SURF_NOLIGHT	0x0400	// Don't calculate light
#define SURF_BUMPLIGHT	0x0800	// calculate three lightmaps for the surface for bumpmapping
#define SURF_NOSHADOWS	0x1000	// Don't receive shadows
#define SURF_NODECALS	0x2000	// Don't receive decals
#define SURF_NOCHOP		0x4000	// Don't subdivide patches on this surface 
#define SURF_HITBOX		0x8000	// surface is part of a hitbox



// -----------------------------------------------------
// spatial content masks - used for spatial queries (traceline,etc.)
// -----------------------------------------------------
#define	MASK_ALL					(0xFFFFFFFF)
// everything that is normally solid
#define	MASK_SOLID					(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE)
// everything that blocks player movement
#define	MASK_PLAYERSOLID			(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_PLAYERCLIP|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE)
// blocks npc movement
#define	MASK_NPCSOLID				(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTERCLIP|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE)
// water physics in these contents
#define	MASK_WATER					(CONTENTS_WATER|CONTENTS_MOVEABLE|CONTENTS_SLIME)
// everything that blocks lighting
#define	MASK_OPAQUE					(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_OPAQUE)
// everything that blocks lighting, but with monsters added.
#define MASK_OPAQUE_AND_NPCS		(MASK_OPAQUE|CONTENTS_MONSTER)
// everything that blocks line of sight for AI
#define MASK_BLOCKLOS				(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_BLOCKLOS)
// everything that blocks line of sight for AI plus NPCs
#define MASK_BLOCKLOS_AND_NPCS		(MASK_BLOCKLOS|CONTENTS_MONSTER)
// everything that blocks line of sight for players
#define	MASK_VISIBLE					(MASK_OPAQUE|CONTENTS_IGNORE_NODRAW_OPAQUE)
// everything that blocks line of sight for players, but with monsters added.
#define MASK_VISIBLE_AND_NPCS		(MASK_OPAQUE_AND_NPCS|CONTENTS_IGNORE_NODRAW_OPAQUE)
// bullets see these as solid
#define	MASK_SHOT					(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_HITBOX)
// non-raycasted weapons see this as solid (includes grates)
#define MASK_SHOT_HULL				(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_GRATE)
// hits solids (not grates) and passes through everything else
#define MASK_SHOT_PORTAL			(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTER)
// everything normally solid, except monsters (world+brush only)
#define MASK_SOLID_BRUSHONLY		(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_GRATE)
// everything normally solid for player movement, except monsters (world+brush only)
#define MASK_PLAYERSOLID_BRUSHONLY	(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE)
// everything normally solid for npc movement, except monsters (world+brush only)
#define MASK_NPCSOLID_BRUSHONLY		(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTERCLIP|CONTENTS_GRATE)
// just the world, used for route rebuilding
#define MASK_NPCWORLDSTATIC			(CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_MONSTERCLIP|CONTENTS_GRATE)
// These are things that can split areaportals
#define MASK_SPLITAREAPORTAL		(CONTENTS_WATER|CONTENTS_SLIME)
// UNDONE: This is untested, any moving water
#define MASK_CURRENT				(CONTENTS_CURRENT_0|CONTENTS_CURRENT_90|CONTENTS_CURRENT_180|CONTENTS_CURRENT_270|CONTENTS_CURRENT_UP|CONTENTS_CURRENT_DOWN)



struct csurface_t {
    const char* name;
    short surfaceProps;
    unsigned short flags;
};

struct cplane_t {
    Vector normal;
    float dist;
    unsigned char type;
    unsigned char signbits;
    unsigned char pad[2];
};

struct CBaseTrace {
    Vector startpos;
    Vector endpos;
    cplane_t plane;
    float fraction;
    int contents;
    unsigned short dispFlags;
    bool allsolid;
    bool startsolid;
};

struct CGameTrace : public CBaseTrace {
    float fractionleftsolid;
    csurface_t surface;
    int hitgroup;
    short physicsbone;
    unsigned short worldSurfaceIndex;
    void* m_pEnt;
    int hitbox;
};

struct VectorAligned : public Vector {
    VectorAligned() : Vector(), w(0) {};
    VectorAligned(float x, float y, float z) : Vector(x, y, z) , w(0) {}
    float w;
} ALIGNED(16);

struct matrix3x4_t {
    float m_flMatVal[3][4];
};

struct VMatrix {
    float m[4][4];
};

struct Ray_t {
    VectorAligned m_Start; // starting point, centered within the extents
    VectorAligned m_Delta; // direction + length of the ray
    VectorAligned m_StartOffset; // Add this to m_Start to get the actual ray start
    VectorAligned m_Extents; // Describes an axis aligned box extruded along a ray
    const matrix3x4_t* m_pWorldAxisTransform = nullptr;
    bool m_IsRay; // are there extents zero
    bool m_IsSwept; // is delta != 0
};

enum TraceType_t {
    TRACE_EVERYTHING = 0,
    TRACE_WORLD_ONLY,
    TRACE_ENTITIES_ONLY,
    TRACE_EVERYTHING_FILTER_PROPS,
};

class ITraceFilter
{
public:
    virtual bool ShouldHitEntity(void* pEntity, int contentsMask) = 0;
    virtual TraceType_t	GetTraceType() const = 0;
};

class CTraceFilter : public ITraceFilter {
public:
    virtual TraceType_t	GetTraceType() const {
        return TRACE_EVERYTHING;
    }
};

class CTraceFilterSimple : public CTraceFilter {
public:
    virtual bool ShouldHitEntity(void* pHandleEntity, int contentsMask) {
        return pHandleEntity != m_pPassEnt;
        //return false;
    };
    virtual void SetPassEntity(const void* pPassEntity) { m_pPassEnt = pPassEntity; }
    virtual void SetCollisionGroup(int iCollisionGroup) { m_collisionGroup = iCollisionGroup; }

private:
    const void* m_pPassEnt;
    int m_collisionGroup;
};

#pragma endregion


enum MotionBlurMode_t {
    MOTION_BLUR_DISABLE = 1,
    MOTION_BLUR_GAME = 2,
    MOTION_BLUR_SFM = 3
};

class CViewSetup {
public:
    int			x;
    int			y;
    int			width;
    int			height;
    bool		m_bOrtho;
    float		m_OrthoLeft;
    float		m_OrthoTop;
    float		m_OrthoRight;
    float		m_OrthoBottom;
    bool		m_bCustomViewMatrix;
    matrix3x4_t	m_matCustomViewMatrix;
    float		fov;
    float		fovViewmodel;
    Vector		origin;
    QAngle		angles;
    float		zNear;
    float		zFar;
    float		zNearViewmodel;
    float		zFarViewmodel;
    float		m_flAspectRatio;
    float		m_flNearBlurDepth;
    float		m_flNearFocusDepth;
    float		m_flFarFocusDepth;
    float		m_flFarBlurDepth;
    float		m_flNearBlurRadius;
    float		m_flFarBlurRadius;
    int			m_nDoFQuality;
    MotionBlurMode_t	m_nMotionBlurMode;
    float	m_flShutterTime;
    Vector	m_vShutterOpenPosition;
    QAngle	m_shutterOpenAngles;
    Vector	m_vShutterClosePosition;
    QAngle	m_shutterCloseAngles;
    float		m_flOffCenterTop;
    float		m_flOffCenterBottom;
    float		m_flOffCenterLeft;
    float		m_flOffCenterRight;
    bool		m_bOffCenter : 1;
    bool		m_bRenderToSubrectOfLargerScreen : 1;
    bool		m_bDoBloomAndToneMapping : 1;
    bool		m_bDoDepthOfField : 1;
    bool		m_bHDRTarget : 1;
    bool		m_bDrawWorldNormal : 1;
    bool		m_bCullFrontFaces : 1;
    bool		m_bCacheFullSceneState : 1;
    bool		m_bRenderFlashlightDepthTranslucents : 1;
};

#pragma region vscript

#define Q_ARRAYSIZE(p) (sizeof(p)/sizeof(p[0]))

#define Assert(a) ((void)0)
#define UTLMEMORY_TRACK_ALLOC() ((void)0)
#define UTLMEMORY_TRACK_FREE() ((void)0)
#define MEM_ALLOC_CREDIT_CLASS() ((void)0)

template <class T>
inline void Construct(T* pMemory)
{
    ::new (pMemory) T;
}
template <class T>
inline void CopyConstruct(T* pMemory, T const& src)
{
    ::new (pMemory) T(src);
}
template <class T>
inline void Destruct(T* pMemory)
{
    pMemory->~T();
}

template <class T, class I = int>
class CUtlMemory {
public:
    CUtlMemory(int nGrowSize = 0, int nInitSize = 0);
    CUtlMemory(T* pMemory, int numElements);
    CUtlMemory(const T* pMemory, int numElements);
    ~CUtlMemory();
    void Init(int nGrowSize = 0, int nInitSize = 0);

    class Iterator_t {
    public:
        Iterator_t(I i)
            : index(i)
        {
        }
        I index;

        bool operator==(const Iterator_t it) const { return index == it.index; }
        bool operator!=(const Iterator_t it) const { return index != it.index; }
    };

    Iterator_t First() const { return Iterator_t(IsIdxValid(0) ? 0 : InvalidIndex()); }
    Iterator_t Next(const Iterator_t& it) const { return Iterator_t(IsIdxValid(it.index + 1) ? it.index + 1 : InvalidIndex()); }
    I GetIndex(const Iterator_t& it) const { return it.index; }
    bool IsIdxAfter(I i, const Iterator_t& it) const { return i > it.index; }
    bool IsValidIterator(const Iterator_t& it) const { return IsIdxValid(it.index); }
    Iterator_t InvalidIterator() const { return Iterator_t(InvalidIndex()); }
    T& operator[](I i);
    const T& operator[](I i) const;
    T& Element(I i);
    const T& Element(I i) const;
    bool IsIdxValid(I i) const;
    static I InvalidIndex() { return (I)-1; }
    T* Base();
    const T* Base() const;
    void SetExternalBuffer(T* pMemory, int numElements);
    void SetExternalBuffer(const T* pMemory, int numElements);
    void AssumeMemory(T* pMemory, int nSize);
    void Swap(CUtlMemory<T, I>& mem);
    void ConvertToGrowableMemory(int nGrowSize);
    int NumAllocated() const;
    int Count() const;
    void Grow(int num = 1);
    void EnsureCapacity(int num);
    void Purge();
    void Purge(int numElements);
    bool IsExternallyAllocated() const;
    bool IsReadOnly() const;
    void SetGrowSize(int size);

protected:
    void ValidateGrowSize()
    {
    }

    enum {
        EXTERNAL_BUFFER_MARKER = -1,
        EXTERNAL_CONST_BUFFER_MARKER = -2,
    };

    T* m_pMemory;
    int m_nAllocationCount;
    int m_nGrowSize;
};

template <class T, class A = CUtlMemory<T>>
class CUtlVector {
    typedef A CAllocator;

public:
    typedef T ElemType_t;

    CUtlVector(int growSize = 0, int initSize = 0);
    CUtlVector(T* pMemory, int allocationCount, int numElements = 0);
    ~CUtlVector();
    CUtlVector<T, A>& operator=(const CUtlVector<T, A>& other);
    T& operator[](int i);
    const T& operator[](int i) const;
    T& Element(int i);
    const T& Element(int i) const;
    T& Head();
    const T& Head() const;
    T& Tail();
    const T& Tail() const;
    T* Base() { return m_Memory.Base(); }
    const T* Base() const { return m_Memory.Base(); }
    int Count() const;
    int Size() const;
    bool IsValidIndex(int i) const;
    static int InvalidIndex();
    int AddToHead();
    int AddToTail();
    int InsertBefore(int elem);
    int InsertAfter(int elem);
    int AddToHead(const T& src);
    int AddToTail(const T& src);
    int InsertBefore(int elem, const T& src);
    int InsertAfter(int elem, const T& src);
    int AddMultipleToHead(int num);
    int AddMultipleToTail(int num, const T* pToCopy = NULL);
    int InsertMultipleBefore(int elem, int num, const T* pToCopy = NULL);
    int InsertMultipleAfter(int elem, int num);
    void SetSize(int size);
    void SetCount(int count);
    void CopyArray(const T* pArray, int size);
    void Swap(CUtlVector<T, A>& vec);
    int AddVectorToTail(CUtlVector<T, A> const& src);
    int Find(const T& src) const;
    bool HasElement(const T& src) const;
    void EnsureCapacity(int num);
    void EnsureCount(int num);
    void FastRemove(int elem);
    void Remove(int elem);
    bool FindAndRemove(const T& src);
    void RemoveMultiple(int elem, int num);
    void RemoveAll();
    void Purge();
    void PurgeAndDeleteElements();
    void Compact();
    void SetGrowSize(int size) { m_Memory.SetGrowSize(size); }
    int NumAllocated() const;
    void Sort(int(__cdecl* pfnCompare)(const T*, const T*));

protected:
    //CUtlVector(CUtlVector const& vec) { Assert(0); }
    void GrowVector(int num = 1);
    void ShiftElementsRight(int elem, int num = 1);
    void ShiftElementsLeft(int elem, int num = 1);

    CAllocator m_Memory;
    int m_Size;
    T* m_pElements;

    inline void ResetDbgInfo() { m_pElements = Base(); }
};

template <typename T, class A>
inline CUtlVector<T, A>::CUtlVector(int growSize, int initSize)
    : m_Memory(growSize, initSize)
    , m_Size(0)
{
    ResetDbgInfo();
}
template <typename T, class A>
inline CUtlVector<T, A>::CUtlVector(T* pMemory, int allocationCount, int numElements)
    : m_Memory(pMemory, allocationCount)
    , m_Size(numElements)
{
    ResetDbgInfo();
}
template <typename T, class A>
inline CUtlVector<T, A>::~CUtlVector()
{
    Purge();
}
template <typename T, class A>
inline CUtlVector<T, A>& CUtlVector<T, A>::operator=(const CUtlVector<T, A>& other)
{
    int nCount = other.Count();
    SetSize(nCount);
    for (int i = 0; i < nCount; i++) {
        (*this)[i] = other[i];
    }
    return *this;
}
template <typename T, class A>
inline T& CUtlVector<T, A>::operator[](int i)
{
    return m_Memory[i];
}
template <typename T, class A>
inline const T& CUtlVector<T, A>::operator[](int i) const
{
    return m_Memory[i];
}
template <typename T, class A>
inline T& CUtlVector<T, A>::Element(int i)
{
    return m_Memory[i];
}
template <typename T, class A>
inline const T& CUtlVector<T, A>::Element(int i) const
{
    return m_Memory[i];
}
template <typename T, class A>
inline T& CUtlVector<T, A>::Head()
{
    Assert(m_Size > 0);
    return m_Memory[0];
}
template <typename T, class A>
inline const T& CUtlVector<T, A>::Head() const
{
    Assert(m_Size > 0);
    return m_Memory[0];
}
template <typename T, class A>
inline T& CUtlVector<T, A>::Tail()
{
    Assert(m_Size > 0);
    return m_Memory[m_Size - 1];
}
template <typename T, class A>
inline const T& CUtlVector<T, A>::Tail() const
{
    Assert(m_Size > 0);
    return m_Memory[m_Size - 1];
}
template <typename T, class A>
inline int CUtlVector<T, A>::Size() const
{
    return m_Size;
}
template <typename T, class A>
inline int CUtlVector<T, A>::Count() const
{
    return m_Size;
}
template <typename T, class A>
inline bool CUtlVector<T, A>::IsValidIndex(int i) const
{
    return (i >= 0) && (i < m_Size);
}
template <typename T, class A>
inline int CUtlVector<T, A>::InvalidIndex()
{
    return -1;
}
template <typename T, class A>
void CUtlVector<T, A>::GrowVector(int num)
{
    if (m_Size + num > m_Memory.NumAllocated()) {
        MEM_ALLOC_CREDIT_CLASS();
        m_Memory.Grow(m_Size + num - m_Memory.NumAllocated());
    }

    m_Size += num;
    ResetDbgInfo();
}
template <typename T, class A>
void CUtlVector<T, A>::Sort(int(__cdecl* pfnCompare)(const T*, const T*))
{
    typedef int(__cdecl * QSortCompareFunc_t)(const void*, const void*);
    if (Count() <= 1)
        return;

    if (Base()) {
        qsort(Base(), Count(), sizeof(T), (QSortCompareFunc_t)(pfnCompare));
    } else {
        Assert(0);

        for (int i = m_Size - 1; i >= 0; --i) {
            for (int j = 1; j <= i; ++j) {
                if (pfnCompare(&Element(j - 1), &Element(j)) < 0) {
                    std::swap(Element(j - 1), Element(j));
                }
            }
        }
    }
}
template <typename T, class A>
void CUtlVector<T, A>::EnsureCapacity(int num)
{
    MEM_ALLOC_CREDIT_CLASS();
    m_Memory.EnsureCapacity(num);
    ResetDbgInfo();
}
template <typename T, class A>
void CUtlVector<T, A>::EnsureCount(int num)
{
    if (Count() < num)
        AddMultipleToTail(num - Count());
}
template <typename T, class A>
void CUtlVector<T, A>::ShiftElementsRight(int elem, int num)
{
    Assert(IsValidIndex(elem) || (m_Size == 0) || (num == 0));
    int numToMove = m_Size - elem - num;
    if ((numToMove > 0) && (num > 0))
        memmove(&Element(elem + num), &Element(elem), numToMove * sizeof(T));
}
template <typename T, class A>
void CUtlVector<T, A>::ShiftElementsLeft(int elem, int num)
{
    Assert(IsValidIndex(elem) || (m_Size == 0) || (num == 0));
    int numToMove = m_Size - elem - num;
    if ((numToMove > 0) && (num > 0)) {
        memmove(&Element(elem), &Element(elem + num), numToMove * sizeof(T));
    }
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddToHead()
{
    return InsertBefore(0);
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddToTail()
{
    return InsertBefore(m_Size);
}
template <typename T, class A>
inline int CUtlVector<T, A>::InsertAfter(int elem)
{
    return InsertBefore(elem + 1);
}
template <typename T, class A>
int CUtlVector<T, A>::InsertBefore(int elem)
{
    Assert((elem == Count()) || IsValidIndex(elem));

    GrowVector();
    ShiftElementsRight(elem);
    Construct(&Element(elem));
    return elem;
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddToHead(const T& src)
{
    Assert((Base() == NULL) || (&src < Base()) || (&src >= (Base() + Count())));
    return InsertBefore(0, src);
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddToTail(const T& src)
{
    Assert((Base() == NULL) || (&src < Base()) || (&src >= (Base() + Count())));
    return InsertBefore(m_Size, src);
}
template <typename T, class A>
inline int CUtlVector<T, A>::InsertAfter(int elem, const T& src)
{
    Assert((Base() == NULL) || (&src < Base()) || (&src >= (Base() + Count())));
    return InsertBefore(elem + 1, src);
}
template <typename T, class A>
int CUtlVector<T, A>::InsertBefore(int elem, const T& src)
{
    Assert((Base() == NULL) || (&src < Base()) || (&src >= (Base() + Count())));

    Assert((elem == Count()) || IsValidIndex(elem));

    GrowVector();
    ShiftElementsRight(elem);
    CopyConstruct(&Element(elem), src);
    return elem;
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddMultipleToHead(int num)
{
    return InsertMultipleBefore(0, num);
}
template <typename T, class A>
inline int CUtlVector<T, A>::AddMultipleToTail(int num, const T* pToCopy)
{
    Assert((Base() == NULL) || !pToCopy || (pToCopy + num < Base()) || (pToCopy >= (Base() + Count())));

    return InsertMultipleBefore(m_Size, num, pToCopy);
}
template <typename T, class A>
int CUtlVector<T, A>::InsertMultipleAfter(int elem, int num)
{
    return InsertMultipleBefore(elem + 1, num);
}
template <typename T, class A>
void CUtlVector<T, A>::SetCount(int count)
{
    RemoveAll();
    AddMultipleToTail(count);
}
template <typename T, class A>
inline void CUtlVector<T, A>::SetSize(int size)
{
    SetCount(size);
}
template <typename T, class A>
void CUtlVector<T, A>::CopyArray(const T* pArray, int size)
{
    Assert((Base() == NULL) || !pArray || (Base() >= (pArray + size)) || (pArray >= (Base() + Count())));

    SetSize(size);
    for (int i = 0; i < size; i++) {
        (*this)[i] = pArray[i];
    }
}
template <typename T, class A>
void CUtlVector<T, A>::Swap(CUtlVector<T, A>& vec)
{
    m_Memory.Swap(vec.m_Memory);
    std::swap(m_Size, vec.m_Size);
    std::swap(m_pElements, vec.m_pElements);
}
template <typename T, class A>
int CUtlVector<T, A>::AddVectorToTail(CUtlVector const& src)
{
    Assert(&src != this);

    int base = Count();

    AddMultipleToTail(src.Count());

    for (int i = 0; i < src.Count(); i++) {
        (*this)[base + i] = src[i];
    }

    return base;
}
template <typename T, class A>
inline int CUtlVector<T, A>::InsertMultipleBefore(int elem, int num, const T* pToInsert)
{
    if (num == 0)
        return elem;

    Assert((elem == Count()) || IsValidIndex(elem));

    GrowVector(num);
    ShiftElementsRight(elem, num);

    for (int i = 0; i < num; ++i)
        Construct(&Element(elem + i));

    if (pToInsert) {
        for (int i = 0; i < num; i++) {
            Element(elem + i) = pToInsert[i];
        }
    }

    return elem;
}
template <typename T, class A>
int CUtlVector<T, A>::Find(const T& src) const
{
    for (int i = 0; i < Count(); ++i) {
        if (Element(i) == src)
            return i;
    }
    return -1;
}
template <typename T, class A>
bool CUtlVector<T, A>::HasElement(const T& src) const
{
    return (Find(src) >= 0);
}
template <typename T, class A>
void CUtlVector<T, A>::FastRemove(int elem)
{
    Assert(IsValidIndex(elem));

    Destruct(&Element(elem));
    if (m_Size > 0) {
        memcpy(&Element(elem), &Element(m_Size - 1), sizeof(T));
        --m_Size;
    }
}
template <typename T, class A>
void CUtlVector<T, A>::Remove(int elem)
{
    Destruct(&Element(elem));
    ShiftElementsLeft(elem);
    --m_Size;
}
template <typename T, class A>
bool CUtlVector<T, A>::FindAndRemove(const T& src)
{
    int elem = Find(src);
    if (elem != -1) {
        Remove(elem);
        return true;
    }
    return false;
}
template <typename T, class A>
void CUtlVector<T, A>::RemoveMultiple(int elem, int num)
{
    Assert(elem >= 0);
    Assert(elem + num <= Count());

    for (int i = elem + num; --i >= elem;)
        Destruct(&Element(i));

    ShiftElementsLeft(elem, num);
    m_Size -= num;
}
template <typename T, class A>
void CUtlVector<T, A>::RemoveAll()
{
    for (int i = m_Size; --i >= 0;) {
        Destruct(&Element(i));
    }

    m_Size = 0;
}
template <typename T, class A>
inline void CUtlVector<T, A>::Purge()
{
    RemoveAll();
    m_Memory.Purge();
    ResetDbgInfo();
}
template <typename T, class A>
inline void CUtlVector<T, A>::PurgeAndDeleteElements()
{
    for (int i = 0; i < m_Size; i++) {
        delete Element(i);
    }
    Purge();
}
template <typename T, class A>
inline void CUtlVector<T, A>::Compact()
{
    m_Memory.Purge(m_Size);
}
template <typename T, class A>
inline int CUtlVector<T, A>::NumAllocated() const
{
    return m_Memory.NumAllocated();
}

template <class T, class I>
CUtlMemory<T, I>::CUtlMemory(int nGrowSize, int nInitAllocationCount)
    : m_pMemory(0)
    , m_nAllocationCount(nInitAllocationCount)
    , m_nGrowSize(nGrowSize)
{
    ValidateGrowSize();
    Assert(nGrowSize >= 0);
    if (m_nAllocationCount) {
        UTLMEMORY_TRACK_ALLOC();
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)malloc(m_nAllocationCount * sizeof(T));
    }
}
template <class T, class I>
CUtlMemory<T, I>::CUtlMemory(T* pMemory, int numElements)
    : m_pMemory(pMemory)
    , m_nAllocationCount(numElements)
{
    m_nGrowSize = EXTERNAL_BUFFER_MARKER;
}
template <class T, class I>
CUtlMemory<T, I>::CUtlMemory(const T* pMemory, int numElements)
    : m_pMemory((T*)pMemory)
    , m_nAllocationCount(numElements)
{
    m_nGrowSize = EXTERNAL_CONST_BUFFER_MARKER;
}
template <class T, class I>
CUtlMemory<T, I>::~CUtlMemory()
{
    Purge();
}
template <class T, class I>
void CUtlMemory<T, I>::Init(int nGrowSize /*= 0*/, int nInitSize /*= 0*/)
{
    Purge();

    m_nGrowSize = nGrowSize;
    m_nAllocationCount = nInitSize;
    ValidateGrowSize();
    Assert(nGrowSize >= 0);
    if (m_nAllocationCount) {
        UTLMEMORY_TRACK_ALLOC();
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)malloc(m_nAllocationCount * sizeof(T));
    }
}
template <class T, class I>
void CUtlMemory<T, I>::Swap(CUtlMemory<T, I>& mem)
{
    std::swap(m_nGrowSize, mem.m_nGrowSize);
    std::swap(m_pMemory, mem.m_pMemory);
    std::swap(m_nAllocationCount, mem.m_nAllocationCount);
}
template <class T, class I>
void CUtlMemory<T, I>::ConvertToGrowableMemory(int nGrowSize)
{
    if (!IsExternallyAllocated())
        return;

    m_nGrowSize = nGrowSize;
    if (m_nAllocationCount) {
        UTLMEMORY_TRACK_ALLOC();
        MEM_ALLOC_CREDIT_CLASS();

        int nNumBytes = m_nAllocationCount * sizeof(T);
        T* pMemory = (T*)malloc(nNumBytes);
        memcpy(pMemory, m_pMemory, nNumBytes);
        m_pMemory = pMemory;
    } else {
        m_pMemory = NULL;
    }
}
template <class T, class I>
void CUtlMemory<T, I>::SetExternalBuffer(T* pMemory, int numElements)
{
    Purge();

    m_pMemory = pMemory;
    m_nAllocationCount = numElements;

    m_nGrowSize = EXTERNAL_BUFFER_MARKER;
}

template <class T, class I>
void CUtlMemory<T, I>::SetExternalBuffer(const T* pMemory, int numElements)
{
    Purge();

    m_pMemory = const_cast<T*>(pMemory);
    m_nAllocationCount = numElements;

    m_nGrowSize = EXTERNAL_CONST_BUFFER_MARKER;
}
template <class T, class I>
void CUtlMemory<T, I>::AssumeMemory(T* pMemory, int numElements)
{
    Purge();

    m_pMemory = pMemory;
    m_nAllocationCount = numElements;
}
template <class T, class I>
inline T& CUtlMemory<T, I>::operator[](I i)
{
    Assert(!IsReadOnly());
    Assert(IsIdxValid(i));
    return m_pMemory[i];
}
template <class T, class I>
inline const T& CUtlMemory<T, I>::operator[](I i) const
{
    Assert(IsIdxValid(i));
    return m_pMemory[i];
}
template <class T, class I>
inline T& CUtlMemory<T, I>::Element(I i)
{
    Assert(!IsReadOnly());
    Assert(IsIdxValid(i));
    return m_pMemory[i];
}
template <class T, class I>
inline const T& CUtlMemory<T, I>::Element(I i) const
{
    Assert(IsIdxValid(i));
    return m_pMemory[i];
}
template <class T, class I>
bool CUtlMemory<T, I>::IsExternallyAllocated() const
{
    return (m_nGrowSize < 0);
}
template <class T, class I>
bool CUtlMemory<T, I>::IsReadOnly() const
{
    return (m_nGrowSize == EXTERNAL_CONST_BUFFER_MARKER);
}
template <class T, class I>
void CUtlMemory<T, I>::SetGrowSize(int nSize)
{
    Assert(!IsExternallyAllocated());
    Assert(nSize >= 0);
    m_nGrowSize = nSize;
    ValidateGrowSize();
}
template <class T, class I>
inline T* CUtlMemory<T, I>::Base()
{
    Assert(!IsReadOnly());
    return m_pMemory;
}
template <class T, class I>
inline const T* CUtlMemory<T, I>::Base() const
{
    return m_pMemory;
}
template <class T, class I>
inline int CUtlMemory<T, I>::NumAllocated() const
{
    return m_nAllocationCount;
}
template <class T, class I>
inline int CUtlMemory<T, I>::Count() const
{
    return m_nAllocationCount;
}
template <class T, class I>
inline bool CUtlMemory<T, I>::IsIdxValid(I i) const
{
    return (((int)i) >= 0) && (((int)i) < m_nAllocationCount);
}
inline int UtlMemory_CalcNewAllocationCount(int nAllocationCount, int nGrowSize, int nNewSize, int nBytesItem)
{
    if (nGrowSize) {
        nAllocationCount = ((1 + ((nNewSize - 1) / nGrowSize)) * nGrowSize);
    } else {
        if (!nAllocationCount) {
            nAllocationCount = (31 + nBytesItem) / nBytesItem;
        }

        while (nAllocationCount < nNewSize) {
            nAllocationCount *= 2;
        }
    }

    return nAllocationCount;
}
template <class T, class I>
void CUtlMemory<T, I>::Grow(int num)
{
    Assert(num > 0);

    if (IsExternallyAllocated()) {
        Assert(0);
        return;
    }

    int nAllocationRequested = m_nAllocationCount + num;

    UTLMEMORY_TRACK_FREE();

    m_nAllocationCount = UtlMemory_CalcNewAllocationCount(m_nAllocationCount, m_nGrowSize, nAllocationRequested, sizeof(T));

    if ((int)(I)m_nAllocationCount < nAllocationRequested) {
        if ((int)(I)m_nAllocationCount == 0 && (int)(I)(m_nAllocationCount - 1) >= nAllocationRequested) {
            --m_nAllocationCount;
        } else {
            if ((int)(I)nAllocationRequested != nAllocationRequested) {
                Assert(0);
                return;
            }
            while ((int)(I)m_nAllocationCount < nAllocationRequested) {
                m_nAllocationCount = (m_nAllocationCount + nAllocationRequested) / 2;
            }
        }
    }

    UTLMEMORY_TRACK_ALLOC();

    if (m_pMemory) {
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)realloc(m_pMemory, m_nAllocationCount * sizeof(T));
        Assert(m_pMemory);
    } else {
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)malloc(m_nAllocationCount * sizeof(T));
        Assert(m_pMemory);
    }
}
template <class T, class I>
inline void CUtlMemory<T, I>::EnsureCapacity(int num)
{
    if (m_nAllocationCount >= num)
        return;

    if (IsExternallyAllocated()) {
        Assert(0);
        return;
    }

    UTLMEMORY_TRACK_FREE();

    m_nAllocationCount = num;

    UTLMEMORY_TRACK_ALLOC();

    if (m_pMemory) {
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)realloc(m_pMemory, m_nAllocationCount * sizeof(T));
    } else {
        MEM_ALLOC_CREDIT_CLASS();
        m_pMemory = (T*)malloc(m_nAllocationCount * sizeof(T));
    }
}
template <class T, class I>
void CUtlMemory<T, I>::Purge()
{
    if (!IsExternallyAllocated()) {
        if (m_pMemory) {
            UTLMEMORY_TRACK_FREE();
            free((void*)m_pMemory);
            m_pMemory = 0;
        }
        m_nAllocationCount = 0;
    }
}
template <class T, class I>
void CUtlMemory<T, I>::Purge(int numElements)
{
    Assert(numElements >= 0);

    if (numElements > m_nAllocationCount) {
        Assert(numElements <= m_nAllocationCount);
        return;
    }

    if (numElements == 0) {
        Purge();
        return;
    }

    if (IsExternallyAllocated()) {
        return;
    }

    if (numElements == m_nAllocationCount) {
        return;
    }

    if (!m_pMemory) {
        Assert(m_pMemory);
        return;
    }

    UTLMEMORY_TRACK_FREE();

    m_nAllocationCount = numElements;

    UTLMEMORY_TRACK_ALLOC();

    MEM_ALLOC_CREDIT_CLASS();
    m_pMemory = (T*)realloc(m_pMemory, m_nAllocationCount * sizeof(T));
}

#define AssertMsg(_exp, _msg) ((void)0)

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_0
#define FUNC_TEMPLATE_ARG_PARAMS_0
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_0
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_0
#define FUNC_ARG_MEMBERS_0
#define FUNC_ARG_FORMAL_PARAMS_0
#define FUNC_PROXY_ARG_FORMAL_PARAMS_0
#define FUNC_CALL_ARGS_INIT_0
#define FUNC_SOLO_CALL_ARGS_INIT_0
#define FUNC_CALL_MEMBER_ARGS_0
#define FUNC_CALL_ARGS_0
#define FUNC_CALL_DATA_ARGS_0(_var)
#define FUNC_FUNCTOR_CALL_ARGS_0
#define FUNC_TEMPLATE_FUNC_PARAMS_0
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_0
#define FUNC_VALIDATION_STRING_0 Q_snprintf(pString, nBufLen, "method( void )");

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_1 typename ARG_TYPE_1
#define FUNC_TEMPLATE_ARG_PARAMS_1 , typename ARG_TYPE_1
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_1 , ARG_TYPE_1
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_1 ARG_TYPE_1
#define FUNC_ARG_MEMBERS_1 ARG_TYPE_1 m_arg1
#define FUNC_ARG_FORMAL_PARAMS_1 , const ARG_TYPE_1& arg1
#define FUNC_PROXY_ARG_FORMAL_PARAMS_1 const ARG_TYPE_1& arg1
#define FUNC_CALL_ARGS_INIT_1 , m_arg1(arg1)
#define FUNC_SOLO_CALL_ARGS_INIT_1			: m_arg1( arg1 )
#define FUNC_CALL_MEMBER_ARGS_1 m_arg1
#define FUNC_CALL_ARGS_1 arg1
#define FUNC_CALL_DATA_ARGS_1(_var) _var->m_arg1
#define FUNC_FUNCTOR_CALL_ARGS_1 , arg1
#define FUNC_TEMPLATE_FUNC_PARAMS_1 , typename FUNC_ARG_TYPE_1
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_1 FUNC_ARG_TYPE_1
#define FUNC_VALIDATION_STRING_1 Q_snprintf(pString, nBufLen, "method( %s )", typeid(ARG_TYPE_1).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_2 typename ARG_TYPE_1, typename ARG_TYPE_2
#define FUNC_TEMPLATE_ARG_PARAMS_2 , typename ARG_TYPE_1, typename ARG_TYPE_2
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_2 , ARG_TYPE_1, ARG_TYPE_2
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_2 ARG_TYPE_1, ARG_TYPE_2
#define FUNC_ARG_MEMBERS_2 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2
#define FUNC_ARG_FORMAL_PARAMS_2 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2
#define FUNC_PROXY_ARG_FORMAL_PARAMS_2 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2
#define FUNC_CALL_ARGS_INIT_2 , m_arg1(arg1), m_arg2(arg2)
#define FUNC_SOLO_CALL_ARGS_INIT_2			: m_arg1( arg1 ), m_arg2( arg2 )
#define FUNC_CALL_MEMBER_ARGS_2 m_arg1, m_arg2
#define FUNC_CALL_ARGS_2 arg1, arg2
#define FUNC_CALL_DATA_ARGS_2(_var) _var->m_arg1, _var->m_arg2
#define FUNC_FUNCTOR_CALL_ARGS_2 , arg1, arg2
#define FUNC_TEMPLATE_FUNC_PARAMS_2 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_2 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2
#define FUNC_VALIDATION_STRING_2 Q_snprintf(pString, nBufLen, "method( %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_3 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3
#define FUNC_TEMPLATE_ARG_PARAMS_3 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_3 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_3 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3
#define FUNC_ARG_MEMBERS_3 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3
#define FUNC_ARG_FORMAL_PARAMS_3 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3
#define FUNC_PROXY_ARG_FORMAL_PARAMS_3 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3
#define FUNC_CALL_ARGS_INIT_3 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3)
#define FUNC_SOLO_CALL_ARGS_INIT_3			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 )
#define FUNC_CALL_MEMBER_ARGS_3 m_arg1, m_arg2, m_arg3
#define FUNC_CALL_ARGS_3 arg1, arg2, arg3
#define FUNC_CALL_DATA_ARGS_3(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3
#define FUNC_FUNCTOR_CALL_ARGS_3 , arg1, arg2, arg3
#define FUNC_TEMPLATE_FUNC_PARAMS_3 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_3 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3
#define FUNC_VALIDATION_STRING_3 Q_snprintf(pString, nBufLen, "method( %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_4 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4
#define FUNC_TEMPLATE_ARG_PARAMS_4 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_4 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_4 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4
#define FUNC_ARG_MEMBERS_4 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4
#define FUNC_ARG_FORMAL_PARAMS_4 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4
#define FUNC_PROXY_ARG_FORMAL_PARAMS_4 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4
#define FUNC_CALL_ARGS_INIT_4 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4)
#define FUNC_SOLO_CALL_ARGS_INIT_4			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 )
#define FUNC_CALL_MEMBER_ARGS_4 m_arg1, m_arg2, m_arg3, m_arg4
#define FUNC_CALL_ARGS_4 arg1, arg2, arg3, arg4
#define FUNC_CALL_DATA_ARGS_4(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4
#define FUNC_FUNCTOR_CALL_ARGS_4 , arg1, arg2, arg3, arg4
#define FUNC_TEMPLATE_FUNC_PARAMS_4 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_4 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4
#define FUNC_VALIDATION_STRING_4 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_5 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5
#define FUNC_TEMPLATE_ARG_PARAMS_5 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_5 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_5 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5
#define FUNC_ARG_MEMBERS_5 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4;     \
    ARG_TYPE_5 m_arg5
#define FUNC_ARG_FORMAL_PARAMS_5 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5
#define FUNC_PROXY_ARG_FORMAL_PARAMS_5 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5
#define FUNC_CALL_ARGS_INIT_5 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5)
#define FUNC_SOLO_CALL_ARGS_INIT_5			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 )
#define FUNC_CALL_MEMBER_ARGS_5 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5
#define FUNC_CALL_ARGS_5 arg1, arg2, arg3, arg4, arg5
#define FUNC_CALL_DATA_ARGS_5(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5
#define FUNC_FUNCTOR_CALL_ARGS_5 , arg1, arg2, arg3, arg4, arg5
#define FUNC_TEMPLATE_FUNC_PARAMS_5 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_5 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5
#define FUNC_VALIDATION_STRING_5 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_6 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6
#define FUNC_TEMPLATE_ARG_PARAMS_6 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_6 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_6 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6
#define FUNC_ARG_MEMBERS_6 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4;     \
    ARG_TYPE_5 m_arg5;     \
    ARG_TYPE_6 m_arg6
#define FUNC_ARG_FORMAL_PARAMS_6 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6
#define FUNC_PROXY_ARG_FORMAL_PARAMS_6 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6
#define FUNC_CALL_ARGS_INIT_6 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6)
#define FUNC_SOLO_CALL_ARGS_INIT_6			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 )
#define FUNC_CALL_MEMBER_ARGS_6 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6
#define FUNC_CALL_ARGS_6 arg1, arg2, arg3, arg4, arg5, arg6
#define FUNC_CALL_DATA_ARGS_6(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6
#define FUNC_FUNCTOR_CALL_ARGS_6 , arg1, arg2, arg3, arg4, arg5, arg6
#define FUNC_TEMPLATE_FUNC_PARAMS_6 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_6 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6
#define FUNC_VALIDATION_STRING_6 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_7 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7
#define FUNC_TEMPLATE_ARG_PARAMS_7 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_7 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_7 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7
#define FUNC_ARG_MEMBERS_7 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4;     \
    ARG_TYPE_5 m_arg5;     \
    ARG_TYPE_6 m_arg6;     \
    ARG_TYPE_7 m_arg7;
#define FUNC_ARG_FORMAL_PARAMS_7 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7
#define FUNC_PROXY_ARG_FORMAL_PARAMS_7 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7
#define FUNC_CALL_ARGS_INIT_7 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7)
#define FUNC_SOLO_CALL_ARGS_INIT_7			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 )
#define FUNC_CALL_MEMBER_ARGS_7 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7
#define FUNC_CALL_ARGS_7 arg1, arg2, arg3, arg4, arg5, arg6, arg7
#define FUNC_CALL_DATA_ARGS_7(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7
#define FUNC_FUNCTOR_CALL_ARGS_7 , arg1, arg2, arg3, arg4, arg5, arg6, arg7
#define FUNC_TEMPLATE_FUNC_PARAMS_7 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_7 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7
#define FUNC_VALIDATION_STRING_7 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_8 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8
#define FUNC_TEMPLATE_ARG_PARAMS_8 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_8 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_8 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8
#define FUNC_ARG_MEMBERS_8 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4;     \
    ARG_TYPE_5 m_arg5;     \
    ARG_TYPE_6 m_arg6;     \
    ARG_TYPE_7 m_arg7;     \
    ARG_TYPE_8 m_arg8;
#define FUNC_ARG_FORMAL_PARAMS_8 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8
#define FUNC_PROXY_ARG_FORMAL_PARAMS_8 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8
#define FUNC_CALL_ARGS_INIT_8 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8)
#define FUNC_SOLO_CALL_ARGS_INIT_8			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 )
#define FUNC_CALL_MEMBER_ARGS_8 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8
#define FUNC_CALL_ARGS_8 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
#define FUNC_CALL_DATA_ARGS_8(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8
#define FUNC_FUNCTOR_CALL_ARGS_8 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
#define FUNC_TEMPLATE_FUNC_PARAMS_8 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_8 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8
#define FUNC_VALIDATION_STRING_8 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_9 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9
#define FUNC_TEMPLATE_ARG_PARAMS_9 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_9 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_9 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9
#define FUNC_ARG_MEMBERS_9 \
    ARG_TYPE_1 m_arg1;     \
    ARG_TYPE_2 m_arg2;     \
    ARG_TYPE_3 m_arg3;     \
    ARG_TYPE_4 m_arg4;     \
    ARG_TYPE_5 m_arg5;     \
    ARG_TYPE_6 m_arg6;     \
    ARG_TYPE_7 m_arg7;     \
    ARG_TYPE_8 m_arg8;     \
    ARG_TYPE_9 m_arg9;
#define FUNC_ARG_FORMAL_PARAMS_9 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9
#define FUNC_PROXY_ARG_FORMAL_PARAMS_9 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9
#define FUNC_CALL_ARGS_INIT_9 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9)
#define FUNC_SOLO_CALL_ARGS_INIT_9			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 )
#define FUNC_CALL_MEMBER_ARGS_9 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9
#define FUNC_CALL_ARGS_9 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
#define FUNC_CALL_DATA_ARGS_9(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9
#define FUNC_FUNCTOR_CALL_ARGS_9 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
#define FUNC_TEMPLATE_FUNC_PARAMS_9 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_9 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9
#define FUNC_VALIDATION_STRING_9 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_10 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10
#define FUNC_TEMPLATE_ARG_PARAMS_10 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_10 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_10 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10
#define FUNC_ARG_MEMBERS_10 \
    ARG_TYPE_1 m_arg1;      \
    ARG_TYPE_2 m_arg2;      \
    ARG_TYPE_3 m_arg3;      \
    ARG_TYPE_4 m_arg4;      \
    ARG_TYPE_5 m_arg5;      \
    ARG_TYPE_6 m_arg6;      \
    ARG_TYPE_7 m_arg7;      \
    ARG_TYPE_8 m_arg8;      \
    ARG_TYPE_9 m_arg9;      \
    ARG_TYPE_10 m_arg10;
#define FUNC_ARG_FORMAL_PARAMS_10 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10
#define FUNC_PROXY_ARG_FORMAL_PARAMS_10 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10
#define FUNC_CALL_ARGS_INIT_10 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9), m_arg10(arg10)
#define FUNC_SOLO_CALL_ARGS_INIT_10			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 ), m_arg10( arg10 )
#define FUNC_CALL_MEMBER_ARGS_10 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9, m_arg10
#define FUNC_CALL_ARGS_10 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10
#define FUNC_CALL_DATA_ARGS_10(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9, _var->m_arg10
#define FUNC_FUNCTOR_CALL_ARGS_10 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10
#define FUNC_TEMPLATE_FUNC_PARAMS_10 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9, typename FUNC_ARG_TYPE_10
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_10 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9, FUNC_ARG_TYPE_10
#define FUNC_VALIDATION_STRING_10 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name(), typeid(ARG_TYPE_10).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_11 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11
#define FUNC_TEMPLATE_ARG_PARAMS_11 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_11 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_11 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11
#define FUNC_ARG_MEMBERS_11 \
    ARG_TYPE_1 m_arg1;      \
    ARG_TYPE_2 m_arg2;      \
    ARG_TYPE_3 m_arg3;      \
    ARG_TYPE_4 m_arg4;      \
    ARG_TYPE_5 m_arg5;      \
    ARG_TYPE_6 m_arg6;      \
    ARG_TYPE_7 m_arg7;      \
    ARG_TYPE_8 m_arg8;      \
    ARG_TYPE_9 m_arg9;      \
    ARG_TYPE_10 m_arg10;    \
    ARG_TYPE_11 m_arg11
#define FUNC_ARG_FORMAL_PARAMS_11 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11
#define FUNC_PROXY_ARG_FORMAL_PARAMS_11 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11
#define FUNC_CALL_ARGS_INIT_11 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9), m_arg10(arg10), m_arg11(arg11)
#define FUNC_SOLO_CALL_ARGS_INIT_11			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 ), m_arg10( arg10 ), m_arg11( arg11 )
#define FUNC_CALL_MEMBER_ARGS_11 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9, m_arg10, m_arg11
#define FUNC_CALL_ARGS_11 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
#define FUNC_CALL_DATA_ARGS_11(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9, _var->m_arg10, _var->m_arg11
#define FUNC_FUNCTOR_CALL_ARGS_11 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
#define FUNC_TEMPLATE_FUNC_PARAMS_11 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9, typename FUNC_ARG_TYPE_10, typename FUNC_ARG_TYPE_11
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_11 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9, FUNC_ARG_TYPE_10, FUNC_ARG_TYPE_11
#define FUNC_VALIDATION_STRING_11 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name(), typeid(ARG_TYPE_10).name(), typeid(ARG_TYPE_11).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_12 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12
#define FUNC_TEMPLATE_ARG_PARAMS_12 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_12 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_12 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12
#define FUNC_ARG_MEMBERS_12 \
    ARG_TYPE_1 m_arg1;      \
    ARG_TYPE_2 m_arg2;      \
    ARG_TYPE_3 m_arg3;      \
    ARG_TYPE_4 m_arg4;      \
    ARG_TYPE_5 m_arg5;      \
    ARG_TYPE_6 m_arg6;      \
    ARG_TYPE_7 m_arg7;      \
    ARG_TYPE_8 m_arg8;      \
    ARG_TYPE_9 m_arg9;      \
    ARG_TYPE_10 m_arg10;    \
    ARG_TYPE_11 m_arg11;    \
    ARG_TYPE_12 m_arg12
#define FUNC_ARG_FORMAL_PARAMS_12 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12
#define FUNC_PROXY_ARG_FORMAL_PARAMS_12 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12
#define FUNC_CALL_ARGS_INIT_12 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9), m_arg10(arg10), m_arg11(arg11), m_arg12(arg12)
#define FUNC_SOLO_CALL_ARGS_INIT_12			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 ), m_arg10( arg10 ), m_arg11( arg11 ), m_arg12( arg12 )
#define FUNC_CALL_MEMBER_ARGS_12 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9, m_arg10, m_arg11, m_arg12
#define FUNC_CALL_ARGS_12 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12
#define FUNC_CALL_DATA_ARGS_12(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9, _var->m_arg10, _var->m_arg11, _var->m_arg12
#define FUNC_FUNCTOR_CALL_ARGS_12 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12
#define FUNC_TEMPLATE_FUNC_PARAMS_12 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9, typename FUNC_ARG_TYPE_10, typename FUNC_ARG_TYPE_11, typename FUNC_ARG_TYPE_12
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_12 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9, FUNC_ARG_TYPE_10, FUNC_ARG_TYPE_11, FUNC_ARG_TYPE_12
#define FUNC_VALIDATION_STRING_12 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name(), typeid(ARG_TYPE_10).name(), typeid(ARG_TYPE_11).name(), typeid(ARG_TYPE_12).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_13 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13
#define FUNC_TEMPLATE_ARG_PARAMS_13 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_13 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12, ARG_TYPE_13
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_13 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12, ARG_TYPE_13
#define FUNC_ARG_MEMBERS_13 \
    ARG_TYPE_1 m_arg1;      \
    ARG_TYPE_2 m_arg2;      \
    ARG_TYPE_3 m_arg3;      \
    ARG_TYPE_4 m_arg4;      \
    ARG_TYPE_5 m_arg5;      \
    ARG_TYPE_6 m_arg6;      \
    ARG_TYPE_7 m_arg7;      \
    ARG_TYPE_8 m_arg8;      \
    ARG_TYPE_9 m_arg9;      \
    ARG_TYPE_10 m_arg10;    \
    ARG_TYPE_11 m_arg11;    \
    ARG_TYPE_12 m_arg12;    \
    ARG_TYPE_13 m_arg13
#define FUNC_ARG_FORMAL_PARAMS_13 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12, const ARG_TYPE_13 &arg13
#define FUNC_PROXY_ARG_FORMAL_PARAMS_13 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12, const ARG_TYPE_13 &arg13
#define FUNC_CALL_ARGS_INIT_13 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9), m_arg10(arg10), m_arg11(arg11), m_arg12(arg12), m_arg13(arg13)
#define FUNC_SOLO_CALL_ARGS_INIT_13			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 ), m_arg10( arg10 ), m_arg11( arg11 ), m_arg12( arg12 ), m_arg13( arg13 )
#define FUNC_CALL_MEMBER_ARGS_13 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9, m_arg10, m_arg11, m_arg12, m_arg13
#define FUNC_CALL_ARGS_13 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13
#define FUNC_CALL_DATA_ARGS_13(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9, _var->m_arg10, _var->m_arg11, _var->m_arg12, _var->m_arg13
#define FUNC_FUNCTOR_CALL_ARGS_13 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13
#define FUNC_TEMPLATE_FUNC_PARAMS_13 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9, typename FUNC_ARG_TYPE_10, typename FUNC_ARG_TYPE_11, typename FUNC_ARG_TYPE_12, typename FUNC_ARG_TYPE_13
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_13 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9, FUNC_ARG_TYPE_10, FUNC_ARG_TYPE_11, FUNC_ARG_TYPE_12, FUNC_ARG_TYPE_13
#define FUNC_VALIDATION_STRING_13 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name(), typeid(ARG_TYPE_10).name(), typeid(ARG_TYPE_11).name(), typeid(ARG_TYPE_12).name(), typeid(ARG_TYPE_13).name());

#define FUNC_SOLO_TEMPLATE_ARG_PARAMS_14 typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13, typename ARG_TYPE_14
#define FUNC_TEMPLATE_ARG_PARAMS_14 , typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13, typename ARG_TYPE_14
#define FUNC_BASE_TEMPLATE_ARG_PARAMS_14 , ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12, ARG_TYPE_13, ARG_TYPE_14
#define FUNC_SOLO_BASE_TEMPLATE_ARG_PARAMS_14 ARG_TYPE_1, ARG_TYPE_2, ARG_TYPE_3, ARG_TYPE_4, ARG_TYPE_5, ARG_TYPE_6, ARG_TYPE_7, ARG_TYPE_8, ARG_TYPE_9, ARG_TYPE_10, ARG_TYPE_11, ARG_TYPE_12, ARG_TYPE_13, ARG_TYPE_14
#define FUNC_ARG_MEMBERS_14 \
    ARG_TYPE_1 m_arg1;      \
    ARG_TYPE_2 m_arg2;      \
    ARG_TYPE_3 m_arg3;      \
    ARG_TYPE_4 m_arg4;      \
    ARG_TYPE_5 m_arg5;      \
    ARG_TYPE_6 m_arg6;      \
    ARG_TYPE_7 m_arg7;      \
    ARG_TYPE_8 m_arg8;      \
    ARG_TYPE_9 m_arg9;      \
    ARG_TYPE_10 m_arg10;    \
    ARG_TYPE_11 m_arg11;    \
    ARG_TYPE_12 m_arg12;    \
    ARG_TYPE_13 m_arg13;    \
    ARG_TYPE_14 m_arg14
#define FUNC_ARG_FORMAL_PARAMS_14 , const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12, const ARG_TYPE_13 &arg13, const ARG_TYPE_14 &arg14
#define FUNC_PROXY_ARG_FORMAL_PARAMS_14 const ARG_TYPE_1 &arg1, const ARG_TYPE_2 &arg2, const ARG_TYPE_3 &arg3, const ARG_TYPE_4 &arg4, const ARG_TYPE_5 &arg5, const ARG_TYPE_6 &arg6, const ARG_TYPE_7 &arg7, const ARG_TYPE_8 &arg8, const ARG_TYPE_9 &arg9, const ARG_TYPE_10 &arg10, const ARG_TYPE_11 &arg11, const ARG_TYPE_12 &arg12, const ARG_TYPE_13 &arg13, const ARG_TYPE_14 &arg14
#define FUNC_CALL_ARGS_INIT_14 , m_arg1(arg1), m_arg2(arg2), m_arg3(arg3), m_arg4(arg4), m_arg5(arg5), m_arg6(arg6), m_arg7(arg7), m_arg8(arg8), m_arg9(arg9), m_arg10(arg10), m_arg11(arg11), m_arg12(arg12), m_arg13(arg13), m_arg14(arg14)
#define FUNC_SOLO_CALL_ARGS_INIT_14			: m_arg1( arg1 ), m_arg2( arg2 ), m_arg3( arg3 ), m_arg4( arg4 ), m_arg5( arg5 ), m_arg6( arg6 ), m_arg7( arg7 ), m_arg8( arg8 ), m_arg9( arg9 ), m_arg10( arg10 ), m_arg11( arg11 ), m_arg12( arg12 ), m_arg13( arg13 ), m_arg14( arg14 )
#define FUNC_CALL_MEMBER_ARGS_14 m_arg1, m_arg2, m_arg3, m_arg4, m_arg5, m_arg6, m_arg7, m_arg8, m_arg9, m_arg10, m_arg11, m_arg12, m_arg13, m_arg14
#define FUNC_CALL_ARGS_14 arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14
#define FUNC_CALL_DATA_ARGS_14(_var) _var->m_arg1, _var->m_arg2, _var->m_arg3, _var->m_arg4, _var->m_arg5, _var->m_arg6, _var->m_arg7, _var->m_arg8, _var->m_arg9, _var->m_arg10, _var->m_arg11, _var->m_arg12, _var->m_arg13, _var->m_arg14
#define FUNC_FUNCTOR_CALL_ARGS_14 , arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14
#define FUNC_TEMPLATE_FUNC_PARAMS_14 , typename FUNC_ARG_TYPE_1, typename FUNC_ARG_TYPE_2, typename FUNC_ARG_TYPE_3, typename FUNC_ARG_TYPE_4, typename FUNC_ARG_TYPE_5, typename FUNC_ARG_TYPE_6, typename FUNC_ARG_TYPE_7, typename FUNC_ARG_TYPE_8, typename FUNC_ARG_TYPE_9, typename FUNC_ARG_TYPE_10, typename FUNC_ARG_TYPE_11, typename FUNC_ARG_TYPE_12, typename FUNC_ARG_TYPE_13, typename FUNC_ARG_TYPE_14
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_14 FUNC_ARG_TYPE_1, FUNC_ARG_TYPE_2, FUNC_ARG_TYPE_3, FUNC_ARG_TYPE_4, FUNC_ARG_TYPE_5, FUNC_ARG_TYPE_6, FUNC_ARG_TYPE_7, FUNC_ARG_TYPE_8, FUNC_ARG_TYPE_9, FUNC_ARG_TYPE_10, FUNC_ARG_TYPE_11, FUNC_ARG_TYPE_12, FUNC_ARG_TYPE_13, FUNC_ARG_TYPE_14
#define FUNC_VALIDATION_STRING_14 Q_snprintf(pString, nBufLen, "method( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )", typeid(ARG_TYPE_1).name(), typeid(ARG_TYPE_2).name(), typeid(ARG_TYPE_3).name(), typeid(ARG_TYPE_4).name(), typeid(ARG_TYPE_5).name(), typeid(ARG_TYPE_6).name(), typeid(ARG_TYPE_7).name(), typeid(ARG_TYPE_8).name(), typeid(ARG_TYPE_9).name(), typeid(ARG_TYPE_10).name(), typeid(ARG_TYPE_11).name(), typeid(ARG_TYPE_12).name(), typeid(ARG_TYPE_13).name(), typeid(ARG_TYPE_14).name());

#define FUNC_GENERATE_ALL_BUT0(INNERMACRONAME) \
    INNERMACRONAME(1);                         \
    INNERMACRONAME(2);                         \
    INNERMACRONAME(3);                         \
    INNERMACRONAME(4);                         \
    INNERMACRONAME(5);                         \
    INNERMACRONAME(6);                         \
    INNERMACRONAME(7);                         \
    INNERMACRONAME(8);                         \
    INNERMACRONAME(9);                         \
    INNERMACRONAME(10);                        \
    INNERMACRONAME(11);                        \
    INNERMACRONAME(12);                        \
    INNERMACRONAME(13);                        \
    INNERMACRONAME(14)

#define FUNC_GENERATE_ALL(INNERMACRONAME) \
    INNERMACRONAME(0);                    \
    FUNC_GENERATE_ALL_BUT0(INNERMACRONAME)

typedef enum _fieldtypes {
    FIELD_VOID = 0,
    FIELD_FLOAT,
    FIELD_STRING,
    FIELD_VECTOR,
    FIELD_QUATERNION,
    FIELD_INTEGER,
    FIELD_BOOLEAN,
    FIELD_SHORT,
    FIELD_CHARACTER,
    FIELD_COLOR32,
    FIELD_EMBEDDED,
    FIELD_CUSTOM,
    FIELD_CLASSPTR,
    FIELD_EHANDLE,
    FIELD_EDICT,
    FIELD_POSITION_VECTOR,
    FIELD_TIME,
    FIELD_TICK,
    FIELD_MODELNAME,
    FIELD_SOUNDNAME,
    FIELD_INPUT,
    FIELD_FUNCTION,
    FIELD_VMATRIX,
    FIELD_VMATRIX_WORLDSPACE,
    FIELD_MATRIX3X4_WORLDSPACE,
    FIELD_INTERVAL,
    FIELD_MODELINDEX,
    FIELD_MATERIALINDEX,
    FIELD_VECTOR2D,
    FIELD_INTEGER64,
    FIELD_VECTOR4D,
    FIELD_TYPECOUNT,
} fieldtype_t;

#define DECLARE_POINTER_HANDLE(name) \
    struct name##__ {                \
        int unused;                  \
    };                               \
    typedef struct name##__* name

class IScriptVM;

enum ScriptLanguage_t {
    SL_NONE,
    SL_GAMEMONKEY,
    SL_SQUIRREL,
    SL_LUA,
    SL_PYTHON,
    SL_DEFAULT = SL_SQUIRREL
};

DECLARE_POINTER_HANDLE(HSCRIPT);
#define INVALID_HSCRIPT ((HSCRIPT)-1)

enum ExtendedFieldType {
    FIELD_TYPEUNKNOWN = FIELD_TYPECOUNT,
    FIELD_CSTRING,
    FIELD_HSCRIPT,
    FIELD_VARIANT,
};

typedef int ScriptDataType_t;
struct ScriptVariant_t;

template <typename T>
struct ScriptDeducer { /*enum { FIELD_TYPE = FIELD_TYPEUNKNOWN };*/
};
#define DECLARE_DEDUCE_FIELDTYPE(fieldType, type) \
    template <>                                   \
    struct ScriptDeducer<type> {                  \
        enum { FIELD_TYPE = fieldType };          \
    };

DECLARE_DEDUCE_FIELDTYPE(FIELD_VOID, void);
DECLARE_DEDUCE_FIELDTYPE(FIELD_FLOAT, float);
DECLARE_DEDUCE_FIELDTYPE(FIELD_CSTRING, const char*);
DECLARE_DEDUCE_FIELDTYPE(FIELD_CSTRING, char*);
DECLARE_DEDUCE_FIELDTYPE(FIELD_VECTOR, Vector);
DECLARE_DEDUCE_FIELDTYPE(FIELD_VECTOR, const Vector&);
DECLARE_DEDUCE_FIELDTYPE(FIELD_INTEGER, int);
DECLARE_DEDUCE_FIELDTYPE(FIELD_BOOLEAN, bool);
DECLARE_DEDUCE_FIELDTYPE(FIELD_CHARACTER, char);
DECLARE_DEDUCE_FIELDTYPE(FIELD_HSCRIPT, HSCRIPT);
DECLARE_DEDUCE_FIELDTYPE(FIELD_VARIANT, ScriptVariant_t);

#define ScriptDeduceType(T) ScriptDeducer<T>::FIELD_TYPE

template <typename T>
inline const char* ScriptFieldTypeName()
{
    T::using_unknown_script_type();
}

#define DECLARE_NAMED_FIELDTYPE(fieldType, strName) \
    template <>                                     \
    inline const char* ScriptFieldTypeName<fieldType>() { return strName; }
DECLARE_NAMED_FIELDTYPE(void, "void");
DECLARE_NAMED_FIELDTYPE(float, "float");
DECLARE_NAMED_FIELDTYPE(const char*, "cstring");
DECLARE_NAMED_FIELDTYPE(char*, "cstring");
DECLARE_NAMED_FIELDTYPE(Vector, "vector");
DECLARE_NAMED_FIELDTYPE(const Vector&, "vector");
DECLARE_NAMED_FIELDTYPE(int, "integer");
DECLARE_NAMED_FIELDTYPE(bool, "boolean");
DECLARE_NAMED_FIELDTYPE(char, "character");
DECLARE_NAMED_FIELDTYPE(HSCRIPT, "hscript");
DECLARE_NAMED_FIELDTYPE(ScriptVariant_t, "variant");

inline const char* ScriptFieldTypeName(int16_t eType)
{
    switch (eType) {
    case FIELD_VOID:
        return "void";
    case FIELD_FLOAT:
        return "float";
    case FIELD_CSTRING:
        return "cstring";
    case FIELD_VECTOR:
        return "vector";
    case FIELD_INTEGER:
        return "integer";
    case FIELD_BOOLEAN:
        return "boolean";
    case FIELD_CHARACTER:
        return "character";
    case FIELD_HSCRIPT:
        return "hscript";
    case FIELD_VARIANT:
        return "variant";
    default:
        return "unknown_script_type";
    }
}

struct ScriptFuncDescriptor_t {
    ScriptFuncDescriptor_t()
    {
        m_pszFunction = NULL;
        m_ReturnType = FIELD_TYPEUNKNOWN;
        m_pszDescription = NULL;
    }

    const char* m_pszScriptName;
    const char* m_pszFunction;
    const char* m_pszDescription;
    ScriptDataType_t m_ReturnType;
    CUtlVector<ScriptDataType_t> m_Parameters;
};

#define SCRIPT_HIDE "@"
#define SCRIPT_SINGLETON "!"
#define SCRIPT_ALIAS(alias, description) "#" alias ":" description

enum ScriptFuncBindingFlags_t {
    SF_MEMBER_FUNC = 0x01,
};

typedef bool (*ScriptBindingFunc_t)(void* pFunction, void* pContext, ScriptVariant_t* pArguments, int nArguments, ScriptVariant_t* pReturn);

struct ScriptFunctionBinding_t {
    ScriptFuncDescriptor_t m_desc;
    ScriptBindingFunc_t m_pfnBinding;
    void* m_pFunction;
    unsigned m_flags;
};

class IScriptInstanceHelper {
public:
    virtual void* GetProxied(void* p) { return p; }
    virtual bool ToString(void* p, char* pBuf, int bufSize) { return false; }
    virtual void* BindOnRead(HSCRIPT hInstance, void* pOld, const char* pszId) { return NULL; }
};

struct ScriptClassDesc_t {
    ScriptClassDesc_t()
        : m_pszScriptName(0)
        , m_pszClassname(0)
        , m_pszDescription(0)
        , m_pBaseDesc(0)
        , m_pfnConstruct(0)
        , m_pfnDestruct(0)
        , pHelper(NULL)
    {
    }

    const char* m_pszScriptName;
    const char* m_pszClassname;
    const char* m_pszDescription;
    ScriptClassDesc_t* m_pBaseDesc;
    CUtlVector<ScriptFunctionBinding_t> m_FunctionBindings;

    void* (*m_pfnConstruct)();
    void (*m_pfnDestruct)(void*);
    IScriptInstanceHelper* pHelper;
};

enum SVFlags_t {
    SV_FREE = 0x01,
};

struct ScriptVariant_t {
    ScriptVariant_t()
        : m_flags(0)
        , m_type(FIELD_VOID)
    {
        m_pVector = 0;
    }
    ScriptVariant_t(int val)
        : m_flags(0)
        , m_type(FIELD_INTEGER)
    {
        m_int = val;
    }
    ScriptVariant_t(float val)
        : m_flags(0)
        , m_type(FIELD_FLOAT)
    {
        m_float = val;
    }
    ScriptVariant_t(double val)
        : m_flags(0)
        , m_type(FIELD_FLOAT)
    {
        m_float = (float)val;
    }
    ScriptVariant_t(char val)
        : m_flags(0)
        , m_type(FIELD_CHARACTER)
    {
        m_char = val;
    }
    ScriptVariant_t(bool val)
        : m_flags(0)
        , m_type(FIELD_BOOLEAN)
    {
        m_bool = val;
    }
    ScriptVariant_t(HSCRIPT val)
        : m_flags(0)
        , m_type(FIELD_HSCRIPT)
    {
        m_hScript = val;
    }
    ScriptVariant_t(const Vector& val, bool bCopy = false)
        : m_flags(0)
        , m_type(FIELD_VECTOR)
    {
        if (!bCopy) {
            m_pVector = &val;
        }
        else {
            m_pVector = new Vector(val);
            m_flags |= SV_FREE;
        }
    }
    ScriptVariant_t(const Vector* val, bool bCopy = false)
        : m_flags(0)
        , m_type(FIELD_VECTOR)
    {
        if (!bCopy) {
            m_pVector = val;
        }
        else {
            m_pVector = new Vector(*val);
            m_flags |= SV_FREE;
        }
    }
    ScriptVariant_t(const char* val, bool bCopy = false)
        : m_flags(0)
        , m_type(FIELD_CSTRING)
    {
        if (!bCopy) {
            m_pszString = val;
        }
        else {
            m_pszString = strdup(val);
            m_flags |= SV_FREE;
        }
    }

    bool IsNull() const { return (m_type == FIELD_VOID); }

    operator int() const
    {
        Assert(m_type == FIELD_INTEGER);
        return m_int;
    }
    operator float() const
    {
        Assert(m_type == FIELD_FLOAT);
        return m_float;
    }
    operator const char* () const
    {
        Assert(m_type == FIELD_CSTRING);
        return (m_pszString) ? m_pszString : "";
    }
    operator const Vector& () const
    {
        Assert(m_type == FIELD_VECTOR);
        static Vector vecNull = { 0, 0, 0 };
        return (m_pVector) ? *m_pVector : vecNull;
    }
    operator char() const
    {
        Assert(m_type == FIELD_CHARACTER);
        return m_char;
    }
    operator bool() const
    {
        Assert(m_type == FIELD_BOOLEAN);
        return m_bool;
    }
    operator HSCRIPT() const
    {
        Assert(m_type == FIELD_HSCRIPT);
        return m_hScript;
    }

    void operator=(int i)
    {
        m_type = FIELD_INTEGER;
        m_int = i;
    }
    void operator=(float f)
    {
        m_type = FIELD_FLOAT;
        m_float = f;
    }
    void operator=(double f)
    {
        m_type = FIELD_FLOAT;
        m_float = (float)f;
    }
    void operator=(const Vector& vec)
    {
        m_type = FIELD_VECTOR;
        m_pVector = &vec;
    }
    void operator=(const Vector* vec)
    {
        m_type = FIELD_VECTOR;
        m_pVector = vec;
    }
    void operator=(const char* psz)
    {
        m_type = FIELD_CSTRING;
        m_pszString = psz;
    }
    void operator=(char c)
    {
        m_type = FIELD_CHARACTER;
        m_char = c;
    }
    void operator=(bool b)
    {
        m_type = FIELD_BOOLEAN;
        m_bool = b;
    }
    void operator=(HSCRIPT h)
    {
        m_type = FIELD_HSCRIPT;
        m_hScript = h;
    }
    void Free()
    {
        if ((m_flags & SV_FREE) && (m_type == FIELD_HSCRIPT || m_type == FIELD_VECTOR || m_type == FIELD_CSTRING))
            delete m_pszString;
    }
    template <typename T>
    T Get()
    {
        T value;
        AssignTo(&value);
        return value;
    }
    template <typename T>
    bool AssignTo(T* pDest)
    {
        ScriptDataType_t destType = ScriptDeduceType(T);
        if (destType == FIELD_TYPEUNKNOWN) {
            //DevWarning("Unable to convert script variant to unknown type\n");
        }
        if (destType == m_type) {
            *pDest = *this;
            return true;
        }

        if (m_type != FIELD_VECTOR && m_type != FIELD_CSTRING && destType != FIELD_VECTOR && destType != FIELD_CSTRING) {
            switch (m_type) {
            case FIELD_VOID:
                *pDest = 0;
                break;
            case FIELD_INTEGER:
                *pDest = m_int;
                return true;
            case FIELD_FLOAT:
                *pDest = m_float;
                return true;
            case FIELD_CHARACTER:
                *pDest = m_char;
                return true;
            case FIELD_BOOLEAN:
                *pDest = m_bool;
                return true;
            case FIELD_HSCRIPT:
                *pDest = m_hScript;
                return true;
            }
        }
        else {
            /* DevWarning("No free conversion of %s script variant to %s right now\n",
                ScriptFieldTypeName(m_type), ScriptFieldTypeName<T>()); */
            if (destType != FIELD_VECTOR) {
                *pDest = 0;
            }
        }
        return false;
    }

    bool AssignTo(float* pDest)
    {
        switch (m_type) {
        case FIELD_VOID:
            *pDest = 0;
            return false;
        case FIELD_INTEGER:
            *pDest = (float)m_int;
            return true;
        case FIELD_FLOAT:
            *pDest = m_float;
            return true;
        case FIELD_BOOLEAN:
            *pDest = m_bool;
            return true;
        default:
            //DevWarning("No conversion from %s to float now\n", ScriptFieldTypeName(m_type));
            return false;
        }
    }
    bool AssignTo(int* pDest)
    {
        switch (m_type) {
        case FIELD_VOID:
            *pDest = 0;
            return false;
        case FIELD_INTEGER:
            *pDest = m_int;
            return true;
        case FIELD_FLOAT:
            *pDest = (int)m_float;
            return true;
        case FIELD_BOOLEAN:
            *pDest = m_bool;
            return true;
        default:
            //DevWarning("No conversion from %s to int now\n", ScriptFieldTypeName(m_type));
            return false;
        }
    }
    bool AssignTo(bool* pDest)
    {
        switch (m_type) {
        case FIELD_VOID:
            *pDest = 0;
            return false;
        case FIELD_INTEGER:
            *pDest = m_int;
            return true;
        case FIELD_FLOAT:
            *pDest = m_float;
            return true;
        case FIELD_BOOLEAN:
            *pDest = m_bool;
            return true;
        default:
            //DevWarning("No conversion from %s to bool now\n", ScriptFieldTypeName(m_type));
            return false;
        }
    }
    bool AssignTo(char** pDest)
    {
        //DevWarning("No free conversion of string or vector script variant right now\n");
        *pDest = (char*)"";
        return false;
    }
    bool AssignTo(ScriptVariant_t* pDest)
    {
        pDest->m_type = m_type;
        if (m_type == FIELD_VECTOR) {
            pDest->m_pVector = new Vector;
            *((Vector*)(pDest->m_pVector)) = Vector{ m_pVector->x, m_pVector->y, m_pVector->z };
            pDest->m_flags |= SV_FREE;
        }
        else if (m_type == FIELD_CSTRING) {
            pDest->m_pszString = strdup(m_pszString);
            pDest->m_flags |= SV_FREE;
        }
        else {
            pDest->m_int = m_int;
        }
        return false;
    }

    union {
        int m_int;
        float m_float;
        const char* m_pszString;
        const Vector* m_pVector;
        char m_char;
        bool m_bool;
        HSCRIPT m_hScript;
    };

    int16_t m_type;
    int16_t m_flags;

private:
};

#define SCRIPT_VARIANT_NULL ScriptVariant_t()

#define FUNC_APPEND_PARAMS_0
#define FUNC_APPEND_PARAMS_1               \
    pDesc->m_Parameters.SetGrowSize(1);    \
    pDesc->m_Parameters.EnsureCapacity(1); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1));
#define FUNC_APPEND_PARAMS_2                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(2);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2));
#define FUNC_APPEND_PARAMS_3                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(3);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3));
#define FUNC_APPEND_PARAMS_4                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(4);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4));
#define FUNC_APPEND_PARAMS_5                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(5);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5));
#define FUNC_APPEND_PARAMS_6                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(6);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6));
#define FUNC_APPEND_PARAMS_7                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(7);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7));
#define FUNC_APPEND_PARAMS_8                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(8);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8));
#define FUNC_APPEND_PARAMS_9                                          \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(9);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9));
#define FUNC_APPEND_PARAMS_10                                         \
    pDesc->m_Parameters.SetGrowSize(1);                               \
    pDesc->m_Parameters.EnsureCapacity(10);                           \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_10));
#define FUNC_APPEND_PARAMS_11                                          \
    pDesc->m_Parameters.SetGrowSize(1);                                \
    pDesc->m_Parameters.EnsureCapacity(11);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_10)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_11));
#define FUNC_APPEND_PARAMS_12                                          \
    pDesc->m_Parameters.SetGrowSize(1);                                \
    pDesc->m_Parameters.EnsureCapacity(12);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_10)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_11)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_12));
#define FUNC_APPEND_PARAMS_13                                          \
    pDesc->m_Parameters.SetGrowSize(1);                                \
    pDesc->m_Parameters.EnsureCapacity(13);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_10)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_11)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_12)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_13));
#define FUNC_APPEND_PARAMS_14                                          \
    pDesc->m_Parameters.SetGrowSize(1);                                \
    pDesc->m_Parameters.EnsureCapacity(14);                            \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_1));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_2));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_3));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_4));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_5));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_6));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_7));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_8));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_9));  \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_10)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_11)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_12)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_13)); \
    pDesc->m_Parameters.AddToTail(ScriptDeduceType(FUNC_ARG_TYPE_14));

#define DEFINE_NONMEMBER_FUNC_TYPE_DEDUCER(N)                                                                                                    \
    template <typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                           \
    inline void ScriptDeduceFunctionSignature(ScriptFuncDescriptor_t* pDesc, FUNCTION_RETTYPE (*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N)) \
    {                                                                                                                                            \
        pDesc->m_ReturnType = ScriptDeduceType(FUNCTION_RETTYPE);                                                                                \
        FUNC_APPEND_PARAMS_##N                                                                                                                   \
    }

FUNC_GENERATE_ALL(DEFINE_NONMEMBER_FUNC_TYPE_DEDUCER);

#define DEFINE_MEMBER_FUNC_TYPE_DEDUCER(N)                                                                                                                                                \
    template <typename OBJECT_TYPE_PTR, typename FUNCTION_CLASS, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                 \
    inline void ScriptDeduceFunctionSignature(ScriptFuncDescriptor_t* pDesc, OBJECT_TYPE_PTR pObject, FUNCTION_RETTYPE (FUNCTION_CLASS::*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N)) \
    {                                                                                                                                                                                     \
        pDesc->m_ReturnType = ScriptDeduceType(FUNCTION_RETTYPE);                                                                                                                         \
        FUNC_APPEND_PARAMS_##N                                                                                                                                                            \
    }

FUNC_GENERATE_ALL(DEFINE_MEMBER_FUNC_TYPE_DEDUCER);

#define DEFINE_CONST_MEMBER_FUNC_TYPE_DEDUCER(N)                                                                                                                                                \
    template <typename OBJECT_TYPE_PTR, typename FUNCTION_CLASS, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                       \
    inline void ScriptDeduceFunctionSignature(ScriptFuncDescriptor_t* pDesc, OBJECT_TYPE_PTR pObject, FUNCTION_RETTYPE (FUNCTION_CLASS::*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N) const) \
    {                                                                                                                                                                                           \
        pDesc->m_ReturnType = ScriptDeduceType(FUNCTION_RETTYPE);                                                                                                                               \
        FUNC_APPEND_PARAMS_##N                                                                                                                                                                  \
    }

FUNC_GENERATE_ALL(DEFINE_CONST_MEMBER_FUNC_TYPE_DEDUCER);

#define ScriptInitMemberFuncDescriptor_(pDesc, class, func, scriptName)   \
    if (0) {                                                              \
    } else {                                                              \
        (pDesc)->m_pszScriptName = scriptName;                            \
        (pDesc)->m_pszFunction = #func;                                   \
        ScriptDeduceFunctionSignature(pDesc, (class*)(0), &class ::func); \
    }

#define ScriptInitFuncDescriptorNamed(pDesc, func, scriptName) \
    if (0) {                                                   \
    } else {                                                   \
        (pDesc)->m_pszScriptName = scriptName;                 \
        (pDesc)->m_pszFunction = #func;                        \
        ScriptDeduceFunctionSignature(pDesc, &func);           \
    }
#define ScriptInitFuncDescriptor(pDesc, func) ScriptInitFuncDescriptorNamed(pDesc, func, #func)
#define ScriptInitMemberFuncDescriptorNamed(pDesc, class, func, scriptName) ScriptInitMemberFuncDescriptor_(pDesc, class, func, scriptName)
#define ScriptInitMemberFuncDescriptor(pDesc, class, func) ScriptInitMemberFuncDescriptorNamed(pDesc, class, func, #func)

template <typename FUNCPTR_TYPE>
inline void* ScriptConvertFuncPtrToVoid(FUNCPTR_TYPE pFunc)
{
#ifndef _WIN32
    static_assert(sizeof (FUNCPTR_TYPE) == sizeof (void*) * 2 || sizeof (FUNCPTR_TYPE) == sizeof (void*));
    if (sizeof (FUNCPTR_TYPE) == 4) {
        union {
            FUNCPTR_TYPE pFunc;
            void *v;
        } u = { pFunc };
        return u.v;
    } else {
        union {
            FUNCPTR_TYPE pFunc;
            struct {
                void *v;
                int32_t iToc;
            } fn8;
        } u = { pFunc };
        if (!u.fn8.iToc) return u.fn8.v;
        Assert(0);
    }
#endif

    if ((sizeof(FUNCPTR_TYPE) == sizeof(void*))) {
        union FuncPtrConvert {
            void* p;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvert convert;
        convert.pFunc = pFunc;
        return convert.p;
    }
#if MSVC
    else if ((sizeof(FUNCPTR_TYPE) == sizeof(void*) + sizeof(int))) {
        struct MicrosoftUnknownMFP {
            void* p;
            int m_delta;
        };

        union FuncPtrConvertMI {
            MicrosoftUnknownMFP mfp;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvertMI convert;
        convert.pFunc = pFunc;
        if (convert.mfp.m_delta == 0) {
            return convert.mfp.p;
        }
        AssertMsg(0, "Function pointer must be from primary vtable");
    }
    else if ((sizeof(FUNCPTR_TYPE) == sizeof(void*) + (sizeof(int) * 3))) {
        struct MicrosoftUnknownMFP {
            void* p;
            int m_delta;
            int m_vtordisp;
            int m_vtable_index;
        };

        union FuncPtrConvertMI {
            MicrosoftUnknownMFP mfp;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvertMI convert;
        convert.pFunc = pFunc;
        if (convert.mfp.m_delta == 0) {
            return convert.mfp.p;
        }
        AssertMsg(0, "Function pointer must be from primary vtable");
    }
#elif defined(GNUC)
    else if ((sizeof(FUNCPTR_TYPE) == sizeof(void*) + sizeof(int))) {
        AssertMsg(0, "Note: This path has not been verified yet. See comments below in #else case.");

        struct GnuMFP {
            union {
                void* funcadr;
                int vtable_index_2;
            };
            int delta;
        };

        GnuMFP* p = (GnuMFP*)&pFunc;
        if (p->vtable_index_2 & 1) {
            char** delta = (char**)p->delta;
            char* pCur = *delta + (p->vtable_index_2 + 1) / 2;
            return (void*)(pCur + 4);
        }
        else {
            return p->funcadr;
        }
    }
#endif
    else
        AssertMsg(0, "Member function pointer not supported. Why on earth are you using virtual inheritance!?");
    return NULL;
}

template <typename FUNCPTR_TYPE>
inline FUNCPTR_TYPE ScriptConvertFuncPtrFromVoid(void* p)
{
#ifndef _WIN32
    static_assert(sizeof (FUNCPTR_TYPE) == sizeof (void*) * 2 || sizeof (FUNCPTR_TYPE) == sizeof (void*));
    if (sizeof (FUNCPTR_TYPE) == 4) {
        union {
            void *v;
            FUNCPTR_TYPE pFunc;
        } u = { p };
        return u.pFunc;
    } else {
        union {
            struct {
                void *v;
                int32_t iToc;
            } fn8;
            FUNCPTR_TYPE pFunc;
        } u;
        u.pFunc = 0;
        u.fn8.v = p;
        u.fn8.iToc = 0;
        return u.pFunc;
    }
#endif
    if ((sizeof(FUNCPTR_TYPE) == sizeof(void*))) {
        union FuncPtrConvert {
            void* p;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvert convert;
        convert.p = p;
        return convert.pFunc;
    }

#if MSVC
    if ((sizeof(FUNCPTR_TYPE) == sizeof(void*) + sizeof(int))) {
        struct MicrosoftUnknownMFP {
            void* p;
            int m_delta;
        };

        union FuncPtrConvertMI {
            MicrosoftUnknownMFP mfp;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvertMI convert;
        convert.mfp.p = p;
        convert.mfp.m_delta = 0;
        return convert.pFunc;
    }
    if ((sizeof(FUNCPTR_TYPE) == sizeof(void*) + (sizeof(int) * 3))) {
        struct MicrosoftUnknownMFP {
            void* p;
            int m_delta;
            int m_vtordisp;
            int m_vtable_index;
        };

        union FuncPtrConvertMI {
            MicrosoftUnknownMFP mfp;
            FUNCPTR_TYPE pFunc;
        };

        FuncPtrConvertMI convert;
        convert.mfp.p = p;
        convert.mfp.m_delta = 0;
        return convert.pFunc;
    }
#elif defined(POSIX)
    AssertMsg(0, "Note: This path has not been implemented yet.");
#endif
    Assert(0);
    return NULL;
}

#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_0
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_1 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_1
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_2 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_2
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_3 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_3
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_4 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_4
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_5 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_5
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_6 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_6
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_7 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_7
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_8 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_8
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_9 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_9
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_10 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_10
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_11 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_11
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_12 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_12
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_13 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_13
#define FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_14 , FUNC_BASE_TEMPLATE_FUNC_PARAMS_14

#define SCRIPT_BINDING_ARGS_0
#define SCRIPT_BINDING_ARGS_1 pArguments[0]
#define SCRIPT_BINDING_ARGS_2 pArguments[0], pArguments[1]
#define SCRIPT_BINDING_ARGS_3 pArguments[0], pArguments[1], pArguments[2]
#define SCRIPT_BINDING_ARGS_4 pArguments[0], pArguments[1], pArguments[2], pArguments[3]
#define SCRIPT_BINDING_ARGS_5 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4]
#define SCRIPT_BINDING_ARGS_6 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5]
#define SCRIPT_BINDING_ARGS_7 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6]
#define SCRIPT_BINDING_ARGS_8 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7]
#define SCRIPT_BINDING_ARGS_9 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8]
#define SCRIPT_BINDING_ARGS_10 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8], pArguments[9]
#define SCRIPT_BINDING_ARGS_11 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8], pArguments[9], pArguments[10]
#define SCRIPT_BINDING_ARGS_12 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8], pArguments[9], pArguments[10], pArguments[11]
#define SCRIPT_BINDING_ARGS_13 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8], pArguments[9], pArguments[10], pArguments[11], pArguments[12]
#define SCRIPT_BINDING_ARGS_14 pArguments[0], pArguments[1], pArguments[2], pArguments[3], pArguments[4], pArguments[5], pArguments[6], pArguments[7], pArguments[8], pArguments[9], pArguments[10], pArguments[11], pArguments[12], pArguments[13]

#define DEFINE_SCRIPT_BINDINGS(N)                                                                                                                                     \
    template <typename FUNC_TYPE, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                            \
    class CNonMemberScriptBinding##N {                                                                                                                                \
    public:                                                                                                                                                           \
        static bool Call(void* pFunction, void* pContext, ScriptVariant_t* pArguments, int nArguments, ScriptVariant_t* pReturn)                                      \
        {                                                                                                                                                             \
            Assert(nArguments == N);                                                                                                                                  \
            Assert(pReturn);                                                                                                                                          \
            Assert(!pContext);                                                                                                                                        \
                                                                                                                                                                      \
            if (nArguments != N || !pReturn || pContext) {                                                                                                            \
                return false;                                                                                                                                         \
            }                                                                                                                                                         \
            *pReturn = ((FUNC_TYPE)pFunction)(SCRIPT_BINDING_ARGS_##N);                                                                                               \
            if (pReturn->m_type == FIELD_VECTOR)                                                                                                                      \
                pReturn->m_pVector = new Vector(*pReturn->m_pVector);                                                                                                 \
            return true;                                                                                                                                              \
        }                                                                                                                                                             \
    };                                                                                                                                                                \
                                                                                                                                                                      \
    template <typename FUNC_TYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                                                       \
    class CNonMemberScriptBinding##N<FUNC_TYPE, void FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_##N> {                                                                   \
    public:                                                                                                                                                           \
        static bool Call(void* pFunction, void* pContext, ScriptVariant_t* pArguments, int nArguments, ScriptVariant_t* pReturn)                                      \
        {                                                                                                                                                             \
            Assert(nArguments == N);                                                                                                                                  \
            Assert(!pReturn);                                                                                                                                         \
            Assert(!pContext);                                                                                                                                        \
                                                                                                                                                                      \
            if (nArguments != N || pReturn || pContext) {                                                                                                             \
                return false;                                                                                                                                         \
            }                                                                                                                                                         \
            ((FUNC_TYPE)pFunction)(SCRIPT_BINDING_ARGS_##N);                                                                                                          \
            return true;                                                                                                                                              \
        }                                                                                                                                                             \
    };                                                                                                                                                                \
                                                                                                                                                                      \
    template <class OBJECT_TYPE_PTR, typename FUNC_TYPE, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                     \
    class CMemberScriptBinding##N {                                                                                                                                   \
    public:                                                                                                                                                           \
        static bool Call(void* pFunction, void* pContext, ScriptVariant_t* pArguments, int nArguments, ScriptVariant_t* pReturn)                                      \
        {                                                                                                                                                             \
            Assert(nArguments == N);                                                                                                                                  \
            Assert(pReturn);                                                                                                                                          \
            Assert(pContext);                                                                                                                                         \
                                                                                                                                                                      \
            if (nArguments != N || !pReturn || !pContext) {                                                                                                           \
                return false;                                                                                                                                         \
            }                                                                                                                                                         \
            *pReturn = (((OBJECT_TYPE_PTR)(pContext))->*ScriptConvertFuncPtrFromVoid<FUNC_TYPE>(pFunction))(SCRIPT_BINDING_ARGS_##N);                                 \
            if (pReturn->m_type == FIELD_VECTOR)                                                                                                                      \
                pReturn->m_pVector = new Vector(*pReturn->m_pVector);                                                                                                 \
            return true;                                                                                                                                              \
        }                                                                                                                                                             \
    };                                                                                                                                                                \
                                                                                                                                                                      \
    template <class OBJECT_TYPE_PTR, typename FUNC_TYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                                \
    class CMemberScriptBinding##N<OBJECT_TYPE_PTR, FUNC_TYPE, void FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_##N> {                                                     \
    public:                                                                                                                                                           \
        static bool Call(void* pFunction, void* pContext, ScriptVariant_t* pArguments, int nArguments, ScriptVariant_t* pReturn)                                      \
        {                                                                                                                                                             \
            Assert(nArguments == N);                                                                                                                                  \
            Assert(!pReturn);                                                                                                                                         \
            Assert(pContext);                                                                                                                                         \
                                                                                                                                                                      \
            if (nArguments != N || pReturn || !pContext) {                                                                                                            \
                return false;                                                                                                                                         \
            }                                                                                                                                                         \
            (((OBJECT_TYPE_PTR)(pContext))->*ScriptConvertFuncPtrFromVoid<FUNC_TYPE>(pFunction))(SCRIPT_BINDING_ARGS_##N);                                            \
            return true;                                                                                                                                              \
        }                                                                                                                                                             \
    };                                                                                                                                                                \
                                                                                                                                                                      \
    template <typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                                                                                \
    inline ScriptBindingFunc_t ScriptCreateBinding(FUNCTION_RETTYPE (*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N))                                                \
    {                                                                                                                                                                 \
        typedef FUNCTION_RETTYPE (*Func_t)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N);                                                                                       \
        return &CNonMemberScriptBinding##N<Func_t, FUNCTION_RETTYPE FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_##N>::Call;                                               \
    }                                                                                                                                                                 \
                                                                                                                                                                      \
    template <typename OBJECT_TYPE_PTR, typename FUNCTION_CLASS, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                             \
    inline ScriptBindingFunc_t ScriptCreateBinding(OBJECT_TYPE_PTR pObject, FUNCTION_RETTYPE (FUNCTION_CLASS::*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N))       \
    {                                                                                                                                                                 \
        typedef FUNCTION_RETTYPE (FUNCTION_CLASS::*Func_t)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N);                                                                       \
        return &CMemberScriptBinding##N<OBJECT_TYPE_PTR, Func_t, FUNCTION_RETTYPE FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_##N>::Call;                                 \
    }                                                                                                                                                                 \
                                                                                                                                                                      \
    template <typename OBJECT_TYPE_PTR, typename FUNCTION_CLASS, typename FUNCTION_RETTYPE FUNC_TEMPLATE_FUNC_PARAMS_##N>                                             \
    inline ScriptBindingFunc_t ScriptCreateBinding(OBJECT_TYPE_PTR pObject, FUNCTION_RETTYPE (FUNCTION_CLASS::*pfnProxied)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N) const) \
    {                                                                                                                                                                 \
        typedef FUNCTION_RETTYPE (FUNCTION_CLASS::*Func_t)(FUNC_BASE_TEMPLATE_FUNC_PARAMS_##N);                                                                       \
        return &CMemberScriptBinding##N<OBJECT_TYPE_PTR, Func_t, FUNCTION_RETTYPE FUNC_BASE_TEMPLATE_FUNC_PARAMS_PASSTHRU_##N>::Call;                                 \
    }

FUNC_GENERATE_ALL(DEFINE_SCRIPT_BINDINGS);

#define ScriptInitFunctionBinding(pScriptFunction, func) ScriptInitFunctionBindingNamed(pScriptFunction, func, #func)
#define ScriptInitFunctionBindingNamed(pScriptFunction, func, scriptName)              \
    do {                                                                               \
        ScriptInitFuncDescriptorNamed((&(pScriptFunction)->m_desc), func, scriptName); \
        (pScriptFunction)->m_pfnBinding = ScriptCreateBinding(&func);                  \
        (pScriptFunction)->m_pFunction = (void*)&func;                                 \
    } while (0)

#define ScriptInitMemberFunctionBinding(pScriptFunction, class, func) ScriptInitMemberFunctionBinding_(pScriptFunction, class, func, #func)
#define ScriptInitMemberFunctionBindingNamed(pScriptFunction, class, func, scriptName) ScriptInitMemberFunctionBinding_(pScriptFunction, class, func, scriptName)
#define ScriptInitMemberFunctionBinding_(pScriptFunction, class, func, scriptName)              \
    do {                                                                                        \
        ScriptInitMemberFuncDescriptor_((&(pScriptFunction)->m_desc), class, func, scriptName); \
        (pScriptFunction)->m_pfnBinding = ScriptCreateBinding(((class*)0), &class ::func);      \
        (pScriptFunction)->m_pFunction = ScriptConvertFuncPtrToVoid(&class ::func);             \
        (pScriptFunction)->m_flags = SF_MEMBER_FUNC;                                            \
    } while (0)

#define ScriptInitClassDesc(pClassDesc, class, pBaseClassDesc) ScriptInitClassDescNamed(pClassDesc, class, pBaseClassDesc, #class)
#define ScriptInitClassDescNamed(pClassDesc, class, pBaseClassDesc, scriptName) ScriptInitClassDescNamed_(pClassDesc, class, pBaseClassDesc, scriptName)
#define ScriptInitClassDescNoBase(pClassDesc, class) ScriptInitClassDescNoBaseNamed(pClassDesc, class, #class)
#define ScriptInitClassDescNoBaseNamed(pClassDesc, class, scriptName) ScriptInitClassDescNamed_(pClassDesc, class, NULL, scriptName)
#define ScriptInitClassDescNamed_(pClassDesc, class, pBaseClassDesc, scriptName) \
    do {                                                                         \
        (pClassDesc)->m_pszScriptName = scriptName;                              \
        (pClassDesc)->m_pszClassname = #class;                                   \
        (pClassDesc)->m_pBaseDesc = pBaseClassDesc;                              \
    } while (0)

#define ScriptAddFunctionToClassDesc(pClassDesc, class, func, description) ScriptAddFunctionToClassDescNamed(pClassDesc, class, func, #func, description)
#define ScriptAddFunctionToClassDescNamed(pClassDesc, class, func, scriptName, description)                                    \
    do {                                                                                                                       \
        ScriptFunctionBinding_t* pBinding = &((pClassDesc)->m_FunctionBindings[(pClassDesc)->m_FunctionBindings.AddToTail()]); \
        pBinding->m_desc.m_pszDescription = description;                                                                       \
        ScriptInitMemberFunctionBindingNamed(pBinding, class, func, scriptName);                                               \
    } while (0)

#define ScriptRegisterFunction(pVM, func, description) ScriptRegisterFunctionNamed(pVM, func, #func, description)
#define ScriptRegisterFunctionNamed(pVM, func, scriptName, description) \
    do {                                                                \
        static ScriptFunctionBinding_t binding;                         \
        binding.m_desc.m_pszDescription = description;                  \
        binding.m_desc.m_Parameters.RemoveAll();                        \
        ScriptInitFunctionBindingNamed(&binding, func, scriptName);     \
        pVM->RegisterFunction(&binding);                                \
    } while (0)

#define ALLOW_SCRIPT_ACCESS() template <typename T> \
friend ScriptClassDesc_t* GetScriptDesc(T*);

#define BEGIN_SCRIPTDESC(className, baseClass, description) BEGIN_SCRIPTDESC_NAMED(className, baseClass, #className, description)
#define BEGIN_SCRIPTDESC_ROOT(className, description) BEGIN_SCRIPTDESC_ROOT_NAMED(className, #className, description)

#if defined(MSVC) && _MSC_VER < 1900
#define DEFINE_SCRIPTDESC_FUNCTION(className, baseClass) \
    ScriptClassDesc_t* GetScriptDesc(className*)
#else
#define DEFINE_SCRIPTDESC_FUNCTION(className, baseClass)     \
    template <>                                              \
    ScriptClassDesc_t* GetScriptDesc<baseClass>(baseClass*); \
    template <>                                              \
    ScriptClassDesc_t* GetScriptDesc<className>(className*)
#endif

#define BEGIN_SCRIPTDESC_NAMED(className, baseClass, scriptName, description)                     \
    ScriptClassDesc_t g_##className##_ScriptDesc;                                                 \
    DEFINE_SCRIPTDESC_FUNCTION(className, baseClass)                                              \
    {                                                                                             \
        static bool bInitialized;                                                                 \
        if (bInitialized) {                                                                       \
            return &g_##className##_ScriptDesc;                                                   \
        }                                                                                         \
                                                                                                  \
        bInitialized = true;                                                                      \
                                                                                                  \
        typedef className _className;                                                             \
        ScriptClassDesc_t* pDesc = &g_##className##_ScriptDesc;                                   \
        pDesc->m_pszDescription = description;                                                    \
        ScriptInitClassDescNamed(pDesc, className, GetScriptDescForClass(baseClass), scriptName); \
        ScriptClassDesc_t* pInstanceHelperBase = pDesc->m_pBaseDesc;                              \
        while (pInstanceHelperBase) {                                                             \
            if (pInstanceHelperBase->pHelper) {                                                   \
                pDesc->pHelper = pInstanceHelperBase->pHelper;                                    \
                break;                                                                            \
            }                                                                                     \
            pInstanceHelperBase = pInstanceHelperBase->m_pBaseDesc;                               \
        }

#define BEGIN_SCRIPTDESC_ROOT_NAMED(className, scriptName, description) \
    BEGIN_SCRIPTDESC_NAMED(className, ScriptNoBase_t, scriptName, description)

#define END_SCRIPTDESC() \
    return pDesc;        \
    }

#define DEFINE_SCRIPTFUNC(func, description) DEFINE_SCRIPTFUNC_NAMED(func, #func, description)
#define DEFINE_SCRIPTFUNC_NAMED(func, scriptName, description) ScriptAddFunctionToClassDescNamed(pDesc, _className, func, scriptName, description);
#define DEFINE_SCRIPT_CONSTRUCTOR() ScriptAddConstructorToClassDesc(pDesc, _className);
#define DEFINE_SCRIPT_INSTANCE_HELPER(p) pDesc->pHelper = (p);

template <typename T>
ScriptClassDesc_t* GetScriptDesc(T*);

struct ScriptNoBase_t;
template <>
inline ScriptClassDesc_t* GetScriptDesc<ScriptNoBase_t>(ScriptNoBase_t*) { return NULL; }

#define GetScriptDescForClass(className) GetScriptDesc((className*)NULL)

template <typename T>
class CScriptConstructor {
public:
    static void* Construct() { return new T; }
    static void Destruct(void* p) { delete (T*)p; }
};

#define ScriptAddConstructorToClassDesc(pClassDesc, class)                    \
    do {                                                                      \
        (pClassDesc)->m_pfnConstruct = &CScriptConstructor<class>::Construct; \
        (pClassDesc)->m_pfnDestruct = &CScriptConstructor<class>::Destruct;   \
    } while (0)

enum ScriptErrorLevel_t {
    SCRIPT_LEVEL_WARNING = 0,
    SCRIPT_LEVEL_ERROR,
};

typedef void (*ScriptOutputFunc_t)(const char* pszText);
typedef bool (*ScriptErrorFunc_t)(ScriptErrorLevel_t eLevel, const char* pszText);

#ifdef RegisterClass
#undef RegisterClass
#endif

enum ScriptStatus_t {
    SCRIPT_ERROR = -1,
    SCRIPT_DONE,
    SCRIPT_RUNNING,
};

class CUtlBuffer;

class IScriptVM {
public:
    virtual bool Init() = 0; // 0
    virtual void Shutdown() = 0; // 1
    virtual bool ConnectDebugger() = 0; // 2
    virtual void DisconnectDebugger() = 0; // 3
    virtual ScriptLanguage_t GetLanguage() = 0; // 4
    virtual const char* GetLanguageName() = 0; // 5
    virtual void AddSearchPath(const char* pszSearchPath) = 0; // 6
    virtual bool Frame(float simTime) = 0; // 7
#ifdef _WIN32
    virtual ScriptStatus_t Run(HSCRIPT hScript, HSCRIPT hScope = NULL, bool bWait = true) = 0; // 8
    virtual ScriptStatus_t Run(HSCRIPT hScript, bool bWait) = 0; // 9
    virtual ScriptStatus_t Run(const char* pszScript, bool bWait = true) = 0; // 10
    inline ScriptStatus_t Run(const unsigned char* pszScript, bool bWait = true) { return Run((char*)pszScript, bWait); }
    virtual HSCRIPT CompileScript(const char* pszScript, const char* pszId = NULL) = 0; // 11
    inline HSCRIPT CompileScript(const unsigned char* pszScript, const char* pszId = NULL) { return CompileScript((char*)pszScript, pszId); }
    virtual void ReleaseScript(HSCRIPT) = 0; // 12
#else
    virtual ScriptStatus_t Run(const char* pszScript, bool bWait = true) = 0; // 8
    inline ScriptStatus_t Run(const unsigned char* pszScript, bool bWait = true) { return Run((char*)pszScript, bWait); }
    virtual HSCRIPT CompileScript(const char* pszScript, const char* pszId = NULL) = 0; // 9
    inline HSCRIPT CompileScript(const unsigned char* pszScript, const char* pszId = NULL) { return CompileScript((char*)pszScript, pszId); }
    virtual void ReleaseScript(HSCRIPT) = 0; // 10
    virtual ScriptStatus_t Run(HSCRIPT hScript, HSCRIPT hScope = NULL, bool bWait = true) = 0; // 11
    virtual ScriptStatus_t Run(HSCRIPT hScript, bool bWait) = 0; // 12
#endif
    virtual HSCRIPT CreateScope(const char* pszScope, HSCRIPT hParent = NULL) = 0; // 13
    virtual void ReleaseScope(HSCRIPT hScript) = 0; // 14
    virtual HSCRIPT LookupFunction(const char* pszFunction, HSCRIPT hScope = NULL) = 0; // 15
    virtual void ReleaseFunction(HSCRIPT hScript) = 0; // 16
    virtual ScriptStatus_t ExecuteFunction(HSCRIPT hFunction, ScriptVariant_t* pArgs, int nArgs, ScriptVariant_t* pReturn, HSCRIPT hScope, bool bWait) = 0; // 17
    virtual void RegisterFunction(ScriptFunctionBinding_t* pScriptFunction) = 0; // 18
    virtual bool RegisterClass(ScriptClassDesc_t* pClassDesc) = 0; // 19
    virtual HSCRIPT RegisterInstance(ScriptClassDesc_t* pDesc, void* pInstance) = 0; // 20
    virtual void SetInstanceUniqeId(HSCRIPT hInstance, const char* pszId) = 0; // 21
    template <typename T>
    HSCRIPT RegisterInstance(T* pInstance) { return RegisterInstance(GetScriptDesc(pInstance), pInstance); }
    template <typename T>
    HSCRIPT RegisterInstance(T* pInstance, const char* pszInstance, HSCRIPT hScope = NULL)
    {
        HSCRIPT hInstance = RegisterInstance(GetScriptDesc(pInstance), pInstance);
        SetValue(hScope, pszInstance, hInstance);
        return hInstance;
    }
    virtual void RemoveInstance(HSCRIPT) = 0; // 22
    void RemoveInstance(HSCRIPT hInstance, const char* pszInstance, HSCRIPT hScope = NULL)
    {
        ClearValue(hScope, pszInstance);
        RemoveInstance(hInstance);
    }
    void RemoveInstance(const char* pszInstance, HSCRIPT hScope = NULL)
    {
        ScriptVariant_t val;
        if (GetValue(hScope, pszInstance, &val)) {
            if (val.m_type == FIELD_HSCRIPT) {
                RemoveInstance(val, pszInstance, hScope);
            }
            ReleaseValue(val);
        }
    }
    virtual void* GetInstanceValue(HSCRIPT hInstance, ScriptClassDesc_t* pExpectedType = NULL) = 0; // 23
    virtual bool GenerateUniqueKey(const char* pszRoot, char* pBuf, int nBufSize) = 0; // 24
    virtual bool ValueExists(HSCRIPT hScope, const char* pszKey) = 0; // 25
    bool ValueExists(const char* pszKey) { return ValueExists(NULL, pszKey); }
    virtual bool SetValue(HSCRIPT hScope, const char* pszKey, const char* pszValue) = 0; // 26
    virtual bool SetValue(HSCRIPT hScope, const char* pszKey, const ScriptVariant_t& value) = 0; // 27
    bool SetValue(const char* pszKey, const ScriptVariant_t& value) { return SetValue(NULL, pszKey, value); }
    virtual void CreateTable(ScriptVariant_t& Table) = 0; // 28
    virtual int GetNumTableEntries(HSCRIPT hScope) = 0; // 29
    virtual int GetKeyValue(HSCRIPT hScope, int nIterator, ScriptVariant_t* pKey, ScriptVariant_t* pValue) = 0; // 30
    virtual bool GetValue(HSCRIPT hScope, const char* pszKey, ScriptVariant_t* pValue) = 0; // 31
    bool GetValue(const char* pszKey, ScriptVariant_t* pValue) { return GetValue(NULL, pszKey, pValue); }
    virtual void ReleaseValue(ScriptVariant_t& value) = 0; // 32
    virtual bool ClearValue(HSCRIPT hScope, const char* pszKey) = 0; // 33
    bool ClearValue(const char* pszKey) { return ClearValue(NULL, pszKey); }
    virtual void WriteState(CUtlBuffer* pBuffer) = 0; // 34
    virtual void ReadState(CUtlBuffer* pBuffer) = 0; // 35
    virtual void RemoveOrphanInstances() = 0; // 36
    virtual void DumpState() = 0; // 37
    virtual void SetOutputCallback(ScriptOutputFunc_t pFunc) = 0; // 38
    virtual void SetErrorCallback(ScriptErrorFunc_t pFunc) = 0; // 39
    virtual bool RaiseException(const char* pszExceptionText) = 0; // 40

    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope = NULL, bool bWait = true, ScriptVariant_t* pReturn = NULL)
    {
        return ExecuteFunction(hFunction, NULL, 0, pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1)
    {
        ScriptVariant_t args[1];
        args[0] = arg1;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2)
    {
        ScriptVariant_t args[2];
        args[0] = arg1;
        args[1] = arg2;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3)
    {
        ScriptVariant_t args[3];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4)
    {
        ScriptVariant_t args[4];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5)
    {
        ScriptVariant_t args[5];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6)
    {
        ScriptVariant_t args[6];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7)
    {
        ScriptVariant_t args[7];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8)
    {
        ScriptVariant_t args[8];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9)
    {
        ScriptVariant_t args[9];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9, ARG_TYPE_10 arg10)
    {
        ScriptVariant_t args[10];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        args[9] = arg10;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9, ARG_TYPE_10 arg10, ARG_TYPE_11 arg11)
    {
        ScriptVariant_t args[11];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        args[9] = arg10;
        args[10] = arg11;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9, ARG_TYPE_10 arg10, ARG_TYPE_11 arg11, ARG_TYPE_12 arg12)
    {
        ScriptVariant_t args[12];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        args[9] = arg10;
        args[10] = arg11;
        args[11] = arg12;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9, ARG_TYPE_10 arg10, ARG_TYPE_11 arg11, ARG_TYPE_12 arg12, ARG_TYPE_13 arg13)
    {
        ScriptVariant_t args[13];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        args[9] = arg10;
        args[10] = arg11;
        args[11] = arg12;
        args[12] = arg13;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
    template <typename ARG_TYPE_1, typename ARG_TYPE_2, typename ARG_TYPE_3, typename ARG_TYPE_4, typename ARG_TYPE_5, typename ARG_TYPE_6, typename ARG_TYPE_7, typename ARG_TYPE_8, typename ARG_TYPE_9, typename ARG_TYPE_10, typename ARG_TYPE_11, typename ARG_TYPE_12, typename ARG_TYPE_13, typename ARG_TYPE_14>
    ScriptStatus_t Call(HSCRIPT hFunction, HSCRIPT hScope, bool bWait, ScriptVariant_t* pReturn, ARG_TYPE_1 arg1, ARG_TYPE_2 arg2, ARG_TYPE_3 arg3, ARG_TYPE_4 arg4, ARG_TYPE_5 arg5, ARG_TYPE_6 arg6, ARG_TYPE_7 arg7, ARG_TYPE_8 arg8, ARG_TYPE_9 arg9, ARG_TYPE_10 arg10, ARG_TYPE_11 arg11, ARG_TYPE_12 arg12, ARG_TYPE_13 arg13, ARG_TYPE_14 arg14)
    {
        ScriptVariant_t args[14];
        args[0] = arg1;
        args[1] = arg2;
        args[2] = arg3;
        args[3] = arg4;
        args[4] = arg5;
        args[5] = arg6;
        args[6] = arg7;
        args[7] = arg8;
        args[8] = arg9;
        args[9] = arg10;
        args[10] = arg11;
        args[11] = arg12;
        args[12] = arg13;
        args[13] = arg14;
        return ExecuteFunction(hFunction, args, Q_ARRAYSIZE(args), pReturn, hScope, bWait);
    }
};
#pragma endregion


//Particle system stuff

template<class T> struct CUtlReference {
    CUtlReference* m_pNext;
    CUtlReference* m_pPrev;
    T* m_pObject;
};
template<class T> struct CUtlIntrusiveList {
    T* m_pHead;
};
template<class T> struct CUtlIntrusiveDList : public CUtlIntrusiveList<T> {};
template<class T> struct CUtlReferenceList : public CUtlIntrusiveDList< CUtlReference<T> > {};

typedef union {
    float  m128_f32[4];
    unsigned int m128_u32[4];
} fltx4;

struct CParticleControlPoint {
    Vector m_Position;
    Vector m_PrevPosition;

    // orientation
    Vector m_ForwardVector;
    Vector m_UpVector;
    Vector m_RightVector;

    // reference to entity or whatever this control point comes from
    void* m_pObject;

    // parent for hierarchies
    int m_nParent;

    // CParticleSnapshot which particles can read data from or write data to:
    void* m_pSnapshot;
};

struct CModelHitBoxesInfo {
    float m_flLastUpdateTime;
    float m_flPrevLastUpdateTime;
    int m_nNumHitBoxes;
    int m_nNumPrevHitBoxes;
    void* m_pHitBoxes;
    void* m_pPrevBoxes;
};

struct CParticleCPInfo {
    CParticleControlPoint m_ControlPoint;
    CModelHitBoxesInfo m_CPHitBox;
};

struct CParticleAttributeAddressTable {
    float* m_pAttributes[24];
    size_t m_nFloatStrides[24];
};

// Alien Swarm SDK definition is used, but it doesn't work properly
// TODO: figure out all members of this struct

class CParticleCollection {
public:
    //CUtlReference< void > m_Sheet; // CSheet
    //fltx4 m_fl4CurTime;
    //int m_nPaddedActiveParticles;
    //float m_flCurTime;
    //float m_flPrevSimTime;
    //float m_flTargetDrawTime;
    //int m_nActiveParticles;
    //float m_flDt;
    //float m_flPreviousDt;
    //float m_flNextSleepTime;
    //CUtlReference< void > m_pDef; //CParticleSystemDefinition
    //int m_nAllocatedParticles;
    //int m_nMaxAllowedParticles;
    //bool m_bDormant;
    //bool m_bEmissionStopped;
    //bool m_bPendingRestart;
    //bool m_bQueuedStartEmission;
    //bool m_bFrozen;
    //bool m_bInEndCap;
    //int m_LocalLightingCP;
    //Color m_LocalLighting;
    unsigned char unknown001[100];

    int m_nNumControlPointsAllocated;
    CParticleCPInfo* m_pCPInfo;
    unsigned char* m_pOperatorContextData;
    CParticleCollection* m_pNext;
    CParticleCollection* m_pPrev;
    struct CWorldCollideContextData* m_pCollisionCacheData[4];
    CParticleCollection* m_pParent;
    CUtlIntrusiveDList<CParticleCollection>  m_Children;
    Vector m_Center;
    void* m_pRenderable;
    bool m_bBoundsValid;
    Vector m_MinBounds;
    Vector m_MaxBounds;
    int m_nHighestCP;
    //int m_nAttributeMemorySize;
    //unsigned char* m_pParticleMemory;
    //unsigned char* m_pParticleInitialMemory;
    //unsigned char* m_pConstantMemory;
    //unsigned char* m_pPreviousAttributeMemory;
    //int m_nPerParticleInitializedAttributeMask;
    //int m_nPerParticleUpdatedAttributeMask;
    //int m_nPerParticleReadInitialAttributeMask;
    //CParticleAttributeAddressTable m_ParticleAttributes;
    //CParticleAttributeAddressTable m_ParticleInitialAttributes;
    //CParticleAttributeAddressTable m_PreviousFrameAttributes;
    //float* m_pConstantAttributes;
    //unsigned long long m_nControlPointReadMask;
    //unsigned long long m_nControlPointNonPositionalMask;
    //int m_nParticleFlags;
    //bool m_bIsScrubbable : 1;
    //bool m_bIsRunningInitializers : 1;
    //bool m_bIsRunningOperators : 1;
    //bool m_bIsTranslucent : 1;
    //bool m_bIsTwoPass : 1;
    //bool m_bAnyUsesPowerOfTwoFrameBufferTexture : 1;
    //bool m_bAnyUsesFullFrameBufferTexture : 1;
    //bool m_bIsBatchable : 1;
    //bool m_bIsOrderImportant : 1;
    //bool m_bRunForParentApplyKillList : 1;
    //bool m_bUsesPowerOfTwoFrameBufferTexture;
    //bool m_bUsesFullFrameBufferTexture;
    //int m_nDrawnFrames;
    //int m_nUniqueParticleId;
    //int m_nRandomQueryCount;
    //int m_nRandomSeed;
    //int m_nOperatorRandomSampleOffset;
    //float m_flMinDistSqr;
    //float m_flMaxDistSqr;
    //float m_flOOMaxDistSqr;
    //Vector m_vecLastCameraPos;
    //float m_flLastMinDistSqr;
    //float m_flLastMaxDistSqr;
    //int m_nNumParticlesToKill;
    //void* m_pParticleKillList; // KillListItem_t
    //CParticleCollection* m_pNextDef;
    //CParticleCollection* m_pPrevDef;
    //void* m_pRenderOp; //CParticleOperatorInstance
};

struct CNewParticleEffect {
    void* valveYouAbsoluteDumbFucksIWishYouAllGetHitByAnIcecreamTruck[4];
    CParticleCollection collection;
};

struct ICommandLine
{
public:
    virtual void		CreateCmdLine(const char* commandline) = 0;
    virtual void		CreateCmdLine(int argc, char** argv) = 0;
    virtual const char* GetCmdLine(void) const = 0;
    virtual	const char* CheckParm(const char* psz, const char** ppszValue = 0) const = 0;
    virtual void		RemoveParm(const char* parm) = 0;
    virtual void		AppendParm(const char* pszParm, const char* pszValues) = 0;
    virtual const char* ParmValue(const char* psz, const char* pDefaultVal = 0) const = 0;
    virtual int			ParmValue(const char* psz, int nDefaultVal) const = 0;
    virtual float		ParmValue(const char* psz, float flDefaultVal) const = 0;
    virtual int			ParmCount() const = 0;
    virtual int			FindParm(const char* psz) const = 0;
    virtual const char* GetParm(int nIndex) const = 0;
    virtual void SetParm(int nIndex, char const* pNewParm) = 0;
};
