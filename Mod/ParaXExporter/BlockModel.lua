 --[[
Title: block model
Author(s): LiXizhi
Date: 2015/12/4
Desc: a single cube block model containing all vertices
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/STLExporter/BlockModel.lua");
local BlockModel = commonlib.gettable("Mod.STLExporter.BlockModel");
local node = BlockModel:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local vector2d = commonlib.gettable("mathlib.vector2d");
local BlockModel = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BlockModel"));
local bor = mathlib.bit.bor;
local band = mathlib.bit.band;

BlockModel.FaceInvisiable = 0;
BlockModel.FaceVisiableNotSign = 1;
BlockModel.FaceVisiableSigned = 2;


BlockModel.evf_none = 0;
BlockModel.evf_topFront = 0x001;
BlockModel.evf_topLeft = 0x002;
BlockModel.evf_topRight = 0x004;
BlockModel.evf_topBack = 0x008;
BlockModel.evf_LeftFront = 0x010;
BlockModel.evf_leftBack = 0x020;
BlockModel.evf_rightFont = 0x040;
BlockModel.evf_rightBack = 0x080;
BlockModel.evf_bottomFront = 0x100;
BlockModel.evf_bottomLeft = 0x200;
BlockModel.evf_bottomRight = 0x400;
BlockModel.evf_bottomBack = 0x800;

BlockModel.evf_xyz = 0x01000;
BlockModel.evf_xyNz = 0x02000;
BlockModel.evf_xNyz = 0x04000;
BlockModel.evf_xNyNz = 0x08000;
BlockModel.evf_Nxyz = 0x10000;
BlockModel.evf_NxyNz = 0x20000;
BlockModel.evf_NxNyz = 0x40000;
BlockModel.evf_NxNyNz = 0x80000;

BlockModel.CubeAmbientMaskMap = {
		[0] = bor(bor(BlockModel.evf_topFront, BlockModel.evf_topLeft), BlockModel.evf_NxyNz);
		[1] = bor(bor(BlockModel.evf_topLeft, BlockModel.evf_topBack), BlockModel.evf_Nxyz);
		[2] = bor(bor(BlockModel.evf_topRight, BlockModel.evf_topBack), BlockModel.evf_xyz);
		[3] = bor(bor(BlockModel.evf_topFront, BlockModel.evf_topRight), BlockModel.evf_xyNz);
		[4] = bor(bor(BlockModel.evf_LeftFront, BlockModel.evf_bottomFront), BlockModel.evf_NxNyNz);
		[5] = bor(bor(BlockModel.evf_topFront, BlockModel.evf_LeftFront), BlockModel.evf_NxyNz);
		[6] = bor(bor(BlockModel.evf_topFront, BlockModel.evf_rightFont), BlockModel.evf_xyNz);
		[7] = bor(bor(BlockModel.evf_rightFont, BlockModel.evf_bottomFront), BlockModel.evf_xNyNz);
		[8] = bor(bor(BlockModel.evf_bottomLeft, BlockModel.evf_bottomBack), BlockModel.evf_NxNyz);
		[9] = bor(bor(BlockModel.evf_bottomFront, BlockModel.evf_bottomLeft), BlockModel.evf_NxNyNz);
		[10] = bor(bor(BlockModel.evf_bottomFront, BlockModel.evf_bottomRight), BlockModel.evf_xNyNz);
		[11] = bor(bor(BlockModel.evf_bottomRight, BlockModel.evf_bottomBack), BlockModel.evf_xNyz);
		[12] = bor(bor(BlockModel.evf_leftBack, BlockModel.evf_bottomLeft), BlockModel.evf_NxNyz);
		[13] = bor(bor(BlockModel.evf_topLeft, BlockModel.evf_leftBack), BlockModel.evf_Nxyz);
		[14] = bor(bor(BlockModel.evf_topLeft, BlockModel.evf_LeftFront), BlockModel.evf_NxyNz);
		[15] = bor(bor(BlockModel.evf_LeftFront, BlockModel.evf_bottomLeft), BlockModel.evf_NxNyNz);
		[16] = bor(bor(BlockModel.evf_rightFont, BlockModel.evf_bottomRight), BlockModel.evf_xNyNz);
		[17] = bor(bor(BlockModel.evf_topRight, BlockModel.evf_rightFont), BlockModel.evf_xyNz);
		[18] = bor(bor(BlockModel.evf_topRight, BlockModel.evf_rightBack), BlockModel.evf_xyz);
		[19] = bor(bor(BlockModel.evf_rightBack, BlockModel.evf_bottomRight), BlockModel.evf_xNyz);
		[20] = bor(bor(BlockModel.evf_rightBack, BlockModel.evf_bottomBack), BlockModel.evf_xNyz);
		[21] = bor(bor(BlockModel.evf_topBack, BlockModel.evf_rightBack), BlockModel.evf_xyz);
		[22] = bor(bor(BlockModel.evf_topBack, BlockModel.evf_leftBack), BlockModel.evf_Nxyz);
		[23] = bor(bor(BlockModel.evf_leftBack, BlockModel.evf_bottomBack), BlockModel.evf_NxNyz);
	};

function BlockModel:ctor()
	self.m_vertices = {};
	self.faces = {};
	self.m_nFaceCount = 0;
end

-- init the model as a cube
function BlockModel:InitCube(texFaceNum)
	self:MakeCube(texFaceNum);
	return self;
end

function BlockModel:InitFace()
	for i = 1, 6 do
		table.insert(self.faces, BlockModel.FaceInvisiable);
	end
end

function BlockModel:GetFace(index)
	return self.faces[index];
end


-- make this block model as a cube 
function BlockModel:MakeCube(texFaceNum)
	local vertices = self.m_vertices;

	for i=1, 24 do
		vertices[i] = {};
	end
	--top face
	vertices[1].position = vector3d:new({0,1,0});
	vertices[2].position = vector3d:new({0,1,1});
	vertices[3].position = vector3d:new({1,1,1});
	vertices[4].position = vector3d:new({1,1,0});

	vertices[1].normal = vector3d:new({0,1,0});
	vertices[2].normal = vector3d:new({0,1,0});
	vertices[3].normal = vector3d:new({0,1,0});
	vertices[4].normal = vector3d:new({0,1,0});

	--front face
	vertices[5].position = vector3d:new({0,0,0});
	vertices[6].position = vector3d:new({0,1,0});
	vertices[7].position = vector3d:new({1,1,0});
	vertices[8].position = vector3d:new({1,0,0});

	vertices[5].normal = vector3d:new({0,0,-1});
	vertices[6].normal = vector3d:new({0,0,-1});
	vertices[7].normal = vector3d:new({0,0,-1});
	vertices[8].normal = vector3d:new({0,0,-1});

	--bottom face
	vertices[9].position = vector3d:new({0,0,1});
	vertices[10].position = vector3d:new({0,0,0});
	vertices[11].position = vector3d:new({1,0,0});
	vertices[12].position = vector3d:new({1,0,1});

	vertices[9].normal = vector3d:new({0,-1,0});
	vertices[10].normal = vector3d:new({0,-1,0});
	vertices[11].normal = vector3d:new({0,-1,0});
	vertices[12].normal = vector3d:new({0,-1,0});

	--left face
	vertices[13].position = vector3d:new({0,0,1});
	vertices[14].position = vector3d:new({0,1,1});
	vertices[15].position = vector3d:new({0,1,0});
	vertices[16].position = vector3d:new({0,0,0});

	vertices[13].normal = vector3d:new({-1,0,0});
	vertices[14].normal = vector3d:new({-1,0,0});
	vertices[15].normal = vector3d:new({-1,0,0});
	vertices[16].normal = vector3d:new({-1,0,0});

	--right face
	vertices[17].position = vector3d:new({1,0,0});
	vertices[18].position = vector3d:new({1,1,0});
	vertices[19].position = vector3d:new({1,1,1});
	vertices[20].position = vector3d:new({1,0,1});

	vertices[17].normal = vector3d:new({1,0,0});
	vertices[18].normal = vector3d:new({1,0,0});
	vertices[19].normal = vector3d:new({1,0,0});
	vertices[20].normal = vector3d:new({1,0,0});

	--back face
	vertices[21].position = vector3d:new({1,0,1});
	vertices[22].position = vector3d:new({1,1,1});
	vertices[23].position = vector3d:new({0,1,1});
	vertices[24].position = vector3d:new({0,0,1});

	vertices[21].normal = vector3d:new({0,0,1});
	vertices[22].normal = vector3d:new({0,0,1});
	vertices[23].normal = vector3d:new({0,0,1});
	vertices[24].normal = vector3d:new({0,0,1}); 

	if (texFaceNum == 3) then
		vertices[1].uv = vector2d:new(0, 0.5);
		vertices[2].uv = vector2d:new(0, 0);
		vertices[3].uv = vector2d:new(0.5, 0);
		vertices[4].uv = vector2d:new(0.5, 0.5);

		vertices[5].uv = vector2d:new(0, 1);
		vertices[6].uv = vector2d:new(0, 0.5);
		vertices[7].uv = vector2d:new(0.5, 0.5);
		vertices[8].uv = vector2d:new(0.5, 1);

		vertices[9].uv = vector2d:new(0.5, 0.5);
		vertices[10].uv = vector2d:new(0.5, 0);
		vertices[11].uv = vector2d:new(1, 0);
		vertices[12].uv = vector2d:new(1, 0.5);

		vertices[13].uv = vector2d:new(0, 1);
		vertices[14].uv = vector2d:new(0, 0.5);
		vertices[15].uv = vector2d:new(0.5, 0.5);
		vertices[16].uv = vector2d:new(0.5, 1);

		vertices[17].uv = vector2d:new(0, 1);
		vertices[18].uv = vector2d:new(0, 0.5);
		vertices[19].uv = vector2d:new(0.5, 0.5);
		vertices[20].uv = vector2d:new(0.5, 1);

		vertices[21].uv = vector2d:new(0, 1);
		vertices[22].uv = vector2d:new(0, 0.5);
		vertices[23].uv = vector2d:new(0.5, 0.5);
		vertices[24].uv = vector2d:new(0.5, 1);
	elseif (texFaceNum == 4) then
		vertices[1].uv = vector2d:new(0, 0.5);
		vertices[2].uv = vector2d:new(0, 0);
		vertices[3].uv = vector2d:new(0.5, 0);
		vertices[4].uv = vector2d:new(0.5, 0.5);

		vertices[5].uv = vector2d:new(0, 1);
		vertices[6].uv = vector2d:new(0, 0.5);
		vertices[7].uv = vector2d:new(0.5, 0.5);
		vertices[8].uv = vector2d:new(0.5, 1);

		vertices[9].uv = vector2d:new(0.5, 0.5);
		vertices[10].uv = vector2d:new(0.5, 0);
		vertices[11].uv = vector2d:new(1, 0);
		vertices[12].uv = vector2d:new(1, 0.5);

		vertices[13].uv = vector2d:new(0.5, 1);
		vertices[14].uv = vector2d:new(0.5, 0.5);
		vertices[15].uv = vector2d:new(1, 0.5);
		vertices[16].uv = vector2d:new(1, 1);

		vertices[17].uv = vector2d:new(0.5, 1);
		vertices[18].uv = vector2d:new(0.5, 0.5);
		vertices[19].uv = vector2d:new(1, 0.5);
		vertices[20].uv = vector2d:new(1, 1);

		vertices[21].uv = vector2d:new(0, 1);
		vertices[22].uv = vector2d:new(0, 0.5);
		vertices[23].uv = vector2d:new(0.5, 0.5);
		vertices[24].uv = vector2d:new(0.5, 1);
	elseif (texFaceNum == 6) then
		vertices[1].uv = vector2d:new(0.5, 0);
		vertices[2].uv = vector2d:new(0.5, 0);
		vertices[3].uv = vector2d:new(0.375, 0);
		vertices[4].uv = vector2d:new(0.375, 1);

		vertices[5].uv = vector2d:new(0.5, 1);
		vertices[6].uv = vector2d:new(0.5, 0);
		vertices[7].uv = vector2d:new(0.375, 0);
		vertices[8].uv = vector2d:new(0.375, 1);

		vertices[9].uv = vector2d:new(0.625, 0);
		vertices[10].uv = vector2d:new(0.625, 1);
		vertices[11].uv = vector2d:new(0.75, 1);
		vertices[12].uv = vector2d:new(0.75, 0);

		vertices[13].uv = vector2d:new(0.125, 1);
		vertices[14].uv = vector2d:new(0.125, 0);
		vertices[15].uv = vector2d:new(0, 0);
		vertices[16].uv = vector2d:new(0, 1);

		vertices[17].uv = vector2d:new(0.375, 1);
		vertices[18].uv = vector2d:new(0.375, 0);
		vertices[19].uv = vector2d:new(0.25, 0);
		vertices[20].uv = vector2d:new(0.25, 1);

		vertices[21].uv = vector2d:new(0.25, 1);
		vertices[22].uv = vector2d:new(0.25, 0);
		vertices[23].uv = vector2d:new(0.125, 0);
		vertices[24].uv = vector2d:new(0.125, 1);
	else
		vertices[1].uv = vector2d:new(0, 1);
		vertices[2].uv = vector2d:new(0, 0);
		vertices[3].uv = vector2d:new(1, 0);
		vertices[4].uv = vector2d:new(1, 1);

		vertices[5].uv = vector2d:new(0, 1);
		vertices[6].uv = vector2d:new(0, 0);
		vertices[7].uv = vector2d:new(1, 0);
		vertices[8].uv = vector2d:new(1, 1);

		vertices[9].uv = vector2d:new(0, 1);
		vertices[10].uv = vector2d:new(0, 0);
		vertices[11].uv = vector2d:new(1, 0);
		vertices[12].uv = vector2d:new(1, 1);

		vertices[13].uv = vector2d:new(0, 1);
		vertices[14].uv = vector2d:new(0, 0);
		vertices[15].uv = vector2d:new(1, 0);
		vertices[16].uv = vector2d:new(1, 1);

		vertices[17].uv = vector2d:new(0, 1);
		vertices[18].uv = vector2d:new(0, 0);
		vertices[19].uv = vector2d:new(1, 0);
		vertices[20].uv = vector2d:new(1, 1);

		vertices[21].uv = vector2d:new(0, 1);
		vertices[22].uv = vector2d:new(0, 0);
		vertices[23].uv = vector2d:new(1, 0);
		vertices[24].uv = vector2d:new(1, 1);
	end
end

function BlockModel:OffsetPosition(dx, dy, dz)
	for _, vertice in pairs(self.m_vertices) do
		if(vertice.position)then
			vertice.position:add(dx, dy, dz);
		end
	end
end

-- TODO: please note it does not clone the vertex
-- @param nVertexIndex: 0 based index
function BlockModel:AddVertex(from_block, nVertexIndex)
	table.insert(self.m_vertices, from_block.m_vertices[nVertexIndex+1]);
	return #self.m_vertices - 1;
end

function BlockModel:SetFaceVisible(index)
	self.faces[index + 1] = BlockModel.FaceVisiableNotSign;
end

function BlockModel:SetFaceUsed(index)
	self.faces[index + 1] = BlockModel.FaceVisiableSigned;
end

function BlockModel:IsFaceNotUse(index)
	return self.faces[index + 1] == BlockModel.FaceVisiableNotSign;
end	

function BlockModel:AddFace(from_block, nFaceIndex)
	local nFirstVertex = nFaceIndex * 4;
	for v = 0,3 do
		local i = nFirstVertex + v;
		self:AddVertex(from_block, i);
	end
end

function BlockModel:SetVertexColor(index, color)
	self.m_vertices[index+1].color2 = color;
end

function BlockModel:GetVertices()
	return self.m_vertices;
end

-- each rectangle face has two triangles, and 4 vertices
function BlockModel:GetFaceCount()
	return (self:GetVerticesCount()) / 4;
end

function BlockModel:GetVerticesCount()
	return #(self.m_vertices);
end

function BlockModel:GetVertex(nIndex)
	return self.m_vertices[nIndex+1];
end

function BlockModel:CalculateCubeVertexAOShadowLevel(nIndex, aoFlags)
	local nShadowValues = band(aoFlags, BlockModel.CubeAmbientMaskMap[nIndex]);
		if (nShadowValues > 0) then
			return self:CountBits(nShadowValues)*45;
		end
	return 0;
end

function BlockModel:CountBits(v)
	local count = 0;
	while v ~= 0 do
		count = count + 1;
		v = band(v, v - 1);
	end
	return count;
end

-- @param nFaceIndex: 0 based index
-- @param nTriangleIndex: 0 for first, 1 for second
-- @return v1,v2,v3 on the face
function BlockModel:GetFaceTriangle(nFaceIndex, nTriangleIndex)
	local nFirstVertexIndex = nFaceIndex*4+1;
	local vertices = self.m_vertices;
	if(nTriangleIndex == 0) then
		return vertices[nFirstVertexIndex].position, vertices[nFirstVertexIndex+1].position, vertices[nFirstVertexIndex+2].position;
	else
		return vertices[nFirstVertexIndex].position, vertices[nFirstVertexIndex+2].position, vertices[nFirstVertexIndex+3].position;
	end
end

function BlockModel:ClearVertices()
	self.m_nFaceCount = 0
	self.m_vertices = {};
end