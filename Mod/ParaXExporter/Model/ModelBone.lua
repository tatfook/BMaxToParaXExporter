NPL.load("(gl)Mod/ParaXExporter/Model/AnimationBlock.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");


local vector3d = commonlib.gettable("mathlib.vector3d");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local AnimationBlock = commonlib.gettable("Mod.ParaXExporter.Model.AnimationBlock");
local ModelBone = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelBone"));


function ModelBone:ctor()
	self.animid = 0;
	self.flags = 0;
	self.parent = -1;
	self.boneid = -1;
	self.translation = AnimationBlock:new();
	self.rotation = AnimationBlock:new();
	self.scaling = AnimationBlock:new();
	self.pivot = vector3d:new({0,0,0});

	self.axis = vector3d:new({0,1,0});
	self.bUsePivot = false;
end

function ModelBone:GetDefaultAxis()
	return self.axis;
end

function ModelBone:AddAnimationFrame(block, time, data)
	table.insert(block.times, time);
	table.insert(block.keys, data);
end