-- CraftETA: chat reminders. Each one can be turned off in settings.
--   1. a profession is ready for its next rank: who teaches it
--   2. you open the auction house and your prices are old (or were never scanned)
--   3. everything on your shopping list is in your bags
local _, ns = ...
local T = ns.T

local function On(key) return ns.db and ns.db[key] ~= false end
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- 1. rank reminder: once for each profession and rank, per login
local toldRank = {}
local function CheckRanks()
  if not On("rankRemind") then return end
  for profID, s in pairs(ns.Skills()) do
    local r, name, where = ns.TrainNow(profID, s.rank, s.max)
    local key = r and (profID .. ":" .. r.at)
    if r and not toldRank[key] then
      toldRank[key] = true
      local prof = ns.ProfName and ns.ProfName(profID) or ""
      ns.Print(T("rankRemind", prof, name, where))
    end
  end
end
ns.Register("PLAYER_LOGIN")
ns.Register("SKILL_LINES_CHANGED")
ns.On("PLAYER_LOGIN", function() C_Timer.After(12, CheckRanks) end)
ns.On("SKILL_LINES_CHANGED", function() C_Timer.After(2, CheckRanks) end)

-- 2. old prices when the auction house opens
ns.Register("AUCTION_HOUSE_SHOW")
ns.On("AUCTION_HOUSE_SHOW", function()
  if not On("scanRemind") or not ns.QuickScanState then return end
  C_Timer.After(1, function()
    local _, _, last = ns.QuickScanState()
    local hours = 24
    if last and time() - last < hours * 3600 then return end
    if last then
      local h = math.floor((time() - last) / 3600)
      ns.Print(L("Your prices are %d hours old. Press scan for fresh ones.",
        "Dine priser er %d timer gamle. Tryk scan for friske."):format(h))
    else
      ns.Print(L("You haven't scanned prices yet. Press scan to get them.",
        "Du har ikke scannet priser endnu. Tryk scan for at få dem."))
    end
  end)
end)

-- 3. the list is complete
local complete = false
local function CheckList()
  if not On("listRemind") or not ns.ListItems then return end
  local ok, items = pcall(ns.ListItems)
  if not ok or type(items) ~= "table" or #items == 0 then complete = false return end
  local all = true
  for _, it in ipairs(items) do
    if not it.crate and (it.have or 0) < (it.need or 0) then all = false break end
  end
  if all and not complete then
    complete = true
    ns.Print(T("listComplete"))
  elseif not all then
    complete = false
  end
end
ns.Register("BAG_UPDATE_DELAYED")
ns.On("BAG_UPDATE_DELAYED", function() C_Timer.After(1, CheckList) end)
