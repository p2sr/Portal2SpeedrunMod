#pragma once

enum SourceGameVersion {
    SourceGame_Unknown = 0,

    SourceGame_Portal2 = (1 << 0),

    SourceGame_Portal2Engine = SourceGame_Portal2
};

class Game {
public:
    SourceGameVersion version;

public:
    virtual ~Game() = default;
    virtual void LoadOffsets() = 0;
    virtual const char* Version();

    bool IsPortal2Engine();

    static Game* CreateNew();
};
