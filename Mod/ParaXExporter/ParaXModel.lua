NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/ParaXHeader.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");

local ParaXHeader = commonlib.gettable("Mod.ParaXExporter.ParaXHeader");
local BlockTypes = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Common = commonlib.gettable("Mod.ParaXExporter.Common")
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel")

local ParaXModel = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.ParaXModel"));


function ParaXModel:ctor()
	self.m_movie_blocks = {};
	self.m_bAutoScale = true;

	self.m_nodes = {};
	self.m_header = ParaXHeader:new();
	
	self.actor_model = BMaxModel:new();
end

-- public: load from file
-- @param bmax_filename: load from *.bmax file
function ParaXModel:Load(bmax_filename)
	if(not bmax_filename)then return end
	--local xmlRoot = ParaXML.LuaXML_ParseFile(bmax_filename);
	--self:ParseHeader(xmlRoot);
	self:ParseActor(bmax_filename);
end

function ParaXModel:ParseHeader(xmlRoot)
	if(not xmlRoot)then return end
	local blocktemplate = xmlRoot[1];
	if(blocktemplate and blocktemplate.attr and blocktemplate.attr.auto_scale and (blocktemplate.attr.auto_scale == "false" or blocktemplate.attr.auto_scale == "False"))then
		self.m_bAutoScale = false;	
	end
end

function ParaXModel:ParseBlocks(xmlRoot)
	if(not xmlRoot)then return end
	local node;
	local result;

	NPL.load("(gl)Mod/ParaXExporter/ParaXMovieBlock.lua");
	local ParaXMovieBlock = commonlib.gettable("Mod.ParaXExporter.ParaXMovieBlock");
	local index = 1;
	for node in commonlib.XPath.eachNode(xmlRoot, "/pe:blocktemplate/pe:blocks") do
		--find block node
		
		local block_item = commonlib.LoadTableFromString(node[1])[1];
		if block_item[4] == 228 then
			local movie_block = ParaXMovieBlock:new();
			movie_block:Init(block_item);
			self.m_movie_blocks[index] = movie_block;
			index = index + 1;
		end
	end
end

function ParaXModel:ParseActor(bmax_filename)
	self.actor_model:Load(bmax_filename);
end


