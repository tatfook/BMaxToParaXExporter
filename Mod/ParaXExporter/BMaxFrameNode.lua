NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockConfig.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelBone.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/vector.lua");

local Quaternion = commonlib.gettable("mathlib.Quaternion");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");
local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");


local BMaxFrameNode = commonlib.inherit(commonlib.gettable("Mod.ParaXExporter.BMaxNode"), commonlib.gettable("Mod.ParaXExporter.BMaxFrameNode"));
local vector3d = commonlib.gettable("mathlib.vector3d");
local ModelBone = commonlib.gettable("Mod.ParaXExporter.Model.ModelBone");
local Common = commonlib.gettable("Mod.ParaXExporter.Common")

function BMaxFrameNode:ctor()
	self.m_nParentIndex = -1;
	self.bone = ModelBone:new();

	self.startFrame = 0;
	self.endFrame = 0;

	self.m_nodes = {};
end

function BMaxFrameNode:init(model, x, y, z, template_id, block_data, bone_index)
	self.model = model;
	self.x = x;
	self.y = y;
	self.z = z;
	self.template_id = template_id;
	self.block_data = block_data and block_data or 0;
	self.n_index = bone_index;
	self.bone_name = nil;
	self.m_children = {};


	return self;
end

function BMaxFrameNode:GenerateStartFrame(startTime)
	local bone = self.bone;
	local tranBlock = bone.translation;
	local rotBlock =  bone.rotation;
	local scaleBlock = bone.scaling;
	tranBlock:AddKey({0, 0, 0});
	tranBlock:AddTime(startTime);
	rotBlock:AddKey(Quaternion:new():FromAngleAxis(0, self:GetAxis()));
	rotBlock:AddTime(startTime);
	scaleBlock:AddKey({1, 1, 1});
	scaleBlock:AddTime(startTime);
end
	
function BMaxFrameNode:GetBone()
	return self.bone;
end


function BMaxFrameNode:UpdatePivot(m_fScale)
	local center = self.model.m_centerPos;
	local x, y, z = self.x - center[1] + BlockConfig.g_blockSize * 0.5, self.y + BlockConfig.g_blockSize * 0.5, self.z - center[3] + BlockConfig.g_blockSize * 0.5;
	local pivot =  vector3d:new({x,y,z});
	self.bone.bUsePivot = true;
	self.bone.pivot = pivot:MulByFloat(m_fScale);
	self.bone.flags = 0;
end

function BMaxFrameNode:GetParent()
	if (self.m_nParentIndex >= 0) then
		local pParent = self.model.m_nodes[self.m_nParentIndex];
		if pParent ~= nil then
			return pParent;
		end
	end
	return nil;
end

function BMaxFrameNode:GetColor()
	if self.m_color ~= -1 then
		return self.m_color;
	end
	
	local pParentNode = self:GetParent();
	local mySide, myLevelData = self:GetBoneSideAndLevelData(self.block_data);
	local myOpSide = BlockDirection:GetOpSide(mySide);

	for i = 0, 5 do
		local side = BlockDirection:GetBlockSide((myOpSide + i) % 6);
		if side ~= mySide or pParentNode == nil then
			local neighbourNode = self:GetNeighbour(side);
			if neighbourNode and not neighbourNode:HasBoneWeight() and neighbourNode.template_id ~= BMaxModel.BoneBlockId then
				self.m_color = neighbourNode:GetColor();
				return self.m_color;
			end
		end
	end

	if pParentNode then 
		self.m_color = pParentNode:GetColor();
	end

	return self.m_color;
end

function BMaxFrameNode:AutoSetBoneName()
	if self.bone_name == nil then
		local bone_name = "bone";
		local pChild = self;
		local nSide = -1;
		local nMultiChildParentCount = 0;
		local nParentCount = 0;

		while pChild do
			local pParent = pChild:GetParent();
			if (pParent and #pParent.m_children > 1) then
				nMultiChildParentCount = nMultiChildParentCount + 1;
				if pParent.z > pChild.z then
					nSide = 1;
				elseif pParent.z < pChild.z then
					nSide = 0;
				end
			end
			pChild = pParent;
			nParentCount = nParentCount + 1;
		end
		
		if nParentCount > 0 then
			nParentCount = nParentCount - 1;
		end

		if nSide == 0 then
			bone_name = bone_name.."_left";
		elseif nSide == 1 then
			bone_name =  bone_name.."_right";
		end

		if nSide >= 0 and nMultiChildParentCount > 1 then
			bone_name =  bone_name.."_mp"..nMultiChildParentCount;
		end

		bone_name = bone_name.."_p"..nParentCount;

		local parent = self:GetParent();
		if parent and #parent.m_children == 1 then
			parent = parent:GetParent();

			if parent and #parent.m_children == 1 then
				parent = parent:GetParent();
		
				if parent and #parent.m_children > 1 then
					parent = parent:GetParent();
					bone_name = bone_name.."_IK";		
				end	
			end
		end

		local nCount = self.model:GetNameAppearanceCount(bone_name);
		if (nCount > 0) then 
			bone_name = bone_name.."_"..nCount;
		end

		self.bone_name = bone_name;
		--print("bone_name",  self.bone_name, self:GetBoneIndex());
	end
end

-- @return side, levelData;
function BMaxFrameNode:GetBoneSideAndLevelData(blockData)
	blockData = blockData or 0;
	local side = BlockDirection:GetBlockSide(mathlib.bit.band(blockData, 0xf))
	local levelData = mathlib.bit.rshift(blockData, 8)
	return side, levelData;
end

-- this function should match EntityBlockBone:GetParentBone() in paracraft. 
function BMaxFrameNode:GetParentBone(bRefresh)
	if bRefresh then

		self:SetParentIndex(-1);

		local cx = self.x;
		local cy = self.y;
		local cz = self.z;

		local side, levelData = self:GetBoneSideAndLevelData(self.block_data);
		local offset = BlockDirection:GetOffsetBySide(side);

		local dx = offset.x;
		local dy = offset.y;
		local dz = offset.z;
		local maxBoneLength = self.model.MaxBoneLengthHorizontal;
		if dy ~= 0 then
			maxBoneLength = self.model.MaxBoneLengthVertical;
		end
		--print("origin", self:GetBoneIndex(), self.block_data, offset.x, offset.y, offset.z);
		for i = 1, maxBoneLength do
			local x = cx + dx * i;
			local y = cy + dy * i;
			local z = cz + dz * i;
			
			local parent = self.model:GetFrameNode(x, y, z);
			if (parent) then
				local parentSide, parentLevelData = self:GetBoneSideAndLevelData(parent.block_data);
				if(parentLevelData == levelData) then
					local opSide = BlockDirection:GetOpSide(parentSide);
					-- if two bones are opposite to each other, the lower one is the parent
					if opSide ~= side or (dx + dy + dz) < 0 then
						-- prevent acyclic links
						if (not self:IsAncestorOf(parent)) then
							self:SetParentIndex(parent:GetIndex());
						end
					end
				end
				break;
			end
		end

		-- search for closest higher level bones
		if(not self:HasParent()) then
			local maxParentDistance = 10;
			local maxParentDistanceSq = maxParentDistance^2;
			local candidateParent;
			local candidateLevel = 9999999;
			local candidateDistSq = 9999999;
			for _, node in ipairs(self.model:GetBones()) do
				local x, y, z = node.x, node.y, node.z;
				local distSq = (x-cx)^2 +(y-cy)^2 + (z-cz)^2  
				if(distSq <= maxParentDistanceSq and distSq > 0) then
					local parentSide, parentLevelData = self:GetBoneSideAndLevelData(node.block_data)
					if(parentLevelData > levelData) then
						if((candidateLevel > parentLevelData) or ((candidateLevel == parentLevelData) and (candidateDistSq > distSq))) then
							candidateLevel = parentLevelData
							candidateDistSq = distSq
							candidateParent = node;
						end
					end
				end
			end
			if(candidateParent) then
				self:SetParentIndex(candidateParent:GetIndex());
			end
		end
	end
end

function BMaxFrameNode:GetBoneIndex()
	return self.n_index;
end

function BMaxFrameNode:SetParentIndex(index)
	self.m_nParentIndex = index;

	local parent = self:GetParent();
	if (parent) then
		parent:AddChild(self);
		self.bone.parent = parent:GetBoneIndex();
	else
		self.bone.parent = -1;
	end
end

function BMaxFrameNode:AddChild(child)
	local nIndex = child:GetIndex();
	for k, childIndex in ipairs(self.m_children) do
		if (childIndex == nIndex) then
			return;
		end
	end
	table.insert(self.m_children, nIndex);
end

function BMaxFrameNode:GetParent()
	if (self.m_nParentIndex >= 0)then
		
		local parent = self.model.m_nodes[self.m_nParentIndex];
		if (parent) then
			return parent;
		end
	end
	return nil;
end

function BMaxFrameNode:IsAncestorOf(pChild)
	while (pChild) do
		if (pChild == self) then
			return true;
		elseif (not pChild:HasParent()) then
			return false;
		else
			pChild = pChild:GetParent();
		end
	end
    return false;
end

function BMaxFrameNode:HasParent()
	return self.m_nParentIndex >= 0;
end

function BMaxFrameNode:AddBoneAnimation(startTime, endTime, time, data, range, anim)

	local block = nil;
	if anim == "rot" then
		block = self.bone.rotation;	
	elseif anim == "trans" then
		block = self.bone.translation;
	elseif anim == "scale" then
		block = self.bone.scaling;
	end

	local currentRange = block.nRanges;
	if block then
		for k , v in ipairs(data) do
			if time[k] and data[k] then
				self.bone:AddAnimationFrame(block, startTime + time[k], data[k]);
			end
		end
	end
end

function BMaxFrameNode:ToBoneNode()
	return self;
end

function BMaxFrameNode:IsBoneNode()
	return true;
end

function BMaxFrameNode:GetBoneSide()
	return BlockDirection:GetBlockSide(self.block_data);
end

function BMaxFrameNode:GetAxis()
	local mySide = self:GetBoneSide();
	local offset = BlockDirection:GetOffsetBySide(BlockDirection:GetOpSide(mySide));
	return vector3d:new(offset.x, offset.y, offset.z);
end