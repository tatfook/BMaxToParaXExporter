NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");

local ModelVertice = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelVertice"));

function ModelVertice:ctor()
	self.pos = nil;
	self.weights = {-1, 0, 0, 0};
	self.bones = {0, 0, 0, 0};
	self.normal = nil;
	self.texcoords = {0, 0};
	self.color0 = 0xffffffff;
	self.color1 = 0xffffffff;
end
