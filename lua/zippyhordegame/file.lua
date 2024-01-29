util.AddNetworkString("ZippyHorde_GetPresets")
util.AddNetworkString("ZippyHorde_SendPresetsToClient")
util.AddNetworkString("ZippyHorde_SelectPreset")
util.AddNetworkString("ZippyHorde_GivePresetContents")
util.AddNetworkString("ZippyHorde_RemovePreset")
util.AddNetworkString("ZippyHorde_NewPreset")

local PATH = "hordegame_presets/"
local DEFAULT_PRESET_NAME = PATH.."default.json"

------------------------------------------------------------------------------=#
local function sendPresetsToClient()

    local files = file.Find(PATH.."*", "DATA")

    net.Start("ZippyHorde_SendPresetsToClient")
    net.WriteTable(files)
    net.Broadcast()

end
------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_GetPresets", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    sendPresetsToClient()

end)
------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_SelectPreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local presetToSelect = net.ReadString()..".json"
    local files = file.Find(PATH.."*", "DATA")

    for _, preset in ipairs(files) do
        if preset != presetToSelect then continue end

        Z_HORDEGAME.NPCsToSpawn = util.JSONToTable(file.Read(PATH..preset))

        net.Start("ZippyHordeGame_RefreshNPCList")
        net.WriteTable( Z_HORDEGAME.NPCsToSpawn )
        net.Broadcast()

        break
    end

end)
------------------------------------------------------------------------------=#
function Z_HORDEGAME:PresetSave( name )

    if name == "default" then return end

    file.Write(PATH..string.lower( name )..".json", util.TableToJSON(Z_HORDEGAME.NPCsToSpawn, true))
    sendPresetsToClient()

end
------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_NewPreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local files = file.Find(PATH.."*", "DATA")

    if #files > 100 then
        PrintMessage(HUD_PRINTTALK, "WARNING: Preset limit reached!")   return
    end

    Z_HORDEGAME:PresetSave( net.ReadString() )

end)
------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_RemovePreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    file.Delete(PATH..net.ReadString()..".json")
    sendPresetsToClient()

end)
------------------------------------------------------------------------------=#
local function makeDefaultPreset()

    local fileContents = util.TableToJSON(
    {
        npc_fastzombie = {
            spawnmenuData=list.Get("NPC")["npc_fastzombie"],
            chance = 1
        }
    }
    )

    file.Write(DEFAULT_PRESET_NAME, fileContents)

end
------------------------------------------------------------------------------=#
hook.Add("Initialize", "Initialize_ZippyHorde_FileStuff", function()

    if !file.Exists(PATH, "DATA") then
        file.CreateDir(PATH)
    end

    if !file.Exists(DEFAULT_PRESET_NAME, "DATA") then
        makeDefaultPreset()
    end

end)
------------------------------------------------------------------------------=#