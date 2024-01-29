-------------------------------------------------------------------------------------=#

TOOL.AddToMenu = false
TOOL.Category = "Horde Mode"

local toolname = "Spawn Point Creator"
TOOL.Name = toolname
TOOL.Description = "Create spawn points that NPCs can spawn on."

-------------------------------------------------------------------------------------=#
if CLIENT then

    local help = "Left-click: Create a point at the postition you are looking at. Right-click: Create a point on yourself. Reload: Remove the spawn area at your position."

    language.Add("tool.zippymapspawner_areacreator.name", TOOL.Name)
    language.Add("tool.zippymapspawner_areacreator.desc", TOOL.Description)
    language.Add("tool.zippymapspawner_areacreator.0", help)

end
-------------------------------------------------------------------------------------=#
function TOOL:Deploy()

end
-------------------------------------------------------------------------------------=#
function TOOL:LeftClick( trace )

end
-------------------------------------------------------------------------------------=#
function TOOL:RightClick( trace )

end
-------------------------------------------------------------------------------------=#
function TOOL:Reload( trace )

end
-------------------------------------------------------------------------------------=#