--[[=========================== CONV MESSAGE START ===========================]]--
MissingConvMsg2 = CLIENT && function()

    Derma_Query(
        "This server does not have Zippy's Library installed, addons will function incorrectly!",

        "ZIPPY'S LIBRARY MISSING!",
        
        "Get Zippy's Library",

        function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
        end,

        "Close"
    )

end or nil

hook.Add("PlayerInitialSpawn", "MissingConvMsg2", function( ply )

    if file.Exists("autorun/conv.lua", "LUA") then return end

    local sendstr = 'MissingConvMsg2()'
    ply:SendLua(sendstr)

end)
--[[============================ CONV MESSAGE END ============================]]--

local path = "zippyhordegame/"

AddCSLuaFile(path.."cvars.lua")
AddCSLuaFile(path.."client.lua")
AddCSLuaFile(path.."halo.lua")

include(path.."cvars.lua")

if SERVER then
    include(path.."parsefile.lua")
    include(path.."server.lua")
    include(path.."scheduling.lua")
    include(path.."npcs.lua")
    include(path.."file.lua")
else
    include(path.."client.lua")
    include(path.."halo.lua")
end