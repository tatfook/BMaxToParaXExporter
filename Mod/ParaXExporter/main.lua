--[[
Title: 
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ParaXExporter/main.lua");
local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)Mod/ParaXExporter/ParaXWriter.lua");

local ParaXWriter = commonlib.gettable("Mod.ParaXExporter.ParaXWriter");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local BMaxParser = commonlib.gettable("Mod.ParaXExporter.BMaxParser");	
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");	
local ParaXExporter = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.ParaXExporter"));

function ParaXExporter:ctor()
	self.lodFiles = {};
end

-- virtual function get mod name

function ParaXExporter:GetName()
	return "ParaXExporter"
end

-- virtual function get mod description 

function ParaXExporter:GetDesc()
	return "ParaXExporter is a plugin in paracraft"
end

function ParaXExporter:init()
	LOG.std(nil, "info", "ParaXExporter", "plugin initialized");
	self:RegisterExporter();
	self:RegisterCommand();
end

function ParaXExporter:OnLogin()
end
-- called when a new world is loaded. 

function ParaXExporter:OnWorldLoad()
	--self:Export("Mod/ParaXExporter/test/1.bmax", "temp/output.x");
end
-- called when a world is unloaded. 

function ParaXExporter:OnLeaveWorld()
end

function ParaXExporter:OnDestroy()
end

-- add plugin integration points with the IDE
function ParaXExporter:RegisterExporter()
	GameLogic.GetFilters():add_filter("GetExporters", function(exporters)
		local title = L"ParaX 动画模型导出";
		local desc = L"将模型方块或多个电影方块导出为 *.x 动画文件";
		exporters[#exporters+1] = {id="ParaX", title=title, desc=desc}
		return exporters;
	end);

	GameLogic.GetFilters():add_filter("select_exporter", function(id)
		if(id == "ParaX") then
			id = nil; -- prevent other exporters
			self:OnClickExport();
		end
		return id;
	end);
end

function ParaXExporter:GetFilenameFullPath(templatename)
	local filename, relative_path;
	templatename = templatename:gsub("_LOD%d+", "")
	if(commonlib.Files.IsAbsolutePath(templatename)) then
		filename = relative_path;
	else
		templatename = templatename:gsub("^blocktemplates/", "");
		templatename = commonlib.Encoding.Utf8ToDefault(templatename);
		relative_path = format("blocktemplates/%s", templatename);
		filename = GameLogic.GetWorldDirectoryAt()..relative_path;
	end
	return filename;
end

function ParaXExporter:OnClickExport()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入ParaX文件名:", function(result)
		if(result and result~="") then
			ParaXExporter.last_filename = result;
			local filename = result
			LOG.std(nil, "info", "ParaXExporter", "exporting to %s", filename);
			GameLogic.RunCommand("paraxexporter", filename);
		end
	end, ParaXExporter.last_filename or "test", nil, "x");
end

function ParaXExporter:RegisterCommand()
	local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
	Commands["paraxexporter"] = {
		name="paraxexporter", 
		quick_ref="/paraxexporter [filename]", 
		desc=[[export a bmax file or current selection to paraX file
/paraxexporter test.x			export current selection to test.x file
]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			local file_name;
			file_name = (cmd_text or ""):gsub("^%s+", ""):gsub("%s+$", "");
			if(file_name and file_name~="") then
				file_name = self:GetFilenameFullPath(file_name)
				self:Export(nil, file_name);
			end
		end,
	};
	Commands["exportxfile"] = {
		name="exportxfile", 
		quick_ref="/exportxfile [filename.fbx|bmax]", 
		desc=[[export a given file(*.fbx|bmax) to paraX file (*.x) file
/exportxfile test.fbx
/exportxfile test.bmax
]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			local filename;
			filename = (cmd_text or ""):gsub("^%s+", ""):gsub("%s+$", "");
			if(filename and filename~="") then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				filename = Files.FindFile(filename)
				if(filename) then
					local output_file_name = filename:gsub("%.(%w+)$", ".x")
					LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", filename, output_file_name);
					NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
					local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
					local attr = ParaXModelAttr:new():initFromAssetFile(filename, function(attr)
						LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", filename, output_file_name);
						attr:SaveToDisk(output_file_name);
						GameLogic.AddBBS(nil, format(L"文件导出到 %s", commonlib.Encoding.DefaultToUtf8(output_file_name)));
					end)
				else
					LOG.std(nil, "info", "ParaXExporter", "file not found for %s", cmd_text);
				end
			end
		end,
	};
end

-- @param input_file: *.bmax file name
-- @param output_file: *.x fileame
function ParaXExporter:ConvertFromBMaxToParaX(input_file, output_file, useTextures, bForceNoScale, zipArchive)
	self:Export(input_file, output_file, useTextures, bForceNoScale, zipArchive);
end

function ParaXExporter:ConvertBlocksToParaX(blocks, output_file_name, bForceNoScale)
	if ((not blocks) or (not output_file_name)) then return end

	if(#blocks == 1) then
		local v = blocks[1];
		local entity = Game.BlockEngine:GetBlockEntity(v[1], v[2], v[3]);
		if(entity and entity:isa(Game.EntityManager.EntityBlockModel)) then
			-- if there is only one entity block model, we will simply export the model data
			local filename = entity:GetModelDiskFilePath();
			NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
			local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
			local attr = ParaXModelAttr:new():initFromPlayer(entity:GetInnerObject())
			LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", filename, output_file_name);
			attr:SaveToDisk(output_file_name);
			GameLogic.AddBBS(nil, format(L"文件导出到 %s", commonlib.Encoding.DefaultToUtf8(output_file_name)));
			return;
		end
	end

	output_file_name, extension = string.match(output_file_name,"(.+)%.(%w+)$");
	--local bmax_file_name = output_file_name..".bmax";
	--self:WriteBMaxFile(bmax_file_name, blocks);

	-- update block entity data if any
	for _, b in ipairs(blocks) do
		b[6] = b[6] or Game.BlockEngine:GetBlockEntityData(b[1], b[2], b[3]);
	end
	
	local model = BMaxModel:new();
	model:UseTextures(true);
	model:EnableAutoScale(not bForceNoScale);
	model:LoadFromBlocks(blocks, true);

	local actor_model;
	if model.m_modelType == BMaxModel.ModelTypeBlockModel then
		actor_model = model;
	elseif model.m_modelType == BMaxModel.ModelTypeMovieModel then
		actor_model = model.actor_model;
	end
	if(not actor_model) then
		LOG.std(nil, "warn", "ParaXExporter", "actor model not found in %s", output_file_name);
		return;
	end

	local boundingMin;
	local boundindMax;
	local originRectangles = actor_model.m_originRectangles;
	if originRectangles then
		actor_model:FillVerticesAndIndices(originRectangles);
		self:WriteParaXFile(actor_model, output_file_name, 0, true);
		boundingMin = actor_model:GetMinExtent();
		boundindMax = actor_model:GetMaxExtent();
	end

	local filename = output_file_name .. ".xml";
	local root_node = {name = "mesh", attr = {version = "1", type = "0"}};

	local boundingTable = {minx=boundingMin[1], miny=boundingMin[2], minz=boundingMin[3],
						   maxx=boundindMax[1], maxy=boundindMax[2], maxz=boundindMax[3]};
	root_node[#root_node+1] = {name = "boundingbox", attr = boundingTable};
	root_node[#root_node+1] = {name = "submesh", attr = {loddist = BMaxModel.LodIndexToMeter[1], 
		filename = string.match(output_file_name, "[^/\\]+$") ..".x"}};

	--self:WriteXMLFile(filename, root_node);
	if(GameLogic)then
		local filename = string.gsub(filename,GameLogic.GetWorldDirectory(),"")
		GameLogic.AddBBS("ParaXModel", format(L"ParaX文件成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)),  4000, "0 255 0");
	end
end

-- @param input_file_name: file name. if it is *.bmax, we will convert this file and save output to *.x file.
-- if it is not, we will convert current selection to *.x files. 
-- @param output_file_name: this should be nil, unless you explicitly specify an output name.
-- @param useTextures: true to export textures
-- @param bForceNoScale: true to export 1:1 .x
function ParaXExporter:Export(input_file_name, output_file_name, useTextures, bForceNoScale, zipArchive)
	local name, extension;
	if( input_file_name ) then
		 name, extension = string.match(input_file_name,"(.+)%.(%w+)$");
	end
	if(not output_file_name)then
		if(extension == "bmax") then
			output_file_name = name;
		elseif(extension == "x") then
			output_file_name = name;
		else
			return;
		end
	end
	if(not output_file_name:match("%.x[ml]*$")) then
		output_file_name = output_file_name .. ".x";
	end

	local zip_root_dir, zip_root_name, zip_file_name, bmax_file_name;
	if (zipArchive) then
		useTextures = true
		local root_dir = ParaIO.GetParentDirectoryFromPath(output_file_name, 0);
		local file_name = ParaIO.GetFileName(output_file_name);
		file_name = string.match(file_name,"(.+)%.(%w+)$");
		zip_root_dir = string.format("%s%s/*.*", root_dir, file_name);
		zip_root_name = string.format("%s%s/%s", root_dir, file_name, file_name);
		zip_file_name = string.format("%s%s.zip", root_dir, file_name);
		bmax_file_name = zip_root_name..".bmax";
	end

	local model = BMaxModel:new();
	model:UseTextures(useTextures);
	local isValid = true;
	if(extension == "bmax") then
		if ParaIO.DoesFileExist(input_file_name) then
			LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", input_file_name, output_file_name);
			model:EnableAutoScale(not bForceNoScale);
			model:Load(input_file_name);
			if (zipArchive) then
				ParaIO.CopyFile(input_file_name, bmax_file_name, true);
			end
		else 
			isValid = false;
		end
	else
		local blocks = Game.SelectionManager:GetSelectedBlocks();
		if(blocks) then
			if(#blocks == 1) then
				local v = blocks[1];
				local entity = Game.BlockEngine:GetBlockEntity(v[1], v[2], v[3]);
				if(entity and entity:isa(Game.EntityManager.EntityBlockModel)) then
					-- if there is only one entity block model, we will simply export the model data
					local filename = entity:GetModelDiskFilePath();
					NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
					local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
					local attr = ParaXModelAttr:new():initFromPlayer(entity:GetInnerObject())
					LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", filename, output_file_name);
					attr:SaveToDisk(output_file_name);
					GameLogic.AddBBS(nil, format(L"文件导出到 %s", commonlib.Encoding.DefaultToUtf8(output_file_name)));
					return;
				end
			end

			-- update block entity data if any
			for _, b in ipairs(blocks) do
				b[6] = b[6] or Game.BlockEngine:GetBlockEntityData(b[1], b[2], b[3]);
			end
			if (zipArchive) then
				self:WriteBMaxFile(bmax_file_name, blocks);
			end
			LOG.std(nil, "info", "ParaXExporter", "exporting from selection to %s", output_file_name);
			
			model:EnableAutoScale(not bForceNoScale);
			model:LoadFromBlocks(blocks);
		end
	end

	if isValid then
		output_file_name = output_file_name:gsub("%.x[ml]*$", "");
		if (zipArchive) then
			output_file_name = zip_root_name;
		end
		local actor_model;

		if model.m_modelType == BMaxModel.ModelTypeBlockModel then
			actor_model = model;
		elseif model.m_modelType == BMaxModel.ModelTypeMovieModel then
			actor_model = model.actor_model;
		end
		if(not actor_model) then
			LOG.std(nil, "warn", "ParaXExporter", "actor model not found in %s", output_file_name);
			return;
		end

		local boundingMin;
		local boundindMax;
		local originRectangles = actor_model.m_originRectangles;
		if originRectangles then
			actor_model:FillVerticesAndIndices(originRectangles);
			isValid = self:WriteParaXFile(actor_model, output_file_name, 0, useTextures);
			boundingMin = actor_model:GetMinExtent();
			boundindMax = actor_model:GetMaxExtent();
		end

		local lodRectangles = actor_model.m_lodRectangles;
		self.lodFiles = {};
		if lodRectangles then
			for index, retangle in ipairs(lodRectangles) do
				actor_model:FillVerticesAndIndices(retangle);
				self:WriteParaXFile(actor_model, output_file_name, BMaxModel.LodIndexToMeter[index+1], useTextures);
			end
		end

		local filename = output_file_name .. ".xml";
		local root_node = {name = "mesh", attr = {version = "1", type = "0"}};

		local boundingTable = {minx=boundingMin[1], miny=boundingMin[2], minz=boundingMin[3],
							   maxx=boundindMax[1], maxy=boundindMax[2], maxz=boundindMax[3]};
		root_node[#root_node+1] = {name = "boundingbox", attr = boundingTable};
		root_node[#root_node+1] = {name = "submesh", attr = {loddist = BMaxModel.LodIndexToMeter[1], 
			filename = string.match(output_file_name, "[^/\\]+$") ..".x"}};

		local nOffset = #root_node;
		for i = 1, #self.lodFiles do
			local lodFile = self.lodFiles[i];
			local lodAttrTable = {loddist = lodFile.m, filename = lodFile.filename};
			root_node[i + nOffset] = {name = "submesh", attr = lodAttrTable};
		end
		self:WriteXMLFile(filename, root_node);
		if(GameLogic)then
			local filename = string.gsub(filename,GameLogic.GetWorldDirectory(),"")
			GameLogic.AddBBS("ParaXModel", format(L"ParaX文件成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)),  4000, "0 255 0");
		end

		if (isValid) then
			if (useTextures) then
				ParaAsset.SetAssetServerUrl("http://cdn.keepwork.com/update61/assetdownload/update/");
				ParaXWriter.loadAssetFile(actor_model.m_textures, function()
					local output_root_folder = ParaIO.GetParentDirectoryFromPath(output_file_name, 0);
					local textures = ParaXWriter.copyFiles(actor_model.m_textures, output_root_folder);
					if (zipArchive) then
						self:WriteZipFile(zip_file_name, zip_root_dir);
					end
				end);
			end
		end

		if true then
			GameLogic.GetFilters():apply_filters("file_exported", "x", filename);
		end
	else
		LOG.std(nil, "info", "ParaXExporter", "no valid input");
	end
end

function ParaXExporter:WriteXMLFile(filename, root_node)
	NPL.load("(gl)script/ide/LuaXML.lua");
		ParaIO.CreateDirectory(filename);
		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then
			file:WriteString([[<?xml version="1.0" encoding="utf-8" ?>]]);
			file:WriteString("\r\n");
			file:WriteString(commonlib.Lua2XmlString(root_node, true) or "");
			file:close();
			LOG.std(nil, "info", "DocGen", "successfully written to %s", filename);
		end
end

function ParaXExporter:WriteParaXFile(model, output_file_name, meter, useTextures)
	if meter > 0 then 
		output_file_name = output_file_name.."_LOD"..meter..".x";
		table.insert(self.lodFiles, {m = meter, filename = string.match(output_file_name, ".+/([^/]*%.%w+)$")});
	else
		output_file_name = output_file_name..".x";
	end


	local writer = ParaXWriter:new();
	writer:LoadModel(model);
	local res = writer:SaveAsBinary(output_file_name, useTextures);
	if res then 
		--[[_guihelper.MessageBox(format("Successfully saved ParaX file to :%s, do you want to open it?", commonlib.Encoding.DefaultToUtf8(output_file_name)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..output_file_name, "", "", 1);
			end
		end, _guihelper.MessageBoxButtons.YesNo);--]]
	end
	return res;
end

function ParaXExporter:WriteBMaxFile(bmax_file_name, blocks)
	ParaIO.CreateDirectory(bmax_file_name);
	local o = {name="pe:blocktemplate", attr = {}};
	o[1] = {name="pe:blocks", [1]=commonlib.serialize_compact(blocks, true),};
	local xml_data = commonlib.Lua2XmlString(o, true, true);
	if (xml_data) then
		local file = ParaIO.open(bmax_file_name, "w");
		if(file:IsValid()) then
			file:WriteString(xml_data);
			file:close();
		end
	end
end

function ParaXExporter:WriteZipFile(zip_file_name, zip_root_dir)
	local file = ParaIO.CreateZip(zip_file_name, "");
	if (file:IsValid()) then
		local dir_name = ParaIO.GetFileName(zip_file_name);
		dir_name = string.match(dir_name,"(.+)%.(%w+)$");
		file:AddDirectory(dir_name, zip_root_dir, 3);
		file:close();
	end
end