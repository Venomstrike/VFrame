-- Author: Max David aka Vènomstrikè
-- LibArena is a Library to get informations in/about a Arena match
-- Designed for VFrame, for usage look up in the VFrame Code or the API Documentation!

---------Setting the lib-----------

local version = 1

lib = LibStub:NewLibrary("LibArena-1.0", version)

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)


if not lib then return end

local classtbl = {
	[62] = "Mage: Arcane",
	[63] = "Mage: Fire",
	[64] = "Mage: Frost",
	[65] = "Paladin: Holy",
	[66] = "Paladin: Protection",
	[70] = "Paladin: Retribution",
	[71] = "Warrior: Arms",
	[72] = "Warrior: Fury",
	[73] = "Warrior: Protection",
	[102] = "Druid: Balance",
	[103] = "Druid: Feral",
	[104] = "Druid: Guardian",
	[105] = "Druid: Restoration",
	[250] = "Death Knight: Blood",
	[251] = "Death Knight: Frost",
	[252] = "Death Knight: Unholy",
	[253] = "Hunter: Beast Mastery",
	[254] = "Hunter: Marksmanship",
	[255] = "Hunter: Survival",
	[256] = "Priest: Discipline",
	[257] = "Priest: Holy",
	[258] = "Priest: Shadow",
	[259] = "Rogue: Assassination",
	[260] = "Rogue: Combat",
	[261] = "Rogue: Subtlety",
	[262] = "Shaman: Elemental",
	[263] = "Shaman: Enhancement",
	[264] = "Shaman: Restoration",
	[265] = "Warlock: Affliction",
	[266] = "Warlock: Demonology",
	[267] = "Warlock: Destruction",
	[268] = "Monk: Brewmaster",
	[269] = "Monk: Windwalker",
	[270] = "Monk: Mistweaver",
}

local UBScount = 0

----------Methode Part-------------

function lib:getMapIndex(mapName, eng)

	locale = GetLocale()

	deDE = { -- German
		[1] = "Ruinen von Lordaeron",
		[2] = "Kanalisation von Dalaran",
		[3] = "Arena von Nagrand",
		[4] = "Der Tigergipfel",
		[5] = "Arena des Schergrats",
		[6] = "Arena der Tol'vir"
	}

	enUS = { -- American English
		[1] = "Ruins of Lordaeron",
		[2] = "Dalaran Sewers",
		[3] = "Nagrand Arena",
		[4] = "The Tiger's Peak",
		[5] = "Blade's Edge Arena",
		[6] = "Tol'Viron Arena"
	}

	esES = { -- Spanish (European)
		[1] = "Ruinas de Lordaeron",
		[2] = "Cloacas de Dalaran",
		[3] = "Arena de Nagrand",
		[4] = "La Cima del Tigre",
		[5] = "Arena Filospada",
		[6] = "Arena Tol'viron"
	}

	frFR = { -- French
		[1] = "Ruines de Lordaeron",
		[2] = "Égouts de Dalaran",
		[3] = "Arène de Nagrand",
		[4] = "Le croc du Tigre",
		[5] = "Arène des Tranchantes",
		[6] = "Arène Tol'viron"
	}

	ruRU = { -- Russian
		[1] = "Руины Лордерона",
		[2] = "Стоки Даларана",
		[3] = "Арена Награнда",
		[4] = "Пик Тигра",
		[5] = "Арена Острогорья",
		[6] = "Арена Тол'вир"
	}

	koKR = { -- Korean
		[1] = "로데론의 폐허",
		[2] = "달라란 하수도",
		[3] = "나그란드 투기장",
		[4] = "범의 봉우리",
		[5] = "칼날 산맥 투기장",
		[6] = "톨비론 투기장"
	}

	zhTW = { -- Chinese (traditional; Taiwan)
		[1] = "羅德隆廢墟",
		[2] = "達拉然下水道",
		[3] = "納葛蘭競技場",
		[4] = "猛虎峰",
		[5] = "劍刃競技場",
		[6] = "托維恩競技場"
	}


	if locale == "deDE" then localetbl = deDE end
	if locale == "enGB" then localetbl = enUS end
	if locale == "enUS" then localetbl = enUS end
	if locale == "esES" then localetbl = esES end
	if locale == "esMX" then localetbl = esES end
	if locale == "frFR" then localetbl = frFR end
	if locale == "ruRU" then localetbl = ruRU end
	if locale == "koKR" then localetbl = koKR end
	if locale == "zhCN" then localetbl = zhTW end
	if locale == "zhTW" then localetbl = zhTW end


	if eng then
		for i,n in pairs(localetbl) do
			if n == mapName then return enUS[i] end
		end
	else
		for i,n in pairs(localetbl) do
			if n == mapName then return i end
		end
	end

	return nil

end

function lib:getSpecIdFromName(name, classToken) -- getting the specID from a specName in any language [Specnames like Frost are exsisting multiple times so we need the class too] 

	for i,n in pairs(classtbl) do	
		id, specName, description, icon, background, role, specClass = GetSpecializationInfoByID(i)
		if specName == name and specClass == classToken then return i end
	end

	return "Unable to get specID from specName: " .. name .. "!"

end

function lib:getRankedInfo(size)
	
	rating, seasonBest, weeklyBest, plays, wins, weeklyPlayed, weeklyWon, cap = GetPersonalRatedInfo(size)

	looses = plays - wins
	zw = wins/plays
	ratio = zw*100

	return wins, looses, math.floor(ratio), rating

end

function lib:IsArenaEnemy(unit) -- returns only true when it is an arena unit and not unknown

	if unit == "arena1" then 
		return true 
	elseif unit == "arena2" then 
		return true 
	elseif unit == "arena3" then 
		return true 
	elseif unit == "arena4" then 
		return true 
	elseif unit == "arena5" then 
		return true 
	else
		return false
	end

end

function lib.callbacks:OnUsed(target, eventname)

	framePEW = CreateFrame("Frame", nil, nil)
	framePEW:RegisterEvent("PLAYER_ENTERING_WORLD")

	if eventname == "MATCH_INFO_UPDATE" then framePEW:SetScript("OnEvent", function() PLAYER_ENTERING_WORLD() end ) end

end

-------------------------------
------GetPlayerInfos Part------
-------------------------------

local IsInArena = false
function PLAYER_ENTERING_WORLD() -- fires when arena is entered or leaved

	instanceType = select(2, IsInInstance())

	-- check if we are entering or leaving an arena
	if instanceType == "arena" then	
			--------------------

			if IsInArena then -- UBS fires 2 times when arena inv accepted while in arena!
				UBScount = -1
			else 
				UBScount = 0
			end

			-- Arena Entered
			IsInArena = true

			print("Arena entered")

			frameUBS = CreateFrame("Frame", nil, nil)
			frameUBS:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
			frameUBS:SetScript("OnEvent", function() UPDATE_BATTLEFIELD_STATUS() end)
			

			--------------------
	else
		if IsInArena == true then
			--------------------

			print("Arena leaved")
			-- Arena Leaved
			UBScount = 0

			IsInArena = false

			--------------------
		end
	end 

end

function UPDATE_BATTLEFIELD_STATUS() -- Fires when the arena begins and ends 
	UBScount = UBScount + 1

	print("UBS: "..UBScount)

	if UBScount == 2 then
		handlePlayedMatch()
	end
	
end

function handlePlayedMatch()
	local total = 0
	local used = false
		 
		local function onUpdate(self, elapsed)
		    total = total + elapsed
		    if total >= 2 then
		    	if not used then
		    		GetMatchInfo()
		    		used = true
		    	end
		    end
		end
		 
		local f = CreateFrame("frame")
		f:SetScript("OnUpdate", onUpdate)
end

function GetMatchInfo()
	UBScount = -3 -- setting -3 because UPDATE_BATTLEFIELD_STATUS is fired twice when in an arena an new arena invite is accepted

	players = {}
	match = {}

	-----Getting infos for all players in the match------
	num = 1
	repeat

		infos = {}
		infos.name, infos.kills, infos.honorableKills, infos.deaths, infos.honorGained, infos.faction, infos.race, infos.class, infos.classToken, infos.dmg, infos.heal, infos.rating, infos.ratingChange, infos.preMatchMMR, infos.mmrChange, infos.specName = GetBattlefieldScore(num)
		infos.win = win
		infos.spec = lib:getSpecIdFromName(infos.specName, infos.classToken)
		players[num] = infos

		num = num + 1
	until not select(1, GetBattlefieldScore(num))
	-----------------------------------

	-----Getting infos about the match--------
	ownFac = GetBattlefieldArenaFaction()
	if ownFac == GetBattlefieldWinner() then win = true else win = false end
	status, mapName, instanceID, bracketMin, bracketMax, teamSize, registeredMatch = GetBattlefieldStatus(1)
	if not registeredMatch then registeredMatch = 0 end

	infos = players[1]; match.rating = infos.rating;
	match.win = win
	match.time = GetBattlefieldInstanceRunTime()
	match.map = mapName
	match.ownFac = ownFac
	if teamSize == "ARENASKIRMISH" then match.size = 2 else match.size = teamSize end
	if teamSize == "ARENASKIRMISH" then match.ranked = false else match.ranked = true end

	lib.callbacks:Fire("MATCH_INFO_UPDATE", match, getArenaPlayers(players, ownFac))

end

function getArenaPlayers(players, ownFac)

	enemys = {}
	team = {}

	mi = 0
	ei = 0
	for i,n in pairs(players) do
		infos = n
		if infos.faction == ownFac then
			mi = mi + 1
			member = {}
				member.dmg = infos.dmg
				member.heal = infos.heal
				member.name = infos.name
				member.spec = infos.spec
				if infos.dmg == 0 and infos.heal == 0 and infos.honorableKills == 0 then member.state = "cleared" else member.state = "normal" end
			team[mi] = member
		else
			ei = ei + 1
			enemy = {}
				enemy.dmg = infos.dmg
				enemy.heal = infos.heal
				enemy.name = infos.name
				enemy.spec = infos.spec
				if infos.dmg == 0 and infos.heal == 0 and infos.honorableKills == 0 then enemy.state = "cleared" else enemy.state = "normal" end
			enemys[ei] = enemy
		end
	end

	if mi <= 5 then
		repeat
			mi = mi + 1
			member = {}
				member.dmg = 0
				member.heal = 0
				member.name = "ni"
				member.spec = 0
				member.state = "ni"
			team[mi] = member
		until mi == 5 
	end

	if ei <= 5 then
		repeat
			ei = ei + 1
			enemy = {}
				enemy.dmg = 0
				enemy.heal = 0
				enemy.name = "ni"
				enemy.spec = 0
				enemy.state = "ni"
			enemys[ei] = enemy
		until ei == 5 
	end

	newPlayers = {}
	newPlayers.enemys = enemys
	newPlayers.team = team

	return newPlayers

end

-------------------------------
-------------------------------


------------------------------------