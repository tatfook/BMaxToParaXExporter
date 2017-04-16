--[[
Title: bmax model
Author(s): leio, refactored LiXizhi
Date: 2015/12/4
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/STLExporter/BMaxModel.lua");
local BMaxModel = commonlib.gettable("Mod.STLExporter.BMaxModel");
local model = BMaxModel:new();
model:Load(filename)
model:LoadFromBlocks(blocks)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/XPath.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxFrameNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxMovieBlockNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxBlockSignNode.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockCommon.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockConfig.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelGeoset.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelVertice.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelRenderPass.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelAnimation.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/ModelBone.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");

local Quaternion = commonlib.gettable("mathlib.Quaternion");
local ModelGeoset = commonlib.gettable("Mod.ParaXExporter.Model.ModelGeoset");
local ModelVertice = commonlib.gettable("Mod.ParaXExporter.Model.ModelVertice");
local ModelRenderPass = commonlib.gettable("Mod.ParaXExporter.Model.ModelRenderPass");
local ModelAnimation = commonlib.gettable("Mod.ParaXExporter.Model.ModelAnimation");
local ModelBone = commonlib.gettable("Mod.ParaXExporter.Model.ModelBone");
local BlockCommon = commonlib.gettable("Mod.ParaXExporter.BlockCommon");
local BlockModel = commonlib.gettable("Mod.ParaXExporter.BlockModel");
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");
local BMaxNode = commonlib.gettable("Mod.ParaXExporter.BMaxNode");
local BMaxFrameNode = commonlib.gettable("Mod.ParaXExporter.BMaxFrameNode");
local BMaxMovieBlockNode = commonlib.gettable("Mod.ParaXExporter.BMaxMovieBlockNode");
local BMaxBlockSignNode = commonlib.gettable("Mod.ParaXExporter.BMaxBlockSignNode");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local lshift = mathlib.bit.lshift;
local Common = commonlib.gettable("Mod.ParaXExporter.Common")

local BMaxModel = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxModel"));

-- model will be scaled to this size. 
BMaxModel.m_maxSize = 1.0;
BMaxModel.m_bAutoScale = true;

BMaxModel.MaxBoneLengthHorizontal = 50;
BMaxModel.MaxBoneLengthVertical = 100;

BMaxModel.ModelTypeBlockModel= 0;
BMaxModel.ModelTypeMovieModel = 1;

BMaxModel.BoneBlockId = 253;
BMaxModel.MovieBlockId = 228;
BMaxModel.BlockSignId = 211;
BMaxModel.ReapeaterId = 197;
BMaxModel.WiresId = 189;
BMaxModel.ActorId = 10062;

BMaxModel.MovieBlockInterval = 1000;

function BMaxModel:ctor()
	-- if it is the movie bmax file;
	self.actor_model = nil;

	self.m_blockAABB = nil;
	self.m_centerPos = nil;
	self.m_fScale = 1;
	self.m_modelType = 0;
	self.m_nodes = {};
	self.m_blockModels = {};
	self.m_movieBlocks = {};
	
	self.m_geosets = {};
	self.m_bones = {};
	self.m_renderPasses = {};
	self.m_indices = {};
	self.m_vertices = {};
	self.m_animations = {};
	self.m_minExtent = nil;
	self.m_maxExtent = nil;
end

-- whether we will resize the model to self:GetMaxModelSize();
function BMaxModel:EnableAutoScale(bEnable)
	self.m_bAutoScale = bEnable;
end

function BMaxModel:GetMaxModelSize()
	return self.m_maxSize;
end

function BMaxModel:SetMaxModelSize(size)
	self.m_maxSize = size or 1;
end

-- public: load from file
-- @param bmax_filename: load from *.bmax file
function BMaxModel:Load(bmax_filename)
	if(not bmax_filename)then return end
	self:SetFileName(bmax_filename);
	local xmlRoot = ParaXML.LuaXML_ParseFile(bmax_filename);
	self:ParseHeader(xmlRoot);
	local blocks = self:ParseBlocks(xmlRoot);
	if(blocks) then
		return self:LoadFromBlocks(blocks);
	end
end

-- public: load from array of blocks
-- @param blocks: array of {x,y,z,id, data, serverdata}
function BMaxModel:LoadFromBlocks(blocks)
	self:InitFromBlocks(blocks);

	if self.m_modelType == BMaxModel.ModelTypeMovieModel then
		self:ParseMovieBlocks();
	elseif self.m_modelType == BMaxModel.ModelTypeBlockModel then
		self:ParseBlockFrames();		
		--self:CalculateBoneWeights();
		self:CalculateVisibleBlocks();
		if(self.m_bAutoScale)then
			self:ScaleModels();
		end
		self:FillVerticesAndIndices();
		--self:CreateDefaultAnimation();
	end
end

function BMaxModel:ParseHeader(xmlRoot)
	if(not xmlRoot)then return end
	local blocktemplate = xmlRoot[1];
	if(blocktemplate and blocktemplate.attr and blocktemplate.attr.auto_scale and (blocktemplate.attr.auto_scale == "false" or blocktemplate.attr.auto_scale == "False"))then
		self.m_bAutoScale = false;	
	end
end

function BMaxModel:ParseBlocks(xmlRoot)
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

-- load from array of blocks
-- @param blocks: array of {x,y,z,id, data, serverdata}
function BMaxModel:InitFromBlocks(blocks)
	print("blocks", blocks);
	if(not blocks) then
		return
	end
	local nodes = {};
	local aabb = ShapeAABB:new();
	local bHasBoneBlock = false;
	for k,v in ipairs(blocks) do
		local x = v[1];
		local y = v[2];
		local z = v[3];
		local template_id = v[4];
		local block_data = v[5];
		local block_content = v[6];
		aabb:Extend(x,y,z);
		
		if template_id == BMaxModel.MovieBlockId then
			self.m_modelType = BMaxModel.ModelTypeMovieModel;
			local movieNode = BMaxMovieBlockNode:new():init(self, x, y, z, template_id, block_data, block_content);
			table.insert(nodes, movieNode);
			table.insert(self.m_movieBlocks, movieNode);
		elseif template_id == BMaxModel.BlockSignId then
			local blockSignNode = BMaxBlockSignNode:new():init(self, x, y, z, template_id, block_data, block_content);
			table.insert(nodes, blockSignNode);
		elseif template_id == BMaxModel.BoneBlockId then
			bHasBoneBlock = true;

			local nBoneIndex = #self.m_bones;
			local frameNode = BMaxFrameNode:new():init(self, x, y, z, template_id, block_data, nBoneIndex);
			table.insert(nodes, frameNode);
			table.insert(self.m_bones, frameNode);
		else 
			local node = BMaxNode:new():init(self, x,y,z,template_id, block_data);
			table.insert(nodes, node);
		end
		
	end
	self.m_blockAABB = aabb;

	local blockMinX,  blockMinY, blockMinZ = self.m_blockAABB:GetMinValues();
	local blockMaxX,  blockMaxY, blockMaxZ = self.m_blockAABB:GetMaxValues();
	local width = blockMaxX - blockMinX;
	local height = blockMaxY - blockMinY;
	local depth = blockMaxZ - blockMinZ;

	self.m_centerPos = self.m_blockAABB:GetCenter();
	self.m_centerPos[1] = (width + 1.0) * 0.5;
	self.m_centerPos[2] = 0;
	self.m_centerPos[3]= (depth + 1.0) * 0.5;

	print("center", self.m_centerPos[1], self.m_centerPos[2], self.m_centerPos[3]);

	local offset_x = blockMinX;
	local offset_y = blockMinY;
	local offset_z = blockMinZ;

	for k,node in ipairs(nodes) do
		node.x = node.x - offset_x;
		node.y = node.y - offset_y;
		node.z = node.z - offset_z;
		self:InsertNode(node);
	end
	--set scaling;
	if (self.m_bAutoScale) then
		local fMaxLength = math.max(math.max(height, width), depth) + 1;
		print("fMaxLength", fMaxLength);
		self.m_fScale = self:CalculateScale(fMaxLength);
		print("m_fScale", self.m_fScale);
		if (bHasBoneBlock) then 
			self.m_fScale = self.m_fScale * 2;
		end
	end

end

function BMaxModel:CalculateScale(length)
	local nPowerOf2Length = mathlib.NextPowerOf2( math.floor(length + 0.1) );
	print ("nPowerOf2Length", nPowerOf2Length);

	return BlockConfig.g_blockSize / nPowerOf2Length;
end

function BMaxModel:InsertNode(node)
	if(not node)then return end
	local index = self:GetNodeIndex(node.x,node.y,node.z);
	if(index)then
		self.m_nodes[index] = node;
	end
end

function BMaxModel:GetNode(x,y,z)
	local index = self:GetNodeIndex(x,y,z);
	if(not index)then
		return nil;
	end
	return self.m_nodes[index];
end

function BMaxModel:GetNodeIndex(x,y,z)
	if(x < 0 or y < 0 or z < 0)then
		return
	end
	return x + lshift(z, 8) + lshift(y, 16);
end

function BMaxModel:ParseMovieBlocks()
	
	for _, movieBlock in ipairs(self.m_movieBlocks) do
		movieBlock:ParseMovieInfo();
		movieBlock:ConnectMovieBlock();
	end

	local assetName;
	local firstBlock;
	-- parse mesh and vertice
	for _, movieBlock in ipairs(self.m_movieBlocks) do
		if not movieBlock:HasLastBlock() then
			firstBlock = movieBlock;
			firstBlock.animId = 0;
			movieBlock:ParseActor();
			assetName = movieBlock.asset_file;
			self.actor_model = BMaxModel:new();
			local actorFile = self:FindActorFile(assetName);
			self.actor_model:Load(actorFile);
		end
	end

	-- parse animation 
	local startTime = 0;
	self.actor_model:AddBoneAnimation(startTime, firstBlock.movieLength, 4, nil, 0);
	startTime = startTime + firstBlock.movieLength + BMaxModel.MovieBlockInterval;
	local next = firstBlock.nextBlock;

	while next ~= -1 do
		local currentBlock = self.m_nodes[next];
		currentBlock:ParseActor(assetName);
		local bone_anim = currentBlock:GetAnimData();
		local endTime = startTime + currentBlock.movieLength;
		if bone_anim then 
			self.actor_model:AddBoneAnimation(startTime, endTime, 4, bone_anim, currentBlock.animId);
		end
		startTime = startTime + currentBlock.movieLength + BMaxModel.MovieBlockInterval;
		next = currentBlock.nextBlock;
	end
end

function BMaxModel:ParseBlockFrames()
	for _, bone in ipairs(self.m_bones) do
		bone:UpdatePivot(self.m_fScale);
	end

	for _, bone in ipairs(self.m_bones) do
		bone:GetParentBone(true);
	end

	for _, bone in ipairs(self.m_bones) do
		bone:AutoSetBoneName();
	end
end

function BMaxModel:CalculateVisibleBlocks()
	for _, node in pairs(self.m_nodes) do
		local cube = node:TessellateBlock();
		if(cube:GetVerticesCount() > 0)then
			table.insert(self.m_blockModels,cube);
		end
	end
end

function BMaxModel:ScaleModels()
	local scale = self.m_fScale;
	for _,cube in ipairs(self.m_blockModels) do
		for i, vertex in ipairs(cube:GetVertices()) do
			vertex.position:MulByFloat(scale);

		end
	end
end

function BMaxModel:GetTotalTriangleCount()
	local face_cont = 6;
	local cnt = 0;
	for _, cube in ipairs(self.m_blockModels) do
		cnt = cnt + cube:GetFaceCount()*2;
	end	
	return cnt;
end

function BMaxModel:FillVerticesAndIndices()
	
	if self.m_blockModels == nil or #self.m_blockModels == 0 then
		return;
	end
	
	local aabb = ShapeAABB:new();
	local geoset = self:AddGeoset();
	local pass = self:AddRenderPass();
	pass:SetGeoset(geoset.id);

	local nStartIndex = 0;
	local total_count = 0;
	local nStartVertex = 0;

	for _ , model in ipairs(self.m_blockModels) do
		local nVertices = model:GetVerticesCount();

		local vertices = model:GetVertices();
		local nFace = model:GetFaceCount();

		local nIndexCount = nFace * 6;

		if nIndexCount + geoset:GetIndexCount() >= 0xffff then
			nStartIndex = #self.m_indices;
			geoset = self:AddGeoset();
			pass = self:AddRenderPass();
	
			pass:SetGeoset(geoset.id);
			pass:SetStartIndex(nStartIndex);
			geoset:SetVertexStart(total_count);
			nStartVertex = 0;
		end

		geoset.vstart = geoset.vstart + nVertices;
		geoset.icount = geoset.icount+ nIndexCount;
		pass.indexCount = pass.indexCount + nIndexCount;

		local vertex_weight = 0xff;
		for i, vertice in ipairs(vertices) do
			local modelVertex = ModelVertice:new();
			modelVertex.pos = vertice.position;
			modelVertex.normal = vertice.normal;
			modelVertex.color0 = vertice.color2;

			table.insert(self.m_vertices, modelVertex);

			aabb:Extend(modelVertex.pos);
		end 

		local vertex_weight = 0xff;

		for k = 0, nFace - 1 do
			local start_index = k * 4 + nStartVertex;
			table.insert(self.m_indices, start_index + 0);
			table.insert(self.m_indices, start_index + 1);
			table.insert(self.m_indices, start_index + 2);
			table.insert(self.m_indices, start_index + 0);
			table.insert(self.m_indices, start_index + 2);
			table.insert(self.m_indices, start_index + 3);
		end

		total_count = total_count + nVertices;
		nStartVertex = nStartVertex + nVertices;
	end

	--print("m_minExtent", self.m_minExtent[1], self.m_minExtent[2], self.m_minExtent(3));
	self.m_minExtent = aabb:GetMin();
	self.m_maxExtent = aabb:GetMax();
end	

function BMaxModel:CalculateBoneWeights()
		-- pass 1: calculate all blocks directly connected to bone block and share the same bone color
		for _, bone in ipairs(m_bones) do
			self:CalculateBoneSkin(bone);
		end

		--[[// pass 2: from remaining blocks, calculate blocks which are connected to bones, but with different colors to those bones. 
		for (auto bone : m_bones)
		{
			BlockDirection::Side mySide = BlockDirection::GetBlockSide(bone->block_data);
			for (int i = 0; i < 6; i++)
			{
				BlockDirection::Side side = BlockDirection::GetBlockSide(i);
				if (mySide != side)
				{
					CalculateBoneWeightForBlock(bone.get(), bone->GetNeighbour(side), false);
				}
			}
		}

		// pass 3: from remaining blocks, calculate blocks which are connected to other binded blocks, but with different colors to those blocks.
		for (auto& item : m_nodes)
		{
			CalculateBoneWeightFromNeighbours(item.second.get());
		}--]]
end

function BMaxModel:CalculateBoneSkin(bone)
	
end

function BMaxModel:AddBoneAnimation(startTime, endTime, moveSpeed, anim_data, animId)
	local anim = ModelAnimation:new();
	anim.timeStart = startTime;
	anim.timeEnd = endTime;
	anim.animId = animId;
	anim.moveSpeed = moveSpeed;
	table.insert(self.m_animations, anim);

	for _, frameNode in ipairs(self.m_bones) do
		local bone = frameNode.bone;

		local tranBlock = bone.translation;
		local rotBlock =  bone.rotation;
		local scaleBlock = bone.scaling;
		
		tranBlock:AddKey({0, 0, 0});
		tranBlock:AddTime(startTime);
		rotBlock:AddKey(Quaternion:new():FromAngleAxis(0, frameNode:GetAxis()));
		rotBlock:AddTime(startTime);
		scaleBlock:AddKey({1, 1, 1});
		scaleBlock:AddTime(startTime);
	end

	if anim_data then 
		for k, v in pairs(anim_data) do
			if string.find(k, "bone") == 1 then
				local name = v.name;
				if name then
					local frameNode, anim = self:GetBone(name);
					if frameNode then
						local time = v.times;
						local data = v.data;
						local range = v.ranges;
						local bone = frameNode.bone;

						local block = nil;
						if anim == "rot" then
							block = bone.rotation;	
						elseif anim == "trans" then
							block = bone.translation;
						elseif anim == "scale" then
							block = bone.scaling;
						end
					
						if block then
							for k , v in ipairs(data) do
								if time[k] and data[k] then
									block:AddKey(data[k]);
									block:AddTime(time[k] + startTime);
								end
							end
						end
					end
				end
			end
		end
	end

	for _, frameNode in ipairs(self.m_bones) do
		local bone = frameNode.bone;

		local tranBlock = bone.translation;
		local rotBlock =  bone.rotation;
		local scaleBlock = bone.scaling;
		
		tranBlock:AddRange();
		rotBlock:AddRange();
		scaleBlock:AddRange();
	end
end
function BMaxModel:GetBone(bone_name)
	for _, bone in ipairs(self.m_bones) do
		if string.find(bone_name, bone.bone_name) == 1 then
			local anim = string.gsub(bone_name, bone.bone_name.."_", ""); 
			return bone, anim;
		end
	end

	return nil;
end

function BMaxModel:GetFrameNode(x, y, z)
	local node = self:GetNode(x, y, z);
	if node then
		return node:ToBoneNode();
	end
	return nil;
end
	

function BMaxModel:CreateDefaultAnimation()
	if #self.m_bones == 0 then
		self:CreateRootBone();
	end
	
	self:AddIdleAnimation();
end

function BMaxModel:CreateRootBone()
	table.insert(self.m_bones, BMaxFrameNode:new());
end

function BMaxModel:AddIdleAnimation()
	local anim = ModelAnimation:new();
	anim.timeStart = 0;
	anim.timeEnd = 30000;
	anim.animID = 0;
	anim.moveSpeed = 0.4;
	table.insert(self.m_animations, anim);

end

function BMaxModel:AddGeoset()
	local geoset = ModelGeoset:new();
	geoset:SetId(#self.m_geosets);
	table.insert(self.m_geosets, geoset);
	return geoset;
end

function BMaxModel:AddRenderPass()
	local renderPass = ModelRenderPass:new();
	table.insert(self.m_renderPasses, renderPass);
	return renderPass;
end

function BMaxModel:GetMinExtent()
	return self.m_minExtent;
end

function BMaxModel:GetMaxExtent()
	return self.m_maxExtent;
end

-- find in world directory, and then find in the current bmax file directory. 
-- return full path
function BMaxModel:FindActorFile(actorFileName)
	local actorFileName_ = GameLogic.GetWorldDirectory()..actorFileName;
	if(not ParaIO.DoesFileExist(actorFileName_)) then
		actorFileName_ = self:GetFileName():gsub("[^/]+$", "") .. actorFileName:match("([^/]+)$");
		if(not ParaIO.DoesFileExist(actorFileName_)) then
			actorFileName_ = actorFileName;
		end
	end
	return actorFileName_;
end

function BMaxModel:GetFileName()
	return self.filename or "";
end

function BMaxModel:SetFileName(filename)
	self.filename = filename;
end
