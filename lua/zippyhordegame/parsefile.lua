local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 4096

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2

---------------------------------------------------------------------------------------------------------=#
local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end
---------------------------------------------------------------------------------------------------------=#
local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end
---------------------------------------------------------------------------------------------------------=#
local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end
---------------------------------------------------------------------------------------------------------=#
local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end
---------------------------------------------------------------------------------------------------------=#
function HordeSilverlanParseFile(f)
	f = file.Open(f,"rb","GAME")
		if(!f) then return end
		local ainet_ver = ReadInt(f)
		local map_ver = ReadInt(f)
		local nodegraph = {
			ainet_version = ainet_ver,
			map_version = map_ver
		}
		if(ainet_ver != AINET_VERSION_NUMBER) then
			MsgN("Unknown graph file")
			return
		end
		local numNodes = ReadInt(f)
		if(numNodes > MAX_NODES || numNodes < 0) then
			MsgN("Graph file has an unexpected amount of nodes")
			return
		end
		local nodes = {}
		for i = 1,numNodes do
			local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
			local yaw = f:ReadFloat()
			local flOffsets = {}
			for i = 1,NUM_HULLS do
				flOffsets[i] = f:ReadFloat()
			end
			local nodetype = f:ReadByte()
			local nodeinfo = ReadUShort(f)
			local zone = f:ReadShort()
			
			local node = {
				pos = v,
				yaw = yaw,
				offset = flOffsets,
				type = nodetype,
				info = nodeinfo,
				zone = zone,
				neighbor = {},
				numneighbors = 0,
				link = {},
				numlinks = 0
			}
			table.insert(nodes,node)
		end
		local numLinks = ReadInt(f)
		local links = {}
		for i = 1,numLinks do
			local link = {}
			local srcID = f:ReadShort()
			local destID = f:ReadShort()
			local nodesrc = nodes[srcID +1]
			local nodedest = nodes[destID +1]
			if(nodesrc && nodedest) then
				table.insert(nodesrc.neighbor,nodedest)
				nodesrc.numneighbors = nodesrc.numneighbors +1
				
				table.insert(nodesrc.link,link)
				nodesrc.numlinks = nodesrc.numlinks +1
				link.src = nodesrc
				link.srcID = srcID +1
				
				table.insert(nodedest.neighbor,nodesrc)
				nodedest.numneighbors = nodedest.numneighbors +1
				
				table.insert(nodedest.link,link)
				nodedest.numlinks = nodedest.numlinks +1
				link.dest = nodedest
				link.destID = destID +1
			else MsgN("Unknown link source or destination " .. srcID .. " " .. destID) end
			local moves = {}
			for i = 1,NUM_HULLS do
				moves[i] = f:ReadByte()
			end
			link.move = moves
			table.insert(links,link)
		end
		local lookup = {}
		for i = 1,numNodes do
			table.insert(lookup,ReadInt(f))
		end
	f:Close()
	nodegraph.nodes = nodes
	nodegraph.links = links
	nodegraph.lookup = lookup
	return nodegraph
end
---------------------------------------------------------------------------------------------------------=#
function ZIPPYHORDEGAME_GET_NODE_POSITIONS()
	local nodegraph = HordeSilverlanParseFile("maps/graphs/" .. game.GetMap() .. ".ain")

	if !nodegraph then
		return {}
	end

	local node_positions = {}

	for _, node in pairs(nodegraph.nodes) do
		local trStart = node.pos + Vector(0, 0, 30)

		local tr = util.TraceLine({
			start = trStart,
			endpos = trStart - Vector(0, 0, 10000),
			mask = MASK_NPCWORLDSTATIC,
		})

		local posFinal = tr.HitPos + tr.HitNormal*15

		if bit.band( util.PointContents(posFinal), CONTENTS_WATER ) == CONTENTS_WATER then
			continue
		end

		table.insert(node_positions, posFinal)
	end

	return node_positions
end
---------------------------------------------------------------------------------------------------------=#