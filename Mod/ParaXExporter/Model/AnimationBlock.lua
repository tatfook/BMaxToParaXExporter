local AnimationBlock = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.AnimationBlock"));

function AnimationBlock:ctor()
	self.type = 1;
	self.seq = -1;
	self.nRanges = 0;
	self.nTimes = 0;
	self.nKeys = 0;

	self.times = {};
	self.ranges = {};
	self.keys = {};
end


function AnimationBlock:AddKey(key)
	table.insert(self.keys, key);
	self.nKeys = self.nKeys + 1;
end

function AnimationBlock:AddTime(time)
	table.insert(self.times, time);
	self.nTimes = self.nTimes + 1;
end

function AnimationBlock:AddRange()
	local currentRange = 0;
	if self.nRanges > 0 then
		currentRange = self.ranges[self.nRanges][2] + 1;
	end
	table.insert(self.ranges, {currentRange, self.nTimes - 1});
	self.nRanges = self.nRanges + 1;
end