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
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorBlock.lua");
local BlockModel = commonlib.gettable("Mod.ParaXExporter.BlockModel");
local BlockCommon = commonlib.gettable("Mod.ParaXExporter.BlockCommon");
local Color = commonlib.gettable("System.Core.Color");
local ItemColorBlock =  commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock");
local lshift = mathlib.bit.lshift;

local BMaxNode = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxNode"));


function BMaxNode:ctor()
	self.neighborBlocks = {};
end

function BMaxNode:init(model, x,y,z,template_id, block_data)
	self.model = model;
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
	neighborBlocks[BlockCommon.rbp_center] = self;
	self:QueryNeighborBlockData(neighborBlocks, 1, nNearbyBlockCount - 1);
	local temp_cube = BlockModel:new():InitCube();
	local dx = self.x - self.model.m_centerPos[1];
	local dy = self.y - self.model.m_centerPos[2];
	local dz = self.z - self.model.m_centerPos[3];
	temp_cube:OffsetPosition(dx,dy,dz);

	for face = 0, 5 do
		local pCurBlock = neighborBlocks[BlockCommon.RBP_SixNeighbors[face]];
		if(not pCurBlock)then
			cube:AddFace(temp_cube, face);
		end
	end

	local color = self:GetColor();
	cube:SetColor(color);

	return cube;
end

function BMaxNode:QueryNeighborBlockData(pBlockData,nFrom,nTo)
	local neighborOfsTable = BlockCommon.NeighborOfsTable;

	for i = nFrom,nTo do
		local xx = self.x + neighborOfsTable[i].x;
		local yy = self.y + neighborOfsTable[i].y;
		local zz = self.z + neighborOfsTable[i].z;

		local pBlock = self.model:GetNode(xx,yy,zz);
		local index = i - nFrom + 1;
		pBlockData[index] = pBlock;
	end
end

function BMaxNode:GetColor()
	if (self.block_data) then
		return ItemColorBlock:DataToColor(self.block_data);
	end
end

function BMaxNode:GetIndex()
	return self.x + lshift(self.z, 8) + lshift(self.y, 16);
end

function BMaxNode:ToBoneNode()
	return nil;
end
