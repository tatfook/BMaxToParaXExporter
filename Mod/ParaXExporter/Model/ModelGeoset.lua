local ModelGeoset = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelGeoset"));

function ModelGeoset:ctor()
	self.id = 0;
	self.vstart = 0;
	self.icount = 0;

	self.id = 0;
	self.d2 = 0;
	self.vcount = 0;
	self.istart = 0;
	self.d3 = 0;
	self.d4 = 0;
	self.d5 = 0;
	self.d6 = 0;
end

function ModelGeoset:SetId(id)
	if id >= 0 then
		self.id = id;
	end
end

function ModelGeoset:SetVertexStart(vstart)
	if vstart ~= nil then
		self.vstart = vstart;
	end
end

function ModelGeoset:GetIndexCount()
	return self.icount;
end