AddCSLuaFile()

CreateConVar("zippyhorde_start_time", "10", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_spawndist", "2000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_spawndist_min", "1000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_max_spawned", "40", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_teleport_fx", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_teleport", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_refill_health", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_chase_player", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_run_chase", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_no_noclip", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_end_on_death", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_use_nodes", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyhorde_vischeck", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))

if CLIENT then
    Z_HORDE_HALO_ENABLE = CreateConVar("zippyhorde_halo_enable", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
    -- Z_HORDE_HALO_BLUR = CreateConVar("zippyhorde_halo_blur", "8", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
end