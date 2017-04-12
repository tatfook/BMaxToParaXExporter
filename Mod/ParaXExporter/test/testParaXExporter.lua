--[[
Title: 
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ParaXExporter/test/testParaXExporter.lua");
local testParaXExporter = commonlib.gettable("tests.testParaXExporter");
testParaXExporter:testStatic()
------------------------------------------------------------
]]

local testParaXExporter = commonlib.gettable("tests.testParaXExporter");

function testParaXExporter:testStatic()
	NPL.load("(gl)Mod/ParaXExporter/main.lua");
	local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
	--ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x");
	ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/test_muti_movie_block.bmax", "temp/output.x");
end
