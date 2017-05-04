--[[
Title: 
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ParaXExporter/ParaXWriter.lua");
local ParaXWriter = commonlib.gettable("Mod.ParaXExporter.ParaXWriter");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ParaXExporter/ParaXModel.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/Model/AnimationBlock.lua");

local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local Common = commonlib.gettable("Mod.ParaXExporter.Common");
local AnimationBlock = commonlib.gettable("Mod.ParaXExporter.Model.AnimationBlock");

local ParaXWriter = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.ParaXWriter"));

function ParaXWriter:ctor()
	self.file = nil;

	self.offset = 0;
	self.data_length = 0;
	self.model = nil;
end

function ParaXWriter:SaveAsBinary(output_file_name)
	ParaIO.CreateDirectory(output_file_name);

	if(not self:IsValid()) then
		return false;
	end

	ParaIO.CreateDirectory(output_file_name);

	self.file = ParaIO.open(output_file_name, "w");
	if(self.file:IsValid()) then
		self:WriteTemplate();
		self:WriteHeader();
		self:WriteBody();
		self:WriteXDWordArray();
		LOG.std(nil, "info", "ParaXWriter", "file written to %s with %d bytes", output_file_name, self.data_length);
		self.file:close();
		return true;
	end
	
end

function ParaXWriter:LoadModel(bmaxModel)
	self.model = bmaxModel;
end

function ParaXWriter:IsValid()
	if(self.model) then
		return true;
	end
end


function ParaXWriter:WriteTemplate()
	local file_name = "Mod/ParaXExporter/template.txt";
	if(ParaIO.DoesFileExist(file_name)) then
		local template_file = ParaIO.open(file_name, "r");
		local template_data = template_file:GetText(0, -1);
		template_file:close();
		self.file:write(template_data, #template_data);
	end

end

function ParaXWriter:WriteHeader()

	--local actor = self.model.m_movie_blocks[1].m_actors[3];

	self:WriteName("ParaXHeader");

	self:WriteToken("{");

	-- int list 
	self:WriteToken("<int_list>");
	-- int count 10
	-- 4 para + 4 version + 1 type + 1 animate = 10
	self.file:WriteInt(10);

	self:WriteCharArr("para");

	-- version
	self.file:WriteInt(1);
	self.file:WriteInt(0);
	self.file:WriteInt(0);
	self.file:WriteInt(0);

	-- type 0: PARAX_MODEL_ANIMATED
	self.file:WriteInt(4);

	-- isAnimated 5: not understand(AnimationBitwise;# boolean animBones,animTextures)
	if self.model.bHasBoneBlock then
		self.file:WriteInt(5);
	else 
		self.file:WriteInt(0);
	end
	

	-- minExtent 3 float & maxExtent 3 float
	self:WriteToken("<flt_list>");
	self.file:WriteInt(6);

	local min_extent = self.model:GetMinExtent();
	local max_extent = self.model:GetMaxExtent();
	--local blockMinX,  blockMinY, blockMinZ = bmax_model.m_blockAABB:GetMinValues();
	--local blockMaxX,  blockMaxY, blockMaxZ = bmax_model.m_blockAABB:GetMaxValues();

	self.file:WriteFloat(min_extent[1]);
	self.file:WriteFloat(min_extent[2]);
	self.file:WriteFloat(min_extent[3]);
	
	self.file:WriteFloat(max_extent[1]);
	self.file:WriteFloat(max_extent[2]);
	self.file:WriteFloat(max_extent[3]);

	-- int list 
	self:WriteToken("<int_list>");

	-- int count
	-- 1 nModelFormat
	self.file:WriteInt(1);

	-- nModelFormat 0:default
	self.file:WriteInt(0);

	self:WriteToken("}");
end

function ParaXWriter:WriteBody()
	self:WriteName("ParaXBody");

	self:WriteToken("{");

	--self:WriteXViews();
	self:WriteXTextures();
	--self:WriteXAttachments();
	self:WriteXVertices();
	self:WriteXIndices0();
	self:WriteXGeosets();
	self:WriteXRenderPass();
	self:WriteXBones();
	self:WriteXAnimations();

	self:WriteToken("}");
end

function ParaXWriter:WriteXViews()
	self:WriteName("XViews");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- XViews
	-- no need to do anything, since there is only one view. all view 0 information are duplicated in other nodes.
	-- count 0 
	--[[self.file:WriteInt(12);
	self.file:WriteInt(1);
	for i = 1, 11 do
		self.file:WriteInt(0);
	end--]]

	self.file:WriteInt(1);
	self.file:WriteInt(0);
	self:WriteToken("}");
end

function ParaXWriter:WriteXTextures()

	self:WriteName("XTextures");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- XTextures 1  
	-- int count 3 
	-- 1 xtextures + 1 x (1 type + 1 flags) = 3
	self.file:WriteInt(3);

	local XTexturesCount = 1;
	self.file:WriteInt(XTexturesCount);
	for i = 1, XTexturesCount do 

		--[[/** old texture definition for md2 file*/
		struct ModelTextureDef {
			uint32 type;
			uint32 flags;
			uint32 nameLen;
			uint32 nameOfs;
		};]]--

		-- XTexturesType default 0
		self.file:WriteInt(0);
		-- XTexturesFlag default 0
		self.file:WriteInt(0);
		self:WriteString("Texture/blocks/snow.png");
	end

	
	self:WriteToken("}");
end

function ParaXWriter:WriteXAttachments()
	self:WriteName("XAttachments");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- XAttachments
	-- int count 4 
	-- 1 attachment + 1 attachmentLookup x (1 id + 1 bones) = 4
	self.file:WriteInt(4);

	local XAttachmentCount = 1;
	local XAttachmentLookup = 1;

	self.file:WriteInt(XAttachmentCount);
	self.file:WriteInt(XAttachmentLookup);

	for i = 1, XAttachmentCount do 

		-- XAttachmentId
		self.file:WriteInt(0);

		-- XAttachmentBone
		self.file:WriteInt(2);

		local pos = {0, 0, 0};
		self:Write3DVector(pos, true);

		self:WriteToken("<int_list>");
		self.file:WriteInt(9);
		
		self:WriteAnimationBlock(AnimationBlock:new(), 0);
	end

	for i = 1, XAttachmentLookup do 
		-- XAttachmentLookup not clearly
		-- count 0 
		self.file:WriteInt(0);
	end
	self:WriteToken("}");
end

function ParaXWriter:WriteXVertices()
	local vertices = self.model.m_vertices;
	
	self:WriteName("XVertices");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- XVertices
	-- count 1 nType + 1 nVertexBytes + 1 nVertices + 1 ofsVertices = 4
	self.file:WriteInt(4);

	-- nType default 0
	self.file:WriteInt(0);

	-- nVertexBytes 48
	self.file:WriteInt(48);

	-- nVertices 96
	self.file:WriteInt(#vertices);

	-- ofsVertices default 0
	self.file:WriteInt(self.offset);

	self:AddFileOffset(#vertices * 48)

	self:WriteToken("}");
end

function ParaXWriter:WriteXIndices0()
	local indices = self.model.m_indices;
	self:WriteName("XIndices0");
	self:WriteToken("{");

	--Common:PrintTable(indices);

	-- int list 
	self:WriteToken("<int_list>");
	-- XViews
	-- count 1 nIndices 1 ofsIndices = 2
	self.file:WriteInt(2);

	-- nIndices 0
	self.file:WriteInt(#indices);

	-- ofsIndices 0
	self.file:WriteInt(self.offset);

	self:AddFileOffset(#indices * 2);

	self:WriteToken("}");
end


function ParaXWriter:WriteXGeosets()
	
	self:WriteName("XGeosets");
	self:WriteToken("{");

	local geosets = self.model.m_geosets;
	-- int list 
	self:WriteToken("<int_list>");
	-- XIndices0
	-- count 1 geo_count + 1 x (id + d2 + vstart + vcount + istart + icount + d3 + d4 + d5 + d6) = 11

	self.file:WriteInt(11);

	self.file:WriteInt(#geosets);

	for i, geoset in ipairs(geosets) do
		if(i ~= 1) then
			self:WriteToken("<int_list>");
			self.file:WriteInt(10);
		end
		self.file:WriteInt(geoset.id);
		self.file:WriteInt(geoset.d2);
		self.file:WriteInt(geoset.vstart);
		self.file:WriteInt(geoset.vcount);
		self.file:WriteInt(geoset.istart);
		self.file:WriteInt(geoset.icount);
		self.file:WriteInt(geoset.d3);
		self.file:WriteInt(geoset.d4);
		self.file:WriteInt(geoset.d5);
		self.file:WriteInt(geoset.d6);

		
		local v = {0, 0, 0};
		self:Write3DVector(v, true);
	end

	self:WriteToken("}");
end

function ParaXWriter:WriteXRenderPass()
	self:WriteName("XRenderPass");
	self:WriteToken("{");

	local render_passes = self.model.m_renderPasses;
	local render_passes_count = #render_passes;
	-- int list 
	self:WriteToken("<int_list>");
	-- XRenderPass
	-- count 1 geo_count + 1 x (indexStart + indexCount + vertexStart + vertexEnd) = 6
	
	self.file:WriteInt(6);

	self.file:WriteInt(render_passes_count);


	for i, pass in ipairs(render_passes) do 
		self.file:WriteInt(pass.indexStart);
		self.file:WriteInt(pass.indexCount);
		self.file:WriteInt(pass.vertexStart);
		self.file:WriteInt(pass.vertexEnd);
		self.file:WriteInt(pass.tex);
		
		-- int list 
		self:WriteToken("<flt_list>");

		self.file:WriteInt(1);
		-- count 1 m_fReserved0 
		self.file:WriteFloat(pass.m_fReserved0);

		self:WriteToken("<int_list>");
		if i == render_passes_count then
			self.file:WriteInt(7);
		else 
			self.file:WriteInt(12);
		end

		self.file:WriteInt(pass.texanim);
		self.file:WriteInt(pass.color);
		self.file:WriteInt(pass.opacity);
		self.file:WriteInt(pass.blendmode);
		self.file:WriteInt(pass.order);
		self.file:WriteInt(pass.geoset);
		self.file:WriteInt(0);
	end
	
	self:WriteToken("}");
end

function ParaXWriter:WriteXBones()
	local bones = self.model.m_bones;
	local nbones = #bones;
	self:WriteName("XBones");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- XViews
	-- no need to do anything, since there is only one view. all view 0 information are duplicated in other nodes.
	-- count 0 
	if nbones > 0 then
		self.file:WriteInt(29);
	else
		self.file:WriteInt(1);
	end
	self.file:WriteInt(nbones);

	for i, frameNode in ipairs(bones) do

		local bone = frameNode.bone;
		if bone then 
			self.file:WriteInt(bone.animid);
			self.file:WriteInt(bone.flags);
			self.file:WriteInt(bone.parent);
			self.file:WriteInt(bone.boneid);
		
			self:WriteAnimationBlock(bone.translation, 12);
			self:WriteAnimationBlock(bone.rotation, 16);
			self:WriteAnimationBlock(bone.scaling, 12);
			self:Write3DVector(bone.pivot, true);
			if i < nbones then
				self:WriteToken("<int_list>");
				self.file:WriteInt(28);
			end
		end
	end
	
	
	self:WriteToken("}");
end

function ParaXWriter:WriteXAnimations()
	local animations = self.model.m_animations;
	local animation_count = #animations;

	self:WriteName("XAnimations");
	self:WriteToken("{");
	-- int list 
	self:WriteToken("<int_list>");
	-- count 0 
	self.file:WriteInt(4);

	self.file:WriteInt(animation_count);

	for i, anim in ipairs(animations) do 
		self.file:WriteInt(anim.animId);
		self.file:WriteInt(anim.timeStart);
		self.file:WriteInt(anim.timeEnd);
		
		-- int list 
		self:WriteToken("<flt_list>");
		self.file:WriteInt(1);
		-- count 1 m_fReserved0 
		self.file:WriteFloat(anim.moveSpeed);
		
		self:WriteToken("<int_list>");
		self.file:WriteInt(5);

		self.file:WriteInt(1);
		
		self.file:WriteInt(anim.flags);
		self.file:WriteInt(anim.d1);
		self.file:WriteInt(anim.d2);
		self.file:WriteInt(anim.playSpeed);

		self:WriteToken("<flt_list>");
		self.file:WriteInt(7);
		self:Write3DVector(anim.boxA, false);
		self:Write3DVector(anim.boxB, false);
		
		-- count 1 m_fReserved0 
		self.file:WriteFloat(anim.rad);

		self:WriteToken("<int_list>");
		if i == animation_count then
			self.file:WriteInt(2);
		else 
			self.file:WriteInt(5);
		end

		self.file:WriteInt(anim.s[1]);
		self.file:WriteInt(anim.s[2]);
		
	end
	self:WriteToken("}");
end

function ParaXWriter:WriteXDWordArray()
	
	self:WriteName("XDWORDArray");
	self:WriteRawData();
end

function ParaXWriter:WriteRawData()
	self:WriteName("ParaXRawData");
	self:WriteToken("{");

	self:WriteToken("<int_list>");

	local count = self.data_length / 4;
	self.file:WriteInt(count + 1);
	self.file:WriteInt(count);

	local vertices = self.model.m_vertices;
	for _, vertice in ipairs(vertices) do
		local pos = vertice.pos;
		self.file:WriteFloat(pos[1]);
		self.file:WriteFloat(pos[2]);
		self.file:WriteFloat(pos[3]);

		--print("12");
		self.file:WriteBytes(4, vertice.weights);
		self.file:WriteBytes(4, vertice.bones);

		local normal = vertice.normal;
		self.file:WriteFloat(normal[1]);
		self.file:WriteFloat(normal[2]);
		self.file:WriteFloat(normal[3]);

		local texcoords = vertice.texcoords;
		self.file:WriteFloat(texcoords[1]);
		self.file:WriteFloat(texcoords[2]);

		self.file:WriteInt(vertice.color0);
		self.file:WriteInt(vertice.color1);
	end

	local indices = self.model.m_indices;

	for _, indice in ipairs(indices) do
		self.file:WriteShort(indice);
	end 

	print("12");
	local bones = self.model.m_bones;

	for _, frameNode in ipairs(bones) do
		local bone = frameNode.bone;
		self:InvertRotData(bone)
		self:WriteAnimationBlockRawData(bone.translation);
		self:WriteAnimationBlockRawData(bone.rotation);
		self:WriteAnimationBlockRawData(bone.scaling);
	end
	
	self:WriteToken("}");
end

function ParaXWriter:InvertRotData(bone)
	local keys = bone.rotation.keys;
	for _, key in ipairs(keys) do
		key[1] = -key[1];
		key[2] = -key[2];
		key[3] = -key[3];
	end
end

function ParaXWriter:WriteAnimationBlockRawData(animation_block)

	for _, range in ipairs(animation_block.ranges) do 
		self.file:WriteInt(range[1]);
		self.file:WriteInt(range[2]);
	end
	for _, time in ipairs(animation_block.times) do 
		self.file:WriteInt(time);
	end

	for _, key in ipairs(animation_block.keys) do 
		for i, value in ipairs(key) do
			self.file:WriteFloat(key[i]);
		end
	end
end

function ParaXWriter:WriteCharArr(char_str)
	for i = 1, string.len(char_str) do
	   local number = string.byte(string.sub(char_str, i, i));
       self.file:WriteInt(number);
	end
	
end

function ParaXWriter:WriteName(name)
	local len = string.len(name);
	if len > 0 then
		-- name token
		self:WriteToken("name");
		-- name length
		self.file:WriteInt(len);
		self.file:WriteString(name);
	end
	
end

function ParaXWriter:WriteString(name)
	local len = string.len(name);
	if len > 0 then
		-- name token
		self:WriteToken("string");
		-- name length
		self.file:WriteInt(len);
		self.file:WriteString(name);
		self:WriteToken(";");
	end
	
end

function ParaXWriter:WriteAnimationBlock(animation_block, key_size)
	
	self.file:WriteInt(animation_block.type);
	self.file:WriteInt(animation_block.seq);
	self.file:WriteInt(animation_block.nRanges);
	if(animation_block.nRanges > 0) then
		self.file:WriteInt(self.offset);
		self:AddFileOffset(8 * animation_block.nRanges);
	else 
		self.file:WriteInt(0);
	end
	
	self.file:WriteInt(animation_block.nTimes);
	if(animation_block.nTimes > 0) then
		self.file:WriteInt(self.offset);
		self:AddFileOffset(4 * animation_block.nTimes);
	else 
		self.file:WriteInt(0);
	end
	
	self.file:WriteInt(animation_block.nKeys);
	if(animation_block.nKeys > 0) then
		self.file:WriteInt(self.offset);
		self:AddFileOffset(key_size * animation_block.nKeys);
	else 
		self.file:WriteInt(0);
	end
end

function ParaXWriter:Write3DVector(vector, need_count)

	if vector ~= nil and #vector == 3 then
		if need_count then
			self:WriteToken("<flt_list>");
			self.file:WriteInt(3);
		end
		
		self.file:WriteFloat(vector[1]);
		self.file:WriteFloat(vector[2]);
		self.file:WriteFloat(vector[3]);
		
	end
	--[[5694 192
	vertices 40 * 48 7806
	indices 72 * 2 7950
	bones 3284 8978--]]
end

function ParaXWriter:AddFileOffset(length) 
	self.offset = self.offset + length;
	self.data_length = self.data_length + length;	
end

function ParaXWriter:WriteToken(token)
	if token == "name" then
		self.file:WriteShort(0x01);
	elseif token == "string" then
		self.file:WriteShort(0x02);
	elseif token == "<int_list>" then
		self.file:WriteShort(0x06);
	elseif token == "<flt_list>" then
		self.file:WriteShort(0x07);
	elseif token == "{" then
		self.file:WriteShort(0x0a);
	elseif token == "}" then
		self.file:WriteShort(0x0b);
	elseif token == "[" then
		self.file:WriteShort(0x0e);
	elseif token == "]" then
		self.file:WriteShort(0x0f);
	elseif token == ";" then
		self.file:WriteShort(0x14);
	elseif token == "guid" then
		self.file:WriteShort(0x05);
	elseif token == "template" then
		self.file:WriteShort(0x1f);
	elseif token == "DWORD" then
		self.file:WriteShort(0x29);
	elseif token == "CHAR" then
		self.file:WriteShort(0x2c);
	elseif token == "UCHAR" then
		self.file:WriteShort(0x2d);
	elseif token == "array" then
		self.file:WriteShort(0x34);

	end
end