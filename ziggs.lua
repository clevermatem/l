if Player.CharName ~= "Ziggs" then return end

---[Variables]------------------------------------------------------------------------
--SDK & Libs
local ObjManager = _G.CoreEx.ObjectManager
local EventManager = _G.CoreEx.EventManager
local Geometry = _G.CoreEx.Geometry
local Renderer = _G.CoreEx.Renderer
local Enums = _G.CoreEx.Enums
local Game = _G.CoreEx.Game
local Input = _G.CoreEx.Input
local Menu = _G.Libs.NewMenu

local defaultColor = 0x3C9BF0FF
local scriptName = "SomethingZiggs"

local spells = {
  Q = Enums.SpellSlots.Q,
  W = Enums.SpellSlots.W,
  E = Enums.SpellSlots.E,
  R = Enums.SpellSlots.R
}
local menuData = {
  { slot = spells.Q, id = "Q", displayText = "[Q] Short Fuse",
    range = spells.Q.Range },
  { slot = spells.W, id = "W", displayText = "[W] Bouncing Bomb", range = spells.W.Range },
  { slot = spells.E, id = "E", displayText = "[E] Satchel Charge", range = spells.E.Range },
  { slot = spells.R, id = "R", displayText = "[R] Mega Inferno Bomb", range = spells.R.Range }
}

---[DrawMenu]------------------------------------------------------------------------
function Ziggs.DrawMenu()
  local function QMenu()
    Menu.ColoredText(menuData[1].displayText, defaultColor, true)
  end

  local function ChampMenu()
  end

  Menu.RegisterMenu(scriptName, scriptName, ChampMenu)
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
  Game.PrintChat('Welcome')
  Ziggs.DrawMenu()
  Ziggs.SetEvents()
  return true
end
