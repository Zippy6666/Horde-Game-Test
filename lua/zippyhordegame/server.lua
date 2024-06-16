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


local DistMaxCvar = GetConVar("zippyhorde_spawndist")
local DistMinCvar = GetConVar("zippyhorde_spawndist_min")
local maxNodeIter = 10
function Z_HORDEGAME:FindNodePos( ply )
    table.Shuffle(self.NodePositions)

    local DistMin = DistMaxCvar:GetInt()^2
    local DistMax = DistMinCvar:GetInt()^2
    local iters = 0
    local plyPos = ply:GetPos()
    for _, v in ipairs(self.NodePositions) do
        if v:DistToSqr(plyPos) >= DistMin && v:DistToSqr(plyPos) <= DistMax then
            print("found node position!")
            return v
        end

        iters = iters + 1
        if iters >= maxNodeIter then
            break
        end
    end
end


function Z_HORDEGAME:CheckVisibility( pos )
    
    for _, ply in player.Iterator() do
        
        if ply:PosInView(pos) then
            return true
        end

    end


    return false

end



local TracerStartUpAmt = 150 
local TracerEndPosDownVec = Vector(0, 0, 500)
local UseNodesCvar = GetConVar("zippyhorde_use_nodes")
function Z_HORDEGAME:FindPlyRelPos( ply )
    local DownTRStartPos
    if UseNodesCvar:GetBool() && !(istable(self.NodePositions) && table.IsEmpty(self.NodePositions)) then

        -- Use nodes

        if !istable(self.NodePositions) then

            self.NodePositions = ZIPPYHORDEGAME_GET_NODE_POSITIONS()
            if table.IsEmpty(self.NodePositions) then
                PrintMessage(HUD_PRINTTALK, "[HORDE] Could not find nodes :(")
            end

        end

        DownTRStartPos = self:FindNodePos( ply )

    else

        -- Don't use nodes

        local VecMin = DistMaxCvar:GetInt()
        local VecMax = DistMinCvar:GetInt()
        local PlyPos = ply:WorldSpaceCenter()
        local xMult = table.Random({-1, 1})
        local yMult = table.Random({-1, 1})
        DownTRStartPos = PlyPos + Vector( math.random(VecMin, VecMax)*xMult, math.random(VecMin, VecMax)*yMult, TracerStartUpAmt )

        debugoverlay.Line(PlyPos, DownTRStartPos, 3)

    end


    -- Position not in world, don't continue
    if !util.IsInWorld(DownTRStartPos) then return end 


    -- Down trace
    local tr = util.TraceLine({
        start=DownTRStartPos,
        endpos = DownTRStartPos-TracerEndPosDownVec,
        mask = MASK_NPCWORLDSTATIC,
    })

    -- Must hit floor to spawn NPC
    if !tr.Hit then return end


    -- Debug
    debugoverlay.Line(DownTRStartPos, DownTRStartPos-TracerEndPosDownVec, 3)


    -- Final position
    local ReturnPos = tr.HitPos+tr.HitNormal*15 


    -- A player can see this position right now, don't return
    if self:CheckVisibility(ReturnPos) then return end 


    -- All checks satisfied, return the position
    return ReturnPos

end


function Z_HORDEGAME:TryPositionNPC( npc, noTeleportFromEffect )


    local ply = table.Random(player.GetAll())
    local useSpawnPoints = !table.IsEmpty(ZHORDE_SPAWN_POINTS)
    local function effect( pos )
        if GetConVar("zippyhorde_teleport_fx"):GetBool() then

            if !noTeleportFromEffect then
                ParticleEffect("aurora_shockwave", npc:GetPos(), Angle())
                sound.Play("beams/beamstart5.wav", npc:GetPos(), 90, math.random(90, 110), 0.5)
            end

            ParticleEffect("aurora_shockwave", pos, Angle())
            sound.Play("beams/beamstart5.wav", pos, 90, math.random(90, 110), 0.5)

        end
    end


    if useSpawnPoints then
        -- Spawn point spawning
        for _, v in ipairs(ZHORDE_SPAWN_POINTS) do
            local checkPos = self:NPC_Good_Position(npc, v:GetPos()+Vector(0, 0, 25))

            local trData = {
                start = checkPos,
                endpos = checkPos,
                filter = npc,
            }

            if util.TraceEntity(trData, npc).Hit then continue end

            effect( checkPos )

            npc:SetPos(checkPos)
            npc:SetAngles(Angle(0, math.random(1, 360), 0))
            -- npc:SetNoDraw(false)
            npc:ClearSchedule()
            return true
        end
    else

        -- Relative spawning
        local pos = self:FindPlyRelPos(ply)
        if pos then
            local checkPos = self:NPC_Good_Position(npc, pos+Vector(0, 0, 25))

            local trData = {
                start = checkPos,
                endpos = checkPos,
                filter = npc,
            }

            if !util.TraceEntity(trData, npc).Hit then

                effect( checkPos )

                npc:SetPos(checkPos)
                npc:SetAngles(Angle(0, math.random(1, 360), 0))
                -- npc:SetNoDraw(false)
                npc:ClearSchedule()
                return true
            
            end
        end

    end

end


function Z_HORDEGAME:TooCloseToPlayer( pos )

    for _, ply in ipairs(player.GetAll()) do
        local dist = GetConVar("zippyhorde_spawndist_min"):GetInt()
        if pos:DistToSqr(ply:GetPos()) < dist^2 then return true end
    end

end


function Z_HORDEGAME:GetBasedOnStrength( number )
    return math.floor( number*self.NPCStrength + number*self.NPCStrengthIncreaseAmount*self.WavesDone )
end


function Z_HORDEGAME:GetAliveNPCsCount( spawnmenuClass )

    local count = 0

    for _, npc in ipairs(self.NPCs) do
        if npc.ZippyHordeSpawnMenuClass == spawnmenuClass then count = count+1 end
    end

    return count

end


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
        PrintMessage(HUD_PRINTTALK, "[HORDE] WARNING: No NPCs to spawn!")
    end

    while math.random(1, npcData.chance) != 1 do
        npcData = table.Random(npcPool)
    end

    return npcData.spawnmenuData, spawnmenuClass, npcData.CustomWeapons

end


function Z_HORDEGAME:SpawnNPC()

    -- Create NPC --
    local npcSpawnmenuData, spawnmenuClass, customWeapons = self:DecideNPC()
    local wep = customWeapons && table.Random(customWeapons)
    local NPC = ents.CreateSpawnMenuNPC( spawnmenuClass, pos, wep or nil )

    -- Vars
    NPC.IsZippyHordeNPC = true
    NPC.ZippyHordeSpawnMenuClass = spawnmenuClass
    NPC.ZippyHorde_PositionOffset = npcSpawnmenuData.Offset


    -- Register
    NPC:CallOnRemove("hordeRegisterDeadOnRemove", function()
        self:RegisterDead(NPC)
    end)
    table.insert(Z_HORDEGAME.NPCs, NPC)


    -- Count
    if !self.WaveNPCsSpawnedCount[spawnmenuClass] then
        self.WaveNPCsSpawnedCount[spawnmenuClass] = 0
    end
    self.WaveNPCsSpawnedCount[spawnmenuClass] = self.WaveNPCsSpawnedCount[spawnmenuClass] + 1


    -- New Health Based on Strenght
    timer.Simple(0.1, function()

        if !IsValid(NPC) then return end

        local newHealth = self:GetBasedOnStrength( NPC:GetMaxHealth() )
        NPC:SetMaxHealth(newHealth)
        NPC:SetHealth(newHealth)

    end)


    -- Position it, or let us know if it failed
    NPC.ZippyHorde_NotPositionedYet = !self:TryPositionNPC(NPC, true) 


    -- AUTO TELEPORT SYSTEM (FROM PROXSPAWN)
    -- Try moving to another location if it has been out of view for some time
    NPC:ConvTimer( "ProxyMove", math.Rand(15, 25), function()
        if GetConVar("zippyhorde_teleport"):GetBool() && !self:CheckVisibility( NPC:GetPos() ) then
            local success = self:TryPositionNPC( NPC )

            if success && NPC:IsNPC() && NPC:IsGoalActive() then -- Clear goal after teleportation so we don't just run off
                NPC:ClearGoal()
            end
        end
    end, 0 )
end


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

    -- if table.IsEmpty(self.NodePositions) && table.IsEmpty(ZHORDE_SPAWN_POINTS) then
    --     PrintMessage(HUD_PRINTTALK, "[HORDE] WARNING: No nodegraph detected! Try setting \"ai_norebuildgraph\" to \"1\" and restart the map, or use spawn points!")
    -- end

end


function Z_HORDEGAME:StartExtraSpawnTimer( count )

    local extraNPCsSpawned = 0

    timer.Create("ZippyHordeSpawnRestTimer", 1, 0, function()

        if table.Count(Z_HORDEGAME.NPCs) >= GetConVar("zippyhorde_max_spawned"):GetInt() then return end
    
        self:SpawnNPC()
        extraNPCsSpawned = extraNPCsSpawned+1

        if extraNPCsSpawned >= count then timer.Remove("ZippyHordeSpawnRestTimer") end

    end)

end


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


function Z_HORDEGAME:RefillHealth()

    if !GetConVar("zippyhorde_refill_health"):GetBool() then return end

    for _, ply in ipairs(player.GetAll()) do
        ply:SetHealth(ply:GetMaxHealth())
        ply:SetArmor(ply:GetMaxArmor())
    end

    PrintMessage(HUD_PRINTTALK, "[HORDE] Health and armor refilled!")

end


function Z_HORDEGAME:StartWave()

    self.WaveNPCsKilled = 0
    self.WaveNPCsSpawnedCount = {}
    self.WaveNPCCount = self.BaseNPCCount + self.NPCIncreaseAmount*self.WavesDone

    local startTime = GetConVar("zippyhorde_start_time"):GetInt()
    PrintMessage(HUD_PRINTCENTER, "NEW WAVE IN "..startTime.." SECONDS")
    timer.Create("ZippyHordeWaitTimer", startTime, 1, function() self:SpawnWave() end)

end


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


function Z_HORDEGAME:RemoveAllLiveNPCs()

    for _, ent in ipairs(ents.GetAll()) do
        if !ent.IsZippyHordeNPC then continue end

        ent.ZippyHorde_Dead = true -- Prevent register
        table.RemoveByValue(Z_HORDEGAME.NPCs, ent) -- Still remove from table
        ent:Remove()
    end

end


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


net.Receive("ZippyHordeGame_ForceEndWave", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if !Z_HORDEGAME.Started then return end
    if !Z_HORDEGAME.WaveActive then return end

    if timer.Exists("ZippyHordeSpawnRestTimer") then timer.Remove("ZippyHordeSpawnRestTimer") end

    Z_HORDEGAME:RemoveAllLiveNPCs()
    Z_HORDEGAME:WaveOver()

end)


hook.Add("EntityTakeDamage", "EntityTakeDamage_ZippyHorde", function( ent, dmginfo )

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if attacker.IsZippyHordeNPC or inflictor.IsZippyHordeNPC or (IsValid(inflictor) && inflictor:GetOwner().IsZippyHordeNPC) then

        if attacker.ZippyHorde_NotPositionedYet then
            -- Not positioned, cannot deal damage
            return true
        end

        local newDamage = Z_HORDEGAME:GetBasedOnStrength(dmginfo:GetDamage())
        dmginfo:SetDamage(newDamage)

    end


    if ent.ZippyHorde_NotPositionedYet then
        -- Not positioned, cannot be hurt
        return true
    end

end)


hook.Add("OnNPCKilled", "OnNPCKilled_ZippyHorde", function( npc )
    Z_HORDEGAME:RegisterDead(npc)
end)



hook.Add("PlayerNoClip", "ZippyHordeNoNoclip", function( ply, desiredState )
    if Z_HORDEGAME.Started && GetConVar("zippyhorde_no_noclip"):GetBool() then
        return false
    end
end)


hook.Add("PlayerDeath", "ZippyHordeEnd", function()

    if !Z_HORDEGAME.Started then return end
    if !GetConVar("zippyhorde_end_on_death"):GetBool() then return end
    if timer.Exists("ZippyHordeWaitTimer") then timer.Remove("ZippyHordeWaitTimer") end
    if timer.Exists("ZippyHordeSpawnRestTimer") then timer.Remove("ZippyHordeSpawnRestTimer") end

    Z_HORDEGAME:RemoveAllLiveNPCs()

    Z_HORDEGAME.Started = false

    net.Start("ZippyHordeGame_EnableButton")
    net.Broadcast()

    PrintMessage(HUD_PRINTCENTER, "GAME OVER")

end)


hook.Add("InitPostEntity", "ZippyHorde_InitPostEntity", function()
    Z_HORDEGAME.NodePositions = ZIPPYHORDEGAME_GET_NODE_POSITIONS()
end)


local function retryPosition( NPC )

    -- Position if still on its default (0;0;0) coordinates:
    NPC.ZippyHorde_NotPositionedYet = !Z_HORDEGAME:TryPositionNPC(NPC)

end


local nextTick = CurTime()
hook.Add("Tick", "ZippyHorde_Thinker", function()

    if nextTick > CurTime() then return end
    if !Z_HORDEGAME.Started then return end

    for _, NPC in ipairs(Z_HORDEGAME.NPCs) do

        if NPC.ZippyHorde_NotPositionedYet then
            retryPosition( NPC )
        end
        
        -- Freeze AI if it hasn't been positioned yet
        if NPC.ZippyHorde_NotPositionedYet && NPC:IsNPC() && !NPC:IsCurrentSchedule(SCHED_NPC_FREEZE) then
            NPC:TaskComplete()
            NPC:ClearGoal()
            NPC:ClearSchedule()
            NPC:StopMoving()
            NPC:SetMoveVelocity(vector_origin)
            NPC:SetSchedule(SCHED_NPC_FREEZE)
        end

    end

    nextTick = CurTime()+1

end)

