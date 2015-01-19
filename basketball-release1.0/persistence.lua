local sqlite3 = require "sqlite3"
local persistence = {path = system.pathForFile( "sot-basketball-db.db", system.DocumentsDirectory )}

function persistence.initDatabase()
	
	local db = sqlite3.open( persistence.path )
	
	-- we need to execute this shit every time in case the table doesn't exist
	local playerSetup = [[CREATE TABLE IF NOT EXISTS player (id INTEGER PRIMARY KEY, name TEXT, points INTEGER);]]
	db:exec( playerSetup )
	
	local modeSetup = [[CREATE TABLE IF NOT EXISTS mode (id INTEGER PRIMARY KEY, key TEXT); ]]
	db:exec(modeSetup)
	
	local modeResultSetup = [[CREATE TABLE IF NOT EXISTS mode_result(
		player_id INTEGER, mode_id INTEGER, score INTEGER, rounds INTEGER, 
		
		FOREIGN KEY(player_id) REFERENCES player(id),
		FOREIGN KEY(mode_id) REFERENCES mode(id)
		);]]
	db:exec(modeResultSetup)
	
	local count = 0
	local modeCountQuery = "SELECT count(*) as count from mode"
	for row in db:nrows(modeCountQuery) do
		count = row.count
	end
	
	local modes = {freeChallengeMode = {id=1, key="freeChallengeMode"}, timeChallengeMode={id=2, key="timeChallengeMode"}}
	
	if(count == 0) then 
		
		for k, mode in pairs(modes) do 
			local modeInsert = [[INSERT INTO mode(id, key) VALUES (]] .. tostring(mode.id) .. [[, ']] .. mode.key .. [[')]];
			db:exec(modeInsert)
		end
	end
	
	local selectQuery = "SELECT count(*) as count from player"
	
	
	for row in db:nrows(selectQuery) do
		count = row.count
	end
	
	local defaultId = 1
	
	if(count == 0) then
		local playerInsert = [[INSERT INTO player (id, name, points) values (]] .. tostring(defaultId) .. [[, 'default', 0)]]
		db:exec(playerInsert)
		for k, mode in pairs(modes) do 
			local modeResultInsert = [[INSERT INTO mode_result(player_id, mode_id, score, rounds) VALUES (]] .. tostring(defaultId) .. [[, ]] .. mode.id .. [[, 0, 0)]]
	
			db:exec(modeResultInsert)
		end
	end
	
	db:close()
	db = nil
end

function persistence.loadPlayer(name)
	local db = sqlite3.open( persistence.path )
	
	local loadedPlayer = {}
	local playerQuery = [[select * from player where name = ']] .. name .. [[']]
	for row in db:nrows(playerQuery) do
		loadedPlayer.id = row.id
		loadedPlayer.name = row.name
		loadedPlayer.points = row.points
	end
	
	if(not loadedPlayer.id) then
		return nil
	end
	
	local resultsQuery =[[select r.score as score, r.rounds as rounds, m.id as id, m.key as 
	key from mode_result as r join mode as m on r.mode_id = m.id where r.player_id = ]] .. tostring(loadedPlayer.id)
	
	loadedPlayer.results = {}
	for row in db:nrows(resultsQuery) do
		loadedPlayer.results[row.key] = {id=row.id, key=row.key, score=row.score, rounds=row.rounds}
	end
	
	db:close()
	db = nil
	return loadedPlayer
end

function persistence.updatePlayer(player)
	local db = sqlite3.open( persistence.path )
	local playerUpdate = [[update player set points = ]] .. tostring(player.points) .. [[ where id = ]] .. tostring(player.id)
	local g = db:exec(playerUpdate)

	for k,result in pairs(player.results) do 
		local resultUpdate = [[update mode_result set score = ]] .. tostring(result.score) .. [[ , rounds = ]] .. tostring(result.rounds)
			.. [[ where player_id = ]] .. tostring(player.id) .. [[ and mode_id = ]] .. tostring(result.id)
		db:exec(resultUpdate)
	end
	db:close()
	db = nil
end

function persistence.clear()
	local db = sqlite3.open( persistence.path )
	db:exec("update mode_result set score = 0, rounds= 0")
	db:exec("update player set points=0")
	db:close()
end
return persistence