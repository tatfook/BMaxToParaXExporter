NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockModel.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxFrameNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxAnimGenerator.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockConfig.lua");
NPL.load("(gl)Mod/ParaXExporter/ParaXModel.lua");

local BMaxAnimGenerator = commonlib.gettable("Mod.ParaXExporter.BMaxAnimGenerator");
local BlockTypes = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local BMaxNode = commonlib.gettable("Mod.ParaXExporter.BMaxNode");
local BMaxFrameNode = commonlib.gettable("Mod.ParaXExporter.BMaxFrameNode");
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");
local ParaXModel = commonlib.gettable("Mod.ParaXExporter.ParaXModel");
local BlockModel = commonlib.gettable("Mod.ParaXExporter.BlockModel");

local BMaxParser = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxParser"));

function BMaxParser:ctor()
	self.anim_generator = nil;
	self.m_bAutoScale = true;

	self.m_bones = {};
	self.m_pAnimGenerator = nil;
	self.m_blockAABB = nil;
	self.m_centerPos = nil;
	self.m_fScale = nil;

	self.paraXModel = ParaXModel:new();
end

-- public: load from file
-- @param bmax_filename: load from *.bmax file
function BMaxParser:Load(bmax_filename)
	if(not bmax_filename)then return end
	local xmlRoot = ParaXML.LuaXML_ParseFile(bmax_filename);

	self:ParseHeader(xmlRoot);
	local blocks = self:ParseBlocks(xmlRoot);
	print("blocks", blocks);
	if(blocks) then
		return self:LoadFromBlocks(blocks);
	end
end


function BMaxParser:ParseHeader(xmlRoot)
	if(not xmlRoot)then return end
	local blocktemplate = xmlRoot[1];
	if(blocktemplate and blocktemplate.attr and blocktemplate.attr.auto_scale and (blocktemplate.attr.auto_scale == "false" or blocktemplate.attr.auto_scale == "False"))then
		self.m_bAutoScale = false;	
	end
end


function BMaxParser:ParseBlocks(xmlRoot)
	if(not xmlRoot)then return end
	local node;
	local result;
	for node in commonlib.XPath.eachNode(xmlRoot, "/pe:blocktemplate/pe:blocks") do
		--find block node
		result = node;
		break;
	end
	if(not result)then return end
	return commonlib.LoadTableFromString(result[1]);
end

function BMaxParser:LoadFromBlocks(blocks)
	self:ParseBlocksInternal(blocks)
	--self:ParseBlockFrames();
	self:ParseVisibleBlocks();
end

function BMaxParser:ParseBlocksInternal(blocks)
	local aabb = ShapeAABB:new();

	local has_bone = false;
	local nodes = {};
	for k, block_item in ipairs(blocks) do
		local x = block_item[1];
		local y = block_item[2];
		local z = block_item[3];
		local template_id = block_item[4];
		local block_data = block_item[5];

		aabb:Extend(x, y, z);
		
		if template_id == 253 then
			has_bone = true;
			local bone_index = #self.m_bones;
			local frame_node = BMaxFrameNode:new():init(self, x, y, z, template_id, block_data, bone_index);
			self.m_bones[bone_index + 1] = frame_node;
			nodes[#nodes + 1] = frame_node;

			local entity_data = block_item[6];
			
			local bone_name = self:GetAnimGenerator():ParseParameters(entity_data, nBoneIndex);
			
			if entity_data[1] ~= nil then 
				local cmd = entity_data[1];

				if cmd[1] ~= nil then
					if bone_name ~= nil then
						frame_node:GetBone():SetName(bone_name);
					end
				end
			end
		else 
			local node = BMaxNode:new():init(x, y, z, template_id, block_data);
			nodes[#nodes + 1] = node;
		end
	end


	self.m_blockAABB = aabb;

	local x, y, z = self.m_blockAABB:GetExtendValues();
	local width = x * 2;
	local height = y * 2;
	local depth = z * 2;

	self.m_centerPos = self.m_blockAABB:GetCenter();
	self.m_centerPos.y = 0;
	self.m_centerPos.x = (width + 1) * 0.5;
	self.m_centerPos.z = (depth + 1) * 0.5;

	local offset_x = self.m_blockAABB:GetMin()[1];
	local offset_y = self.m_blockAABB:GetMin()[2];
	local offset_z = self.m_blockAABB:GetMin()[3];

	for key, node in ipairs(nodes) do
		node.x = node.x - offset_x;
		node.y = node.y - offset_y;
		node.z = node.z - offset_z;
		self.paraXModel:InsertNode(node);
	end

	if self.m_bAutoScale then
		local fMaxLength = math.max(height, width, depth) + 1;
		self.m_fScale = self:CalculateScale(fMaxLength);
		print("m_fScale", self.m_fScale);

		if has_bone then
			self.m_fScale = self.m_fScale * 2;
		end
	end
end

function BMaxParser:GetAnimGenerator()
	if(self.m_pAnimGenerator == nil) then 
		self.m_pAnimGenerator = BMaxAnimGenerator:new();
	end

	return self.m_pAnimGenerator;
end

function BMaxParser:CalculateScale(length)
	local nPowerOf2Length = 2 ^ math.floor(length + 0.1);
	return BlockConfig.g_blockSize / nPowerOf2Length;
end

function BMaxParser:ParseBlockFrames()
	for k, bone in ipairs(self.m_bones) do 
		bone:UpdatePivot();
		bone:GetParentBone(true);
	end
end

function BMaxParser:ParseVisibleBlocks()
	local block_models = {};

	for _, node in ipairs(self.paraXModel.m_nodes) do
		print(node.x, node.y, node.z);
		block_models[#block_models + 1] = node:TessellateBlock();
	end
end

function BMaxParser:FillVerticesAndIndices()
	
end

function BMaxParser:FillParaXModelData()
	self:FillVerticesAndIndices();
end


--[[void BMaxParser::ParseBlockFrames()
	{
		// calculate parent bones
		for (auto bone : m_bones)
			bone->UpdatePivot();
		// calculate parent bones
		for (auto bone : m_bones)
			bone->GetParentBone(true);
		// set bone name
		for (auto bone : m_bones)
			bone->AutoSetBoneName();

		GetAnimGenerator()->FillAnimations();

		// create animation
		//CreateDefaultAnimations();
	}--]]