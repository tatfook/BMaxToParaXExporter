NPL.load("(gl)Mod/ParaXExporter/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");

local BMaxBlockSignNode = commonlib.inherit(commonlib.gettable("Mod.ParaXExporter.BMaxNode") ,commonlib.gettable("Mod.ParaXExporter.BMaxBlockSignNode"));

function BMaxBlockSignNode:ctor()
	self.signTitle = nil;
end


function BMaxBlockSignNode:ParseBlockSign()
	local block_content = self.block_content;
	if block_content then 
		local cmd = block_content[1];
		if type(cmd) == "table" then 
			return cmd[1];
		end
	end
end

function BMaxBlockSignNode:GetSignTitle()
	if self.signTitle == nil then
		local text = self:ParseBlockSign();
		if(type(text) == "string") then
			self.signTitle = text
		else
			self.signTitle = ""
		end
	end
	return self.signTitle;
end