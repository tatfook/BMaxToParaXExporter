NPL.load("(gl)script/ide/math/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)script/ide/math/vector.lua");


local vector3d = commonlib.gettable("mathlib.vector3d");
local Common = commonlib.gettable("Mod.ParaXExporter.Common");
local Rectangle = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.Rectangle"));
local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");

Rectangle.DirectionOffsetTable = {
	--top face
	[0]  = vector3d:new({0,0,1});
	[1]  = vector3d:new({1,0,0});
	[2]  = vector3d:new({0,0,-1});
	[3]  = vector3d:new({-1,0,0});

	--front face
	[4]  = vector3d:new({0,1,0});	
	[5]  = vector3d:new({1,0,0});
	[6]  = vector3d:new({0,-1,0});
	[7]  = vector3d:new({-1,0,0});

	--bottom face
	[8]  = vector3d:new({0,0,-1});
	[9]  = vector3d:new({1,0,0});	
	[10] = vector3d:new({0,0,1});	
	[11] = vector3d:new({-1,0,0});	

	--left face
	[12] = vector3d:new({0,1,0});	
	[13] = vector3d:new({0,0,-1});	
	[14] = vector3d:new({0,-1,0});
	[15] = vector3d:new({0,0,1});

	--right face
	[16] = vector3d:new({0,1,0});	
	[17] = vector3d:new({0,0,1});	
	[18] = vector3d:new({0,-1,0});
	[19] = vector3d:new({0,0,-1});

	--back face
	[20] = vector3d:new({0,1,0}); 
	[21] = vector3d:new({-1,0,0});
	[22] = vector3d:new({0,-1,0}); 
	[23] = vector3d:new({1,0,0});
};

function Rectangle:ctor()
	self.nodes = nil;
	self.retangleVertices = {};
end

function Rectangle:init(nodes, faceIndex)
	self.nodes = nodes;
	self.faceIndex = faceIndex;

	return self;
end


function Rectangle:GetNode(index)
	index = index % 4;
	return self.nodes[index + 1], self.nodes[(index + 1) % 4 + 1]; 
end

function Rectangle:UpdateNode(fromNode, toNode, index)
	index = index % 4;
	self.nodes[index + 1] = fromNode;
	self.nodes[(index + 1) % 4 + 1] = toNode;
end

function Rectangle:GetVertices()
	return self.retangleVertices;
end

function Rectangle:GetBoneIndex(index)
	return self.nodes[index]:GetBoneIndex();
end

function Rectangle:CloneNodes()
	local startVertex = self.faceIndex * 4;
	for i = 1, 4 do
		local cube = self.nodes[i]:GetCube();
		local vertices = cube:GetVertices();
		local pos = vector3d:new({})
		table.insert(self.retangleVertices, vertices[startVertex + i]);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	end
end

function Rectangle:ScaleVertices(scale)
	for _, vertice in ipairs(self.retangleVertices) do
		vertice.position = vertice.position:MulByFloat(scale);
	end
end