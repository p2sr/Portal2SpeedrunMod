for /f "tokens=* usebackq" %%x in (`git describe --tags`) do (set version=%%x)
echo #define SMSM_VERSION "%version%">Version.hpp
