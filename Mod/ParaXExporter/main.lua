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
NPL.load("(gl)Mod/ParaXExporter/BMaxParser.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)Mod/ParaXExporter/ParaXWriter.lua");
		
		
local ParaXWriter = commonlib.gettable("Mod.ParaXExporter.ParaXWriter");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local BMaxParser = commonlib.gettable("Mod.ParaXExporter.BMaxParser");	
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");	
local ParaXExporter = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.ParaXExporter"));

function ParaXExporter:ctor()
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
	--self:RegisterExporter();
	--self:RegisterCommand();
end

function ParaXExporter:OnLogin()
end
-- called when a new world is loaded. 

function ParaXExporter:OnWorldLoad()
	NPL.load("(gl)Mod/ParaXExporter/test/testParaXExporter.lua");
	local testParaXExporter = commonlib.gettable("tests.testParaXExporter");
	testParaXExporter:testStatic();
end
-- called when a world is unloaded. 

function ParaXExporter:OnLeaveWorld()
end

function ParaXExporter:OnDestroy()
end

-- add plugin integration points with the IDE
function ParaXExporter:RegisterExporter()
	GameLogic.GetFilters():add_filter("GetExporters", function(exporters)
		exporters[#exporters+1] = {id="ParaX", title="ParaX exporter", desc="export ParaX files for 3d movie"}
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
	SaveFileDialog.ShowPage("please enter Parax file name", function(result)
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
@param -native: use C++ exporter, instead of NPL.
/paraxexporter test.x			export current selection to test.stl file
/paraxexporter -b test.bmax		convert test.bmax file to test.stl file
]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			local file_name;
			file_name,cmd_text = CmdParser.ParseString(cmd_text);
			self:Export(file_name, "output.x");
		end,
	};
end

-- @param input_file: *.bmax file name
-- @param output_file: *.x fileame
function ParaXExporter:ConvertFromBMaxToParaX(input_file, output_file)
	local model = BMaxModel:new();
	local writer = ParaXWriter:new();

	model:Load(input_file);
	if model then 
		writer:LoadModel(model.actor_model);
		writer:SaveAsBinary(output_file);
	end
end

-- @param input_file_name: file name. if it is *.bmax, we will convert this file and save output to *.x file.
-- if it is not, we will convert current selection to *.x files. 
-- @param output_file_name: this should be nil, unless you explicitly specify an output name.
-- @param -native: use C++ exporter, instead of NPL.
function ParaXExporter:Export(input_file_name, output_file_name)
	--[[input_file_name = input_file_name or "default.x";
	pri
	local name, extension = string.match(input_file_name,"(.+)%.(%w+)$");

	if(not output_file_name)then
		if(extension == "bmax") then
			output_file_name = name .. ".x";
		elseif(extension == "x") then
			output_file_name = name .. ".x";
		else
			output_file_name = input_file_name..".x";
		end
	end
	LOG.std(nil, "info", "ParaxExporter", "exporting from %s to %s", input_file_name, output_file_name);
	
	local res;
		
		--NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
		--local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");

		--[[local model = BMaxModel:new();
		print (model)
		local blocks = Game.SelectionManager:GetSelectedBlocks();
			if(blocks) then
				model:LoadFromBlocks(blocks);
			end]]
		--local blocks = Game.SelectionManager:GetSelectedBlocks();
	--[[print("123123");
	local input_file = GameLogic.GetWorldDirectory()..input_file_name;
	local output_file = GameLogic.GetWorldDirectory()..output_file_name;
	self:ConvertFromBMaxToParaX(input_file, output_file)--]]

	

end

