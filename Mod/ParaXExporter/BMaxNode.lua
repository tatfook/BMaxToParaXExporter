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
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockDirection.lua");

local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockModel = commonlib.gettable("Mod.ParaXExporter.BlockModel");
local BlockCommon = commonlib.gettable("Mod.ParaXExporter.BlockCommon");
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local Color = commonlib.gettable("System.Core.Color");
local lshift = mathlib.bit.lshift;
local bor = mathlib.bit.bor;
local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");

local BMaxNode = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxNode"));

function BMaxNode:ctor()
	self.neighborBlocks = {};
	self.m_color = -1;

	self.bone_index = -1;
	self.block_model = nil;
end

function BMaxNode:init(model, x, y, z, template_id, block_data, block_content)
	self.model = model;
	self.x = x;
	self.y = y;
	self.z = z;
	self.template_id = template_id;
	self.block_data = block_data;
	self.block_content = block_content;
	return self;
end

function BMaxNode:UpdatePosition(x, y, z)
	self.x = x;
	self.y = y;
	self.z = z;
end

function BMaxNode:GetNeighbour(side)
	local offset = BlockDirection:GetOffsetBySide(side);
	local nX = self.x + offset.x;
	local nY = self.y + offset.y;
	local nZ = self.z + offset.z;
	return self.model:GetNode(nX, nY, nZ);
end 

function BMaxNode:GetNeighbourByOffset(offset)
	local nX = self.x + offset[1];
	local nY = self.y + offset[2];
	local nZ = self.z + offset[3];
	return self.model:GetNode(nX, nY, nZ);
end

function BMaxNode:TessellateBlock()

	local cube = BlockModel:new();
	local nNearbyBlockCount = 27;
	local neighborBlocks = {};
	neighborBlocks[BlockCommon.rbp_center] = self;

	self:QueryNeighborBlockData(neighborBlocks, 1, nNearbyBlockCount - 1);
	local cube = BlockModel:new():InitCube();
	local dx = self.x - self.model.m_centerPos[1];
	local dy = self.y - self.model.m_centerPos[2];
	local dz = self.z - self.model.m_centerPos[3];
	cube:OffsetPosition(dx,dy,dz);

	local aoFlags = self:CalculateCubeAO(neighborBlocks);

	local color = self:GetColor();
	for face = 0, 5 do
		local nFirstVertex = face * 4;

		local pCurBlock = neighborBlocks[BlockCommon.RBP_SixNeighbors[face]];
		--[[if #self.model.m_nodeIndexes == 1588 and self.x == 19 and self.y == 1 and self.z == 1 then
			print("node0", self.x, self.y, self.z, face, pCurBlock);
		end--]]
			
		if(not pCurBlock or pCurBlock:GetBoneIndex() ~= self.bone_index) then
			for v = 0, 3 do
				local i = nFirstVertex + v;
				--local nIndex = cube:AddVertex(temp_cube, i);
				local nShadowLevel = 0;
				if (aoFlags > 0) then
					nShadowLevel = cube:CalculateCubeVertexAOShadowLevel(i, aoFlags);
					local fShadow = (255 - nShadowLevel) / 255;

					local r, g, b = Color.DWORD_TO_RGBA(color);
					r = math.floor(fShadow * r);
					g = math.floor(fShadow * g);
					b = math.floor(fShadow * b);
					cube:SetVertexColor(i, Color.RGBA_TO_DWORD(r, g, b));
				else 
					cube:SetVertexColor(i, color);
				end
			end
			
			cube:SetFaceVisiable(face);
		end
	end

	if(cube:GetVerticesCount() > 0)then
		self.block_model = cube;
	end
end

function BMaxNode:GetCube()
	if self.block_model then
		return self.block_model;
	end

	return nil;
end

function BMaxNode:CalculateCubeAO(neighborBlocks)
	local aoFlags = 0;

	local pCurBlock = neighborBlocks[BlockCommon.rbp_pXpYpZ];
	if pCurBlock then
		aoFlags =  bor(aoFlags, BlockModel.evf_xyz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXpYpZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_Nxyz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXpYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_xyNz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXpYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_NxyNz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_topFront);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXpY];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_topLeft);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXpY];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_topRight);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pYpZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_topBack);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_LeftFront);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXpZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_leftBack);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXpZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_rightBack);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_rightFont);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXnYPz];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_xNyz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXnYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_xNyNz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXnYPz];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_NxNyz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXnYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_NxNyNz);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nYnZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_bottomFront);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nXnY];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_bottomLeft);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_pXnY];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_bottomRight);
	end

	pCurBlock = neighborBlocks[BlockCommon.rbp_nYpZ];
	if pCurBlock then
		aoFlags = bor(aoFlags, BlockModel.evf_bottomBack);
	end

	return aoFlags;
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
	if self.m_color == -1 then
		local block_template = block_types.get(self.template_id);
		self.m_color = block_template:GetBlockColor(self.x, self.y, self.z)	
	end
	return self.m_color;
end

function BMaxNode:SetColor(color)
	self.m_color = color;
end

function BMaxNode:HasBoneWeight()
	return self.bone_index >= 0;
end

function BMaxNode:GetBoneIndex()
	return self.bone_index;
end

function BMaxNode:SetBoneIndex(bone_index)
	self.bone_index = bone_index;
end

function BMaxNode:GetIndex()
	return self.x + lshift(self.z, 8) + lshift(self.y, 16);
end

function BMaxNode:ToBoneNode()
	return nil;
end

function BMaxNode:IsBoneNode()
	return false;
end