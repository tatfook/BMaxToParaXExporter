local ModelRenderPass = commonlib.inherit(nil, commonlib.gettable("Mod.ParaXExporter.Model.ModelRenderPass"));

function ModelRenderPass:ctor()
	self.cull = true;
	self.texanim = -1;
	self.color = -1;
	self.opacity = -1;

	self.vertexStart = 0;
	self.vertexEnd = 0;
	self.tex = 0;
	self.m_fReserved0 = 0;
	self.blendmode = 0;
	self.order = 0;

	self.geoset = 0;
	self.indexStart = 0;
	self.indexCount = 0;
end

function ModelRenderPass:SetGeoset(geoset)
	if geoset ~= nil then
		self.geoset = geoset;
	end
end

function ModelRenderPass:SetStartIndex(start_index)
	if start_index ~= nil then
		self.indexStart = start_index;
	end
end