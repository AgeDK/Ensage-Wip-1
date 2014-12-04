-- Bloodseeker will auto bloodrage and attempt to kill lowest target

-- ===================
-- == Features V1.0 ==
-- ===================
-- Hold space to enable
-- Auto phase boots if you have em
-- Auto bloodrage if we can

require("libs.Utils")
require("libs.ScriptConfig")
require("libs.HeroInfo")

-- Script config - set hotkeys blah blah

local config = ScriptConfig.new()
config:SetParameter("chaseHealth", 300)
config:SetParameter("chaseKey", 32, config.TYPE_HOTKEY)
config:Load()

chaseKey = config.chaseKey
chaseHealth = config.chaseHealth

local autoChase = false
local chaseVictim = nil
local reg = false

local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local chaseText = drawMgr:CreateText(-80*monitor,-20*monitor,-1,'AutoChase',F14) chaseText.visible = false

function Key(msg, code)
  if msg ~= KEY_UP or client.chat or client.console then return end
  if code == chaseKey then
    autoChase = not autoChase
  end
end

function Tick(tick)
  
  if not PlayingGame() or client.paused then return end
  
  local me = entityList:GetMyHero()
  if not me then
    return
  end
  
--  if autoChase then
--	  chaseText.entity = me
--    chaseText.entityPosition = Vector(0,0,me.healthBarOffset)
--    if not chaseVictim then
--      chaseText.text = "Autochase Enabled"
--	  print("chasing enabled")
--    else
--      chaseText.text = "Auto Chasing: "..client:Localize(chaseVictim.name)
--	  print("chasing hero")
--    end
--  else
--  print("no chase")
--    chaseText.text = "Not chasing"
--  end
  

  local bloodRage = me:GetAbility(1)
  
  if me.alive and bloodRage and bloodRage.level > 0 and bloodRage.state == LuaEntityAbility.STATE_READY then
    print("two")
    FindTarget()
  end
  
  if chaseVictim and chaseVictim.visible and autoChase then
    print("Five")
    if GetDistance2D(me, chaseVictim) <= me.attackRange-25 then
      print("six")
      if bloodRage and bloodRage.state == LuaEntityAbility.STATE_READY then
        print("seven")
        me:SafeCastAbility(bloodRage)
      end
      entityList:GetMyPlayer():Attack(chaseVictim)
      Sleep(100)
    else
      print("eight")
      me:Move(chaseVictim.position)
      Sleep(100)
    end
  end
end

function FindTarget()
  local lowenemy = nil
  local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO,team=entityList:GetMyHero():GetEnemyTeam(),visible=true,alive=true})
  print(enemies)
  print("one")
  for i, v in ipairs(enemies) do
    print("three")
    if v.health <= chaseHealth then
	    if lowenemy == nil then
		    lowenemy = v
		    print("four with no low enemy")
	    elseif lowenemy.health > v.health then
		    lowenemy = v
		    print("Four with lower enemy")
	    end
    end
  end
  lowenemy = chaseVictim
end
  
function Load()
  if PlayingGame() then
    local me = entityList:GetMyHero()
    if not me or me.classId ~= CDOTA_Unit_Hero_Bloodseeker then
      script:Disable()
    else
      chaseText.visible = true
      reg = true
      victim = nil
      autoChase = false
      chaseVictim = nil
      script:RegisterEvent(EVENT_TICK, Tick)
      script:RegisterEvent(EVENT_KEY, Key)
      script:UnregisterEvent(Load)
    end
  end
end

function Close()
  chaseText.visible = false
  victim = nil
  autoChase = false
  chaseVictim = nil
  if reg then
    script:UnregisterEvent(Tick)
    script:UnregisterEvent(Key)
    script:RegisterEvent(EVENT_TICK, Load)
    reg = false
  end
end

script:RegisterEvent(EVENT_CLOSE, Close)
script:RegisterEvent(EVENT_TICK, Load)