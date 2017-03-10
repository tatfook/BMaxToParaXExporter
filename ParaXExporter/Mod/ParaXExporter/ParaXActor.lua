NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");

local Common = commonlib.gettable("Mod.ParaXExporter.Common");

local ParaXActor = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.ParaXActor"));
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");


function ParaXActor:ctor()
	self.bmax_model = nil;
end


function ParaXActor:InitActor(actor)
	if (not actor) then
		return;
	end

	self:ParseActorContent(actor[1])
end

function ParaXActor:ParseActorContent(actor_content) 
	local actor_table = commonlib.LoadTableFromString(actor_content);
	local time_series = actor_table.timeseries;
	if(not time_series) then
		return;
	end

	local asset_file_path = self:ParseTimeSeriesFromActor(time_series);
	if (asset_file_path ~= nil and asset_file_path ~= "actor") then
		self:ParseAssetFile(asset_file_path);
	end
end

function ParaXActor:ParseTimeSeriesFromActor(time_series)
	local asset_file_data = time_series.assetfile.data;
	return asset_file_data[1];
end

function ParaXActor:ParseAssetFile(asset_file_path)
	

	self.bmax_model = BMaxModel:new();
	--local real_path = GameLogic.GetWorldDirectory()..asset_file_path;
	real_path = "worlds/DesignHouse/world/"..asset_file_path;
	self.bmax_model:Load(real_path);
end