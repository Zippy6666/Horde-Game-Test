if CLIENT then
    function MissingConvMsg()
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 125)
        frame:SetTitle("Missing Library!")
        frame:Center()
        frame:MakePopup()

        local text = vgui.Create("DLabel", frame)
        text:SetText("This server does not have the CONV library installed, some addons may function incorrectly. Click the link below to get it:")
        text:Dock(TOP)
        text:SetWrap(true)  -- Enable text wrapping for long messages
        text:SetAutoStretchVertical(true)  -- Allow the text label to stretch vertically
        text:SetFont("BudgetLabel")

        local label = vgui.Create("DLabelURL", frame)
        label:SetText("CONV Library")
        label:SetURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
        label:Dock(BOTTOM)
        label:SetContentAlignment(5)  -- 5 corresponds to center alignment
    end
elseif SERVER && !file.Exists("convenience/adam.lua", "LUA") then
    -- Conv lib not on on server, send message to clients
    hook.Add("PlayerInitialSpawn", "convenienceerrormsg", function( ply )
        local sendstr = 'MissingConvMsg()'
        ply:SendLua(sendstr)
    end)
end


--[[
=======================================================================================================================
                                            HORDE
=======================================================================================================================
--]]



local path = "zippyhordegame/"

AddCSLuaFile(path.."cvars.lua")
AddCSLuaFile(path.."client.lua")
AddCSLuaFile(path.."particles.lua")

include(path.."cvars.lua")
include(path.."particles.lua")

if SERVER then
    include(path.."parsefile.lua")
    include(path.."server.lua")
    include(path.."scheduling.lua")
    include(path.."npcs.lua")
    include(path.."file.lua")
else
    include(path.."client.lua")
end