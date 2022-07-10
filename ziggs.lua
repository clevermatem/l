if Player.CharName ~= "Ziggs" then return end

---[Variables]------------------------------------------------------------------------
--SDK & Libs
local ObjManager   = _G.CoreEx.ObjectManager
local EventManager = _G.CoreEx.EventManager
local Geometry     = _G.CoreEx.Geometry
local Renderer     = _G.CoreEx.Renderer
local Enums        = _G.CoreEx.Enums
local Game         = _G.CoreEx.Game
local Input        = _G.CoreEx.Input
local Menu         = _G.Libs.NewMenu
local Orbwalker    = _G.Libs.Orbwalker
local Spell        = _G.Libs.Spell
local TS           = _G.Libs.TargetSelector()
local Prediction   = _G.Libs.Prediction

--Local variables
local Ziggs = {
  EPosition = nil
}
local events = {}
local defaultColor = 0xe7f2f8FF
local scriptName = "SomethingZiggs"
--local scriptDev = "testerhdre"


local Spells = {
  Q1 = Spell.Skillshot({
    Slot = Enums.SpellSlots.Q,
    Range = 850,
    Delay = 0.25,
    Radius = 150,
    Speed = 1650,
    Type = "Circular"
  }),
  Q2 = Spell.Skillshot({
    Slot = Enums.SpellSlots.Q,
    Range = 1125,
    Delay = 0.745,
    Radius = 150,
    Speed = 1700,
    Type = "Circular"
  }),
  Q3 = Spell.Skillshot({
    Slot = Enums.SpellSlots.Q,
    Range = 1400,
    Delay = 1.24,
    Radius = 150,
    Speed = 1700,
    Type = "Circular"
  }),
  W = Spell.Skillshot({
    Slot = Enums.SpellSlots.W,
    Range = 1000,
    Delay = 0.25,
    Radius = 325,
    Speed = 1750,
    Type = "Circular"
  }),
  E = Spell.Skillshot({
    Slot = Enums.SpellSlots.E,
    Range = 900,
    Delay = 0.25,
    Radius = 325,
    Speed = 1550,
    Type = "Circular"
  }),
  R = Spell.Skillshot({
    Slot = Enums.SpellSlots.R,
    Range = 5000,
    Delay = 0.375,
    Radius = 500,
    Speed = 2250,
    Type = "Circular"
  })

}

---[Functions]------------------------------------------------------------------------

--AutoTurret
function Ziggs.AutoTurret()
  if not Spells.W:IsReady() then return end

  local healthPercent =
  ({ 0.25, 0.275, 0.30, 0.325, 0.35 })[Spells.W:GetLevel()]

  for _, x in pairs(ObjManager.Get('enemy', 'turrets')) do
    local turret = x.AsTurret

    if Spells.W:IsInRange(turret) and turret.IsAlive and
        turret.HealthPercent <= healthPercent then
      Spells.W:Cast(turret.Position)
      return
    end
  end
end

--IsAvailable
function IsAvailable()
  return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

--GetBestCastPos
function Ziggs.GetBestCastPos(spell, targets, slot)

  if spell:IsReady() and Menu.Get("Ziggs.LC.use" .. slot)
      and Player.ManaPercent * 100 > Menu.Get("Ziggs.LC." .. slot .. "Mana")
  then
    print("Ziggs.LC", Menu.Get("Ziggs.LC." .. slot .. "Mana"))
    local pos, num = spell:GetBestCircularCastPos(targets)

    if num > 0 and spell:IsInRange(pos) then
      spell:Cast(pos)
    end
  end
end

--GetMinionsInRange
function Ziggs.GetMinions(range)
  local minions = {}
  for _, x in pairs(ObjManager.Get('all', 'minions')) do
    local y = x.AsMinion

    if TS:IsValidTarget(y, range) and
        ((y.IsEnemy and y.IsLaneMinion) or y.IsNeutral) then
      minions[#minions + 1] = y.AsAI
    end
  end

  return minions
end

--PushEnemy
function Ziggs.PushEnemy(target)
  if Spells.W:IsReady() and target and TS:IsValidTarget(target) then
    return CastOnHS('W', target)
  end
end

--ThrowToE
function Ziggs.ThrowToE()

  local target = nil
  local throwDistance = 500
  for i, x in pairs(ObjManager.Get('enemy', 'heroes')) do

    if TS:IsValidTarget(x) and x.IsEnemy and
        x:Distance(Ziggs.EPosition) > Spells.E.Radius and
        Spells.W:IsInRange(x) and
        #Geometry.CircleCircleIntersection(Ziggs.EPosition,
          Spells.E.Radius, x.Position,
          throwDistance) > 0
    then

      target = x.AsHero
      break
    end
  end
  if not target then return end
  local pred = Spells.W:GetPrediction(target)
  local cast_pos = Ziggs.EPosition:Extended(pred.CastPosition,
    throwDistance)
  if Spells.W:IsReady() then
    return Spells.W:Cast(cast_pos)

  end
end

--CastOnHS
function CastOnHS(spell, target)
  if (spell == 'Q') then
    return Spells.Q1:CastOnHitChance(target, Menu.Get("Ziggs.Combo.qChance")) or
        Spells.Q2:CastOnHitChance(target, Menu.Get("Ziggs.Combo.qChance")) or
        Spells.Q3:CastOnHitChance(target, Menu.Get("Ziggs.Combo.qChance"))
  end
  if (spell == 'E') then
    return Spells.E:CastOnHitChance(target, Menu.Get("Ziggs.Combo.eChance"))
  end
  if (spell == 'W') then
    return Spells.W:CastOnHitChance(target, Menu.Get("Ziggs.Combo.wChance"))
  end
  if (spell == 'R') then
    return Spells.R:CastOnHitChance(target, Menu.Get("Ziggs.Combo.rChance"))

  end
end

--Q logic
function Ziggs.Q()
  local target = Spells.Q3:GetTarget()
  if Spells.Q1:IsReady() and target and TS:IsValidTarget(target) then
    return CastOnHS('Q', target)
  end
end

--E logic
function Ziggs.E()
  local target = Spells.E:GetTarget()

  if Spells.E:IsReady() and target and TS:IsValidTarget(target) then
    return CastOnHS('E', target)
  end
end

--W logic
function Ziggs.W(mode)
  local target = Spells.W:GetTarget()
  if (Menu.Get("Ziggs." .. mode .. ".throw")) and Ziggs.EPosition then
    Ziggs.ThrowToE()
  elseif (Menu.Get("Ziggs." .. mode .. ".melee")) and target and Player:Distance(target.Position) < 400 then
    Ziggs.PushEnemy(target)
  elseif not (Menu.Get("Ziggs." .. mode .. ".throw")) then
    local target = Spells.W:GetTarget()
    if Spells.W:IsReady() and target and TS:IsValidTarget(target) then
      return CastOnHS('W', target)
    end
  end

end

--R logic
function Ziggs.R(mode)

  local target = Spells.R:GetTarget()
  if Menu.Get("Ziggs." .. mode .. ".RMinEnemies") == 1 then
    if Spells.R:IsReady() and target and TS:IsValidTarget(target) then
      CastOnHS("R", target)
    end
  else
    if Spells.R:IsReady() and target and TS:IsValidTarget(target) then
      Spells.R:CastIfWillHit(Menu.Get("Ziggs.Combo.RMinEnemies"))
    end
  end
end

--Combo
function Ziggs.Combo()
  local mana = Player.ManaPercent * 100
  if Menu.Get("Ziggs.Combo.useQ") and (mana > Menu.Get("Ziggs.Combo.QMana")) then
    Ziggs.Q()
  end
  if Menu.Get("Ziggs.Combo.useE") and (mana > Menu.Get("Ziggs.Combo.EMana")) then
    Ziggs.E()
  end
  if Menu.Get("Ziggs.Combo.useW") and (mana > Menu.Get("Ziggs.Combo.WMana")) then
    Ziggs.W("Combo")
  end
  if Menu.Get("Ziggs.Combo.useR") and (mana > Menu.Get("Ziggs.Combo.RMana")) then
    Ziggs.R("Combo")
  end
end

--Harass
function Ziggs.Harass()
  local mana = Player.ManaPercent * 100
  if Menu.Get("Ziggs.Harass.useQ") and (mana > Menu.Get("Ziggs.Harass.QMana")) then
    Ziggs.Q()
  end
  if Menu.Get("Ziggs.Harass.useE") and (mana > Menu.Get("Ziggs.Harass.EMana")) then
    Ziggs.E()
  end
  if Menu.Get("Ziggs.Harass.useW") and (mana > Menu.Get("Ziggs.Harass.WMana")) then
    Ziggs.W("Harass")
  end
  if Menu.Get("Ziggs.Harass.useR") and (mana > Menu.Get("Ziggs.Harass.RMana")) then
    Ziggs.R("Harass")
  end
end

--Waveclear

function Ziggs.Waveclear()
  local minions = Ziggs.GetMinions(850)

  if #minions == 0 then return end

  return Ziggs.GetBestCastPos(Spells.Q1, minions, "Q") or
      Ziggs.GetBestCastPos(Spells.W, minions, "W") or
      Ziggs.GetBestCastPos(Spells.E, minions, "E")
end

--Flee
function Ziggs.Flee()
  if not Menu.Get("Ziggs.Flee.useW") or not Spells.W:IsReady()
      or Player.ManaPercent * 100 < Menu.Get("Ziggs.Flee.WMana") then
    return
  end

  Spells.W:Cast(Player.Position:Extended(Renderer.GetMousePos(), -50))
end

---[OnDraw event]------------------------------------------------------------------------
function events.OnDraw()
  if not IsAvailable() then
    return
  end

  for k, v in pairs(Spells) do
    if Menu.Get("Ziggs.Colors.use" .. k, true) then
      Renderer.DrawCircle3D(Player.Position, v.Range, 30, 2, Menu.Get("Ziggs.Colors." .. k))
    end
  end
end

---[OnGapClose event]------------------------------------------------------------------------
function events.OnHeroImmobilized(source, end_time, __)
  if not TS:IsValidTarget(source) or source.IsAlly then return end

  if Menu.Get("Ziggs.Auto.immobileE") and Spells.E:IsReady() and end_time - Game.GetTime() >= 0.5 and
      Spells.E:IsInRange(source) then Spells.E:Cast(source) end

end

---[OnGapClose event]------------------------------------------------------------------------
function events.OnGapClose(source, __)
  if not source.IsEnemy or not TS:IsValidTarget(source) then return end

  if Spells.E:IsReady() and Menu.Get("Ziggs.Auto.gapcloseE") then
    if Spells.E:Cast(source) then return end
  end

  if Spells.W:IsReady() and Menu.Get("Ziggs.Auto.gapcloseW") and
      not Ziggs.WActive() then Spells.W:Cast(source) end
end

---[OnCreateObject event]------------------------------------------------------------------------
function events.OnCreateObject(obj)
  if obj.Name == "ZiggsE3" then
    Ziggs.EPosition = obj.Position
    delay(10000, function() Ziggs.EPosition = nil end)
  end
end

---[OnTick event]------------------------------------------------------------------------
function events.OnTick()
  if not IsAvailable() then
    return
  end
  if Menu.Get("Ziggs.Auto.turrets") then Ziggs.AutoTurret() end
  local Mode = Orbwalker.GetMode()
  if Ziggs[Mode] then Ziggs[Mode]() end

end

---[DrawMenu]------------------------------------------------------------------------
function Ziggs.DrawMenu()


  local function ZiggsMenu()
    --Combo menu
    Menu.NewTree("Ziggs.Combo", "[+] Combo Menu", function()
      --Combo.Q menu
      Menu.ColumnLayout("Ziggs.ComboMenu.Q", "Ziggs.ComboMenu.Q", 2, true, function()
        Menu.ColoredText('[Q] Short Fuse', defaultColor, true)
        Menu.Checkbox("Ziggs.Combo.useQ", "use Q in Combo?", true)
        Menu.Slider("Ziggs.Combo.QMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Combo.qChance", "Don't use if hitchance < %", 5, 1, 6, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Combo.W menu
      Menu.ColumnLayout("Ziggs.ComboMenu.W", "Ziggs.ComboMenu.W", 2, true, function()
        Menu.ColoredText('[W] Bouncing Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Combo.useW", "use W in Combo?", true)
        Menu.Checkbox("Ziggs.Combo.throw", "Throw enemy into E with W?", true)
        Menu.Checkbox("Ziggs.Combo.melee", "push close melees away?", false)
        Menu.Slider("Ziggs.Combo.WMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Combo.wChance", "Don't use if hitchance < %", 5, 1, 6, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Combo.E menu
      Menu.ColumnLayout("Ziggs.ComboMenu.E", "Ziggs.ComboMenu.E", 2, true, function()
        Menu.ColoredText('[E] Satchel Charge', defaultColor, true)
        Menu.Checkbox("Ziggs.Combo.useE", "use E in Combo?", true)
        Menu.Slider("Ziggs.Combo.EMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Combo.eChance", "Don't use if hitchance < %", 5, 1, 6, 1)

        Menu.NextColumn()
        Menu.Separator()
      end)
      --Combo.R menu
      Menu.ColumnLayout("Ziggs.ComboMenu.R", "Ziggs.ComboMenu.R", 2, true, function()
        Menu.ColoredText('[R] Mega Inferno Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Combo.useR", "use R in Combo?", true)
        Menu.Slider("Ziggs.Combo.RMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Combo.RMinEnemies", "Don't use if enemies < ", 1, 1, 5, 1)
        Menu.Slider("Ziggs.Combo.rChance", "Don't use if hitchance < %", 6, 1, 6, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)

    end)


    --Harass menu
    Menu.NewTree("Ziggs.Harass", "[+] Harass Menu", function()
      --Harass.Q menu
      Menu.ColumnLayout("Ziggs.Harass.Q", "Ziggs.Harass.Q", 2, true, function()
        Menu.ColoredText('[Q] Short Fuse', defaultColor, true)
        Menu.Checkbox("Ziggs.Harass.useQ", "use Q in Harass?", true)
        Menu.Slider("Ziggs.Harass.QMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Harass.qChance", "Don't use if hitchance < %", 5, 1, 6, 1)

        Menu.NextColumn()
        Menu.Separator()
      end)
      --Harass.W menu
      Menu.ColumnLayout("Ziggs.HarassMenu.W", "Ziggs.HarassMenu.W", 2, true, function()
        Menu.ColoredText('[W] Bouncing Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Harass.useW", "use W in Harass?", true)
        Menu.Checkbox("Ziggs.Harass.throw", "Throw enemy into E with W?", false)
        Menu.Checkbox("Ziggs.Harass.melee", "push close melees away?", true)
        Menu.Slider("Ziggs.Harass.WMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Harass.wChance", "Don't use if hitchance < %", 5, 1, 6, 1)

        Menu.NextColumn()
        Menu.Separator()
      end)
      --Harass.E menu
      Menu.ColumnLayout("Ziggs.HarassMenu.E", "Ziggs.HarassMenu.E", 2, true, function()
        Menu.ColoredText('[E] Satchel Charge', defaultColor, true)
        Menu.Checkbox("Ziggs.Harass.useE", "use E in Harass?", true)
        Menu.Slider("Ziggs.Harass.EMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Harass.eChance", "Don't use if hitchance < %", 5, 1, 6, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Harass.R menu
      Menu.ColumnLayout("Ziggs.HarassMenu.R", "Ziggs.HarassMenu.R", 2, true, function()
        Menu.ColoredText('[R] Mega Inferno Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Harass.useR", "use R in Harass?", true)
        Menu.Slider("Ziggs.Harass.RMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.Slider("Ziggs.Harass.RMinEnemies", "Don't use if enemies < ", 1, 1, 5, 1)
        Menu.Slider("Ziggs.Harass.RChance", "Don't use if hitchance < %", 6, 1, 6, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
    end)


    --Flee menu
    Menu.NewTree("Ziggs.Flee", "[+] Flee Menu", function()

      --Flee.W menu
      Menu.ColumnLayout("Ziggs.FleeMenu.W", "Ziggs.FleeMenu.W", 2, true, function()
        Menu.ColoredText('[W] Bouncing Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Flee.useW", "use W in Flee?", true)
        Menu.Slider("Ziggs.Flee.WMana", "Don't use if Mana < %", 5, 1, 100, 1)

        Menu.NextColumn()
        Menu.Separator()
      end)

    end)


    --LC menu
    Menu.NewTree("Ziggs.LC", "[+] Lane/jungle clear Menu", function()
      --LC.Q menu
      Menu.ColumnLayout("Ziggs.LC.Q", "Ziggs.LC.Q", 2, true, function()
        Menu.ColoredText('[Q] Short Fuse', defaultColor, true)
        Menu.Checkbox("Ziggs.LC.useQ", "use Q in farming?", true)
        Menu.Slider("Ziggs.LC.QMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --LC.W menu
      Menu.ColumnLayout("Ziggs.LCMenu.W", "Ziggs.LCMenu.W", 2, true, function()
        Menu.ColoredText('[W] Bouncing Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.LC.useW", "use W in farming?", true)
        Menu.Slider("Ziggs.LC.WMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --LC.E menu
      Menu.ColumnLayout("Ziggs.LCMenu.E", "Ziggs.LCMenu.E", 2, true, function()
        Menu.ColoredText('[E] Satchel Charge', defaultColor, true)
        Menu.Checkbox("Ziggs.LC.useE", "use E in farming?", true)
        Menu.Slider("Ziggs.LC.EMana", "Don't use if Mana < %", 25, 1, 100, 1)
        Menu.NextColumn()
        Menu.Separator()
      end)
    end)

    --Auto menu
    Menu.NewTree("Ziggs.Auto", "[+] Autos Menu", function()
      --Auto.W menu
      Menu.ColumnLayout("Ziggs.Auto.Menu", "Ziggs.Auto.Menu", 2, true, function()
        Menu.Checkbox("Ziggs.Auto.turrets", "Auto W on turrets?", true)
        Menu.Checkbox("Ziggs.Auto.interruptSpells", "Auto W on interruptible spells?", true)
        Menu.Checkbox("Ziggs.Auto.gapcloseW", "Auto W on gapclosing champs?", true)
        Menu.Separator()

        --Auto.E menu
        Menu.Checkbox("Ziggs.Auto.gapcloseE", "Auto E on gapclosing champs?", true)
        Menu.Checkbox("Ziggs.Auto.immobileE", "Auto E on immobile champs?", true)

        --Auto.E+W  menu
        Menu.Separator()



      end)



    end)

    --Colors menu
    Menu.NewTree("Ziggs.Colors", "[+] Colors Menu", function()
      --Colors.Q menu
      Menu.ColumnLayout("Ziggs.ColorsMenu.Q", "Ziggs.ColorsMenu.Q", 2, true, function()
        Menu.ColoredText('[Q] Short Fuse', defaultColor, true)
        Menu.Checkbox("Ziggs.Colors.useQ1", "Draw Q range?", true)
        Menu.ColorPicker("Ziggs.Colors.Q1", "Q color", defaultColor)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Colors.W menu
      Menu.ColumnLayout("Ziggs.ColorsMenu.W", "Ziggs.ColorsMenu.W", 2, true, function()
        Menu.ColoredText('[W] Bouncing Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Colors.useW", "Draw W range?", true)
        Menu.ColorPicker("Ziggs.Colors.W", "W color ", defaultColor)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Colors.E menu
      Menu.ColumnLayout("Ziggs.ColorsMenu.E", "Ziggs.ColorsMenu.E", 2, true, function()
        Menu.ColoredText('[E] Satchel Charge', defaultColor, true)
        Menu.Checkbox("Ziggs.Colors.useE", "Draw E range?", true)
        Menu.ColorPicker("Ziggs.Colors.E", "E color", defaultColor)
        Menu.NextColumn()
        Menu.Separator()
      end)
      --Colors.R menu
      Menu.ColumnLayout("Ziggs.ColorsMenu.R", "Ziggs.ColorsMenu.R", 2, true, function()
        Menu.ColoredText('[R] Mega Inferno Bomb', defaultColor, true)
        Menu.Checkbox("Ziggs.Colors.useR", "Draw R range?", true)
        Menu.ColorPicker("Ziggs.Colors.R", "R color", defaultColor)
        Menu.NextColumn()
        Menu.Separator()
      end)
    end)





  end

  Menu.RegisterMenu(scriptName, scriptName, ZiggsMenu)
end

---[SetEvents]------------------------------------------------------------------------
function Ziggs.SetEvents()
  for eventName, eventId in pairs(Enums.Events) do
    if events[eventName] then
      EventManager.RegisterCallback(eventId, events[eventName])
    end
  end
end

---[OnLoad]------------------------------------------------------------------------
function OnLoad()
  Ziggs.DrawMenu()
  Ziggs.SetEvents()
  return true
end
