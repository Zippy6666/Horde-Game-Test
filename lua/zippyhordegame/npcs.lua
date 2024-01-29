util.AddNetworkString("ZippyHordeGame_NewNPC")
util.AddNetworkString("ZippyHordeGame_RefreshNPCList")
util.AddNetworkString("ZippyHorde_RemoveNPC")
util.AddNetworkString("ZippyHorde_EditNPC")

if !Z_HORDEGAME.NPCsToSpawn then
    Z_HORDEGAME.NPCsToSpawn = {}
end

----------------------------------------------------------------------------------------------------=#
local function addNPC( class, data )

    if table.Count(Z_HORDEGAME.NPCsToSpawn) > 100 then
        PrintMessage(HUD_PRINTTALK, "WARNING: NPC limit reached!")   return
    end

    local data = data or {}
    local spawnmenuData = list.Get("NPC")[class]

    Z_HORDEGAME.NPCsToSpawn[class] = {
        spawnmenuData=spawnmenuData,
        chance=data.chance or 1,
        waveStart=data.start,
        waveEnd=data._end,
    }

end
----------------------------------------------------------------------------------------------------=#
local function refreshList()

    net.Start("ZippyHordeGame_RefreshNPCList")
    net.WriteTable( Z_HORDEGAME.NPCsToSpawn )
    net.Broadcast()

end
----------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHordeGame_NewNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()

    addNPC( npcClass )
    Z_HORDEGAME:PresetSave( curPresetName )

    refreshList()

end)
----------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_RemoveNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()

    Z_HORDEGAME.NPCsToSpawn[ npcClass ] = nil
    Z_HORDEGAME:PresetSave( curPresetName )

    refreshList()

end)
----------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHorde_EditNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()
    local npcData = net.ReadTable()

    Z_HORDEGAME.NPCsToSpawn[npcClass] = npcData
    Z_HORDEGAME:PresetSave( curPresetName )

    refreshList()

end)
----------------------------------------------------------------------------------------------------=#