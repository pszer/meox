GAMESTATE = {}

function SET_GAMESTATE(gs, args)
	if GAMESTATE.unload then
		GAMESTATE:unload()
	end

	GAMESTATE = gs
	if gs.load then
		gs:load(args)
	end
end
