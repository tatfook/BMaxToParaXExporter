local ParaXHeader = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.ParaXHeader"));

function ParaXHeader:ctor()
	self.head_id = "para";
	self.version = {1, 0, 0, 0};
	self.name = "ParaXHeader";

	self.type = 0;
	self.is_animated = 0;

end