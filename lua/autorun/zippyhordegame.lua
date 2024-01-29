local path = "zippyhordegame/"

AddCSLuaFile(path.."cvars.lua")
AddCSLuaFile(path.."client.lua")

include(path.."cvars.lua")

if SERVER then
    include(path.."parsefile.lua")
    include(path.."server.lua")
    include(path.."scheduling.lua")
    include(path.."npcs.lua")
    include(path.."file.lua")
else
    include(path.."client.lua")
end