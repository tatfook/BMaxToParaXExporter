local AnimationBlock = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.AnimationBlock"));

function AnimationBlock:ctor()
	self.type = 0;
	self.seq = -1;
	self.nRanges = 0;
	self.nTimes = 0;
	self.nKeys = 0;

	self.times = {};
	self.ranges = {};
	self.keys = {};
	self.startRange = 0;
	self.endRange = 0;
end


function AnimationBlock:AddKey(key)
	self.type = 1;
	table.insert(self.keys, key);
	self.nKeys = self.nKeys + 1;
end

function AnimationBlock:UpdateLastKey(key)
	if(self.nKeys > 0) then
		self.keys[self.nKeys] = key;
	end
end

function AnimationBlock:AddTime(time)
	table.insert(self.times, time);
	self.nTimes = self.nTimes + 1;
end

function AnimationBlock:AddRange(index)
	if self.nTimes > 0 then
		if index then 
			self.ranges[index] = {self.startRange, self.endRange};
		else
			table.insert(self.ranges, {self.startRange, self.endRange});
			self.nRanges = self.nRanges + 1;
		end
	end
end


function AnimationBlock:UpdateRange(animIndex)
	self.startRange = self.endRange + 1;
	self.endRange = self.nTimes - 1;
end

