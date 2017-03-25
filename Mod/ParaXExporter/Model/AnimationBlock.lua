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
end