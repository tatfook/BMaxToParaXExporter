NPL.load("(gl)Mod/ParaXExporter/BoneInfo.lua");

local BoneInfo = commonlib.gettable("Mod.ParaXExporter.BoneInfo");

local BMaxAnimGenerator = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.BMaxAnimGenerator"));


function BMaxAnimGenerator:ctor()
	self.m_bHasSetMaxMinPosition = false;
	self.m_vLeftBonePosition = {x = 0, y = 0, z = 0};
	self.m_vRightBonePosition = {0, 0, 0};
	self.m_boneMap = {};
end

function BMaxAnimGenerator:ParseParameters(bone_info, bone_index)
	if (not bone_info[1]) then
		return
	end

	local cmd = bone_info[1];

	local bx = bone_info.attr.bx;
	local by = bone_info.attr.by;
	local bz = bone_info.attr.bz

	local b_position = {bx, by, bz};
	if(self.m_bHasSetMaxMinPosition == false) then
		self.m_bHasSetMaxMinPosition = true;
		self.m_vRightBonePosition = b_postion;
		self.m_vLeftBonePosition = b_postion;
	else 
		if(self.m_vRightBonePosition.z > b_position.z) then
			self.m_vRightBonePosition = b_position;
		end
		
		if(self.m_vLeftBonePosition.z < bz) then
			self.m_vLeftBonePosition = b_postion
		end
	end 
	
	if(not cmd[1]) then
		return;
	end

	print(cmd);
	local cmd_content = cmd[1];
	local bone_flag = "default";

	--local cmd_table = cmd_content.spilt(cmd_content, "-");

	--todo more kind of cmd
	local bone_name = cmd_content;

	local boneInfo = BoneInfo:new();
	boneInfo:SetName(bone_name);
	boneInfo:SetFlag(bone_flag);
	boneInfo:SetIndex(bone_index);
	boneInfo:SetXYZ(bx, by, bz);

	if self.m_boneMap == nil or self.m_boneMap[bone_name] == nil then
		self.m_boneMap[bone_name] = {bone_flag};
	else
		local count = #self.m_boneMap[bone_name];
		self.m_boneMap[bone_name][count + 1] = bone_flag;
	end

	return bone_name
end
