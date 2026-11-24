-- CraftETA: things your guide needs later. Their tooltip says to keep them, and when you open the bank
-- a line in chat lists what in your bags the later steps use, so nobody sells or deletes them by mistake.
local _, ns = ...
local Plain = ns.Plain

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- item name -> { prof, at, recipe, need }: the first later step of your professions that uses it, and how
-- many all later steps use. Items the step you are on uses are marked now = true (keep them in your bags).
local cache, cacheAt = nil, 0
function ns.LaterUse()
  if cache and GetTime() - cacheAt < 5 then return cache end
  local out = {}
  local skills = ns.Skills and ns.Skills() or {}
  for id, s in pairs(skills) do
    local guide = ns.GUIDES[id]
    local cur = guide and s.rank < 300 and ns.StepIndex(guide, s.rank)
    if cur then
      for i = cur, #guide.steps do
        local step = guide.steps[i]
        for _, e in ipairs((ns.Chosen(id, i, step))) do
          local mats = e[3]
          for m = 1, #mats, 2 do
            local name = mats[m]
            local u = out[name]
            if i == cur then
              if u then u.now = true else out[name] = { now = true, need = 0 } end
            else
              if not u or not u.prof then
                u = u or { need = 0 }
                u.prof, u.at, u.recipe = guide.name, step[1], e[1]
                out[name] = u
              end
              u.need = u.need + mats[m + 1]
            end
          end
        end
      end
    end
  end
  cache, cacheAt = out, GetTime()
  return out
end

-- the tooltip: "Keep it: Engineering uses 30 from 160 (Explosive Sheep)"
local byID
local function UseOfID(id)
  local later = ns.LaterUse()
  if not byID or byID.src ~= later then
    byID = { src = later }
    for name, u in pairs(later) do
      local itemID = ns.ItemID(name)
      if itemID then byID[itemID] = u end
    end
  end
  return byID[id]
end

local function AddKeep(tooltip, data)
  if not ns.db or ns.db.tooltip == false or ns.db.keepHint == false then return end
  local id = data and Plain(data.id)
  if type(id) ~= "number" then return end
  local u = UseOfID(id)
  if not u or not u.prof then return end
  tooltip:AddLine(L("CraftETA: keep it. %s uses %d from %d (%s)", "CraftETA: gem den. %s bruger %d fra %d (%s)")
    :format(u.prof, u.need, u.at, u.recipe), 1, 0.82, 0.3, true)
end

ns.Register("PLAYER_LOGIN")
ns.On("PLAYER_LOGIN", function()
  if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then pcall(AddKeep, tooltip, data) end
    end)
  end
end)

-- at the bank: what in your bags only later steps use (not the step you are on), to put in the bank
local lastTold = 0
local function TellBank()
  if not ns.db or ns.db.keepHint == false or GetTime() - lastTold < 10 then return end
  lastTold = GetTime()
  local rows = {}
  for name, u in pairs(ns.LaterUse()) do
    if u.prof and not u.now then
      local id = ns.ItemID(name)
      local n = id and ns.BagCount and ns.BagCount(id) or 0
      if n > 0 then rows[#rows + 1] = { name = name, n = n, u = u } end
    end
  end
  if #rows == 0 then return end
  table.sort(rows, function(a, b) return a.u.at < b.u.at end)
  local parts = {}
  for i, r in ipairs(rows) do
    if i > 8 then parts[#parts + 1] = "+" .. (#rows - 8); break end
    parts[#parts + 1] = ("%d %s (%s %d)"):format(r.n, r.name, r.u.prof, r.u.at)
  end
  ns.Print(L("Bank these for later in your guide: ", "Læg disse i banken til senere i guiden: ") .. table.concat(parts, ", "))
end
ns.Register("BANKFRAME_OPENED")
ns.On("BANKFRAME_OPENED", TellBank)
ns.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(kind)
  local banker = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
  if banker and Plain(kind) == banker then TellBank() end
end)
