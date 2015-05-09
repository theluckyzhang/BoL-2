local version = "1.00"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/gmzopper/BoL/master/Thresh.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Thresh:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/gmzopper/BoL/master/version/Thresh.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				_AutoupdaterMsg("New version available "..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

if myHero.charName ~= "Thresh" then return end   

require("VPrediction") --vpred
require("DivinePred") -- divinepred
require("HPrediction") -- hpred

local enemyChamps = {}
local dp = DivinePred()
local pred = nil

----------------------
--     Variables    --
----------------------

local spells = {}
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 1100, width = 100}
spells.w = {name = myHero:GetSpellData(_W).name, ready = false, range = 950, width = nil}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 500, width = nil}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = 450, width = nil}

Interrupt = {
	["Katarina"] = {charName = "Katarina", stop = {["KatarinaR"] = {name = "Death lotus", spellName = "KatarinaR", ult = true }}},
	["Nunu"] = {charName = "Nunu", stop = {["AbsoluteZero"] = {name = "Absolute Zero", spellName = "AbsoluteZero", ult = true }}},
	["Malzahar"] = {charName = "Malzahar", stop = {["AlZaharNetherGrasp"] = {name = "Nether Grasp", spellName = "AlZaharNetherGrasp", ult = true}}},
	["Caitlyn"] = {charName = "Caitlyn", stop = {["CaitlynAceintheHole"] = {name = "Ace in the hole", spellName = "CaitlynAceintheHole", ult = true, projectileName = "caitlyn_ult_mis.troy"}}},
	["FiddleSticks"] = {charName = "FiddleSticks", stop = {["Drain"] = {name = "Drain", spellName = "Drain", ult = false}}},
	["FiddleSticks"] = {charName = "FiddleSticks", stop = {["Crowstorm"] = {name = "Crowstorm", spellName = "Crowstorm", ult = true}}},
	["Galio"] = {charName = "Galio", stop = {["GalioIdolOfDurand"] = {name = "Idole of Durand", spellName = "GalioIdolOfDurand", ult = true}}},
	["Janna"] = {charName = "Janna", stop = {["ReapTheWhirlwind"] = {name = "Monsoon", spellName = "ReapTheWhirlwind", ult = true}}},
	["MissFortune"] = {charName = "MissFortune", stop = {["MissFortune"] = {name = "Bullet time", spellName = "MissFortuneBulletTime", ult = true}}},
	["MasterYi"] = {charName = "MasterYi", stop = {["MasterYi"] = {name = "Meditate", spellName = "Meditate", ult = false}}},
	["Pantheon"] = {charName = "Pantheon", stop = {["PantheonRJump"] = {name = "Skyfall", spellName = "PantheonRJump", ult = true}}},
	["Shen"] = {charName = "Shen", stop = {["ShenStandUnited"] = {name = "Stand united", spellName = "ShenStandUnited", ult = true}}},
	["Urgot"] = {charName = "Urgot", stop = {["UrgotSwap2"] = {name = "Position Reverser", spellName = "UrgotSwap2", ult = true}}},
	["Varus"] = {charName = "Varus", stop = {["VarusQ"] = {name = "Piercing Arrow", spellName = "Varus", ult = false}}},
	["Warwick"] = {charName = "Warwick", stop = {["InfiniteDuress"] = {name = "Infinite Duress", spellName = "InfiniteDuress", ult = true}}},
}

isAGapcloserUnit = {
	['Ahri']        = {true, spell = _R, 				  range = 450,   projSpeed = 2200, },
	['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
	['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, },
	['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, },
	['Amumu']       = {true, spell = _Q,                  range = 1100,  projSpeed = 1800, },
	['Corki']       = {true, spell = _W,                  range = 800,   projSpeed = 650,  },
	['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, },
	['Darius']      = {true, spell = _R,                  range = 460,   projSpeed = math.huge, },
	['Fiora']       = {true, spell = _Q,                  range = 600,   projSpeed = 2000, },
	['Fizz']        = {true, spell = _Q,                  range = 550,   projSpeed = 2000, },
	['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
	['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
	['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
	['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, },
	['JarvanIV']    = {true, spell = _Q,                  range = 770,   projSpeed = 2000, },
	['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, },
	['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, },
	['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
	['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
	['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
	['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
	['Lucian']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, },
	['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500, },
	['Maokai']      = {true, spell = _W,                  range = 525,   projSpeed = 2000, },
	['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, },
	['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
	['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, },
	['Riven']       = {true, spell = _E,                  range = 150,   projSpeed = 2000, },
	['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
	['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
	['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
	['Shyvana']     = {true, spell = _R,                  range = 1000,  projSpeed = 2000, },
	['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
	['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
	['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, },
	['Yasuo']       = {true, spell = _E,                  range = 475,   projSpeed = 1000, },
	['Vayne']       = {true, spell = _Q,                  range = 300,   projSpeed = 1000, },
	['Wukong']      = {true, spell = _E,                  range = 625,   projSpeed = 1400, },
}

-- Spell cooldown check
function readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

-- Orbwalker check
function orbwalkCheck()
	if _G.AutoCarry then
		PrintChat("SA:C detected, support enabled.")
		SACLoaded = true
	elseif _G.MMA_Loaded then
		PrintChat("MMA detected, support enabled.")
		MMALoaded = true
	else
		PrintChat("SA:C/MMA not running, loading SxOrbWalk.")
		require("SxOrbWalk")
		SxMenu = scriptConfig("SxOrbWalk", "SxOrbb")
		SxOrb:LoadToMenu(SxMenu)
		SACLoaded = false
	end
end

----------------------
--  Cast functions  --
----------------------

local qpred = LineSS(1900,1100, 100, .5, 0)

function CastQ(unit)
    if ValidTarget(unit) and GetDistance(unit) <= settings.combo.qRange then
        if settings.pred == 1 then
            local castPos, chance, pos = pred:GetLineCastPosition(unit, .5, 100, 1100, 1900, myHero, false)
            if  spells.q.ready and chance >= 2 then
                CastSpell(_Q, castPos.x, castPos.z)
            end
        elseif settings.pred == 2 then
            local targ = DPTarget(unit)
            local state,hitPos,perc = dp:predict(targ, qpred)
            if spells.q.ready and state == SkillShot.STATUS.SUCCESS_HIT then
                CastSpell(_Q, hitPos.x, hitPos.z)
            end
        elseif settings.pred == 3 then
            local pos, chance = HPred:GetPredict("Q", unit, myHero) 
            if chance > 0 and spells.q.ready then
                CastSpell(_Q, pos.x, pos.z)
            end
        end
    end
end

function CastQ2()
	if settings.combo.autoJump then
		DelayAction(function() CastSpell(_Q, myHero) end, ((15 / 1000) * settings.combo.holdQ))
	end
end

function CastWEngage(Target)
	if myHero:GetSpellData(_Q).name == "threshqleap" and settings.combo.w and GetDistance(Target) <= 200 then	
		local bestAlly = nil
		
		for i = 1, heroManager.iCount, 1 do
            local ally = heroManager:getHero(i)
			
            if ally.team == myHero.team and ally.name ~= myHero.name then		
				if GetDistance(Target, ally) >= 600 and GetDistance(ally) <= spells.w.range then 
					if ValidTarget(bestAlly) then
						if GetDistance(ally) >= GetDistance(bestAlly) then
							bestAlly = ally
						end
					else
						bestAlly = ally
					end
				end
			end
		end
		
		if bestAlly ~= nil then
			local x, z = wPosition(myHero, bestAlly, 200)
			CastSpell(_W, x, z)
		end
	end
end

function CastWCombo(Target)
	if myHero:GetSpellData(_Q).name == "threshqleap" and settings.combo.w then	
		local bestAlly = nil
		
		for i = 1, heroManager.iCount, 1 do
            local ally = heroManager:getHero(i)
			
            if ally.team == myHero.team and ally.name ~= myHero.name then		
				if GetDistance(Target, ally) >= 600 and GetDistance(ally) <= spells.w.range then 
					if ValidTarget(bestAlly) then
						if GetDistance(ally) >= GetDistance(bestAlly) then
							bestAlly = ally
						end
					else
						bestAlly = ally
					end
				end
			end
		end
		
		if bestAlly ~= nil then
			local x, z = wPosition(myHero, bestAlly, 200)
			CastSpell(_W, x, z)
		end
	end
end

function CastWLowHP()
	if settings.auto.w then
		for i = 1, heroManager.iCount, 1 do
            local ally = heroManager:getHero(i)
			
            if ally.team == myHero.team  and not ally.dead then
				if ally.health < (ally.maxHealth / 100) * settings.auto.hpW and GetEnemyCountInPos(ally, 600) > 0 then
					if spells.w.ready and GetDistance(ally) < spells.w.range then
						if GetDistance(ally) < 300 then
							local CastPosition,  HitChance,  Position = pred:GetCircularCastPosition(ally, 0.5, 150, 950)
							CastSpell(_W, CastPosition.x, CastPosition.z) 
						else
							local x, z = wPosition(myHero, ally, 200)
							CastSpell(_W, x, z)
						end
					end
				end
			end
		end
	end
end

function CastEPull(Target)
    if settings.combo.e then
		if ValidTarget(Target) and spells.e.ready and GetDistance(Target) <= spells.e.range then
			xPos = myHero.x + (myHero.x - Target.x)
			zPos = myHero.z + (myHero.z - Target.z)
			CastSpell(_E, xPos, zPos)
		end
    end    
end

function CastEPush(Target)
	if ValidTarget(Target) and spells.e.ready and GetDistance(Target) <= spells.e.range then
		CastSpell(_E, Target.x, Target.z)
	end   
end

function CastR()
	if settings.auto.auto and spells.r.ready then
		if GetEnemyCountInPos(myHero, spells.r.range) >= settings.auto.ultMinimum then
			CastSpell(_R)
		end
	end    
end

function CastEGap()
	PrintChat("step5")
	if spells.e.ready then
        if settings.e.gapClose then
            if not spellExpired and (GetTickCount() - informationTable.spellCastedTick) <= (informationTable.spellRange/informationTable.spellSpeed)*1000 then
                local spellDirection     = (informationTable.spellEndPos - informationTable.spellStartPos):normalized()
                local spellStartPosition = informationTable.spellStartPos + spellDirection
                local spellEndPosition   = informationTable.spellStartPos + spellDirection * informationTable.spellRange
                local heroPosition = Point(myHero.x, myHero.z)

                local lineSegment = LineSegment(Point(spellStartPosition.x, spellStartPosition.y), Point(spellEndPosition.x, spellEndPosition.y))

                if lineSegment:distance(heroPosition) <= (not informationTable.spellIsAnExpetion and 65 or 200) then
                    CastEPush(informationTable.spellSource)
                end
            else
                spellExpired = true
                informationTable = {}
            end
        end
	end
end

----------------------
--   Calculations   --
----------------------
-- Target Calculation
function getTarg()
	ts:update()
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(1200) return _G.AutoCarry.Crosshair:GetTarget() end		
	if ValidTarget(SelectedTarget) then return SelectedTarget end
	if MMALoaded and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return ts.target
end

function GetEnemyCountInPos(pos, radius)
    local n = 0
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if GetDistanceSqr(pos, enemy) <= radius * radius and ValidTarget(enemy) then n = n + 1 end 
    end
    return n
end

function getHealthPercent(unit)
    local obj = unit or myHero
    return (obj.health / obj.maxHealth) * 100
end

function wPosition(player, target, distance)
	local xVector = player.x - target.x
	local zVector = player.z - target.z
	local distance = math.sqrt(xVector * xVector + zVector * zVector)
	
	return target.x + distance * xVector / distance, target.z + distance * zVector / distance
end
----------------------
--      Hooks       --
----------------------

-- Init hook
function OnLoad()
	print("<font color='#009DFF'>[Thresh]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")

	if autoupdate then
		update()
	end

	for i = 1, heroManager.iCount do
    	local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then enemyChamps[""..hero.networkID] = DPTarget(hero) end
	end

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_MAGIC, true)
	pred = VPrediction()
	HPred = HPrediction()
	hpload = true

	Menu()

	DelayAction(orbwalkCheck,7)
	AddUpdateBuffCallback(CustomUpdateBuff)		

	if hpload then
		HPred:AddSpell("Q", 'Thresh', {type = "DelayLine", delay = 0.5, range = 1100, width = 150, speed=1900})
  	end
end

-- Tick hook
function OnTick()
	readyCheck()

	ts:update()
	Target = getTarg()
	
	if settings.combo.comboKey then
		CastQ(Target)
		CastWCombo(Target)
		CastEPull(Target)
	end
	
	CastR()
	CastWEngage(Target)
	CastWLowHP()
end

-- Drawing hook
function OnDraw()
	if myHero.dead then return end
	
	Target = getTarg()
	
	if ValidTarget(Target) and settings.draw.line then 
		local IsCollision = pred:CheckMinionCollision(Target, Target.pos, 0.5, 150, 1100, 1900, myHero.pos,nil, true)
		DrawLine3D(myHero.x, myHero.y, myHero.z, Target.x, Target.y, Target.z, 5, IsCollision and ARGB(125, 255, 0,0) or ARGB(125, 0, 255,0))
	end
	
	if ValidTarget(Target) then
		DrawCircle(Target.x, Target.y, Target.z, 150, 0xffffff00)
	end
	
	if settings.draw.q and spells.q.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, settings.combo.qRange, 0xFFFF0000)
	end

	if settings.draw.w and spells.w.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.w.range, 0xFFFF0000)
	end

	if settings.draw.e and spells.e.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.e.range, 0xFFFF0000)
	end
end

function OnProcessSpell(object, spellProc)
	if myHero.dead then return end
	if object.team == myHero.team then return end
	
	if Interrupt[object.charName] ~= nil then
		spell = Interrupt[object.charName].stop[spellProc.name]
		if spell ~= nil then
			if settings.interrupt[spellProc.name] then
				if GetDistance(object) < spells.e.range and spell.e.ready then
					CastSpell(_E, object.x, object.z)
				elseif GetDistance(object) < settings.combo.qRange and spell.q.ready then
					CastQ(object)
				end
			end
		end
	end
		
	local unit = object
	local spell = spellProc
	
	if unit.type == myHero.type and unit.team ~= myHero.team and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then			
		if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) and settings.gapClose[unit.charName] then
			if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
				CastEPush(unit)
			else
				spellExpired = false
				informationTable = {
					spellSource = unit,
					spellCastedTick = GetTickCount(),
					spellStartPos = Point(spell.startPos.x, spell.startPos.z),
					spellEndPos = Point(spell.endPos.x, spell.endPos.z),
					spellRange = isAGapcloserUnit[unit.charName].range,
					spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
					spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
				}
			end
		end
	end
end

function CustomUpdateBuff(unit,buff)
	if unit and unit.type == myHero.type and buff.name == "ThreshQ" then
		if unit.team ~= myHero.team then
			CastQ2()
		end
	end
	
	if unit and not unit.isMe and buff.name == "rocketgrab2" and unit.type == myHero.type and settings.auto.blitzcrank then
		if unit.team == myHero.team then
			for _, enemy in ipairs(GetEnemyHeroes()) do
				if enemy.charName == "Blitzcrank" then
					local x, z = wPosition(myHero, enemy, 150)
					CastSpell(_W, x, z)
				end 
			end
		end
	end
end

-- Menu creation
function Menu()
	settings = scriptConfig("Thresh", "Zopper")
	TargetSelector.name = "Thresh"
	settings:addTS(ts)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Combo", "combo")
		settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		settings.combo:addParam("q", "Use Q", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("qRange", "Cast Q on range", SCRIPT_PARAM_SLICE, 1100, 0, 1050, 0)
		settings.combo:addParam("autoJump", "Auto second cast Q", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("holdQ", "Hold Q before Jump", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		settings.combo:addParam("w", "Use W after Q", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("e", "Use E to Pull", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("[" .. myHero.charName.. "] - Auto", "auto")
		settings.auto:addParam("auto", "Use automatically", SCRIPT_PARAM_ONOFF, true)
		settings.auto:addParam("ultMinimum", "ULT if hits x enemies", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
		settings.auto:addParam("w", "Use W to save low HP", SCRIPT_PARAM_ONOFF, true)
		settings.auto:addParam("hpW", "Use W at what % health", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
		settings.auto:addParam("blitzcrank", "Save when hooked by Blitzcrank", SCRIPT_PARAM_ONOFF, true)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Drawing", "draw")
		settings.draw:addParam("line", "Draw Line", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("q", "Draw Q", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("w", "Draw W", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("[" .. myHero.charName.. "] - Auto-Interrupt", "interrupt")
		for i, a in pairs(GetEnemyHeroes()) do
			if Interrupt[a.charName] ~= nil then
				for i, spell in pairs(Interrupt[a.charName].stop) do
					settings.interrupt:addParam(spell.spellName, a.charName.." - "..spell.name, SCRIPT_PARAM_ONOFF, true)
				end
			end
		end
		
	settings:addSubMenu("[" .. myHero.charName.. "] - Anti Gap-Close", "gapClose")
		for _, enemy in pairs(GetEnemyHeroes()) do
			if isAGapcloserUnit[enemy.charName] ~= nil then
				settings.gapClose:addParam(enemy.charName, enemy.charName .. " - " .. enemy:GetSpellData(isAGapcloserUnit[enemy.charName].spell).name, SCRIPT_PARAM_ONOFF, true)
			end
		end
	
    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred", "HPred"})
end


--Lag Free Circles
function DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(40, Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}
		
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)	
end

function Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end