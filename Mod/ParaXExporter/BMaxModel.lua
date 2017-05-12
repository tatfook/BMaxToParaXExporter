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
NPL.load("(gl)Mod/ParaXExporter/Rectangle.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/BlockDirection.lua");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");
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
local Common = commonlib.gettable("Mod.ParaXExporter.Common");
local Rectangle = commonlib.gettable("Mod.ParaXExporter.Rectangle")

local BMaxModel = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxModel"));

-- model will be scaled to this size. 
BMaxModel.m_maxSize = 1.0;
BMaxModel.m_bAutoScale = true;

BMaxModel.MaxBoneLengthHorizontal = 50;
BMaxModel.MaxBoneLengthVertical = 100;

BMaxModel.ModelTypeBlockModel = 0;
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
	self.m_movieBlocks = {};
	
	self.m_geosets = {};
	self.m_bones = {};
	self.m_renderPasses = {};
	self.m_indices = {};
	self.m_vertices = {};
	self.m_animations = {};
	self.m_minExtent = {0, 0, 0};
	self.m_maxExtent = {0, 0, 0};
	self.m_nodeIndexes = {};
	self.m_rectangles = {};
	self.bHasBoneBlock = false;
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
		self:CalculateBoneWeights();
		self:CalculateVisibleBlocks();
		if(self.m_bAutoScale)then
			self:ScaleModels();
		end
		self:MergeCoplanerBlockFace();
		self:FillVerticesAndIndices();
		self:CreateDefaultAnimation();
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
	if(not blocks) then
		return
	end
	local nodes = {};
	local aabb = ShapeAABB:new();
	for k,v in ipairs(blocks) do
		local x = v[1];
		local y = v[2];
		local z = v[3];
		local template_id = v[4];
		local block_data = v[5];
		local block_content = v[6];
		if not block_content then
			block_content = BlockEngine:GetBlockEntityData(v[1], v[2], v[3]);
		end
		--Common:PrintTable(block_content);
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
			self.bHasBoneBlock = true;

			local nBoneIndex = #self.m_bones;
			local frameNode = BMaxFrameNode:new():init(self, x, y, z, template_id, block_data, nBoneIndex);
			
			local bone = frameNode.bone;
			local tranBlock = bone.translation;
			local rotBlock =  bone.rotation;
			local scaleBlock = bone.scaling;
			tranBlock:AddKey({0, 0, 0});
			tranBlock:AddTime(0);
			rotBlock:AddKey(Quaternion:new():FromAngleAxis(0, frameNode:GetAxis()));
			rotBlock:AddTime(0);
			scaleBlock:AddKey({1, 1, 1});
			scaleBlock:AddTime(0);

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

	local offset_x = math.floor(blockMinX);
	local offset_y = math.floor(blockMinY);
	local offset_z = math.floor(blockMinZ);

	for k,node in ipairs(nodes) do
		node.x = node.x - offset_x;
		node.y = node.y - offset_y;
		node.z = node.z - offset_z;
		self:InsertNode(node);
	end
	table.sort(self.m_nodeIndexes);
	--set scaling;
	if (self.m_bAutoScale) then
		local fMaxLength = math.max(math.max(height, width), depth) + 1;
		print("fMaxLength", fMaxLength, blockMaxZ, blockMinZ);
		self.m_fScale = self:CalculateScale(fMaxLength);
		print("m_fScale", self.m_fScale);
		if (self.bHasBoneBlock) then 
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
		table.insert(self.m_nodeIndexes, index);
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
	self.actor_model:AddBoneAnimation(startTime, firstBlock.movieLength, 0, nil, 0);
	startTime = startTime + firstBlock.movieLength + BMaxModel.MovieBlockInterval;
	local next = firstBlock.nextBlock;

	while next ~= -1 do
		local currentBlock = self.m_nodes[next];
		currentBlock:ParseActor(assetName);
		local bone_anim = currentBlock:GetAnimData();
		local moveSpeed = currentBlock:ParseMoveSpeed();
		local endTime = startTime + currentBlock.movieLength;
		if bone_anim then 
			self.actor_model:AddBoneAnimation(startTime, endTime, moveSpeed, bone_anim, currentBlock.animId);
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
	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		node:TessellateBlock();
	end
end

function BMaxModel:ScaleModels()
	local scale = self.m_fScale;
	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		local cube = node:GetCube();
		if cube then
			for i, vertex in ipairs(cube:GetVertices()) do
				vertex.position:MulByFloat(scale);
			end
		end
	end
end

function BMaxModel:GetTotalTriangleCount()
	local face_cont = 6;
	local cnt = 0;
	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		local cube = node:GetCube();
		if cube then 
			cnt = cnt + cube:GetFaceCount()*2;
		end 
	end	
	return cnt;
end

function BMaxModel:MergeCoplanerBlockFace()
	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		local cube = node:GetCube();
		
		for i = 0, 5 do 
			if cube:IsFaceNotUse(i) then
				--print("node", node.x, node.y, node.z);
				self:FindCoplanerFace(node, i);
			end
		end	
	end

	print("rect", #self.m_rectangles);
end 

function BMaxModel:FindCoplanerFace(node, faceIndex)
	local nodes = {node, node, node, node};
	local rectangle = Rectangle:new():init(nodes, faceIndex);
	
	if rectangle then 
		for i = 0, 3 do
			self:FindNeighbourFace(rectangle, i, faceIndex);
			local cube = node:GetCube();
			cube:SetFaceUsed(faceIndex);
		end
	end

	table.insert(self.m_rectangles, rectangle);
end 

function BMaxModel:FindNeighbourFace(rectangle, i, faceIndex)
	
	local index = faceIndex * 4 + i;
	local offset = Rectangle.DirectionOffsetTable[index];
	local nextI;
	if i == 3 then
		nextI = index - 3;
	else 
		nextI = index + 1;
	end
	local fromNode, toNode = rectangle:GetNode(nextI);
	--print("face", i, faceIndex, fromNode.x, fromNode.y, fromNode.z, toNode.x, toNode.y, toNode.z);
	local nextOffset = Rectangle.DirectionOffsetTable[nextI]
	local currentNode = fromNode;
	local nodes = {};
	if fromNode then
		repeat 
			local neighbourNode = currentNode:GetNeighbourByOffset(offset);
			--print("neighbourNode", currentNode, neighbourNode);
			if not neighbourNode or currentNode:GetColor() ~= neighbourNode:GetColor() or currentNode:GetBoneIndex() ~= neighbourNode:GetBoneIndex() then
				return;
			end
			--print("index1", faceIndex, index, offset[1], offset[2], offset[3]);
			local neighbourCube = neighbourNode:GetCube();
			if not neighbourCube:IsFaceNotUse(faceIndex) then
				return;
			end 
			--print("3");
			table.insert(nodes, neighbourNode);

			if currentNode == toNode then
				break;
			end
			currentNode = currentNode:GetNeighbourByOffset(nextOffset);
		until(currentNode == nil)

		local newFromNode = fromNode:GetNeighbourByOffset(offset);
		local newToNode = toNode:GetNeighbourByOffset(offset);
		--[[print("node2s", #nodes);
		print("newFrom", newFromNode.x, newFromNode.y, newFromNode.z);
		print("toNode", newToNode.x, newToNode.y, newToNode.z);--]]
		for _, node in ipairs(nodes) do
			local cube = node:GetCube();
			cube:SetFaceUsed(faceIndex);
		end
		rectangle:UpdateNode(newFromNode, newToNode, nextI);
		self:FindNeighbourFace(rectangle, i, faceIndex);
	end
end



function BMaxModel:FillVerticesAndIndices()	
	local aabb = ShapeAABB:new();
	local geoset = self:AddGeoset();
	local pass = self:AddRenderPass();
	pass:SetGeoset(geoset.id);

	local nStartIndex = 0;
	local total_count = 0;
	local nStartVertex = 0;

	--print("node", Common:PrintNode(self.m_nodes));
	for _, rectangle in ipairs(self.m_rectangles) do
		local nIndexCount =  6;
		local nVertices = 4;
		local vertices = rectangle:GetVertices();
		

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

		local vertex_weight = 255;

		for i, vertice in ipairs(vertices) do
			--print("adv", vertice.position[1], vertice.position[2], vertice.position[3]);
			local modelVertex = ModelVertice:new();
			modelVertex.pos = vertice.position;
			--print("pos", modelVertex.pos[1], modelVertex.pos[2], modelVertex.pos[3]);
			modelVertex.normal = vertice.normal;
			modelVertex.color0 = vertice.color2;
			modelVertex.weights[1] = vertex_weight;
			modelVertex.bones[1] = rectangle:GetBoneIndex(i);


			table.insert(self.m_vertices, modelVertex);

			aabb:Extend(modelVertex.pos);
		end 

		local start_index = nStartVertex;
		table.insert(self.m_indices, start_index + 0);
		table.insert(self.m_indices, start_index + 1);
		table.insert(self.m_indices, start_index + 2);
		table.insert(self.m_indices, start_index + 0);
		table.insert(self.m_indices, start_index + 2);
		table.insert(self.m_indices, start_index + 3);

		total_count = total_count + nVertices;
		nStartVertex = nStartVertex + nVertices;
	end

	--[[for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		local cube = node:GetCube();
		if cube then 
			local nVertices = cube:GetVerticesCount();

			local vertices = cube:GetVertices();
			local nFace = cube:GetFaceCount();

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

			local vertex_weight = 255;
			--print("bone_index", node.x, node.y, node.z, node:GetBoneIndex());
			for i, vertice in ipairs(vertices) do
				local modelVertex = ModelVertice:new();
				modelVertex.pos = vertice.position;
				--print("pos", modelVertex.pos[1], modelVertex.pos[2], modelVertex.pos[3]);
				modelVertex.normal = vertice.normal;
				modelVertex.color0 = vertice.color2;
				modelVertex.weights[1] = vertex_weight;
				modelVertex.bones[1] = node:GetBoneIndex();

				table.insert(self.m_vertices, modelVertex);

				aabb:Extend(modelVertex.pos);
			end 


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
		
	end--]]

	self.m_minExtent = aabb:GetMin();
	self.m_maxExtent = aabb:GetMax();
	print("m_minExtent", self.m_minExtent[1], self.m_minExtent[2], self.m_minExtent[3]);
end	

function BMaxModel:CalculateBoneWeights()

		-- pass 1: calculate all blocks directly connected to bone block and share the same bone color
		for _, bone in ipairs(self.m_bones) do
			
			self:CalculateBoneSkin(bone);

		end

		for _, bone in ipairs(self.m_bones) do
			local mySide = bone:GetBoneSide();
			for i = 0, 5 do
				local side = BlockDirection:GetBlockSide(i);
				if mySide ~= side then
					self:CalculateBoneWeightForBlock(bone, bone:GetNeighbour(side), false);
				end
			end
		end 

		for _, index in ipairs(self.m_nodeIndexes) do
			local node = self.m_nodes[index];	
			self:CalculateBoneWeightFromNeighbours(node);
		end
end

function BMaxModel:CalculateBoneWeightForBlock(pBoneNode, node, bMustBeSameColor)
	if node and not node:HasBoneWeight() then
		if node.template_id ~= BMaxModel.BoneBlockId then
			if (not bMustBeSameColor) or node:GetColor() == pBoneNode:GetColor() then
				node:SetBoneIndex(pBoneNode:GetBoneIndex());
				for i = 0, 5 do
					self:CalculateBoneWeightForBlock(pBoneNode, node:GetNeighbour(i), bMustBeSameColor);
				end
			end
		end
	end
end

function BMaxModel:CalculateBoneWeightFromNeighbours(node)

	if node and not node:HasBoneWeight() then
		local bFoundBone = false;
		for i = 0, 5 do
			if not bFoundBone then
				local side = BlockDirection:GetBlockSide(i);
				local pNeighbourNode = node:GetNeighbour(side);
			
				if pNeighbourNode and pNeighbourNode:HasBoneWeight() then
					--print("node", node.x, node.y, node.z, pNeighbourNode.x, pNeighbourNode.y, pNeighbourNode.z, pNeighbourNode:GetBoneIndex(), i);
					node:SetBoneIndex(pNeighbourNode:GetBoneIndex());
					bFoundBone = true;
				end
			end
			
		end

		if (bFoundBone) then
			for i = 0, 5 do
				local side = BlockDirection:GetBlockSide(i);
				local pNeighbourNode = node:GetNeighbour(side);
			
				if pNeighbourNode and not pNeighbourNode:HasBoneWeight() then
					self:CalculateBoneWeightFromNeighbours(pNeighbourNode);
				end
			end
		end
			
	end
end

function BMaxModel:CalculateBoneSkin(pBoneNode)
	if pBoneNode:HasBoneWeight() then
		return;
	end
	
	local pParentBoneNode = pBoneNode:GetParent();
	if pParentBoneNode and not pParentBoneNode:HasBoneWeight() then
		self:CalculateBoneSkin(pParentBoneNode);
	end

	pBoneNode:SetBoneIndex(pBoneNode:GetBoneIndex());

	local bone_color = pBoneNode:GetColor();

	local mySide = pBoneNode:GetBoneSide();
	for i = 0, 5 do
		local side = BlockDirection:GetBlockSide(i);
		if mySide ~= side then
			self:CalculateBoneWeightForBlock(pBoneNode, pBoneNode:GetNeighbour(side), true);
		end
	end
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
									block:AddKey(data[k])
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

	if #self.m_animations == 0 then
		self:AddIdleAnimation();
	end
end

function BMaxModel:CreateRootBone()
	table.insert(self.m_bones, BMaxFrameNode:new());
end

function BMaxModel:AddIdleAnimation()
	local anim = ModelAnimation:new();
	anim.timeStart = 0;
	anim.timeEnd = 0;
	anim.animID = 0;
	anim.moveSpeed = 0;
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
