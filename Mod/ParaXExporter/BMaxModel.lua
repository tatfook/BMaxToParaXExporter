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
NPL.load("(gl)script/ide/math/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/Rectangle.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local Rectangle = commonlib.gettable("Mod.ParaXExporter.Rectangle")
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


local BMaxModel = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxModel"));

-- model will be scaled to this size. 
BMaxModel.m_maxSize = 1.0;
BMaxModel.m_bAutoScale = true;

BMaxModel.useTextures = false;

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

BMaxModel.LodIndexToMeter = {5, 15, 30, 100};

function BMaxModel:ctor()
	-- if it is the movie bmax file;
	self.actor_model = nil;

	self.m_blockAABB = nil;
	self.m_centerPos = nil;
	self.m_fScale = 1;
	self.m_modelType = 0;
	self.m_nodes = {};
	self.m_nodeIndexes = {};
	self.m_movieBlocks = {};
	
	self.m_geosets = {};
	self.m_bones = {};
	self.m_renderPasses = {};
	self.m_textures = {};
	self.m_indices = {};
	self.m_vertices = {};
	self.m_animations = {};
	self.m_minExtent = {0, 0, 0};
	self.m_maxExtent = {0, 0, 0};
	self.m_nodeIndexTables = {};
	self.m_originRectangles = {};
	self.m_lodRectangles = {};
	self.m_name_occurances = {};
	self.bHasBoneBlock = false;
	self.currentLevel = 1;
end

-- whether we will resize the model to self:GetMaxModelSize();
function BMaxModel:EnableAutoScale(bEnable)
	self.m_bAutoScale = bEnable;
end

function BMaxModel:UseTextures(use)
	if (use) then
		self.useTextures = use;
	end
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


-- public: load file
-- @param xmlRoot: rool element from *.bmax file
function BMaxModel:ParseHeader(xmlRoot)
	if(not xmlRoot)then return end
	local blocktemplate = xmlRoot[1];
	if(blocktemplate and blocktemplate.attr and blocktemplate.attr.auto_scale and (blocktemplate.attr.auto_scale == "false" or blocktemplate.attr.auto_scale == "False"))then
		self.m_bAutoScale = false;	
	end
end

-- public: load file
-- @param xmlRoot: rool element from *.bmax file
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

-- public: load from array of blocks
-- @param blocks: array of {x,y,z,id, data, serverdata}
function BMaxModel:LoadFromBlocks(blocks, counterclockwise)
	self:InitFromBlocks(blocks, counterclockwise);
	if self.m_modelType == BMaxModel.ModelTypeMovieModel then
		self:ParseMovieBlocks();
	elseif self.m_modelType == BMaxModel.ModelTypeBlockModel then
		self:ParseBlockFrames();		
		self:CalculateBoneWeights();
		self:CreateDefaultAnimation();
		self:CalculateLod();
		--self:FillVerticesAndIndices();
	end
end

local function GetBoneNameFromEntityData(node)
	local cmd_text;
	if(node) then
		for i=1, #node do
			sub_node = node[i];
			if(sub_node.name == "cmd") then
				local cmd = sub_node[1]
				if(cmd) then
					if(type(cmd) == "string") then
						cmd_text = cmd;
					elseif(type(cmd) == "table" and type(cmd[1]) == "string") then
						cmd_text = cmd[1];
					end
				end
			end
		end
	end
	if(cmd_text) then
		cmd_text = cmd_text:gsub("^%s+",""):gsub("%s+$","")
	end
	return cmd_text;
end

-- load from array of blocks
-- @param blocks: array of {x,y,z,id, data, serverdata}
function BMaxModel:InitFromBlocks(blocks, counterclockwise)
	if(not blocks) then
		return
	end
	local nodes = {};
	for k,v in ipairs(blocks) do
		local x = v[1];
		local y = v[2];
		local z = v[3];
		local template_id = v[4];
		local block_data = v[5];
		local block_content = v[6];
		
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
			if(block_content) then
				frameNode.bone_name = GetBoneNameFromEntityData(block_content);
			end
		 	frameNode:GenerateStartFrame(0);

			table.insert(nodes, frameNode);
			table.insert(self.m_bones, frameNode);
		else 
			local node = BMaxNode:new():init(self, x,y,z,template_id, block_data, nil, counterclockwise);
			table.insert(nodes, node);
		end
		
	end

	self:CalculateAABB(nodes);
end

-- convert length to scale
-- @param length: length of model
function BMaxModel:CalculateScale(length)
	local nPowerOf2Length = mathlib.NextPowerOf2( math.floor(length + 0.1) );
	-- print ("nPowerOf2Length", nPowerOf2Length);

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
	if(index)then
		return self.m_nodes[index];
	end
end

function BMaxModel:GetFrameNode(x, y, z)
	local node = self:GetNode(x, y, z);
	if node then
		return node:ToBoneNode();
	end
	return nil;
end

function BMaxModel:GetNodeIndex(x,y,z)
	if(x >= 0 and y >= 0 and z >= 0)then
		return y*900000000+x*30000+z;
	end
end

function BMaxModel:CalculateAABB(nodes)
	local aabb = ShapeAABB:new();
	for _, node in pairs(nodes) do
		aabb:Extend(node.x,node.y,node.z);
	end

	self.m_blockAABB = aabb;
	self.m_centerPos = self.m_blockAABB:GetCenter();

	local width, height, depth = self:GetModelFrame();
	
	local blockMinX,  blockMinY, blockMinZ = self.m_blockAABB:GetMinValues();
	local blockMaxX,  blockMaxY, blockMaxZ = self.m_blockAABB:GetMaxValues();
	
	width = blockMaxX - blockMinX;
	height = blockMaxY - blockMinY;
	depth = blockMaxZ - blockMinZ;

	local offset_x = math.floor(blockMinX);
	local offset_y = math.floor(blockMinY);
	local offset_z = math.floor(blockMinZ);

	self.m_centerPos[1] = (width + 1.0) * 0.5;
	self.m_centerPos[2] = 0;
	self.m_centerPos[3]= (depth + 1.0) * 0.5;

	-- print("center", self.m_centerPos[1], self.m_centerPos[2], self.m_centerPos[3]);
	if (self.m_bAutoScale) then
		local fMaxLength = math.max(math.max(height, width), depth) + 1;
		self.m_fScale = self:CalculateScale(fMaxLength);
		if self.bHasBoneBlock then
			self.m_fScale = self.m_fScale * 2;
		end
	end

	self.m_nodes = {};
	self.m_nodeIndexes = {}; 
	for k,node in pairs(nodes) do
		node.x = node.x - offset_x;
		node.y = node.y - offset_y;
		node.z = node.z - offset_z;
		self:InsertNode(node);
	end
	-- print("node23", #self.m_nodeIndexes);
	table.sort(self.m_nodeIndexes);
end

function BMaxModel:GetModelFrame()
	local blockMinX,  blockMinY, blockMinZ = self.m_blockAABB:GetMinValues();
	local blockMaxX,  blockMaxY, blockMaxZ = self.m_blockAABB:GetMaxValues();

	return blockMaxX - blockMinX, blockMaxY - blockMinY, blockMaxZ - blockMinZ;
end

-- return array of all bones
function BMaxModel:GetBones()
	return self.m_bones
end

-- public: load from array of bone
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

function BMaxModel:CalculateLod()
	--local scale = 1;
	local rectangles = self:MergeCoplanerBlockFace();
	self.m_originRectangles = rectangles;
	for _, rectangle in ipairs(rectangles) do
		rectangle:ScaleVertices(self.m_fScale);
	end
	
	-- export with textures, will not calculate LOD
	if (not self.useTextures) then
		local lodTable = self:GetLodTable(#rectangles);
		for i, nextFaceCount in ipairs(lodTable) do
			while #rectangles > nextFaceCount do
				self:PerformLod();
				rectangles = self:MergeCoplanerBlockFace();
			end
			for _, rectangles in ipairs(rectangles) do
				rectangles:ScaleVertices(self.m_fScale);
			end
			self.m_lodRectangles[i] = rectangles;
		end
	end
end

function BMaxModel:GetLodTable(faceCount)
	if faceCount >= 4000 then
		return { 4000, 2000, 500};
	elseif faceCount >= 2000 then 
		return {2000, 500};
	elseif faceCount >= 500 then 
		return {500};
	else 
		return {};
	end
end

function BMaxModel:PerformLod()
	local width, height, depth = self:GetModelFrame();

	local nodes = {};
	local nodeIndexes = {};
	
	for direction = 0, 3 do
		local x = math.floor(self.m_centerPos[1]);
		while x >= -1 and x <= width do 
			for y = 0, height, 2 do
				local z = math.floor(self.m_centerPos[3]);
				while z >= -1 and z <= depth do 

					self:CalculateLodNode(nodes, x, y, z);

					if direction % 2 == 0 then
						z = z + 2;
					else
						z = z - 2;
					end
				end
			end
			if direction >= 2 then
				x = x + 2;
			else
				x = x - 2;
			end
		end
	end

	
	self:CalculateAABB(nodes);
end

function BMaxModel:MergeCoplanerBlockFace()
	local rectangles = {};
	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		node:TessellateBlock();
	end
	

	for _, index in ipairs(self.m_nodeIndexes) do
		local node = self.m_nodes[index];
		local cube = node:GetCube();
		if(cube) then
			local faceCount = cube:GetFaceCount()
			if node:IsCustomCube() then
				for i=0,faceCount-1 do 
					local faceIndex = i
					
					if cube then
						local nodes = {node, node, node, node};
						local rectangle = Rectangle:new():init(nodes, faceIndex);
						cube:SetFaceUsed(faceIndex);	

						rectangle:CloneNodes();
						table.insert(rectangles, rectangle);
					end
				end
			else
				for i = 0, 5 do 
					if cube:IsFaceNotUse(i) then
						self:FindCoplanerFace(rectangles, node, i);
					end
				end	
			end
			
		end
	end
	
	-- print("rect count", #rectangles);
	return rectangles;
end 

function BMaxModel:FindCoplanerFace(rectangles, node, faceIndex)
	
	local nodes = {node, node, node, node};
	local rectangle = Rectangle:new():init(nodes, faceIndex);
	if rectangle then 
		for i = 0, 3 do
			if (not self.useTextures) then
				self:FindNeighbourFace(rectangle, i, faceIndex);
			end
			local cube = node:GetCube();
			if(cube) then
				cube:SetFaceUsed(faceIndex);	
			end
			
		end
	end
	rectangle:CloneNodes();
	table.insert(rectangles, rectangle);
end 

function BMaxModel:FindNeighbourFace(rectangle, i, faceIndex)
	
	local index = faceIndex * 4 + i;
	local offset = Rectangle.DirectionOffsetTable[index];
	if offset==nil then
		return
	end

	local nextI;
	if i == 3 then
		nextI = index - 3;
	else 
		nextI = index + 1;
	end
	local fromNode, toNode = rectangle:GetNode(nextI);
	local nextOffset = Rectangle.DirectionOffsetTable[nextI]
	local currentNode = fromNode;
	local nodes = {};
	if fromNode then
		repeat 
			local neighbourNode = currentNode:GetNeighbourByOffset(offset);
			
			if not neighbourNode or currentNode:GetColor() ~= neighbourNode:GetColor() or currentNode:GetBoneIndex() ~= neighbourNode:GetBoneIndex() then
				return;
			end
			if neighbourNode:IsCustomCube() then
				return
			end
			local neighbourCube = neighbourNode:GetCube();
			if not neighbourCube or not neighbourCube:IsFaceNotUse(faceIndex) then
				return;
			end 
			table.insert(nodes, neighbourNode);

			if currentNode == toNode then
				break;
			end
			currentNode = currentNode:GetNeighbourByOffset(nextOffset);
		until(currentNode == nil)

		local newFromNode = fromNode:GetNeighbourByOffset(offset);
		local newToNode = toNode:GetNeighbourByOffset(offset);
		for _, node in ipairs(nodes) do
			local cube = node:GetCube();
			if(cube) then
				cube:SetFaceUsed(faceIndex);
			end
		end
		rectangle:UpdateNode(newFromNode, newToNode, nextI);
		self:FindNeighbourFace(rectangle, i, faceIndex);
	end
end

function BMaxModel:CalculateLodNode(nodes, x, y, z)
	
	local cnt = 0;

	local colors = {};
	local boneIndices = {};
	for dx = 0, 1 do
		for dy = 0, 1 do
			for dz = 0, 1 do
				local cx = x + dx;
				local cy = y + dy;
				local cz = z + dz;

				if cx >= 0 and cy >= 0 and cx >= 0 then
					local myNode = self:GetNode(cx, cy, cz);
					if myNode then
						cnt = cnt + 1;
						local hasFind = false;
						local myBoneIndex = myNode:GetBoneIndex();
						if(myBoneIndex>=0) then
							local myBone = self.m_bones[myBoneIndex + 1];

							for k, v in pairs(boneIndices) do
								local bone = self.m_bones[k + 1];
								if myBoneIndex == k or bone:IsAncestorOf(myBone)then
									boneIndices[k] = boneIndices[k] + 1;
									hasFind = true;
									break;
								elseif myBone:IsAncestorOf(bone) then
									boneIndices[k] = nil;
									boneIndices[myBoneIndex] = v + 1;
									hasFind = true;
									break;
								end
							end
							if not hasFind then
								boneIndices[myBoneIndex] = 1;
							end
						end

						hasFind = false;
						local myColor = myNode:GetColor();
						for k, v in pairs(colors) do
							if k == myColor then
								colors[k] = colors[k] + 1;
								hasFind = true;
								break;
							end
						end
						if not hasFind then
							colors[myColor] = 1;
						end
					end
				end
			end
		end
	end

	if cnt >= 4 then
		local newX = math.floor((x + 1) / 2);
		local newY = math.floor(y / 2);
		local newZ = math.floor((z + 1) / 2);
		local nodeIndex = self:GetNodeIndex(newX, newY, newZ);

		local maxNum = 0;
		local node = BMaxNode:new():init(self, newX, newY, newZ);
		local color = nil;
		for k, v in pairs(colors) do 
			if v > maxNum then
				maxNum = v;
				color = k;
			end
		end
		if color then 
			node:SetColor(color);
		end

		local boneIndex = nil;
		maxNum = 0;
		for k, v in pairs(boneIndices) do 
			if v > maxNum then
				maxNum = v;
				boneIndex = k;
			end
		end
		if boneIndex then 
			node:SetBoneIndex(boneIndex);
		end

		if nodes[nodeIndex] == nil then
			nodes[nodeIndex] = node;
		end

	end 
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

local blockStack = {}
function BMaxModel:CalculateBoneWeightForBlock(pBoneNode, startNode, bMustBeSameColor)
	if #blockStack > 0 then
		commonlib.resize(blockStack,0)
	end
	local pBoneColor = pBoneNode:GetColor()
	local pBoneIndex = pBoneNode:GetBoneIndex()
    table.insert(blockStack, startNode)
    while #blockStack > 0 do
        local node = table.remove(blockStack)
        if node and not node:HasBoneWeight() then
            if node.template_id ~= BMaxModel.BoneBlockId then
                if (not bMustBeSameColor) or node:GetColor() == pBoneColor then
                    node:SetBoneIndex(pBoneIndex)
                    for i = 0, 5 do
                        local neighbor = node:GetNeighbour(i)
                        if neighbor then
                            table.insert(blockStack, neighbor)
                        end
                    end
                end
            end
        end
    end
end

local neighborStack = {}
function BMaxModel:CalculateBoneWeightFromNeighbours(node)
    if not node or node:HasBoneWeight() then
        return
    end
	if #neighborStack > 0 then
		commonlib.resize(neighborStack,0)
	end

    local visited = {}

    table.insert(neighborStack, node)

    while #neighborStack > 0 do
        local currentNode = table.remove(neighborStack)
        visited[currentNode] = true

        local bFoundBone = false

        for i = 0, 5 do
            if not bFoundBone then
                local side = BlockDirection:GetBlockSide(i)
                local pNeighbourNode = currentNode:GetNeighbour(side)

                if pNeighbourNode and pNeighbourNode:HasBoneWeight() then
                    currentNode:SetBoneIndex(pNeighbourNode:GetBoneIndex())
                    bFoundBone = true
                end
            end
        end

        if bFoundBone then
            for i = 0, 5 do
                local side = BlockDirection:GetBlockSide(i)
                local pNeighbourNode = currentNode:GetNeighbour(side)

                if pNeighbourNode and not visited[pNeighbourNode] and not pNeighbourNode:HasBoneWeight() then
                    table.insert(neighborStack, pNeighbourNode)
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

function BMaxModel:ClearXModel()
	self.m_geosets = {};
	self.m_indices = {};
	self.m_vertices = {};
	self.m_renderPasses = {};
	self.m_textures = {};
end

function BMaxModel:FillVerticesAndIndices(rectangles)	
	if (self.useTextures) then
		self:FillVerticesAndIndices2(rectangles);
		return;
	end

	self:ClearXModel();
	local aabb = ShapeAABB:new();
	local geoset = self:AddGeoset();
	local pass = self:AddRenderPass();
	pass:SetGeoset(geoset.id);
	table.insert(self.m_textures, "Texture/blocks/snow.png");

	local nStartIndex = 0;
	local total_count = 0;
	local nStartVertex = 0;
	local rootBoneIndex = self:FindRootBoneIndex(); 

	for _, rectangle in ipairs(rectangles) do
		local nIndexCount =  6;
		local nVertices = 4;
		local vertices = rectangle:GetVertices();
		

		if (nIndexCount + geoset:GetIndexCount()) >= 0xffff then
			nStartIndex = #self.m_indices;
			geoset = self:AddGeoset();
			pass = self:AddRenderPass();
	
			pass:SetGeoset(geoset.id);
			pass:SetStartIndex(nStartIndex);
			geoset:SetVertexStart(total_count);
			nStartVertex = 0; 
		end

		geoset.icount = geoset.icount+ nIndexCount;
		pass.indexCount = pass.indexCount + nIndexCount;

		local vertex_weight = 255;

		for i, vertice in ipairs(vertices) do
			local modelVertex = ModelVertice:new();
			--modelVertex.pos = vertice.position;
			modelVertex.pos = vertice.position;
			--modelVertex.pos[3] = modelVertex.pos[3] - 5;
			modelVertex.normal = vertice.normal;
			modelVertex.color0 = vertice.color2;
			modelVertex.weights[1] = vertex_weight;
			if rectangle:GetBoneIndex(i) == -1 then
				modelVertex.bones[1] = rootBoneIndex;
			else
				modelVertex.bones[1] = rectangle:GetBoneIndex(i);
			end
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

	self.m_minExtent = aabb:GetMin();
	self.m_maxExtent = aabb:GetMax();
	
	-- print("m_minExtent", self.m_minExtent[1], self.m_minExtent[2], self.m_minExtent[3], self.m_maxExtent[1], self.m_maxExtent[2], self.m_maxExtent[3]);

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

	--self.m_minExtent = aabb:GetMin();
	--self.m_maxExtent = aabb:GetMax();
	--print("m_minExtent", self.m_minExtent[1], self.m_minExtent[2], self.m_minExtent[3], self.m_maxExtent[1], self.m_maxExtent[2], self.m_maxExtent[3]);
end	

-- use textures
function BMaxModel:FillVerticesAndIndices2(rectangles)	
	self:ClearXModel();
	local aabb = ShapeAABB:new();

	local nStartIndex = 0;
	local total_count = 0;
	local rootBoneIndex = self:FindRootBoneIndex(); 

	local blocks = {}
	local mapRectangles = {};
	for i, rectangle in ipairs(rectangles) do
		local id = rectangle.nodes[1].template_id;
		if (mapRectangles[id] == nil) then
			local texture = rectangle.nodes[1].texture;
			mapRectangles[id] = {};
			table.insert(blocks, {id = id, texture = texture});
		end
		table.insert(mapRectangles[id], rectangle);
	end

	local geoset = self:AddGeoset();
	for index, block in ipairs(blocks) do
		table.insert(self.m_textures, block.texture);
		nStartIndex = #self.m_indices;
		local pass = self:AddRenderPass();
		pass:SetGeoset(geoset.id);
		pass:SetStartIndex(nStartIndex);

		for _, rectangle in ipairs(mapRectangles[block.id]) do
			local nIndexCount = 6;
			local nVertices = 4;
			local vertices = rectangle:GetVertices();

			if (nIndexCount + geoset:GetIndexCount()) >= 0xffff then
				nStartIndex = #self.m_indices;
				pass = self:AddRenderPass();
		
				pass:SetGeoset(geoset.id);
				pass:SetStartIndex(nStartIndex);
			end

			geoset.icount = geoset.icount + nIndexCount;
			geoset.vcount = geoset.vcount + nVertices;
			pass.indexCount = pass.indexCount + nIndexCount;
			pass.tex = index - 1;

			local vertex_weight = 255;

			for i, vertice in ipairs(vertices) do
				local modelVertex = ModelVertice:new();
				modelVertex.pos = vertice.position;
				modelVertex.normal = vertice.normal;
				modelVertex.color0 = vertice.color2;
				modelVertex.texcoords[1] = vertice.uv[1];
				modelVertex.texcoords[2] = vertice.uv[2];
				modelVertex.weights[1] = vertex_weight;
				if rectangle:GetBoneIndex(i) == -1 then
					modelVertex.bones[1] = rootBoneIndex;
				else
					modelVertex.bones[1] = rectangle:GetBoneIndex(i);
				end
				table.insert(self.m_vertices, modelVertex);
				aabb:Extend(modelVertex.pos);
			end 

			local start_index = total_count;
			table.insert(self.m_indices, start_index + 0);
			table.insert(self.m_indices, start_index + 1);
			table.insert(self.m_indices, start_index + 2);
			table.insert(self.m_indices, start_index + 0);
			table.insert(self.m_indices, start_index + 2);
			table.insert(self.m_indices, start_index + 3);

			total_count = total_count + nVertices;
		end
	end

	self.m_minExtent = aabb:GetMin();
	self.m_maxExtent = aabb:GetMax();
end	

function BMaxModel:ParseMovieBlocks()
	for _, movieBlock in ipairs(self.m_movieBlocks) do
		movieBlock:ParseMovieInfo();
		movieBlock:ParseActor();
	end
	table.sort(self.m_movieBlocks, function(left, right) 
		local animId1 = left:GetFirstAnimId() or 0;
		local animId2 = right:GetFirstAnimId() or 0;
		return animId1 < animId2
	end)

	for _, movieBlock in ipairs(self.m_movieBlocks) do
		movieBlock:ConnectMovieBlock();
	end

	local assetName;
	local nextIdx;
	-- parse mesh and vertice
	local startTime = 0;
	for _, movieBlock in ipairs(self.m_movieBlocks) do
		if not movieBlock:HasLastBlock() then
			assetName = movieBlock.asset_file;
			if not assetName then
				return;
			end
			self.actor_model = BMaxModel:new();
			local actorFile = self:FindActorFile(assetName);
			self.actor_model:Load(actorFile);
			self:ParseMovieBlockAnimation(startTime, movieBlock);
			startTime = startTime + movieBlock.movieLength + BMaxModel.MovieBlockInterval;
			nextIdx = movieBlock.nextBlock;
		end
	end
	
	while nextIdx ~= -1 do
		local currentBlock = self.m_nodes[nextIdx];
		self:ParseMovieBlockAnimation(startTime, currentBlock);
		nextIdx = currentBlock.nextBlock;
		startTime = startTime + currentBlock.movieLength + BMaxModel.MovieBlockInterval;
	end
	
end

function BMaxModel:ParseMovieBlockAnimation(startTime, currentBlock)
	local bone_anim = currentBlock:GetAnimData();
	local endTime = startTime + currentBlock.movieLength;
	if bone_anim then 
		self.actor_model:AddBoneAnimation(startTime, endTime, bone_anim);
		self.actor_model:UpdateBoneRange();
	end

	for i, animId in ipairs(currentBlock.m_animIds) do
		local animTime = currentBlock.m_animTimes[i];
		local speed = currentBlock.m_speeds[i];
		animTime = animTime and animTime or currentBlock.m_animTimes[1];
		speed = speed or currentBlock.m_speeds[1] or 0;
		-- TODO: endTime logics here is WRONG! 
		self.actor_model:AddModelAnimation(startTime + animTime, endTime, speed, animId);
		-- print("anim", animId, startTime + animTime, endTime, speed);
	end
end

function BMaxModel:AddModelAnimation(startTime, endTime, moveSpeed, animId, loopType)
	if(not loopType) then
		-- if movement speed is not zero or the animID is 4 or 5, we will make it looping by default. 
		loopType = (moveSpeed ~= 0 or animId == 4 or animId == 5) and 0 or 1;
	end
	local function UpdateAnim_(anim, startTime, endTime, moveSpeed, animId, loopType)
		anim.timeStart = startTime;
		anim.timeEnd = endTime;
		anim.animId = animId;
		anim.moveSpeed = moveSpeed;
		anim.loopType = loopType;
	end
	for index, animation in ipairs(self.m_animations) do
		if animation.animId == animId then
			UpdateAnim_(animation, startTime, endTime, moveSpeed, animId, loopType)
			self:AddBoneRange(index);
			return;
		end
	end
	local anim = ModelAnimation:new();
	UpdateAnim_(anim, startTime, endTime, moveSpeed, animId, loopType)
	table.insert(self.m_animations, anim);
	self:AddBoneRange();
end

function BMaxModel:AddBoneRange(index)
	for _, frameNode in ipairs(self.m_bones) do
		local bone = frameNode.bone;

		local tranBlock = bone.translation;
		local rotBlock =  bone.rotation;
		local scaleBlock = bone.scaling;
		
		tranBlock:AddRange(index);
		rotBlock:AddRange(index);
		scaleBlock:AddRange(index);
	end
end

function BMaxModel:UpdateBoneRange()
	for _, frameNode in ipairs(self.m_bones) do
		local bone = frameNode.bone;

		local tranBlock = bone.translation;
		local rotBlock =  bone.rotation;
		local scaleBlock = bone.scaling;
		
		tranBlock:UpdateRange();
		rotBlock:UpdateRange();
		scaleBlock:UpdateRange();
	end
end

function BMaxModel:AddBoneAnimation(startTime, endTime, anim_data)
	
	if anim_data then 
		-- inserting the starting static key in case no animation is found. 
		for _, frameNode in ipairs(self.m_bones) do
			frameNode:GenerateStartFrame(startTime);
		end
		for k, v in pairs(anim_data) do
			if (type(v) == "table") then
				local name = v.name;
				if name then
					local frameNode, anim = self:GetBone(name);
					if frameNode then
						local time = v.times;
						local data = v.data;
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
									if(k == 1) then
										-- we will overwrite the starting static key. 
										block:UpdateLastKey(data[k])
										if(time[k] > 0) then
											block:AddKey(data[k])
											block:AddTime(time[k] + startTime);
										end
									else
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
	end
end

function BMaxModel:GetBone(bone_name)
	for _, bone in ipairs(self.m_bones) do
		if(bone.bone_name) then
			local tranName = bone.bone_name.."_trans";
			local rotName = bone.bone_name.."_rot";
			local scaleName = bone.bone_name.."_scale";
			if bone_name == tranName then
				return bone, "trans";
			elseif bone_name == rotName then
				-- print("rot", bone:GetBoneIndex(), bone_name);
				return bone, "rot";
			elseif bone_name == scaleName then
				return bone, "scale";
			end
		end
	end

	return nil;
end

function BMaxModel:FindRootBoneIndex()
	for _, pBone in ipairs(self.m_bones) do
		if not pBone:HasParent() then
			return pBone:GetBoneIndex();
		end
	end
	return 0;
end

function BMaxModel:CreateDefaultAnimation()
	if #self.m_bones == 0 then
		self:CreateRootBone();
	end

	if #self.m_animations == 0 then
		self:AddModelAnimation(0, 0, 0, 0);
	end
end

function BMaxModel:CreateRootBone()
	table.insert(self.m_bones, BMaxFrameNode:new():init(self, 0, 0, 0, 0, 0, 0));
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
	actorFileName = Files.FindFile(actorFileName)
	return actorFileName;
end

function BMaxModel:GetFileName()
	return self.filename or "";
end

function BMaxModel:SetFileName(filename)
	self.filename = filename;
end

function BMaxModel:GetNameAppearanceCount(name)
	local nLastAppearance = 0;

	for key, value in pairs(self.m_name_occurances) do
		if name == key then
			nLastAppearance = value;
			break;
		end
	end

	self.m_name_occurances[name] = nLastAppearance + 1;
	return nLastAppearance;
end
