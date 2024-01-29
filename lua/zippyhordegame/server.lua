util.AddNetworkString("ZippyHordeGame_Start")
util.AddNetworkString("ZippyHordeGame_GameStartConfirmed")
util.AddNetworkString("ZippyHordeGame_EnableButton")
util.AddNetworkString("ZippyHordeGame_ForceEnd")
util.AddNetworkString("ZippyHordeGame_ForceEndWave")

if !Z_HORDEGAME then
    Z_HORDEGAME = {}
    Z_HORDEGAME.NPCs = {}
    Z_HORDEGAME.WaveNPCCount = 0
    Z_HORDEGAME.WaveNPCsKilled = 0
    Z_HORDEGAME.NextPrintNPCsLeft = CurTime()
end

--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:NPC_Good_Position( npc, pos )

    local vectorExtra = Vector(0, 0, -npc:OBBMins().z)

    if npc:GetClass() == "npc_strider" then
        vectorExtra = vectorExtra + Vector(0, 0, 400)
    elseif npc.ZippyHorde_PositionOffset then
        vectorExtra = vectorExtra + Vector(0, 0, npc.ZippyHorde_PositionOffset)
    elseif npc.IsVJBaseSNPC && npc.MovementType == VJ_MOVETYPE_AERIAL then
        vectorExtra = vectorExtra + Vector(0, 0, npc.AA_GroundLimit)
    end

    return pos + vectorExtra

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:TryPositionNPC( npc, noTeleportFromEffect )

    table.Shuffle(self.NodePositions)

    local playerPos = table.Random(player.GetAll()):GetPos()
    local useSpawnPoints = !table.IsEmpty(ZHORDE_SPAWN_POINTS)
    local positions = useSpawnPoints && ZHORDE_SPAWN_POINTS or self.NodePositions
    for _, v in ipairs(positions) do
        local checkPos = self:NPC_Good_Position(npc, useSpawnPoints && v:GetPos()+Vector(0, 0, 25) or v)

        if !useSpawnPoints then
            if self:TooCloseToPlayer(checkPos) then return end
            if checkPos:DistToSqr(playerPos) > GetConVar("zippyhorde_spawndist"):GetInt()^2 then continue end
        end

        local trData = {
            start = checkPos,
            endpos = checkPos,
            filter = npc,
        }
        
        if util.TraceEntity(trData, npc).Hit then continue end

        -- Goofy effects:
        if GetConVar("zippyhorde_teleport_fx"):GetBool() then

            if !noTeleportFromEffect then
                ParticleEffect("aurora_shockwave", npc:GetPos(), Angle())
                sound.Play("beams/beamstart5.wav", npc:GetPos(), 90, math.random(90, 110), 0.5)
            end
            
            ParticleEffect("aurora_shockwave", checkPos, Angle())
            sound.Play("beams/beamstart5.wav", checkPos, 90, math.random(90, 110), 0.5)

        end

        npc:SetPos(checkPos)    return true
    end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:TooCloseToPlayer( pos )

    for _, ply in ipairs(player.GetAll()) do
        local dist = GetConVar("zippyhorde_spawndist_min"):GetInt()
        if pos:DistToSqr(ply:GetPos()) < dist^2 then return true end
    end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:GetBasedOnStrength( number )
    return math.floor( number*self.NPCStrength + number*self.NPCStrengthIncreaseAmount*self.WavesDone )
end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:GetAliveNPCsCount( spawnmenuClass )

    local count = 0

    for _, npc in ipairs(self.NPCs) do
        if npc.ZippyHordeSpawnMenuClass == spawnmenuClass then count = count+1 end
    end

    return count

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:DecideNPC()

    local npcPool = {}
    local wave = self.WavesDone+1

    -- Decide what NPCs could spawn now --
    --print("NPC POOL:")
    for key, npc in pairs(self.NPCsToSpawn) do
        -- WAVE START AND END STUFF --
        if npc.waveStart && wave < npc.waveStart then continue end
        if npc.waveEnd && wave > npc.waveEnd then continue end
        ----------------------------------------------------=#

        -- NPC LIMIT PER WAVE --
        local spawnedNPCs = self.WaveNPCsSpawnedCount[key]
        if npc.maxPerWave && spawnedNPCs && spawnedNPCs >= npc.maxPerWave then continue end
        ----------------------------------------------------=#

        -- MAX NPCS ALIVE AT ONCE --
        local aliveNPCs = self:GetAliveNPCsCount(key)
        if npc.maxAlive && aliveNPCs >= npc.maxAlive then continue end
        ----------------------------------------------------=#

        -- if npc.maxAlive or npc.maxPerWave then
        --     print(key, "wave spawned: ", spawnedNPCs, "current alive: ", aliveNPCs)
        -- end

        npcPool[key] = npc
    end

    --print("------------------------------------------------")
    ----------------------------------------------------=#

    local npcData, spawnmenuClass = table.Random(npcPool)

    if !npcData then
        PrintMessage(HUD_PRINTTALK, "WARNING: No NPCs to spawn!")
    end

    while math.random(1, npcData.chance) != 1 do
        npcData = table.Random(npcPool)
    end

    return npcData.spawnmenuData, spawnmenuClass, npcData.CustomWeapons

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:SpawnNPC()

    -- Create NPC --
    local npcSpawnmenuData, spawnmenuClass, customWeapons = self:DecideNPC()
    local NPC = ents.Create(npcSpawnmenuData.Class)

    if !IsValid(NPC) then
        PrintMessage(HUD_PRINTTALK, "WARNING: Failed to spawn \""..npcSpawnmenuData.Name.."\"!")
    end
    --------------------------------------------------------------------------------------------=#

    -- Register NPC --
    NPC.IsZippyHordeNPC = true

    NPC:CallOnRemove("hordeRegisterDeadOnRemove", function()
        self:RegisterDead(NPC)
    end)

    table.insert(Z_HORDEGAME.NPCs, NPC)

    if !self.WaveNPCsSpawnedCount[spawnmenuClass] then self.WaveNPCsSpawnedCount[spawnmenuClass] = 0 end
    self.WaveNPCsSpawnedCount[spawnmenuClass] = self.WaveNPCsSpawnedCount[spawnmenuClass] + 1

    NPC.ZippyHordeSpawnMenuClass = spawnmenuClass
    --------------------------------------------------------------------------------------------=#

    NPC:SetAngles( Angle(0, math.Rand(0, 360), 0) ) -- Random Angle

    -- NPC Spawn Menu Stuff --
    if npcSpawnmenuData.Model then
        local dontDoubleSetModel = {
            npc_crabsynth = true,
            npc_ministrider_ep1 = true,
            npc_ministrider_ep2_trailer = true,
            npc_ministrider_spb = true,
        }
    
        NPC:SetModel(npcSpawnmenuData.Model)
        timer.Simple(0, function() if IsValid(NPC) && !dontDoubleSetModel[npcSpawnmenuData.Class] then NPC:SetModel(npcSpawnmenuData.Model) end end)
    end

    local weps = customWeapons or npcSpawnmenuData.Weapons
    if weps then
        local wep = table.Random(weps)
        if istable(wep) then
            wep = wep.Class
        end
        if wep then
            NPC:Give(wep)
        end
    end


    if npcSpawnmenuData.Skin then NPC:SetSkin(npcSpawnmenuData.Skin) end
    if npcSpawnmenuData.Health then NPC:SetMaxHealth(npcSpawnmenuData.Health) NPC:SetHealth(npcSpawnmenuData.Health) end
    if npcSpawnmenuData.Material then NPC:SetMaterial(npcSpawnmenuData.Material) end
    if npcSpawnmenuData.SpawnFlags then NPC:SetKeyValue("spawnflags", npcSpawnmenuData.SpawnFlags) end


    if npcSpawnmenuData.KeyValues then
        for key, value in pairs(npcSpawnmenuData.KeyValues) do
            NPC:SetKeyValue(key, value)
        end
    end
    
    NPC.ZippyHorde_PositionOffset = npcSpawnmenuData.Offset
    --------------------------------------------------------------------------------------------=#

    -- Spawn and Activate --
    NPC:Spawn()
    NPC:Activate()
    --------------------------------------------------------------------------------------------=#

    -- New Health Based on Strenght --
    timer.Simple(0.1, function()
        if !IsValid(NPC) then return end
        local newHealth = self:GetBasedOnStrength( NPC:GetMaxHealth() )
        NPC:SetMaxHealth(newHealth)
        NPC:SetHealth(newHealth)
    end)
    --------------------------------------------------------------------------------------------=#

    NPC.ZippyHorde_NotPositionedYet = !self:TryPositionNPC(NPC, true) -- Position it, or let us know if it failed
end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:SpawnWave_Announce()

    local printStuff = {
        "---------------------------------------------------",
        "WAVE "..self.WavesDone+1,
        self.WaveNPCCount.." NPCs",
        "NPC Strength: "..self:GetBasedOnStrength(100).."%",
        "---------------------------------------------------",
    }

    PrintMessage(HUD_PRINTCENTER, "WAVE "..self.WavesDone+1)

    for _, text in ipairs(printStuff) do
        PrintMessage(HUD_PRINTTALK, text)
    end

    if table.IsEmpty(self.NodePositions) && table.IsEmpty(ZHORDE_SPAWN_POINTS) then
        PrintMessage(HUD_PRINTTALK, "WARNING: No nodegraph detected! Try setting \"ai_norebuildgraph\" to \"1\" and restart the map, or use spawn points!")
    end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:StartExtraSpawnTimer( count )

    local extraNPCsSpawned = 0

    timer.Create("ZippyHordeSpawnRestTimer", 1, 0, function()

        if table.Count(Z_HORDEGAME.NPCs) >= GetConVar("zippyhorde_max_spawned"):GetInt() then return end
    
        self:SpawnNPC()
        extraNPCsSpawned = extraNPCsSpawned+1

        if extraNPCsSpawned >= count then timer.Remove("ZippyHordeSpawnRestTimer") end

    end)

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:SpawnWave()

    self.WaveActive = true

    self:SpawnWave_Announce()
    
    local startNPCCount = math.Clamp(self.WaveNPCCount, 0, GetConVar("zippyhorde_max_spawned"):GetInt())
    local extraNPCCount = self.WaveNPCCount - startNPCCount

    timer.Create("ZippyHordeSpawnRestTimer", 0, startNPCCount, function()
        self:SpawnNPC()
        if timer.RepsLeft("ZippyHordeSpawnRestTimer") == 0 && extraNPCCount > 0 then self:StartExtraSpawnTimer(extraNPCCount) end
    end)
end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:RefillHealth()

    if !GetConVar("zippyhorde_refill_health"):GetBool() then return end

    for _, ply in ipairs(player.GetAll()) do
        ply:SetHealth(100)
        ply:SetArmor(100)
    end

    PrintMessage(HUD_PRINTTALK, "Health and armor refilled!")

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:StartWave()

    self.WaveNPCsKilled = 0
    self.WaveNPCsSpawnedCount = {}
    self.WaveNPCCount = self.BaseNPCCount + self.NPCIncreaseAmount*self.WavesDone

    local startTime = GetConVar("zippyhorde_start_time"):GetInt()
    PrintMessage(HUD_PRINTCENTER, "NEW WAVE IN "..startTime.." SECONDS")
    timer.Create("ZippyHordeWaitTimer", startTime, 1, function() self:SpawnWave() end)

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:WaveOver()

    self.WaveActive = false

    self.WavesDone = self.WavesDone+1

    if self.WavesDone >= self.WaveCount then
        PrintMessage(HUD_PRINTCENTER, "HORDE GAME FINISHED")

        net.Start("ZippyHordeGame_EnableButton")
        net.Broadcast()

        self.Started = false
    else
        PrintMessage(HUD_PRINTCENTER, "WAVE OVER")
        timer.Create("ZippyHordeWaitTimer", 3, 1, function() self:StartWave() end)
    end

    self:RefillHealth()

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:RegisterDead( ent )

    if !ent.IsZippyHordeNPC then return end
    if ent.ZippyHorde_Dead then return end

    ent.ZippyHorde_Dead = true
    table.RemoveByValue(Z_HORDEGAME.NPCs, ent)

    self.WaveNPCsKilled = self.WaveNPCsKilled+1
    local npcsLeft = self.WaveNPCCount-self.WaveNPCsKilled
    
    if self.NextPrintNPCsLeft < CurTime() then
        timer.Simple(1, function()
            if !self.WaveActive then return end

            local npcsLeft = self.WaveNPCCount-self.WaveNPCsKilled
            if npcsLeft < 1 then return end

            PrintMessage(HUD_PRINTTALK, npcsLeft.." NPCs left!")
        end)
    
        self.NextPrintNPCsLeft = CurTime() + 5
    end

    if npcsLeft < 1 then self:WaveOver() end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
function Z_HORDEGAME:RemoveAllLiveNPCs()

    for _, ent in ipairs(ents.GetAll()) do
        if !ent.IsZippyHordeNPC then continue end

        ent.ZippyHorde_Dead = true -- Prevent register
        table.RemoveByValue(Z_HORDEGAME.NPCs, ent) -- Still remove from table
        ent:Remove()
    end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHordeGame_Start", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if Z_HORDEGAME.Started then return end

    Z_HORDEGAME.Started = true
    Z_HORDEGAME.WavesDone = 0

    PrintMessage(HUD_PRINTCENTER, "HORDE GAME STARTED")

    Z_HORDEGAME.WaveCount = net.ReadInt(32)
    Z_HORDEGAME.BaseNPCCount = net.ReadInt(32)
    Z_HORDEGAME.NPCIncreaseAmount = net.ReadInt(32)
    Z_HORDEGAME.NPCStrength = net.ReadFloat()
    Z_HORDEGAME.NPCStrengthIncreaseAmount = net.ReadFloat()

    Z_HORDEGAME:RefillHealth()

    timer.Create("ZippyHordeWaitTimer", 3, 1, function() Z_HORDEGAME:StartWave() end)

    net.Start("ZippyHordeGame_GameStartConfirmed")
    net.Broadcast()

end)
--------------------------------------------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHordeGame_ForceEnd", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if !Z_HORDEGAME.Started then return end

    if timer.Exists("ZippyHordeWaitTimer") then timer.Remove("ZippyHordeWaitTimer") end
    if timer.Exists("ZippyHordeSpawnRestTimer") then timer.Remove("ZippyHordeSpawnRestTimer") end

    Z_HORDEGAME:RemoveAllLiveNPCs()

    Z_HORDEGAME.Started = false

    net.Start("ZippyHordeGame_EnableButton")
    net.Broadcast()

    PrintMessage(HUD_PRINTCENTER, "HORDE GAME ENDED")

end)
--------------------------------------------------------------------------------------------------------------------------------------=#
net.Receive("ZippyHordeGame_ForceEndWave", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if !Z_HORDEGAME.Started then return end
    if !Z_HORDEGAME.WaveActive then return end

    if timer.Exists("ZippyHordeSpawnRestTimer") then timer.Remove("ZippyHordeSpawnRestTimer") end

    Z_HORDEGAME:RemoveAllLiveNPCs()
    Z_HORDEGAME:WaveOver()

end)
--------------------------------------------------------------------------------------------------------------------------------------=#
hook.Add("EntityTakeDamage", "EntityTakeDamage_ZippyHorde", function( _, dmginfo )

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if attacker.IsZippyHordeNPC or inflictor.IsZippyHordeNPC or (IsValid(inflictor) && inflictor:GetOwner().IsZippyHordeNPC) then
        local newDamage = Z_HORDEGAME:GetBasedOnStrength(dmginfo:GetDamage())
        dmginfo:SetDamage(newDamage)
    end

end)
--------------------------------------------------------------------------------------------------------------------------------------=#
hook.Add("OnNPCKilled", "OnNPCKilled_ZippyHorde", function( npc )
    Z_HORDEGAME:RegisterDead(npc)
end)
--------------------------------------------------------------------------------------------------------------------------------------=#
hook.Add("InitPostEntity", "ZippyHorde_InitPostEntity", function()
    Z_HORDEGAME.NodePositions = ZIPPYHORDEGAME_GET_NODE_POSITIONS()
end)
--------------------------------------------------------------------------------------------------------------------------------------=#
local function decideTeleportNPC( NPC )

    -- Position if still on its default (0;0;0) coordinates:
    if NPC.ZippyHorde_NotPositionedYet then
        NPC.ZippyHorde_NotPositionedYet = !Z_HORDEGAME:TryPositionNPC(NPC)
        return
    end

    if !GetConVar("zippyhorde_teleport"):GetBool() then return end
    if !table.IsEmpty(ZHORDE_SPAWN_POINTS) then return end -- Don't teleport if there are spawn points

    -- Teleport if too far away:
    local allPlayersTooFarAway = true

    for _, ply in ipairs(player.GetAll()) do
        local distance = NPC:GetPos():DistToSqr(ply:GetPos())
        if distance < GetConVar("zippyhorde_spawndist"):GetInt()^2 then allPlayersTooFarAway = false break end
    end

    if allPlayersTooFarAway then
        Z_HORDEGAME:TryPositionNPC(NPC)
    end

end
--------------------------------------------------------------------------------------------------------------------------------------=#
timer.Create("ZippyHorde_TeleportNPCs", 1, 0, function()

    if !Z_HORDEGAME.Started then return end

    for _, NPC in ipairs(Z_HORDEGAME.NPCs) do
        decideTeleportNPC( NPC )
    end

end)
--------------------------------------------------------------------------------------------------------------------------------------=#