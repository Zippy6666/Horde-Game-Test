HORDE_PANEL = {}
HORDE_TRYING_TO_START = false

local HORDE_MENU = {}
HORDE_MENU.Spawnmenu_LastCat = 1



local function startButton()

    if HORDE_TRYING_TO_START then return end
    HORDE_TRYING_TO_START = true

    net.Start("ZippyHordeGame_Start")
    net.WriteInt(HORDE_PANEL.waveCount:GetValue(), 32)
    net.WriteInt(HORDE_PANEL.npcAmount:GetValue(), 32)
    net.WriteInt(HORDE_PANEL.increasePerWave:GetValue(), 32)
    net.WriteFloat(HORDE_PANEL.strength:GetValue())
    net.WriteFloat(HORDE_PANEL.strengthIncrease:GetValue())
    net.SendToServer()

end


local function endButton()

    net.Start("ZippyHordeGame_ForceEnd")
    net.SendToServer()

end


local function endWaveButton()

    net.Start("ZippyHordeGame_ForceEndWave")
    net.SendToServer()

end


local function addNPCButton()

    HORDE_MENU:GmodSpawnmenuSelect( "NPC", function( npcClass )

        net.Start("ZippyHordeGame_NewNPC")
        net.WriteString(npcClass)
        net.WriteString(HORDE_MENU:GetSelectedPreset())
        net.SendToServer()

    end, true )

end


local function addPresetButton()

    local frame = vgui.Create("DFrame")
    local width = 350
    local height = 110
    frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    frame:SetSize(width, height)
    frame:SetTitle("Preset Name")
    frame:MakePopup()

    local entry = vgui.Create("DTextEntry", frame)
    entry:SetText("a preset")

    local function finish()

        if entry:GetText() == "default" then return end

        net.Start("ZippyHorde_NewPreset")
        net.WriteString(entry:GetText())
        net.SendToServer()

        frame:Close()

    end

    -- Finish rename when we press enter:
    frame.OnKeyCodePressed = function( _,key )
        if (key == KEY_ENTER) then finish() end
    end

    local text = vgui.Create("DLabel", frame)
    text:SetText("New preset name:")
    text:Dock(TOP)

    local button = vgui.Create("DButton",frame)
    button:Dock(BOTTOM)
    button:SetText("Save Preset")
    button.DoClick = function()
        finish()
    end

    entry:Dock(FILL)
    entry:DockMargin(0,3,0,6)

end


local function removePresetButton()

    local presetName = HORDE_MENU:GetSelectedPreset()

    if !presetName then return end
    if presetName == "default" then return end

    local width = 300
    local height = 80

    local frame = vgui.Create("DFrame")
    frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    frame:SetSize(width, height)
    frame:SetTitle("Remove Preset")
    frame:MakePopup()

    -- Text moment:
    local text = vgui.Create("DLabel", frame)
    text:SetText("Remove \""..presetName.."\" permanently?")
    text:Dock(TOP)

    -- Button that removes the group:
    local remove_button = vgui.Create("DButton",frame)
    remove_button:Dock(BOTTOM)
    remove_button:SetText("Remove")
    remove_button.DoClick = function()

        net.Start("ZippyHorde_RemovePreset")
        net.WriteString(presetName)
        net.SendToServer()

        frame:Close()

    end

end


local function NPC_List_AddLine( npcClass, npcData )

    local name = npcData.spawnmenuData.Name
    local chance = "1/"..npcData.chance
    local start = npcData.waveStart or 1
    local _end = npcData.waveEnd or "Never"
    local maxPerWave = npcData.maxPerWave
    local maxAlive = npcData.maxAlive
    local maxDisplayed = (maxPerWave && maxAlive && math.min(maxAlive, maxPerWave))
    || maxPerWave || maxAlive || "inf"

    local line = HORDE_MENU.NPC_List:AddLine(name, npcClass, chance, maxDisplayed)

    line.OnRightClick = function()

        local options = DermaMenu()

        options:AddOption("Remove", function()

            net.Start("ZippyHorde_RemoveNPC")
            net.WriteString(npcClass)
            net.WriteString(HORDE_MENU:GetSelectedPreset())
            net.SendToServer()

        end)

        options:AddOption("Edit", function()
            HORDE_MENU:NPC_Edit(npcClass, npcData)
        end)

        options:Open()

    end

end


local function presetBoxChooseOption( _, _, _string )

    net.Start("ZippyHorde_SelectPreset")
    net.WriteString(_string)
    net.SendToServer()

    HORDE_MENU.LastPresetChoice = _string

end


net.Receive("ZippyHordeGame_RefreshNPCList", function()

    HORDE_MENU.NPC_List:Clear()

    for npcClass, npcData in pairs(net.ReadTable()) do
        NPC_List_AddLine( npcClass, npcData )
    end

end)


net.Receive("ZippyHorde_SendPresetsToClient", function()

    HORDE_MENU.PresetBox:Clear()

    local Presets = net.ReadTable()
    local choices = {}

    for _, preset in ipairs(Presets) do

        local choice = string.Left(preset, string.len(preset) - 5)

        HORDE_MENU.PresetBox:AddChoice(choice)
        choices[choice] = true

    end

    if choices[HORDE_MENU.LastPresetChoice] then
        HORDE_MENU.PresetBox:ChooseOption(HORDE_MENU.LastPresetChoice)
    end

end)


net.Receive("ZippyHordeGame_GameStartConfirmed", function()

    for _, Panel in pairs(HORDE_PANEL) do
        Panel:SetEnabled(false)
    end

    HORDE_TRYING_TO_START = false

end)


net.Receive("ZippyHordeGame_EnableButton", function()

    for _, Panel in pairs(HORDE_PANEL) do
        Panel:SetEnabled(true)
    end

end)


hook.Add("PopulateToolMenu", "PopulateToolMenu_HordeGameTest", function() spawnmenu.AddToolMenuOption("Utilities", "AI", "Horde", "Horde", "", "", function(panel)

    if !LocalPlayer():IsSuperAdmin() then
        panel:Help("You don't have permission.")
        return
    end

    -- PRESETS --
    panel:Help("\nPresets:")

    HORDE_MENU.PresetBox = vgui.Create("DComboBox", panel)
    HORDE_MENU.PresetBox:SetHeight(25)
    HORDE_MENU.PresetBox:Dock(TOP)
    HORDE_MENU.PresetBox:DockMargin(10, 10, 10, 10)
    HORDE_MENU.PresetBox.OnSelect = presetBoxChooseOption

    local buttonAddPreset = panel:Button("Save Preset")
    buttonAddPreset.DoClick = addPresetButton

    local buttonRemovePreset = panel:Button("Remove Preset")
    buttonRemovePreset.DoClick = removePresetButton

    net.Start("ZippyHorde_SelectPreset")
    net.WriteString("default")
    net.SendToServer()

    HORDE_MENU.LastPresetChoice = "default"

    net.Start("ZippyHorde_GetPresets")
    net.SendToServer()
    ------------------------------------------------------=#

    -- NPC LIST --
    panel:Help("\nNPC List:")

    HORDE_MENU.NPC_List = vgui.Create("DListView", panel)
    HORDE_MENU.NPC_List:SetHeight(200)
    HORDE_MENU.NPC_List:Dock(TOP)
    HORDE_MENU.NPC_List:DockMargin(10, 10, 10, 10)
    HORDE_MENU.NPC_List:AddColumn("NPC")
    HORDE_MENU.NPC_List:AddColumn("CLS")
    HORDE_MENU.NPC_List:AddColumn("1/X")
    HORDE_MENU.NPC_List:AddColumn("MAX")

    local buttonAddNPC = panel:Button("New NPC")
    buttonAddNPC.DoClick = addNPCButton
    ------------------------------------------------------=#

    -- WAVES --
    HORDE_PANEL.waveCount = panel:NumberWang("Waves:", nil, 1, math.huge, 0)
    HORDE_PANEL.waveCount:Dock(TOP)
    HORDE_PANEL.waveCount:SetValue(10)
    ------------------------------------------------------=#

    -- NPC COUNT --
    panel:Help("\nNPC Count:")

    HORDE_PANEL.npcAmount = panel:NumSlider("Start", nil, 1, 20, 0)
    HORDE_PANEL.npcAmount:SetValue(15)
    HORDE_PANEL.increasePerWave = panel:NumSlider("Increase Per Wave", nil, 0, 20, 0)
    HORDE_PANEL.increasePerWave:SetValue(5)
    ------------------------------------------------------=#

    -- NPC STRENGTH --
    panel:Help("\nNPC Strenght:")

    HORDE_PANEL.strength = panel:NumSlider("Start Percentage", nil, 0, 2, 2)
    HORDE_PANEL.strength:SetValue(0.75)
    HORDE_PANEL.strengthIncrease = panel:NumSlider("Percent Added Per Wave", nil, 0, 2, 2)
    HORDE_PANEL.strengthIncrease:SetValue(0.05)
    ------------------------------------------------------=#

    -- CONTROLS --
    panel:Help("\nControls:")

    local buttonStart = panel:Button("Start Horde Game")
    buttonStart.DoClick = startButton
    table.insert(HORDE_PANEL, buttonStart)

    local buttonEnd = panel:Button("End Current Wave")
    buttonEnd.DoClick = endWaveButton

    local buttonEndWave = panel:Button("End Horde Game")
    buttonEndWave.DoClick = endButton
    ------------------------------------------------------=#

    -- Settings --
    panel:Help("\nSpawning:")
    panel:NumSlider("Max NPCs", "zippyhorde_max_spawned", 1, 200, 0)
    panel:NumSlider("Max Distance", "zippyhorde_spawndist", 250, 8000, 0)
    panel:NumSlider("Min Distance", "zippyhorde_spawndist_min", 250, 8000, 0)
    panel:CheckBox("Teleport", "zippyhorde_teleport")
    panel:ControlHelp("Teleport NPCs that have been outside the players' view for some time.")
    panel:CheckBox("VisCheck", "zippyhorde_vischeck")
    panel:ControlHelp("Spawn NPCs out of players sight.")
    panel:CheckBox("Use Nodes", "zippyhorde_use_nodes")
    panel:ControlHelp("Use the nodegraph to improve spawn placement if available.")

    panel:Help("\nRules:")
    panel:CheckBox("Refill Health", "zippyhorde_refill_health")
    panel:CheckBox("End On Death", "zippyhorde_end_on_death")
    panel:CheckBox("No Noclip", "zippyhorde_no_noclip")
    panel:NumSlider("Wave Rest Time", "zippyhorde_start_time", 1, 60, 0)
    panel:CheckBox("Seek Out Players", "zippyhorde_chase_player")
    panel:ControlHelp("Walk towards player position even though they haven't been seen yet.")
    panel:CheckBox("Run Seek Out", "zippyhorde_run_chase")
    panel:ControlHelp("Run when seeking out player.")

    panel:Help("\nVisuals:")
    panel:CheckBox("Teleport FX (SERVER)", "zippyhorde_teleport_fx")
    panel:CheckBox("Show Halos (CLIENT)", "zippyhorde_halo_enable")
    -- panel:CheckBox("Halo Blur Amount (CLIENT)", "zippyhorde_halo_blur")
    ------------------------------------------------------=#

end) end)


function HORDE_MENU:GetSelectedPreset()
    return self.PresetBox:GetSelected() or self.LastPresetChoice or "default"
end


function HORDE_MENU:NPC_Edit( npcClass, npcData )

    local width = 200
    local height = 305
    self.EditNPCFrame = vgui.Create("DFrame")
	self.EditNPCFrame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
	self.EditNPCFrame:SetSize(width, height)
    self.EditNPCFrame:SetTitle(npcData.spawnmenuData.Name)
	self.EditNPCFrame:MakePopup()

    local text

    -- CHANCE --
    text = vgui.Create("DLabel", self.EditNPCFrame)
    text:SetText("Chance (1/x):")
    text:Dock(TOP)

    local chanceWang = vgui.Create("DNumberWang", self.EditNPCFrame)
    chanceWang:Dock(TOP)
    chanceWang:SetValue(npcData.chance)
    -------------------------------------=#

    -- WAVE START --
    text = vgui.Create("DLabel", self.EditNPCFrame)
    text:SetText("Start:")
    text:Dock(TOP)

    local startWang = vgui.Create("DNumberWang", self.EditNPCFrame)
    startWang:Dock(TOP)
    
    if npcData.waveStart then
        startWang:SetValue(npcData.waveStart)
    else
        startWang:SetValue(1)
    end
    -------------------------------------=#

    -- WAVE END --
    text = vgui.Create("DLabel", self.EditNPCFrame)
    text:SetText("End:")
    text:Dock(TOP)

    local endWang = vgui.Create("DNumberWang", self.EditNPCFrame)
    endWang:Dock(TOP)
    endWang.OnValueChanged = function( _, value )
        if value == 0 then endWang:SetText("Never") end
    end

    if npcData.waveEnd then
        endWang:SetValue(npcData.waveEnd)
    else
        endWang:SetText("Never")
    end
    -------------------------------------=#

    -- MAX PER WAVE --
    text = vgui.Create("DLabel", self.EditNPCFrame)
    text:SetText("Max per Wave:")
    text:Dock(TOP)

    local limitWang = vgui.Create("DNumberWang", self.EditNPCFrame)
    limitWang:Dock(TOP)
    limitWang.OnValueChanged = function( _, value )
        if value == 0 then limitWang:SetText("No Limit") end
    end

    if npcData.maxPerWave then
        limitWang:SetValue(npcData.maxPerWave)
    else
        limitWang:SetText("No Limit")
    end
    -------------------------------------=#

    -- MAX ALIVE --
    text = vgui.Create("DLabel", self.EditNPCFrame)
    text:SetText("Max Alive:")
    text:Dock(TOP)

    local limitAliveWang = vgui.Create("DNumberWang", self.EditNPCFrame)
    limitAliveWang:Dock(TOP)
    limitAliveWang.OnValueChanged = function( _, value )
        if value == 0 then limitAliveWang:SetText("No Limit") end
    end

    if npcData.maxAlive then
        limitAliveWang:SetValue(npcData.maxAlive)
    else
        limitAliveWang:SetText("No Limit")
    end
    -------------------------------------=#

    -- CUSTOM WEAPONS --
    -- Text that shows whether or not the NPC has custom weapons:
    local customweapon_help = vgui.Create("DLabel",self.EditNPCFrame)
    customweapon_help:Dock(TOP)
    local function update_customweapon_text() customweapon_help:SetText("Custom Weapons: " .. tostring((npcData.CustomWeapons && true) or false)) end
    update_customweapon_text()
    -- Open Weapon Menu:
    local weaponmenu_button = vgui.Create("DButton", self.EditNPCFrame)
    weaponmenu_button:Dock(TOP)
    weaponmenu_button:SetText("Weapon Menu")
    weaponmenu_button.DoClick = function()
        local weaponedit_last_pos_x
        local weaponedit_last_pos_y

        if IsValid(self.WeaponMenuFrame) then
            -- "Update" panel by closing it and putting the new one at the same position as the last one.
            weaponedit_last_pos_x, weaponedit_last_pos_y = self.WeaponMenuFrame:GetPos()
            self.WeaponMenuFrame:Close()
        end

        local custom_weapons = table.Copy(npcData.CustomWeapons) or {}

        -- Weapon menu base frame:
        self.WeaponMenuFrame = vgui.Create("DFrame")
        local weaponmenu_width = 400
        local weaponmenu_height = 200
        self.WeaponMenuFrame:SetPos( weaponedit_last_pos_x or (ScrW()*0.5)-weaponmenu_width*0.5, weaponedit_last_pos_y or (ScrH()*0.5)-weaponmenu_height*0.5 )
        self.WeaponMenuFrame:SetSize(weaponmenu_width, weaponmenu_height)
        self.WeaponMenuFrame:SetTitle(npcData.spawnmenuData.Name .. " Weapons:")
        self.WeaponMenuFrame:MakePopup()

        local help = vgui.Create("DLabel", self.WeaponMenuFrame)
        local function update_help() help:SetText( (table.IsEmpty(custom_weapons) && "Empty = Default Weapons") or "*Uses Custom Weapons*" ) end

        -- List of current custom weapons:
        local weapon_list = vgui.Create("DListView", self.WeaponMenuFrame)
        local function update_weapon_list()
            for k in ipairs(weapon_list:GetLines()) do
                weapon_list:RemoveLine(k)
            end

            for _,v in ipairs(custom_weapons) do
                --weapon_list:AddLine(v.Class, "1/" .. v.Chance)
                weapon_list:AddLine(v.Class)
            end

            update_help()
        end

        -- Open spawnmenu selector to choose a new weapon that the NPC should have:
        local selectweapon_button = vgui.Create("DButton", self.WeaponMenuFrame)
        selectweapon_button:Dock(TOP)
        selectweapon_button:SetText("Add Weapon")
        selectweapon_button.DoClick = function()
            self:GmodSpawnmenuSelect("Weapon", function(weapon)
                -- Add weapon with 1/1 chance of being given:
                table.insert(custom_weapons, {Class=weapon.ClassName, Chance=1})
                -- Update weapon list when new weapon has been picked:
                update_weapon_list()
            end)
        end

        help:Dock(TOP)
        update_help()

        -- Apply new custom weapons:
        local weaponmenu_finish_button = vgui.Create("DButton", self.WeaponMenuFrame)
        weaponmenu_finish_button:Dock(BOTTOM)
        weaponmenu_finish_button:SetText("Apply Weapon Settings")
        weaponmenu_finish_button.DoClick = function()
            -- Add new custom weapons if any were given. If new custom weapon list is empty, set CustomWeapons to nil, which will make the NPC use its default weapons instead.
            if !table.IsEmpty(custom_weapons) then
                npcData.CustomWeapons = custom_weapons
            else
                npcData.CustomWeapons = nil
            end

            -- Update text that 
            update_customweapon_text()
            self.WeaponMenuFrame:Close()
        end

        -- Fill remaining space with the weapon list:
        weapon_list:Dock(FILL)
        weapon_list:AddColumn("Class")
        --weapon_list:AddColumn("Chance")
        weapon_list.OnRowRightClick = function( _, weapon_idx )
            local options = DermaMenu()

            -- Remove weapon:
            options:AddOption("Remove", function()
                table.remove(custom_weapons, weapon_idx)
                update_weapon_list()
            end)

            -- Duplicate weapon:
            options:AddOption("Duplicate", function()
                table.insert(custom_weapons, custom_weapons[weapon_idx])
                update_weapon_list()
            end)

            options:Open()
        end

        -- Update weapon list when weapon menu is opened:
        update_weapon_list()
    end
    -------------------------------------=#

    local buttonDone = vgui.Create("DButton", self.EditNPCFrame)
    buttonDone:SetText("Done")
    buttonDone:SetHeight(25)
    buttonDone:Dock(BOTTOM)
    buttonDone.DoClick = function()

        npcData.chance = chanceWang:GetValue()
        npcData.waveStart = startWang:GetValue()

        if startWang:GetValue() == 1 then
            npcData.waveStart = nil
        else
            npcData.waveStart = startWang:GetValue()
        end

        if endWang:GetText() == "Never" then
            npcData.waveEnd = nil
        else
            npcData.waveEnd = endWang:GetValue()
        end

        if limitWang:GetText() == "No Limit" then
            npcData.maxPerWave = nil
        else
            npcData.maxPerWave = limitWang:GetValue()
        end

        if limitAliveWang:GetText() == "No Limit" then
            npcData.maxAlive = nil
        else
            npcData.maxAlive = limitAliveWang:GetValue()
        end

        net.Start("ZippyHorde_EditNPC")
        net.WriteString(npcClass)
        net.WriteString(HORDE_MENU:GetSelectedPreset())
        net.WriteTable(npcData)
        net.SendToServer()

        self.EditNPCFrame:Close()

    end

end


function HORDE_MENU:GmodSpawnmenuSelect(_list, func, useKey)
    -- Table containing every item in the spawnmenu
    local spawnmenu_item_list = list.Get(_list)
    -- Data for every spawnmenu item in the current category:
    local items = {}

    -- Base frame:
    self.GmodSpawnmenuFrame = vgui.Create("DFrame")
    local width = 350
    local height = 500
	self.GmodSpawnmenuFrame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
	self.GmodSpawnmenuFrame:SetSize(width,height)
    self.GmodSpawnmenuFrame:SetTitle("Spawnmenu Select")
	self.GmodSpawnmenuFrame:MakePopup()

    -- Category select:
    local cat_box = vgui.Create("DComboBox", self.GmodSpawnmenuFrame)
    cat_box:Dock(TOP)
    -- Add all categories from the list:
    local cats = {}
    local function cat_used(cat)
        for _,v in ipairs(cats) do
            if (v == cat) then return true end
        end
    end
    for _,item in pairs(spawnmenu_item_list) do
        local cat = item.Category
        if !cat_used(cat) then
            cat_box:AddChoice(cat)
            table.insert(cats, cat)
        end
    end
    if self.Spawnmenu_LastCat <= #cats then
        cat_box:ChooseOptionID(self.Spawnmenu_LastCat)
    end
    
    -- List of spawnmenu items that can be added:
    local item_list = vgui.Create("DListView", self.GmodSpawnmenuFrame)
    item_list:Dock(FILL)
    item_list:SetMultiSelect(false)
    item_list:SetSortable(false)
    item_list:AddColumn(_list .. "s:")
    item_list.DoDoubleClick = function( _, i )
        -- Do whatever it was told to do when an item is picked, and send the item as a parameter.
        func(items[i])
        -- And then close the whole thing.
        self.GmodSpawnmenuFrame:Close()
    end
    -- Put all of the items from the selected category into the list:
    local function update_item_list()
        -- Clear item data list:
        items = {}
        -- Remove old lines:
        for k in ipairs(item_list:GetLines()) do
            item_list:RemoveLine(k)
        end
        -- Make new ones and populate item data list:
        for k,data in pairs(spawnmenu_item_list) do
            if data.Category == cat_box:GetSelected() then
                item_list:AddLine(data.Name or k)
                table.insert(items, useKey && k or data)
            end
        end

        item_list:SortByColumn(1)
    end
    -- Update directly when opening the panel:
    update_item_list()
    
    cat_box.OnSelect = function( _,i )
        self.Spawnmenu_LastCat = i
        -- Update whenever we choose a new category:
        update_item_list()
    end
end

