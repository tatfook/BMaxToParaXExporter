NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");

local BlockTypes = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel")

local BMaxParser = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxParser"));


function BMaxParser:ctor()
	self.m_bAutoScale = true;
	self.actor_model = nil;
end

-- public: load from file
-- @param bmax_filename: load from *.bmax file
function BMaxParser:Load(bmax_filename)
	if(not bmax_filename)then return end
	self:SetFileName(bmax_filename);

	local xmlRoot = ParaXML.LuaXML_ParseFile(self:GetFileName());
	self:ParseHeader(xmlRoot);
	local blocks = self:ParseBlocks(xmlRoot);
	if(blocks) then
		 self:LoadFromBlocks(blocks);
	end
end

function BMaxParser:GetFileName()
	return self.filename or "";
end

function BMaxParser:SetFileName(filename)
	self.filename = filename;
end


function BMaxParser:ParseHeader(xmlRoot)
	if(not xmlRoot)then return end
	local blocktemplate = xmlRoot[1];
	if(blocktemplate and blocktemplate.attr and blocktemplate.attr.auto_scale and (blocktemplate.attr.auto_scale == "false" or blocktemplate.attr.auto_scale == "False"))then
		self.m_bAutoScale = false;	
	end
end

function BMaxParser:ParseBlocks(xmlRoot)
	if(not xmlRoot)then return end
	local node;
	local result;
	for node in commonlib.XPath.eachNode(xmlRoot, "/pe:blocktemplate/pe:blocks") do
		--find block node
		result = node;
		break;
	end
	if(not result)then return end
	return commonlib.LoadTableFromString(result[1]);
end

function BMaxParser:LoadFromBlocks(blocks)
	for k,v in ipairs(blocks) do
		local template_id = v[4];
		if template_id == 228 then
			self:ParseMovieBlock(v[6]);
		end
	end
end

function BMaxParser:ParseMovieBlock(block_data)
	local actor = self:LoadActor(block_data[2]);
	if (actor) then
		self:ParseActor(actor)
	end
end

function BMaxParser:LoadActor(actors)
	local result;
	for k, v in ipairs(actors) do
		local attr = v.attr;
		if attr ~= nil and attr.id == 10062 then
			result = v;
			break;
		end
	end

	return commonlib.LoadTableFromString(result[1]);
end

-- find in world directory, and then find in the current bmax file directory. 
-- return full path
function BMaxParser:FindFile(filename)
	local filename_ = GameLogic.GetWorldDirectory()..filename;
	if(not ParaIO.DoesFileExist(filename_)) then
		filename_ = self:GetFileName():gsub("[^/]+$", "") .. filename:match("([^/]+)$");
		if(not ParaIO.DoesFileExist(filename_)) then
			filename_ = filename;
		end
	end
	return filename_;
end

function BMaxParser:ParseActor(actor)
	self.actor_model = BMaxModel:new();
	self.actor_model:Load();

	local timeseries = actor.timeseries;

	local asset_file = timeseries.assetfile;
	local file_name = asset_file.data[1];
	local name, extension = string.match(file_name, "(.+)%.(%w+)$");

	if (extension == "bmax") then
		local filename = self:FindFile(file_name);
		if(filename) then
			self.actor_model:Load(filename);
			self.actor_model:AddBoneAnimData(timeseries.bones) ;
		else
			LOG.std(nil, "warn", "BMaxParser", "actor file %s not found in %s", filename, self:GetFileName());
		end
	end
end

