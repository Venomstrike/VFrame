local VFrame = LibStub("AceAddon-3.0"):NewAddon("VFrame", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

-- Info: Frame for PvP infos and a PvP arena statistic frame
-- Tastks: geting infos in arena, handling with data, displaying infos and statistics
-- Autor: Max David aka Vènomstrikè

-- All Frames generated with SimpleUI
-- Arena informations queried with LibArena-1.0

-- License: GNU General Public License version 2 (GPLv2)

-- Thanks to Phanx and all other Users on WowAce for the help to get this AddOn done!


-- TODO 
	-- 
	-- FontString must be set prettier
	-- Proof AddMatchStats and AddClassStats
	-- Creating ClassStats and/or Stats Views

--------------Global Variables----------------
local InfoFrame
local StatFrame
local MatchView
local StatView
local ClassView 
local DebugFrame

local MatchDB
local ClassDB
local StatDB
local LA

local firstPvPUpdate = true

local zc = {1,2,3,4,5}

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

local mapImg = {
	[1] = "Interface\\AddOns\\VFrame\\Images\\Maps\\uc",
	[2] = "Interface\\AddOns\\VFrame\\Images\\Maps\\dala",
	[3] = "Interface\\AddOns\\VFrame\\Images\\Maps\\nagrand",
	[4] = "Interface\\AddOns\\VFrame\\Images\\Maps\\panda",
	[5] = "Interface\\AddOns\\VFrame\\Images\\Maps\\schergrat",
	[6] = "Interface\\AddOns\\VFrame\\Images\\Maps\\uldum"
}

local pImg = {
	["cleared"] = "Interface\\AddOns\\VFrame\\Images\\State\\cleared",
	["leaved"] = "Interface\\AddOns\\VFrame\\Images\\State\\leaved",
	["ni"] = "Interface\\AddOns\\VFrame\\Images\\State\\ni"
}

-- Workaround for setting up the infos in the statistic frames easier
local MatchViewtbl = {}
----------------------------------------------


function VFrame:OnInitialize() -- the initialation part
	
	--firstLoad = nil

	self:HASOS()

	self:print("AddOn succsessfully loaded!")

	--matches = MatchDB; match = matches[1]; self:print(match.size)

end

-----------------Method Part-----------------

function VFrame:StartingUpdate() -- starts the timer for getting ranked infos all 5 seconds

		self:UpdateInfoFrame()
	 	self:ScheduleRepeatingTimer("UpdateInfoFrame", 30)

end

function VFrame:HASOS() -- handle all things on start

	self:HandleFirstLoad()

	self:GetDB()

	InfoFrame = self:CreateInfoFrame()
	StatFrame = self:CreateStatFrame()
	StatFrame:Hide()
	InfoFrame:Show()

	self:ScheduleTimer("StartingUpdate", 4)

	self:RegisterChatCommand("vf", function () if InfoFrame:IsShown() then InfoFrame:Hide() else InfoFrame:Show() end end)
	self:RegisterChatCommand("vfmove", function () if InfoFrame.resize:IsShown() then InfoFrame.resize:Hide() else InfoFrame.resize:Show() end end)

	self:GetUIParent()

	LA = LibStub("LibArena-1.0", true)
	LA.RegisterCallback(self, "MATCH_INFO_UPDATE")

	self:RegisterEvent("PLAYER_LOGOUT")

end

function VFrame:PLAYER_LOGOUT()
	
	dbs = {}
	dbs.matchdb = MatchDB
	dbs.classdb = ClassDB
	dbs.statdb = StatDB

	VFrameDB.char[UnitName("player")] = dbs

end

function VFrame:GetDB()
	
	dbs = VFrameDB.char[UnitName("player")]
	MatchDB = dbs.matchdb
	ClassDB = dbs.classdb
	StatDB = dbs.statdb

end

function VFrame:HandleFirstLoad()

	loaded = firstLoad
	if not loaded then
		loaded = {}
		firstLoad = loaded
		self:print("Creating Database...")
	end

	if not loaded[UnitName("player")] then
		self:CreateDBStructure()
		loaded[UnitName("player")] = 1
		self:print("Database for Player created!")
	end
 
end

function VFrame:CreateDBStructure()
	
	dbs = {}

	do -- creating the structure for the stats db 
		stats = {}
		stats.winned = 0
		stats.time = 0
			map = {}
			map.uc = 0
			map.dala = 0
			map.nagrand = 0
			map.panda = 0
			map.schergrat = 0
			map.uldum = 0
		stats.map = map
			size = {}
			size.two = 0
			size.three = 0
			size.five = 0
		stats.size = size
		stats.ranked = 0
		stats.unranked = 0
		stats.played = 0

		dbs.statdb = stats
	end

	do -- creating the structure for the class db 
		infos = {}
		infos.wins = 0
		infos.played = 0
		infos.lost = 0
		infos.dmg = 0
		infos.heal = 0

		best = {}
		best.name = ""
		best.dmg = 0
		best.heal = 0
		best.race = ""
		best.rating = 0

		infos.best = best

		class = {}
		for i, n in pairs(classtbl) do
			infos.class = n
			class[i] = infos
		end

		dbs.classdb = class
	end

	do -- creating the structure for the match db 
			
		matches = {1,2,3,4,5}
		match = {}
		match.size = 2
		match.win = 1
		match.time = 100050
		match.map = "Arena der Tol'vir"
		match.ownFac = 0
		match.ranked = false
		match.rating = 1000


		team = {1,2,3,4,5}
		for i,n in pairs(team) do 
			member = {}
				member.dmg = 100
				member.heal = 100
				member.name = "testMember"
				member.spec = 70
				member.state = "normal"
			team[i] = member
		end

		enemys = {1,2,3,4,5}
		for i,n in pairs(enemys) do 
			enemy = {}
				enemy.dmg = 100
				enemy.heal = 100
				enemy.name = "testEnemy"
				enemy.spec = 70
				enemy.state = "normal"
			enemys[i] = enemy
		end

		players = {}
		players.team = team
		players.enemys = enemys
		match.players = players

		match.dmg = 0
		match.heal = 0

		for i, n in pairs(matches) do
			matches[i] = match
		end

		dbs.matchdb = matches
	end

	char = {}
	VFrameDB.char[UnitName("player")] = dbs
	self:print("DB structure created, all informations set to 0")

end

local UIFrame
function VFrame:GetUIParent() -- gets the UIParent Frame 
	
	useFrame = CreateFrame("Frame", nil, UIParent)
	UIFrame = useFrame:GetParent()

end

function VFrame:CreateInfoFrame() -- creates the Info Frame

	frame = CreateFrame("Frame", "InfoFrame", UIParent) 
	frame:SetSize(150, 70) 
	frame:SetPoint("CENTER") 
	texture = frame:CreateTexture() 
	texture:SetAllPoints() 
	texture:SetTexture(0,0,0,0.4) 
	frame.background = texture
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetBackdropBorderColor(0, 0, 0, 0.9)

	-- moving frame
	frame.resize = CreateFrame("Frame", "InfoFrame_resize", frame) 
	frame.resize:SetSize(10, 10) 
	frame.resize:SetPoint("TOPRIGHT", 10, 0) 
	texturers = frame.resize:CreateTexture() 
	texturers:SetAllPoints() 
	texturers:SetTexture(0,0,0,1) 
	frame.resize.background = texturers
	frame.resize:EnableMouse(true)
	frame.resize:SetScript("OnMouseDown", function (self, value) InfoFrame:StartMoving() end) 
	frame.resize:SetScript("OnMouseUp", function (self, value) InfoFrame:StopMovingOrSizing() end)
	--frame.resize:Hide()

	-- rating fonts
	frame.f = frame:CreateFontString(nil, "OVERLAY")
	frame.f:SetPoint("RIGHT", frame, "RIGHT", -135, -1)
	frame.f:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
	frame.f:SetJustifyH("LEFT")
	frame.f:SetShadowOffset(1, -1)
	frame.f:SetTextColor(1, 1, 1)
	frame.f:SetText("")

	frame.t = frame:CreateFontString(nil, "OVERLAY")
	frame.t:SetPoint("RIGHT", frame, "RIGHT", -60, -1)
	frame.t:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
	frame.t:SetJustifyH("LEFT")
	frame.t:SetShadowOffset(1, -1)
	frame.t:SetTextColor(1, 1, 1)
	frame.t:SetText("")

	frame.z = frame:CreateFontString(nil, "OVERLAY")
	frame.z:SetPoint("RIGHT", frame, "RIGHT", -5, -1)
	frame.z:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
	frame.z:SetJustifyH("LEFT")
	frame.z:SetShadowOffset(1, -1)
	frame.z:SetTextColor(1, 1, 1)
	frame.z:SetText("Loading...")


	-- rating desc fonts
	frame.f2 = frame:CreateFontString(nil, "OVERLAY")
	frame.f2:SetPoint("TOP", frame, "TOP", 0, -11)
	frame.f2:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
	frame.f2:SetJustifyH("LEFT")
	frame.f2:SetShadowOffset(1, -1)
	frame.f2:SetTextColor(0.9,0.9,0.1)
	frame.f2:SetText("")

	frame.t2 = frame:CreateFontString(nil, "OVERLAY")
	frame.t2:SetPoint("TOP", frame, "TOP", -60, -11)
	frame.t2:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
	frame.t2:SetJustifyH("LEFT")
	frame.t2:SetShadowOffset(1, -1)
	frame.t2:SetTextColor(0.9,0.9,0.1)
	frame.t2:SetText("")

	frame.z2 = frame:CreateFontString(nil, "OVERLAY")
	frame.z2:SetPoint("TOP", frame, "TOP", 60, -11)
	frame.z2:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
	frame.z2:SetJustifyH("LEFT")
	frame.z2:SetShadowOffset(1, -1)
	frame.z2:SetTextColor(0.9,0.9,0.1)
	frame.z2:SetText("")


	-- win loose ratio fonts
	frame.l = frame:CreateFontString(nil, "OVERLAY")
	frame.l:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -109, 5)
	frame.l:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
	frame.l:SetJustifyH("LEFT")
	frame.l:SetShadowOffset(1, -1)
	frame.l:SetTextColor(1, 1, 1)
	frame.l:SetText("")

	frame.w = frame:CreateFontString(nil, "OVERLAY")
	frame.w:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -55, 5)     
	frame.w:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
	frame.w:SetJustifyH("LEFT")
	frame.w:SetShadowOffset(1, -1)
	frame.w:SetTextColor(1, 1, 1)
	frame.w:SetText("")

	frame.r = frame:CreateFontString(nil, "OVERLAY")
	frame.r:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
	frame.r:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
	frame.r:SetJustifyH("LEFT")
	frame.r:SetShadowOffset(1, -1)
	frame.r:SetTextColor(1, 1, 1)
	frame.r:SetText("")

	
	-- InfoFrame Button
	frame.b = CreateFrame("Button", "InfoFrameB", frame, "UIPanelButtonTemplate")
	frame.b:SetSize(160, 20)
	frame.b:SetPoint("TOP", frame, 0, 12)
	frame.b.text = _G["InfoFrameB" .. "Text"]
	frame.b.text:SetText("Statistics")
	frame.b:SetScript("OnClick", function() VFrame:StatFrameButton() end )
	frame.b:Disable()

	frame:Hide()
	
 return frame 

end

function VFrame:CreateStatFrame() -- creates the Statistics Frame

	backdropS = {
	  -- path to the background texture
	  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
	  -- path to the border texture
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = true,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 32,
	  -- thickness of edge segments and square size of edge corners (in pixels)
	  edgeSize = 32,
	  -- distance from the edges of the frame to those of the background texture (in pixels)
	  insets = {
	    left = 11,
	    right = 12,
	    top = 12,
	    bottom = 11
	  }
	}

	frameM = CreateFrame("Frame", "StatFrame", UIParent)
	frameM:SetSize(770, 770)
	frameM:SetFrameStrata("DIALOG")
	frameM:SetPoint("CENTER", UIParent)
	frameM:SetBackdrop(backdropS)
	frameM:SetMovable(true)
	frameM:SetScript("OnMouseDown", function () frameM:StartMoving() end )
	frameM:SetScript("OnMouseUp", function () frameM:StopMovingOrSizing() end )

	frameM.match = CreateFrame("Button", "btnMatch", frameM, "UIPanelButtonTemplate")
	frameM.match:SetSize(80, 35)
	frameM.match:SetPoint("BOTTOMLEFT", frameM, 200, 15)
	frameM.match.text = _G["btnMatch" .. "Text"]
	frameM.match.text:SetText("Matches")
	frameM.match:SetScript("OnClick", function() MatchView:Show(); ClassView:Hide(); StatView:Hide() end )

	frameM.class = CreateFrame("Button", "btnClass", frameM, "UIPanelButtonTemplate")
	frameM.class:SetSize(80, 35)
	frameM.class:SetPoint("BOTTOMLEFT", frameM, 285, 15)
	frameM.class.text = _G["btnClass" .. "Text"]
	frameM.class.text:SetText("Class Stats")
	frameM.class:SetScript("OnClick", function() MatchView:Hide(); ClassView:Show(); StatView:Hide() end )

	frameM.stat = CreateFrame("Button", "btnStat", frameM, "UIPanelButtonTemplate")
	frameM.stat:SetSize(80, 35)
	frameM.stat:SetPoint("BOTTOMLEFT", frameM, 370, 15)
	frameM.stat.text = _G["btnStat" .. "Text"]
	frameM.stat.text:SetText("Stats")
	frameM.stat:SetScript("OnClick", function() MatchView:Hide(); ClassView:Hide(); StatView:Show() end )

	frameM.option = CreateFrame("Button", "btnOption", frameM, "UIPanelButtonTemplate")
	frameM.option:SetSize(65, 35)
	frameM.option:SetPoint("BOTTOMRIGHT", frameM, -85, 15)
	frameM.option.text = _G["btnOption" .. "Text"]
	frameM.option.text:SetText("Options")
	frameM.option:SetScript("OnClick", function()  end )

	frameM.close = CreateFrame("Button", "btnClose", frameM, "UIPanelButtonTemplate")
	frameM.close:SetSize(70, 35)
	frameM.close:SetPoint("BOTTOMRIGHT", frameM, -15, 15)
	frameM.close.text = _G["btnClose" .. "Text"]
	frameM.close.text:SetText("Close")
	frameM.close:SetScript("OnClick", function() StatFrame:Hide() end )

	self:CreateMatchView(frameM)
	self:CreateClassView(frameM)
	self:CreateStatView(frameM)

	MatchView:SetPoint("CENTER", frameM, 0, 15)
	ClassView:SetPoint("CENTER", frameM, 0, 15)
	StatView:SetPoint("CENTER", frameM, 0, 15)

	MatchView:Show()
	ClassView:Hide()
	StatView:Hide()

	-- filling the View Table for easier setting of the elements
	m = {}
		for i,n in pairs(zc) do 
			eg = {}
			if i == 1 then eg.wl = MatchView.m1WL; eg.icon = MatchView.m1Icon; eg.size = MatchView.m1S end
			if i == 2 then eg.wl = MatchView.m2WL; eg.icon = MatchView.m2Icon; eg.size = MatchView.m2S end
			if i == 3 then eg.wl = MatchView.m3WL; eg.icon = MatchView.m3Icon; eg.size = MatchView.m3S end
			if i == 4 then eg.wl = MatchView.m4WL; eg.icon = MatchView.m4Icon; eg.size = MatchView.m4S end
			if i == 5 then eg.wl = MatchView.m5WL; eg.icon = MatchView.m5Icon; eg.size = MatchView.m5S end
			m[i] = eg
		end

	mP = {}
		for i,n in pairs(zc) do 
			eg = {}
			if i == 1 then eg.Name = MatchView.mP1Name; eg.Icon = MatchView.mP1Icon; eg.Dmg = MatchView.mP1Dmg; eg.Heal = MatchView.mP1Heal end
			if i == 2 then eg.Name = MatchView.mP2Name; eg.Icon = MatchView.mP2Icon; eg.Dmg = MatchView.mP2Dmg; eg.Heal = MatchView.mP2Heal end
			if i == 3 then eg.Name = MatchView.mP3Name; eg.Icon = MatchView.mP3Icon; eg.Dmg = MatchView.mP3Dmg; eg.Heal = MatchView.mP3Heal end
			if i == 4 then eg.Name = MatchView.mP4Name; eg.Icon = MatchView.mP4Icon; eg.Dmg = MatchView.mP4Dmg; eg.Heal = MatchView.mP4Heal end
			if i == 5 then eg.Name = MatchView.mP5Name; eg.Icon = MatchView.mP5Icon; eg.Dmg = MatchView.mP5Dmg; eg.Heal = MatchView.mP5Heal end
			mP[i] = eg
		end

	mE = {}
		for i,n in pairs(zc) do 
			eg = {}
			if i == 1 then eg.Name = MatchView.mE1Name; eg.Icon = MatchView.mE1Icon; eg.Dmg = MatchView.mE1Dmg; eg.Heal = MatchView.mE1Heal end
			if i == 2 then eg.Name = MatchView.mE2Name; eg.Icon = MatchView.mE2Icon; eg.Dmg = MatchView.mE2Dmg; eg.Heal = MatchView.mE2Heal end
			if i == 3 then eg.Name = MatchView.mE3Name; eg.Icon = MatchView.mE3Icon; eg.Dmg = MatchView.mE3Dmg; eg.Heal = MatchView.mE3Heal end
			if i == 4 then eg.Name = MatchView.mE4Name; eg.Icon = MatchView.mE4Icon; eg.Dmg = MatchView.mE4Dmg; eg.Heal = MatchView.mE4Heal end
			if i == 5 then eg.Name = MatchView.mE5Name; eg.Icon = MatchView.mE5Icon; eg.Dmg = MatchView.mE5Dmg; eg.Heal = MatchView.mE5Heal end
			mE[i] = eg
		end

	MatchViewtbl.m = m
	MatchViewtbl.mP = mP
	MatchViewtbl.mE = mE


	return frameM

end

function VFrame:CreateMatchView(frameM)
	
	frame = CreateFrame("Frame", "MatchView", frameM)
	frame:SetSize(700, 680)
	frame:SetPoint("CENTER", UIParent)
	texture = frame:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.05,0.05,0.05,1)
	frame.background = texture

	-- creating borderTop
	backdropS = {
	  -- path to the background texture
	  bgFile = nil,  
	  -- path to the border texture
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = true,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 32,
	  -- thickness of edge segments and square size of edge corners (in pixels)
	  edgeSize = 32,
	  -- distance from the edges of the frame to those of the background texture (in pixels)
	  insets = {
	    left = 11,
	    right = 12,
	    top = 12,
	    bottom = 11
	  }
	}
	frame.borderTop = CreateFrame("Frame", "borderTop", frame)
	frame.borderTop:SetSize(710, 125)
	frame.borderTop:SetFrameStrata("DIALOG")
	frame.borderTop:SetPoint("BOTTOMLEFT", frame, -5, 565)
	frame.borderTop:SetBackdrop(backdropS)

	-- creating borderBot
	frame.borderBot = CreateFrame("Frame", "borderBot", frame)
	frame.borderBot:SetSize(710, 190)
	frame.borderBot:SetPoint("BOTTOMLEFT", frame, -5, 390)
	frame.borderBot:SetBackdrop(backdropS)

	-- creating m1Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.m1Icon = CreateFrame("Frame", "m1Icon", frame)
	frame.m1Icon:SetSize(60, 60)
	frame.m1Icon:SetFrameStrata("DIALOG")
	frame.m1Icon:SetPoint("BOTTOMLEFT", frame, 23, 609)
	frame.m1Icon:SetBackdrop(backdropS)
	frame.m1Icon:SetScript("OnMouseUp", function () VFrame:StatFrameUpdateMatches(1) end)

	-- creating m2Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.m2Icon = CreateFrame("Frame", "m2Icon", frame)
	frame.m2Icon:SetSize(60, 60)
	frame.m2Icon:SetFrameStrata("DIALOG")
	frame.m2Icon:SetPoint("BOTTOMLEFT", frame, 148, 609)
	frame.m2Icon:SetBackdrop(backdropS)
	frame.m2Icon:SetScript("OnMouseUp", function () VFrame:StatFrameUpdateMatches(2) end)

	-- creating m3Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.m3Icon = CreateFrame("Frame", "m3Icon", frame)
	frame.m3Icon:SetSize(60, 60)
	frame.m3Icon:SetFrameStrata("DIALOG")
	frame.m3Icon:SetPoint("BOTTOMLEFT", frame, 281, 609)
	frame.m3Icon:SetBackdrop(backdropS)
	frame.m3Icon:SetScript("OnMouseUp", function () VFrame:StatFrameUpdateMatches(3) end)

	-- creating m4Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.m4Icon = CreateFrame("Frame", "m4Icon", frame)
	frame.m4Icon:SetSize(60, 60)
	frame.m4Icon:SetFrameStrata("DIALOG")
	frame.m4Icon:SetPoint("BOTTOMLEFT", frame, 416, 609)
	frame.m4Icon:SetBackdrop(backdropS)
	frame.m4Icon:SetScript("OnMouseUp", function () VFrame:StatFrameUpdateMatches(4) end)

	-- creating m5Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.m5Icon = CreateFrame("Frame", "m5Icon", frame)
	frame.m5Icon:SetSize(60, 60)
	frame.m5Icon:SetFrameStrata("DIALOG")
	frame.m5Icon:SetPoint("BOTTOMLEFT", frame, 557, 609)
	frame.m5Icon:SetBackdrop(backdropS)
	frame.m5Icon:SetScript("OnMouseUp", function () VFrame:StatFrameUpdateMatches(5) end)

	-- creating m1WL
	frame.m1WL = CreateFrame("Frame", "m1WL", frame)
	frame.m1WL:SetSize(20, 60)
	frame.m1WL:SetFrameStrata("DIALOG")
	frame.m1WL:SetPoint("BOTTOMLEFT", frame, 85, 609)
	texture = frame.m1WL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating m2WL
	frame.m2WL = CreateFrame("Frame", "m2WL", frame)
	frame.m2WL:SetSize(20, 60)
	frame.m2WL:SetFrameStrata("DIALOG")
	frame.m2WL:SetPoint("BOTTOMLEFT", frame, 210, 609)
	texture = frame.m2WL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating m3WL
	frame.m3WL = CreateFrame("Frame", "m3WL", frame)
	frame.m3WL:SetSize(20, 60)
	frame.m3WL:SetFrameStrata("DIALOG")
	frame.m3WL:SetPoint("BOTTOMLEFT", frame, 344, 609)
	texture = frame.m3WL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating m4WL
	frame.m4WL = CreateFrame("Frame", "m4WL", frame)
	frame.m4WL:SetSize(20, 60)
	frame.m4WL:SetFrameStrata("DIALOG")
	frame.m4WL:SetPoint("BOTTOMLEFT", frame, 479, 609)
	texture = frame.m4WL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating m5WL
	frame.m5WL = CreateFrame("Frame", "m5WL", frame)
	frame.m5WL:SetSize(20, 60)
	frame.m5WL:SetFrameStrata("DIALOG")
	frame.m5WL:SetPoint("BOTTOMLEFT", frame, 619, 609)
	texture = frame.m5WL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating m1S
	frame.m1S = frame:CreateFontString(nil, "OVERLAY")
	frame.m1S:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 44, 590)
	frame.m1S:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.m1S:SetJustifyH("LEFT")
	frame.m1S:SetShadowOffset(1, -1)
	frame.m1S:SetTextColor(1, 1, 1)
	frame.m1S:SetText("2v2")

	-- creating m2S
	frame.m2S = frame:CreateFontString(nil, "OVERLAY")
	frame.m2S:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 169, 589)
	frame.m2S:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.m2S:SetJustifyH("LEFT")
	frame.m2S:SetShadowOffset(1, -1)
	frame.m2S:SetTextColor(1, 1, 1)
	frame.m2S:SetText("2v2")

	-- creating m3S
	frame.m3S = frame:CreateFontString(nil, "OVERLAY")
	frame.m3S:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 303, 590)
	frame.m3S:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.m3S:SetJustifyH("LEFT")
	frame.m3S:SetShadowOffset(1, -1)
	frame.m3S:SetTextColor(1, 1, 1)
	frame.m3S:SetText("2v2")

	-- creating m4S
	frame.m4S = frame:CreateFontString(nil, "OVERLAY")
	frame.m4S:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 438, 590)
	frame.m4S:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.m4S:SetJustifyH("LEFT")
	frame.m4S:SetShadowOffset(1, -1)
	frame.m4S:SetTextColor(1, 1, 1)
	frame.m4S:SetText("2v2")

	-- creating m5S
	frame.m5S = frame:CreateFontString(nil, "OVERLAY")
	frame.m5S:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 577, 590)
	frame.m5S:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.m5S:SetJustifyH("LEFT")
	frame.m5S:SetShadowOffset(1, -1)
	frame.m5S:SetTextColor(1, 1, 1)
	frame.m5S:SetText("2v2")

	-- creating mIcon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mIcon = CreateFrame("Frame", "mIcon", frame)
	frame.mIcon:SetSize(100, 100)
	frame.mIcon:SetFrameStrata("DIALOG")
	frame.mIcon:SetPoint("BOTTOMLEFT", frame, 56, 427)
	frame.mIcon:SetBackdrop(backdropS)
	frame.mIcon:SetScript("OnMouseUp", function ()  end)

	-- creating mIconS
	frame.mIconS = frame:CreateFontString(nil, "OVERLAY")
	frame.mIconS:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 91, 543)
	frame.mIconS:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mIconS:SetJustifyH("LEFT")
	frame.mIconS:SetShadowOffset(1, -1)
	frame.mIconS:SetTextColor(1, 1, 1)
	frame.mIconS:SetText("Map")

	-- creating mWL
	frame.mWL = CreateFrame("Frame", "mWL", frame)
	frame.mWL:SetSize(20, 100)
	frame.mWL:SetFrameStrata("DIALOG")
	frame.mWL:SetPoint("BOTTOMLEFT", frame, 160, 427)
	texture = frame.mWL:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.5,0.5,0.5,1)

	-- creating mSize
	frame.mSize = frame:CreateFontString(nil, "OVERLAY")
	frame.mSize:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 301, 466)
	frame.mSize:SetFont("Fonts\\ARIALN.TTF", 25, "OUTLINE")
	frame.mSize:SetJustifyH("LEFT")
	frame.mSize:SetShadowOffset(1, -1)
	frame.mSize:SetTextColor(1, 1, 1)
	frame.mSize:SetText("2v2")

	-- creating mRanked
	frame.mRanked = frame:CreateFontString(nil, "OVERLAY")
	frame.mRanked:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 400, 466)
	frame.mRanked:SetFont("Fonts\\ARIALN.TTF", 25, "OUTLINE")
	frame.mRanked:SetJustifyH("LEFT")
	frame.mRanked:SetShadowOffset(1, -1)
	frame.mRanked:SetTextColor(1, 1, 1)
	frame.mRanked:SetText("Ranked")

	-- creating mTime
	frame.mTime = frame:CreateFontString(nil, "OVERLAY")
	frame.mTime:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 545, 465)
	frame.mTime:SetFont("Fonts\\ARIALN.TTF", 25, "OUTLINE")
	frame.mTime:SetJustifyH("LEFT")
	frame.mTime:SetShadowOffset(1, -1)
	frame.mTime:SetTextColor(1, 1, 1)
	frame.mTime:SetText("Time")

	-- creating mRating
	frame.mRating = frame:CreateFontString(nil, "OVERLAY")
	frame.mRating:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 362, 525)
	frame.mRating:SetFont("Fonts\\ARIALN.TTF", 25, "OUTLINE")
	frame.mRating:SetJustifyH("LEFT")
	frame.mRating:SetShadowOffset(1, -1)
	frame.mRating:SetTextColor(1, 1, 1)
	frame.mRating:SetText("At Rating:")

	-- creating mE1Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mE1Icon = CreateFrame("Frame", "mE1Icon", frame)
	frame.mE1Icon:SetSize(60, 60)
	frame.mE1Icon:SetFrameStrata("DIALOG")
	frame.mE1Icon:SetPoint("BOTTOMLEFT", frame, 60, 106)
	frame.mE1Icon:SetBackdrop(backdropS)
	frame.mE1Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mE2Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mE2Icon = CreateFrame("Frame", "mE2Icon", frame)
	frame.mE2Icon:SetSize(60, 60)
	frame.mE2Icon:SetFrameStrata("DIALOG")
	frame.mE2Icon:SetPoint("BOTTOMLEFT", frame, 182, 105)
	frame.mE2Icon:SetBackdrop(backdropS)
	frame.mE2Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mE3Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mE3Icon = CreateFrame("Frame", "mE3Icon", frame)
	frame.mE3Icon:SetSize(60, 60)
	frame.mE3Icon:SetFrameStrata("DIALOG")
	frame.mE3Icon:SetPoint("BOTTOMLEFT", frame, 313, 105)
	frame.mE3Icon:SetBackdrop(backdropS)
	frame.mE3Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mE4Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mE4Icon = CreateFrame("Frame", "mE4Icon", frame)
	frame.mE4Icon:SetSize(60, 60)
	frame.mE4Icon:SetFrameStrata("DIALOG")
	frame.mE4Icon:SetPoint("BOTTOMLEFT", frame, 441, 105)
	frame.mE4Icon:SetBackdrop(backdropS)
	frame.mE4Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mE5Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mE5Icon = CreateFrame("Frame", "mE5Icon", frame)
	frame.mE5Icon:SetSize(60, 60)
	frame.mE5Icon:SetFrameStrata("DIALOG")
	frame.mE5Icon:SetPoint("BOTTOMLEFT", frame, 567, 104)
	frame.mE5Icon:SetBackdrop(backdropS)
	frame.mE5Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mP1Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mP1Icon = CreateFrame("Frame", "mP1Icon", frame)
	frame.mP1Icon:SetSize(60, 60)
	frame.mP1Icon:SetFrameStrata("DIALOG")
	frame.mP1Icon:SetPoint("BOTTOMLEFT", frame, 62, 305)
	frame.mP1Icon:SetBackdrop(backdropS)
	frame.mP1Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mP2Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mP2Icon = CreateFrame("Frame", "mP2Icon", frame)
	frame.mP2Icon:SetSize(60, 60)
	frame.mP2Icon:SetFrameStrata("DIALOG")
	frame.mP2Icon:SetPoint("BOTTOMLEFT", frame, 181, 303)
	frame.mP2Icon:SetBackdrop(backdropS)
	frame.mP2Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mP3Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mP3Icon = CreateFrame("Frame", "mP3Icon", frame)
	frame.mP3Icon:SetSize(60, 60)
	frame.mP3Icon:SetFrameStrata("DIALOG")
	frame.mP3Icon:SetPoint("BOTTOMLEFT", frame, 312, 303)
	frame.mP3Icon:SetBackdrop(backdropS)
	frame.mP3Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mP4Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mP4Icon = CreateFrame("Frame", "mP4Icon", frame)
	frame.mP4Icon:SetSize(60, 60)
	frame.mP4Icon:SetFrameStrata("DIALOG")
	frame.mP4Icon:SetPoint("BOTTOMLEFT", frame, 436, 302)
	frame.mP4Icon:SetBackdrop(backdropS)
	frame.mP4Icon:SetScript("OnMouseUp", function ()  end)

	-- creating mP5Icon
	backdropS = {
	  -- path to the background texture
	  bgFile = select(3, GetSpellInfo(148910)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	frame.mP5Icon = CreateFrame("Frame", "mP5Icon", frame)
	frame.mP5Icon:SetSize(60, 60)
	frame.mP5Icon:SetFrameStrata("DIALOG")
	frame.mP5Icon:SetPoint("BOTTOMLEFT", frame, 563, 300)
	frame.mP5Icon:SetBackdrop(backdropS)
	frame.mP5Icon:SetScript("OnMouseUp", function ()  end)

	-- creating borderVS
	backdropS = {
	  -- path to the background texture
	  bgFile = nil,  
	  -- path to the border texture
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = true,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 32,
	  -- thickness of edge segments and square size of edge corners (in pixels)
	  edgeSize = 32,
	  -- distance from the edges of the frame to those of the background texture (in pixels)
	  insets = {
	    left = 11,
	    right = 12,
	    top = 12,
	    bottom = 11
	  }
	}
	frame.borderVS = CreateFrame("Frame", "borderVS", frame)
	frame.borderVS:SetSize(710, 410)
	frame.borderVS:SetPoint("BOTTOMLEFT", frame, -5, -5)
	frame.borderVS:SetBackdrop(backdropS)

	frame.borderVS2 = CreateFrame("Frame", "borderVS2", frame)
	frame.borderVS2:SetSize(670, 5)
	frame.borderVS2:SetPoint("BOTTOMLEFT", frame, 15, 207)
	texture = frame.borderVS2:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0.2, 0.2, 0.2, 0.9)

	-- creating cutVS
	frame.cutVS = frame.borderVS2:CreateFontString(nil, "DIALOG")
	frame.cutVS:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 328, 197)
	frame.cutVS:SetFont("Fonts\\ARIALN.TTF", 25, "OUTLINE")
	frame.cutVS:SetJustifyH("LEFT")
	frame.cutVS:SetShadowOffset(1, -1)
	frame.cutVS:SetTextColor(1, 1, 1)
	frame.cutVS:SetText("VS")

	-- creating mP1Name
	frame.mP1Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mP1Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 73, 370)
	frame.mP1Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP1Name:SetJustifyH("LEFT")
	frame.mP1Name:SetShadowOffset(1, -1)
	frame.mP1Name:SetTextColor(1, 1, 1)
	frame.mP1Name:SetText("Name")

	-- creating mP2Name
	frame.mP2Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mP2Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 191, 369)
	frame.mP2Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP2Name:SetJustifyH("LEFT")
	frame.mP2Name:SetShadowOffset(1, -1)
	frame.mP2Name:SetTextColor(1, 1, 1)
	frame.mP2Name:SetText("Name")

	-- creating mP3Name
	frame.mP3Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mP3Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 324, 369)
	frame.mP3Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP3Name:SetJustifyH("LEFT")
	frame.mP3Name:SetShadowOffset(1, -1)
	frame.mP3Name:SetTextColor(1, 1, 1)
	frame.mP3Name:SetText("Name")

	-- creating mP4Name
	frame.mP4Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mP4Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 447, 369)
	frame.mP4Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP4Name:SetJustifyH("LEFT")
	frame.mP4Name:SetShadowOffset(1, -1)
	frame.mP4Name:SetTextColor(1, 1, 1)
	frame.mP4Name:SetText("Name")

	-- creating mP5Name
	frame.mP5Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mP5Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 575, 368)
	frame.mP5Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP5Name:SetJustifyH("LEFT")
	frame.mP5Name:SetShadowOffset(1, -1)
	frame.mP5Name:SetTextColor(1, 1, 1)
	frame.mP5Name:SetText("Name")

	-- creating mEDmg
	frame.mEDmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mEDmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 89, 11)
	frame.mEDmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mEDmg:SetJustifyH("LEFT")
	frame.mEDmg:SetShadowOffset(1, -1)
	frame.mEDmg:SetTextColor(1, 1, 1)
	frame.mEDmg:SetText("Dmg")

	-- creating mEHeal
	frame.mEHeal = frame:CreateFontString(nil, "OVERLAY")
	frame.mEHeal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 419, 9)
	frame.mEHeal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mEHeal:SetJustifyH("LEFT")
	frame.mEHeal:SetShadowOffset(1, -1)
	frame.mEHeal:SetTextColor(1, 1, 1)
	frame.mEHeal:SetText("Heal")

	-- creating mElbDmg
	frame.mElbDmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mElbDmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 11)
	frame.mElbDmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mElbDmg:SetJustifyH("LEFT")
	frame.mElbDmg:SetShadowOffset(1, -1)
	frame.mElbDmg:SetTextColor(1, 1, 1)
	frame.mElbDmg:SetText("All Damage:")

	-- creating mElbHeal
	frame.mElbHeal = frame:CreateFontString(nil, "OVERLAY")
	frame.mElbHeal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 365, 9)
	frame.mElbHeal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mElbHeal:SetJustifyH("LEFT")
	frame.mElbHeal:SetShadowOffset(1, -1)
	frame.mElbHeal:SetTextColor(1, 1, 1)
	frame.mElbHeal:SetText("All Heal:")

	-- creating mPlbDmg
	frame.mPlbDmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mPlbDmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 33, 228)
	frame.mPlbDmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mPlbDmg:SetJustifyH("LEFT")
	frame.mPlbDmg:SetShadowOffset(1, -1)
	frame.mPlbDmg:SetTextColor(1, 1, 1)
	frame.mPlbDmg:SetText("All Damage:")

	-- creating mPlbHeal
	frame.mPlbHeal = frame:CreateFontString(nil, "OVERLAY")
	frame.mPlbHeal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 410, 225)
	frame.mPlbHeal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mPlbHeal:SetJustifyH("LEFT")
	frame.mPlbHeal:SetShadowOffset(1, -1)
	frame.mPlbHeal:SetTextColor(1, 1, 1)
	frame.mPlbHeal:SetText("All Heal:")

	-- creating mPHeal
	frame.mPHeal = frame:CreateFontString(nil, "OVERLAY")
	frame.mPHeal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 464, 225)
	frame.mPHeal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mPHeal:SetJustifyH("LEFT")
	frame.mPHeal:SetShadowOffset(1, -1)
	frame.mPHeal:SetTextColor(1, 1, 1)
	frame.mPHeal:SetText("Heal")

	-- creating mPDmg
	frame.mPDmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mPDmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 106, 228)
	frame.mPDmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mPDmg:SetJustifyH("LEFT")
	frame.mPDmg:SetShadowOffset(1, -1)
	frame.mPDmg:SetTextColor(1, 1, 1)
	frame.mPDmg:SetText("Dmg")

	-- creating mE1Name
	frame.mE1Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mE1Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 73, 173)
	frame.mE1Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE1Name:SetJustifyH("LEFT")
	frame.mE1Name:SetShadowOffset(1, -1)
	frame.mE1Name:SetTextColor(1, 1, 1)
	frame.mE1Name:SetText("Name")

	-- creating mE2Name
	frame.mE2Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mE2Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 195, 172)
	frame.mE2Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE2Name:SetJustifyH("LEFT")
	frame.mE2Name:SetShadowOffset(1, -1)
	frame.mE2Name:SetTextColor(1, 1, 1)
	frame.mE2Name:SetText("Name")

	-- creating mE3Name
	frame.mE3Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mE3Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 326, 170)
	frame.mE3Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE3Name:SetJustifyH("LEFT")
	frame.mE3Name:SetShadowOffset(1, -1)
	frame.mE3Name:SetTextColor(1, 1, 1)
	frame.mE3Name:SetText("Name")

	-- creating mE4Name
	frame.mE4Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mE4Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 453, 171)
	frame.mE4Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE4Name:SetJustifyH("LEFT")
	frame.mE4Name:SetShadowOffset(1, -1)
	frame.mE4Name:SetTextColor(1, 1, 1)
	frame.mE4Name:SetText("Name")

	-- creating mE5Name
	frame.mE5Name = frame:CreateFontString(nil, "OVERLAY")
	frame.mE5Name:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 580, 169)
	frame.mE5Name:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE5Name:SetJustifyH("LEFT")
	frame.mE5Name:SetShadowOffset(1, -1)
	frame.mE5Name:SetTextColor(1, 1, 1)
	frame.mE5Name:SetText("Name")

	-- creating mP1Dmg
	frame.mP1Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mP1Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 77, 284)
	frame.mP1Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP1Dmg:SetJustifyH("LEFT")
	frame.mP1Dmg:SetShadowOffset(1, -1)
	frame.mP1Dmg:SetTextColor(1, 1, 1)
	frame.mP1Dmg:SetText("Dmg")

	-- creating mP1Heal
	frame.mP1Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mP1Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 78, 259)
	frame.mP1Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP1Heal:SetJustifyH("LEFT")
	frame.mP1Heal:SetShadowOffset(1, -1)
	frame.mP1Heal:SetTextColor(1, 1, 1)
	frame.mP1Heal:SetText("Heal")

	-- creating mP2Dmg
	frame.mP2Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mP2Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 198, 282)
	frame.mP2Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP2Dmg:SetJustifyH("LEFT")
	frame.mP2Dmg:SetShadowOffset(1, -1)
	frame.mP2Dmg:SetTextColor(1, 1, 1)
	frame.mP2Dmg:SetText("Dmg")

	-- creating mP2Heal
	frame.mP2Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mP2Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 198, 260)
	frame.mP2Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP2Heal:SetJustifyH("LEFT")
	frame.mP2Heal:SetShadowOffset(1, -1)
	frame.mP2Heal:SetTextColor(1, 1, 1)
	frame.mP2Heal:SetText("Heal")

	-- creating mP3Dmg
	frame.mP3Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mP3Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 330, 283)
	frame.mP3Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP3Dmg:SetJustifyH("LEFT")
	frame.mP3Dmg:SetShadowOffset(1, -1)
	frame.mP3Dmg:SetTextColor(1, 1, 1)
	frame.mP3Dmg:SetText("Dmg")

	-- creating mP3Heal
	frame.mP3Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mP3Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 329, 261)
	frame.mP3Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP3Heal:SetJustifyH("LEFT")
	frame.mP3Heal:SetShadowOffset(1, -1)
	frame.mP3Heal:SetTextColor(1, 1, 1)
	frame.mP3Heal:SetText("Heal")

	-- creating mP4Dmg
	frame.mP4Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mP4Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 453, 281)
	frame.mP4Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP4Dmg:SetJustifyH("LEFT")
	frame.mP4Dmg:SetShadowOffset(1, -1)
	frame.mP4Dmg:SetTextColor(1, 1, 1)
	frame.mP4Dmg:SetText("Dmg")

	-- creating mP4Heal
	frame.mP4Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mP4Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 453, 260)
	frame.mP4Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP4Heal:SetJustifyH("LEFT")
	frame.mP4Heal:SetShadowOffset(1, -1)
	frame.mP4Heal:SetTextColor(1, 1, 1)
	frame.mP4Heal:SetText("Heal")

	-- creating mP5Dmg
	frame.mP5Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mP5Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 579, 280)
	frame.mP5Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP5Dmg:SetJustifyH("LEFT")
	frame.mP5Dmg:SetShadowOffset(1, -1)
	frame.mP5Dmg:SetTextColor(1, 1, 1)
	frame.mP5Dmg:SetText("Dmg")

	-- creating mP5Heal
	frame.mP5Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mP5Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 578, 259)
	frame.mP5Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mP5Heal:SetJustifyH("LEFT")
	frame.mP5Heal:SetShadowOffset(1, -1)
	frame.mP5Heal:SetTextColor(1, 1, 1)
	frame.mP5Heal:SetText("Heal")

	-- creating mE1Dmg
	frame.mE1Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mE1Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 74, 85)
	frame.mE1Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE1Dmg:SetJustifyH("LEFT")
	frame.mE1Dmg:SetShadowOffset(1, -1)
	frame.mE1Dmg:SetTextColor(1, 1, 1)
	frame.mE1Dmg:SetText("Dmg")

	-- creating mE1Heal
	frame.mE1Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mE1Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 74, 62)
	frame.mE1Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE1Heal:SetJustifyH("LEFT")
	frame.mE1Heal:SetShadowOffset(1, -1)
	frame.mE1Heal:SetTextColor(1, 1, 1)
	frame.mE1Heal:SetText("Heal")

	-- creating mE2Dmg
	frame.mE2Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mE2Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 199, 83)
	frame.mE2Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE2Dmg:SetJustifyH("LEFT")
	frame.mE2Dmg:SetShadowOffset(1, -1)
	frame.mE2Dmg:SetTextColor(1, 1, 1)
	frame.mE2Dmg:SetText("Dmg")

	-- creating mE2Heal
	frame.mE2Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mE2Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 198, 61)
	frame.mE2Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE2Heal:SetJustifyH("LEFT")
	frame.mE2Heal:SetShadowOffset(1, -1)
	frame.mE2Heal:SetTextColor(1, 1, 1)
	frame.mE2Heal:SetText("Heal")

	-- creating mE3Dmg
	frame.mE3Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mE3Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 329, 84)
	frame.mE3Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE3Dmg:SetJustifyH("LEFT")
	frame.mE3Dmg:SetShadowOffset(1, -1)
	frame.mE3Dmg:SetTextColor(1, 1, 1)
	frame.mE3Dmg:SetText("Dmg")

	-- creating mE3Heal
	frame.mE3Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mE3Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 329, 63)
	frame.mE3Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE3Heal:SetJustifyH("LEFT")
	frame.mE3Heal:SetShadowOffset(1, -1)
	frame.mE3Heal:SetTextColor(1, 1, 1)
	frame.mE3Heal:SetText("Heal")

	-- creating mE4Dmg
	frame.mE4Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mE4Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 459, 86)
	frame.mE4Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE4Dmg:SetJustifyH("LEFT")
	frame.mE4Dmg:SetShadowOffset(1, -1)
	frame.mE4Dmg:SetTextColor(1, 1, 1)
	frame.mE4Dmg:SetText("Dmg")

	-- creating mE4Heal
	frame.mE4Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mE4Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 460, 65)
	frame.mE4Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE4Heal:SetJustifyH("LEFT")
	frame.mE4Heal:SetShadowOffset(1, -1)
	frame.mE4Heal:SetTextColor(1, 1, 1)
	frame.mE4Heal:SetText("Heal")

	-- creating mE5Dmg
	frame.mE5Dmg = frame:CreateFontString(nil, "OVERLAY")
	frame.mE5Dmg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 585, 85)
	frame.mE5Dmg:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE5Dmg:SetJustifyH("LEFT")
	frame.mE5Dmg:SetShadowOffset(1, -1)
	frame.mE5Dmg:SetTextColor(1, 1, 1)
	frame.mE5Dmg:SetText("Dmg")

	-- creating mE5Heal
	frame.mE5Heal = frame:CreateFontString(nil, "OVERLAY")
	frame.mE5Heal:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 585, 65)
	frame.mE5Heal:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
	frame.mE5Heal:SetJustifyH("LEFT")
	frame.mE5Heal:SetShadowOffset(1, -1)
	frame.mE5Heal:SetTextColor(1, 1, 1)
	frame.mE5Heal:SetText("Heal")


	MatchView = frame

end

function VFrame:CreateClassView(frameM)
	
	frameCV = CreateFrame("Frame", "ClassView", frame)
	frameCV:SetSize(700, 680)
	texture = frameCV:CreateTexture()
	texture:SetAllPoints() 
	texture:SetTexture(0,0,0,1) 

	ClassView = frameCV

end

function VFrame:CreateStatView(frameM)
	
	frameSV = CreateFrame("Frame", "StatView", frame)
	frameSV:SetSize(700, 680)
	texture = frameSV:CreateTexture()
	texture:SetAllPoints() 
	texture:SetTexture(0,0,0,1) 

	StatView = frameSV

end

function VFrame:UpdateInfoFrame() -- Updates the Info Frame with ranked infos

	if firstPvPUpdate then
		TogglePVPUI()
		firstPvPUpdate = false
		TogglePVPUI()
	end

	--if select(1, LA:getRankedInfo(1)) == 0 then self:ScheduleTimer("UpdateInfoFrame", 1); return end

	InfoFrame.z:SetText(select(4, LA:getRankedInfo(1)))
	InfoFrame.t:SetText(select(4, LA:getRankedInfo(2)))
	InfoFrame.f:SetText(select(4, LA:getRankedInfo(3)))

	wins, looses, ratio, rating = LA:getRankedInfo(1)

	InfoFrame.w:SetText("W: " .. wins)
	InfoFrame.l:SetText("L: " .. looses)
	InfoFrame.r:SetText("R: " .. ratio .. "%")

	InfoFrame.z2:SetText("2v2")
	InfoFrame.f2:SetText("3v3")
	InfoFrame.t2:SetText("5v5")

	InfoFrame.b:Enable()

end

function VFrame:StatFrameButton() -- the statistic button on the info frame
	-- handle all data set/update all strings, icons, information
	self:StatFrameUpdateMatches(1)	

	if StatFrame:IsShown() then StatFrame:Hide(); return else StatFrame:Show() end

end

function VFrame:HandlePlayedArena(match, players) -- handles all the info for the last 5 played arenas (sorting and shifting)

	matches = MatchDB
	matches[5] = matches[4]
	matches[4] = matches[3]
	matches[3] = matches[2]
	matches[2] = matches[1]

	newMatch = {}
		newMatch.size = match.size
		newMatch.win = match.win
		newMatch.map = match.map
		newMatch.ranked = match.ranked
		newMatch.time = match.time
		newMatch.ownFac = match.ownFac
		newMatch.rating = match.rating

	newMatch.players = players

	matches[1] = newMatch
	MatchDB = matches

end

function VFrame:MATCH_INFO_UPDATE(event, match, players)
	
	-------Printing infos-----------
	if not match.ranked then self:print("Skirmish, " .. match.size)
	else self:print("Ranked, " .. match.size) end
	if match.win == 1 then self:print("Won! in " .. match.map) else self:print("Lost! in " .. match.map) end
	self:print("Estimated Time: " .. SecondsToTime(match.time))

	for i,n in pairs(players.enemys) do
		if n.state == "normal" then
		classStat = {}
		 classStat.dmg = n.dmg
		 classStat.heal = n.heal
		 classStat.win = n.win
		 classStat.rating = n.rating
		 classStat.spec = n.spec
		 classStat.name = n.name

		self:AddClassStats(classStat)
		self:print("Stat added: " .. n.name)
		end
	end

	self:AddMatchStats(match)
	self:HandlePlayedArena(match, players)

end

function VFrame:StatFrameUpdateMatches(index)

	-- matches = {1,2,3,4,5},
	-- match = {}
	--	match.size = 0
	--	match.win = false
	--	match.time = 0
	--  match.ownFac = 0
	--	match.map = ""
	--	match.ranked = false
	--	match.players = players	
	--	match.dmg = 0
	--	match.heal = 0

	matches = MatchDB
	match = matches[index]

	MatchViewtbl.mIcon = MatchView.mIcon

	for i,n in pairs(zc) do
		m = MatchViewtbl.m
		group = m[i]
		if matches[i].win == 1 then 
			texture = group.wl:CreateTexture(); texture:SetAllPoints(); texture:SetTexture(0, 1, 0, 1) 
		else 
			texture = group.wl:CreateTexture(); texture:SetAllPoints(); texture:SetTexture(1, 0, 0, 1) 
		end	

		group.size:SetText(matches[i].size .. "v" .. matches[i].size)

		group.icon:SetBackdrop(self:getBackdrop(mapImg[LA:getMapIndex(matches[i].map, false)]))
	end

	MatchViewtbl.mIcon:SetBackdrop(self:getBackdrop(mapImg[LA:getMapIndex(match.map, false)]))
	if match.win == 1 then texture = MatchView.mWL:CreateTexture(); texture:SetAllPoints(); texture:SetTexture(0, 1, 0, 1) else texture = MatchView.mWL:CreateTexture(); texture:SetAllPoints(); texture:SetTexture(1, 0, 0, 1) end
	MatchView.mIconS:SetText(match.map)
	MatchView.mSize:SetText(match.size .. "v" .. match.size)
	if match.ranked then MatchView.mRanked:SetText("Ranked") else MatchView.mRanked:SetText("Skirmish") end 
	MatchView.mTime:SetText(SecondsToTime(match.time/1000))


	allDmgP = 0; allHealP = 0
	allDmgE = 0; allHealE = 0

	players = match.players
	team = players.team
	enemys = players.enemys

	for i,n in pairs(team) do
		self:AddPlayer(n, i, true)
		allDmgP = allDmgP + n.dmg
		allHealP = allHealP + n.heal
	end

	for i,n in pairs(enemys) do
		self:AddPlayer(n, i, false)
		allDmgE = allDmgE + n.dmg
		allHealE = allHealE + n.heal
	end

	MatchView.mPDmg:SetText(allDmgP)
	MatchView.mPHeal:SetText(allHealP)
	MatchView.mEDmg:SetText(allDmgE)
	MatchView.mEHeal:SetText(allHealE)

end

function VFrame:AddPlayer(infos, i, ownTeam)

	backdropS = {
	  -- path to the background texture
	  bgFile = select(4, GetSpecializationInfoByID(infos.spec)),
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	if infos.state == "normal" then
		if ownTeam then
			group = MatchViewtbl.mP[i]
			group.Icon:SetBackdrop(backdropS); group.Name:SetText(infos.name); 
			group.Dmg:SetText(infos.dmg); group.Heal:SetText(infos.heal)
		else
			group = MatchViewtbl.mE[i]
			group.Icon:SetBackdrop(backdropS); group.Name:SetText(infos.name); 
			group.Dmg:SetText(infos.dmg); group.Heal:SetText(infos.heal)
		end
	elseif infos.state == "cleared" then
		if ownTeam then
			group = MatchViewtbl.mP[i]
			group.Icon:SetBackdrop(self:getBackdrop(pImg.cleared)); group.Name:SetText(infos.name); 
			group.Dmg:SetText(""); group.Heal:SetText("")
		else
			group = MatchViewtbl.mE[i]
			group.Icon:SetBackdrop(self:getBackdrop(pImg.ni)); group.Name:SetText(infos.name); 
			group.Dmg:SetText(""); group.Heal:SetText("")
		end
	else -- infos.state == "ni"
		if ownTeam then
			group = MatchViewtbl.mP[i]
			group.Icon:SetBackdrop(self:getBackdrop(pImg.ni)); group.Name:SetText(""); 
			group.Dmg:SetText(""); group.Heal:SetText("")
		else
			group = MatchViewtbl.mE[i]
			group.Icon:SetBackdrop(self:getBackdrop(pImg.ni)); group.Name:SetText(""); 
			group.Dmg:SetText(""); group.Heal:SetText("")
		end
	end

end

---------------Misc Methods-----------------

function VFrame:getBackdrop(path)
	backdropS = {
	  -- path to the background texture
	  bgFile = path,
	  -- true to repeat the background texture to fill the frame, false to scale it
	  tile = false,
	  -- size (width or height) of the square repeating background tiles (in pixels)
	  tileSize = 20
	}

	return backdropS

end

--------------DB functions----------------

function VFrame:AddMatchStats(match)
	-- match.win, match.time, match.map, match.size, match.ranked

	stats = StatDB
	map = stats.map
	size = stats.size

	map = LA:getMapIndex(map, false)
	stats.map = map

	if match.win then stats.winned = stats.winned + 1 else stats.winned = stats.winned - 1 end
	stats.time = stats.time + match.time
	if match.ranked then stats.ranked = stats.ranked + 1 else stats.unranked = stats.unranked + 1 end
	stats.played = stats.played + 1	

	if match.size == 2 then size.two = size.two + 1 
	elseif match.size == 3 then size.three = size.three + 1 
	elseif match.size == 5 then size.five = size.five + 1 
	else size.two = size.two + 1 end
	stats.size = size

	StatDB = stats

end

function VFrame:AddClassStats(infosO)
	-- infos.win, infos.name, infos.kills, infos.faction, infos.race, infos.class, infos.classToken, infos.dmg, infos.heal, infos.spec

	infos = ClassDB[infosO.spec]
	if infosO.win then infos.wins = infos.wins + 1 else infos.wins = infos.wins - 1 end
	infos.played = infos.played + 1
	if not infosO.win then infos.lost = infos.lost + 1 end
	infos.dmg = infos.dmg + infosO.dmg
	infos.heal = infos.heal + infosO.heal

	---figuring out if new best player----
	best = {}
	best = infos.best
	if infosO.dmg > best.dmg then best.dmg = infosO.dmg; best.name = infosO.name; best.heal = infosO.heal; best.race = infosO.race; best.rating = infosO.rating end
	if infosO.heal > best.heal then best.heal = infosO.heal; best.name = infosO.name; best.dmg = infosO.dmg; best.race = infosO.race; best.rating = infosO.rating end
	infos.best = best
	--------------------------------------

	ClassDB[infosO.spec] = infos

end

----------------------------------------------

function VFrame:print(msg) -- the print funktion with the Red VFrame before every chat msg

	print("|cffff0020VFrame|r: " .. msg)

end

function VFrame:StringSplit(string, key, tbl) -- splits an string 
	table = {}
	
	for word in string.gmatch(string, '([^' .. key .. ']+)') do
		table.insert(word)
	end

	if tbl then return table end 
	if not tbl then return table[1], table[2] end

end

function VFrame:round(n) -- rounds a value 

    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)

end

----------------------------------------------