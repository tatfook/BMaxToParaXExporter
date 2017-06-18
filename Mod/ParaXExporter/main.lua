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
		local desc = L"将多个电影方块导出为 *.x 动画文件";
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

function ParaXExporter:OnClickExport()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入ParaX文件名:", function(result)
		if(result and result~="") then
			ParaXExporter.last_filename = result;
			local filename = GameLogic.GetWorldDirectory()..result;
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
			file_name,cmd_text = CmdParser.ParseString(cmd_text);
			self:Export(file_name);
		end,
	};
end

-- @param input_file: *.bmax file name
-- @param output_file: *.x fileame
function ParaXExporter:ConvertFromBMaxToParaX(input_file, output_file)
	self:Export(input_file, output_file);
end

-- @param input_file_name: file name. if it is *.bmax, we will convert this file and save output to *.x file.
-- if it is not, we will convert current selection to *.x files. 
-- @param output_file_name: this should be nil, unless you explicitly specify an output name.
-- @param -native: use C++ exporter, instead of NPL.
function ParaXExporter:Export(input_file_name, output_file_name)

	local name, extension = string.match(input_file_name,"(.+)%.(%w+)$");

	if(not output_file_name)then
		if(extension == "bmax") then
			output_file_name = name;
		elseif(extension == "x") then
			output_file_name = name;
		else
			output_file_name = input_file_name;
		end
	end

	LOG.std(nil, "info", "ParaXExporter", "exporting from %s to %s", input_file_name, output_file_name);
	local model = BMaxModel:new();
	local isValid = true;
	if(extension == "bmax") then
		if ParaIO.DoesFileExist(input_file_name) then
			model:Load(input_file_name);
		else 
			isValid = false;
		end
	else
		local blocks = Game.SelectionManager:GetSelectedBlocks();
		if(blocks) then
			model:LoadFromBlocks(blocks);
		end
	end

	if isValid then
		local actor_model;

		if model.m_modelType == BMaxModel.ModelTypeBlockModel then
			actor_model = model;
		elseif model.m_modelType == BMaxModel.ModelTypeMovieModel then
			actor_model = model.actor_model;
		end

		local boundingMin;
		local boundindMax;
		local originRectangles = actor_model.m_originRectangles;
		if originRectangles then
			actor_model:FillVerticesAndIndices(originRectangles);
			self:WriteParaXFile(actor_model, output_file_name, 0);
			boundingMin = actor_model:GetMinExtent();
			boundindMax = actor_model:GetMaxExtent();
		end

		local lodRectangles = actor_model.m_lodRectangles;
		self.lodFiles = {};
		if lodRectangles then
			for index, retangle in ipairs(lodRectangles) do
				actor_model:FillVerticesAndIndices(retangle);
				self:WriteParaXFile(actor_model, output_file_name, BMaxModel.LodIndexToMeter[index]);
			end
		end


		local filename = output_file_name .. ".xml";
		local root_node = {name = "mesh", attr = {version = "1", type = "0"}};

		local boundingTable = {minx=boundingMin[1], miny=boundingMin[2], minz=boundingMin[3],
							   maxx=boundindMax[1], maxy=boundindMax[2], maxz=boundindMax[3]};
		root_node[1] = {name = "boundingbox", attr = boundingTable};
		for i = 1, #self.lodFiles do
			local lodFile = self.lodFiles[i];
			local lodAttrTable = {loddist = lodFile.m, filename = lodFile.filename};
			root_node[i + 1] = {name = "submesh", attr = lodAttrTable};
		end
		self:WriteXMLFile(filename, root_node);
		
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

function ParaXExporter:WriteParaXFile(model, output_file_name, meter)
	if meter > 0 then 
		output_file_name = output_file_name.."_LOD"..meter..".x";
		table.insert(self.lodFiles, {m = meter, filename = string.match(output_file_name, ".+/([^/]*%.%w+)$")});
	else
		output_file_name = output_file_name..".x";
	end


	local writer = ParaXWriter:new();
	writer:LoadModel(model);
	local res = writer:SaveAsBinary(output_file_name);
	if res then 
		--[[_guihelper.MessageBox(format("Successfully saved ParaX file to :%s, do you want to open it?", commonlib.Encoding.DefaultToUtf8(output_file_name)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..output_file_name, "", "", 1);
			end
		end, _guihelper.MessageBoxButtons.YesNo);--]]
		GameLogic.AddBBS("ParaXModel", format(L"成功导出ParaX文件到%s.x", ParaXExporter.last_filename),  4000, "0 255 0");
		
	end
end
