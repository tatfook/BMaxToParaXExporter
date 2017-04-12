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
		if cmd then 
			return cmd[1];
		end
	end
end

function BMaxBlockSignNode:GetSignTitle()
	if self.signTitle == nil then
		self.signTitle = self:ParseBlockSign();
	end
	return self.signTitle;
end