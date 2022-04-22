local ModelAnimation = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelAnimation"));

function ModelAnimation:ctor()
	self.animId = 0;
	self.timeStart = 0;
	self.timeEnd = 0;

	self.moveSpeed = 0;
	self.loopType = 1; -- 0 for looping, 1 for non-looping
	self.flags = 0;
	self.d1 = 0;
	self.d2 = 0;
	self.playSpeed = 13333;

	self.boxA = {0, 0, 0};
	self.boxB = {0, 0, 0};

	self.rad = 0;
	self.s = {0, 0};
end