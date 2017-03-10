--[[
Title: bmax node
Author(s): LiXizhi
Date: 2015/12/4
Desc: a single bmax cube node
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/STLExporter/BMaxNode.lua");
local BMaxNode = commonlib.gettable("Mod.STLExporter.BMaxNode");
local node = BMaxNode:new();
------------------------------------------------------------
]]

NPL.load("(gl)Mod/ParaXExporter/BlockModel.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockCommon.lua");
local BlockModel = commonlib.gettable("Mod.ParaXExporter.BlockModel");
local BlockCommon = commonlib.gettable("Mod.ParaXExporter.BlockCommon");

local BMaxNode = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxNode"));

function BMaxNode:ctor()
	self.neighborBlocks = {};
end

function BMaxNode:init(x,y,z,template_id, block_data)
	self.x = x;
	self.y = y;
	self.z = z;
	self.template_id = template_id;
	self.block_data = block_data;
	return self;
end

function BMaxNode:TessellateBlock()

	local cube = BlockModel:new();
	local nNearbyBlockCount = 27;
	local neighborBlocks = {};
	neighborBlocks[BlockCommon.rbp_center] = node;
	self:QueryNeighborBlockData(x, y, z, neighborBlocks, 1, nNearbyBlockCount - 1);
	local temp_cube = BlockModel:new():InitCube();
	local dx = node.x - self.m_centerPos[1];
	local dy = node.y - self.m_centerPos[2];
	local dz = node.z - self.m_centerPos[3];
	temp_cube:OffsetPosition(dx,dy,dz);

	for face = 0, 5 do
		local pCurBlock = neighborBlocks[BlockCommon.RBP_SixNeighbors[face]];
		if(not pCurBlock)then
			cube:AddFace(temp_cube, face);
		end
	end
	return cube;

end
	
function BMaxNode:QueryNeighborBlockData(x,y,z,pBlockData,nFrom,nTo)
	local neighborOfsTable = BlockCommon.NeighborOfsTable;
	local node = self:GetNode(x, y, z);
	if(not node)then return end
	
	for i = nFrom,nTo do
		local xx = x + neighborOfsTable[i].x;
		local yy = y + neighborOfsTable[i].y;
		local zz = z + neighborOfsTable[i].z;

		local pBlock = self:GetNode(xx,yy,zz);
		local index = i - nFrom + 1;
		pBlockData[index] = pBlock;
	end
end
