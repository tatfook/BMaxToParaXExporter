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

testFiles 

"Mod/ParaXExporter/test/test_simple_two_block.bmax" simple two white block
"Mod/ParaXExporter/test/test_simple_four_block.bmax" simple four white block
"Mod/ParaXExporter/test/test_simple_twenty-seven_block.bmax" simple twenty-seven white block
"Mod/ParaXExporter/test/test_different_color_block.bmax" the blocks has two colors
"Mod/ParaXExporter/test/test_different_color_complex.bmax" more complex color in blocks 
"Mod/ParaXExporter/test/test_complex_shape.bmax" complex model has different shapes and colors 

ps:only the last model has animation
]]

local testParaXExporter = commonlib.gettable("tests.testParaXExporter");

function testParaXExporter:testStatic()
	NPL.load("(gl)Mod/ParaXExporter/main.lua");
	local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
	ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/test_muti_movie_block.bmax", "temp/output.x");
end
