Z_HORDE_HALO_ENTS = Z_HORDE_HALO_ENTS or {}
Z_HORDE_HALO_ENTS_ITER = Z_HORDE_HALO_ENTS_ITER or ipairs(Z_HORDE_HALO_ENTS)


net.Receive("ZippyHordeAddHalo", function()

    local ent = net.ReadEntity()

    if IsValid(ent) then
        table.InsertEntity( Z_HORDE_HALO_ENTS, ent )
    end

    Z_HORDE_HALO_ENTS_ITER = ipairs(Z_HORDE_HALO_ENTS)

end)

local blurstrenght = 8
local color_green = Color( 0, 255, 0 )
hook.Add("PreDrawHalos", "ZippyHorde", function()
    local ply = LocalPlayer()

    if IsValid(ply) && !table.IsEmpty(Z_HORDE_HALO_ENTS) then

        halo.Add( Z_HORDE_HALO_ENTS, color_green, blurstrenght, blurstrenght, 1, true, true )

    end
end)