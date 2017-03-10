NPL.load("(gl)Mod/ParaXExporter/Model/AnimationBlock.lua");
NPL.load("(gl)script/ide/math/vector.lua");


local vector3d = commonlib.gettable("mathlib.vector3d");
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
	self.pivot = vector3d:new({0,0,0});;

	self.axis = vector3d:new({1,0,0});;
end

function ModelBone:AddIdleAnimation()
	self.translation.type = 1;
	self.translation.seq = -1;
	self.translation.nRanges = self.translation.nRanges + 1;
	self.translation.nTimes = self.translation.nTimes + 1;
	self.translation.nKeys = self.translation.nKeys + 1;

	table.insert(self.translation.times, 0);
	table.insert(self.translation.ranges, {0, 1});
	table.insert(self.translation.keys, {0, 0, 0});

	self.translation.nRanges = self.translation.nRanges + 1;
	self.translation.nTimes = self.translation.nTimes + 1;
	self.translation.nKeys = self.translation.nKeys + 1;

	table.insert(self.translation.times, 4000);
	table.insert(self.translation.ranges, {0, 1});
	table.insert(self.translation.keys, {1, 0, 0});

	self.scaling.type = 1;
	self.scaling.seq = -1;
	self.scaling.nTimes = self.scaling.nTimes + 1;
	self.scaling.nRanges = self.scaling.nRanges + 1;
	self.scaling.nKeys = self.scaling.nKeys + 1;
	table.insert(self.scaling.times, 0);
	table.insert(self.scaling.ranges, {0, 1});
	table.insert(self.scaling.keys, {1, 1, 1});

	self.scaling.type = 1;
	self.scaling.seq = -1;
	self.scaling.nTimes = self.scaling.nTimes + 1;
	self.scaling.nRanges = self.scaling.nRanges + 1;
	self.scaling.nKeys = self.scaling.nKeys + 1;
	table.insert(self.scaling.times, 4000);
	table.insert(self.scaling.ranges, {0, 1});
	table.insert(self.scaling.keys, {2, 2, 2});
end

function ModelBone:AddTranAnimation(time, key)

	--[[self.rotation.type = 1;
	self.rotation.seq = -1;
	self.rotation.nTimes = self.rotation.nTimes + 1;
	self.rotation.nKeys = self.rotation.nKeys + 1;
	table.insert(self.rotation.times, 0);
	table.insert(self.rotation.keys, {0, 0, 0, 0});

	self.scaling.type = 1;
	self.scaling.seq = -1;
	self.scaling.nTimes = self.scaling.nTimes + 1;
	self.scaling.nKeys = self.scaling.nKeys + 1;
	table.insert(self.scaling.times, 0);
	table.insert(self.scaling.keys, {1, 1, 1});--]]

end

function ModelBone:GetDefaultAxis()
	return self.axis;
end

function ModelBone:AddRotAnimationFrame(time, angel)
	
end

function ModelBone:SetWalkAnimation()
	self.animid = 4;
end