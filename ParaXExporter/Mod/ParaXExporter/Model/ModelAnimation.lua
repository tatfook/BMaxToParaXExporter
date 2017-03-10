local ModelAnimation = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelAnimation"));

function ModelAnimation:ctor()
	self.animID = 0;
	self.timeStart = 0;
	self.timeEnd = 0;

	self.moveSpeed = 0;
	self.loopType = 0;
	self.flags = 0;
	self.d1 = 0;
	self.d2 = 0;
	self.playSpeed = 0;

	self.boxA = {0, 0, 0};
	self.boxB = {0, 0, 0};

	self.rad = 0;
	self.s = {0, 0};
end