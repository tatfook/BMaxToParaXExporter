NPL.load("(gl)Mod/ParaXExporter/Common.lua");
NPL.load("(gl)Mod/ParaXExporter/ParaXActor.lua");

local ParaXActor = commonlib.gettable("Mod.ParaXExporter.ParaXActor");
local Common = commonlib.gettable("Mod.ParaXExporter.Common");

local ParaXMovieBlock = commonlib.inherit(nil,commonlib.gettable("Mod.ParaXExporter.ParaXMovieBlock"));

function ParaXMovieBlock:ctor()
	self.m_actors = {};
	self.cmd = nil;
end

-- public: load from file
-- @param bmax_filename: load from *.bmax file
function ParaXMovieBlock:Init(movie_block)
	if (not movie_block) then
		return;
	end

	self:LoadActorFromMovieBlockData(movie_block[6])
end

function ParaXMovieBlock:LoadActorFromMovieBlockData(block_data)
	if (not block_data) then
		return;
	end

	local cmd = block_data[1];
	self.cmd = cmd[1];

	local actors = block_data[2];
	local index = 1;

	for k, v in ipairs(actors) do
		if v.attr ~= nil then
			if v.attr.id == 10062 then
				local actor = ParaXActor:new();
				actor:InitActor(v);
				self.m_actors[index] = actor;
				index = index + 1;
			end
		end
	end

end
