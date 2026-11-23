-- CraftETA: what the route earns or costs. For one craft, one step and a stretch of the route (1 to 300):
-- materials against the sell price from the latest auction house prices, after the AH's 5%, and what
-- selling the finished crafts gives back. A price that is missing is said so, never counted as zero.
local _, ns = ...
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

local AH_CUT = 0.95

-- one craft of a guide entry { name, crafts, { mat, count, ... }, yield? }
-- { cost, costMissing, sell, sellState, profit }
--   sellState: "ok", "none" (nobody sells it on the AH) or "missing" (no price: not scanned, or no item)
function ns.EntryNet(entry)
  local runs = math.max(1, entry[2] or 1)
  local y = entry[4] or 1
  local cost, costMissing = 0, false
  local list = entry[3] or {}
  for i = 1, #list, 2 do
    local p = ns.MatPrice(list[i])
    if p then cost = cost + p * list[i + 1] / runs else costMissing = true end
  end
  local out = { cost = cost, costMissing = costMissing, y = y, sellState = "missing" }
  local id = ns.ItemID(entry[1])
  if id then
    local sell, none = ns.SellUnit(id)
    if sell then
      out.sell, out.sellState = sell, "ok"
      out.profit = sell * AH_CUT * y - cost
    elseif none then
      out.sellState = "none"
    end
  end
  return out
end

-- a step: every craft the route makes in it (the chosen one for an "any" step)
-- { n = crafts, cost, revenue, profit, unpriced = crafts with no price, entries = { { entry, net, n } } }
function ns.StepNet(profID, index, step)
  local res = { cost = 0, revenue = 0, profit = 0, unpriced = 0, crafts = 0, entries = {} }
  for _, entry in ipairs((ns.Chosen(profID, index, step))) do
    local n = entry[2]
    local net = ns.EntryNet(entry)
    res.crafts = res.crafts + n
    res.cost = res.cost + net.cost * n
    if net.profit then
      res.revenue = res.revenue + net.sell * AH_CUT * net.y * n
      res.profit = res.profit + net.profit * n
    else
      res.unpriced = res.unpriced + n
    end
    if net.costMissing then res.costMissing = true end
    res.entries[#res.entries + 1] = { entry = entry, net = net, n = n }
  end
  return res
end

-- a stretch of the route, from skill `from` to `to`:
-- { cost (all materials), revenue (selling what the route makes and does not use itself), net,
--   crafts, unpriced (crafts whose product has no price), costUnknown }
-- bags = true: the materials you already have are not counted as cost
function ns.RouteNet(profID, from, to, bags)
  local guide = ns.GUIDES[profID]
  if not guide then return nil end
  local _, mats = ns.Plan(profID, from, to)
  local cost, costUnknown = 0, false
  if bags then
    cost, costUnknown = ns.Cost(mats)
  else
    for name, count in pairs(mats) do
      local c = ns.MatCost(name, count)
      if c then cost = cost + c else costUnknown = true end
    end
  end
  -- what the route makes, minus what its own later steps use
  local made, used, crafts = {}, {}, {}
  local total = 0
  for index, step in ipairs(guide.steps) do
    if step[1] < to and from < step[2] then
      local share = ns.Share(step, from)
      if step[2] > to then
        share = share * (to - math.max(step[1], from)) / math.max(1, step[2] - math.max(step[1], from))
      end
      for _, entry in ipairs((ns.Chosen(profID, index, step))) do
        local n = math.ceil(entry[2] * share)
        total = total + n
        made[entry[1]] = (made[entry[1]] or 0) + n * (entry[4] or 1)
        crafts[entry[1]] = entry
        local list = entry[3] or {}
        for m = 1, #list, 2 do
          used[list[m]] = (used[list[m]] or 0) + math.ceil(list[m + 1] * share)
        end
      end
    end
  end
  local revenue, unpriced, sold = 0, 0, 0
  for name, count in pairs(made) do
    local spare = count - (used[name] or 0)
    if spare > 0 then
      local entry = crafts[name]
      local id = ns.ItemID(name)
      local sell = id and ns.SellUnit(id)
      if sell then
        revenue = revenue + sell * AH_CUT * spare
        sold = sold + spare
      else
        unpriced = unpriced + math.ceil(spare / math.max(1, entry[4] or 1))
      end
    end
  end
  return { cost = cost, costUnknown = costUnknown, revenue = revenue, net = cost - revenue,
    crafts = total, unpriced = unpriced, sold = sold }
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------
local GREEN, RED, GREY = "|cff5cd67c", "|cffe6594d", "|cff8c8f96"

function ns.SignedMoney(v)
  if math.abs(v) < 0.5 then return ns.Money(0) end
  return (v > 0 and "+" or "-") .. ns.Money(math.abs(v))
end

-- "+3s 20c" in green, "-1g" in red, or why there is no number
function ns.ProfitText(net)
  if net.profit then
    return (net.profit >= 0 and GREEN or RED) .. ns.SignedMoney(net.profit) .. "|r"
  elseif net.sellState == "none" then
    return GREY .. L("nobody sells it on the AH", "ingen sælger den på AH") .. "|r"
  end
  return GREY .. L("no price", "ingen pris") .. "|r"
end

-- one line for a stretch: "Sells back 85g  ·  net cost 35g" (or net gain)
function ns.RouteNetText(r, short)
  if not r or r.crafts == 0 then return "" end
  local parts = {}
  if r.sold > 0 or r.unpriced == 0 then
    parts[#parts + 1] = L("Sells back ", "Sælges igen for ") .. ns.Money(r.revenue)
  end
  local net = r.net
  if net >= 0 then
    parts[#parts + 1] = L("net cost ", "netto pris ") .. (r.costUnknown and "~" or "") .. ns.Money(net)
  else
    parts[#parts + 1] = GREEN .. L("net gain ", "netto gevinst ") .. ns.Money(-net) .. "|r"
  end
  local text = table.concat(parts, "  ·  ")
  if r.unpriced > 0 then
    text = text .. "  " .. RED .. (short and L("(%d unpriced)", "(%d uden pris)") or L("(no price for %d crafts)", "(ingen pris på %d crafts)")):format(r.unpriced) .. "|r"
  end
  return text
end

-- the tooltip for a stretch, lines to add under a title
function ns.AddRouteTip(tip, label, r)
  if not r then return end
  tip:AddLine(" ")
  tip:AddLine(label, 1, 0.82, 0.3)
  tip:AddDoubleLine(L("Materials", "Materialer"), (r.costUnknown and "~" or "") .. ns.Money(r.cost), 0.85, 0.87, 0.9, 1, 1, 1)
  tip:AddDoubleLine(L("Sell the crafts (after the AH's 5%)", "Sælg crafts (efter AH's 5%)"), "+" .. ns.Money(r.revenue), 0.85, 0.87, 0.9, 0.36, 0.84, 0.49)
  if r.net >= 0 then
    tip:AddDoubleLine(L("Net cost", "Netto pris"), ns.Money(r.net), 1, 0.82, 0.3, 1, 1, 1)
  else
    tip:AddDoubleLine(L("Net gain", "Netto gevinst"), ns.Money(-r.net), 1, 0.82, 0.3, 0.36, 0.84, 0.49)
  end
  if r.unpriced > 0 then
    tip:AddLine(L("%d crafts have no price from the latest scan: they are not counted. Press Scan AH at the auction house.",
      "%d crafts har ingen pris fra seneste scan: de er ikke talt med. Tryk Scan AH ved auktionshuset."):format(r.unpriced), 0.9, 0.35, 0.3, true)
  end
  tip:AddLine(L("Products the route uses itself (bolts, stones) are not counted as sold.",
    "Det ruten selv bruger videre (bolte, sten) tælles ikke som solgt."), 0.55, 0.58, 0.64, true)
end

-- a short one for the step list: the profit of the whole step, in green or red ("~" when part has no price)
function ns.StepProfitShort(sn)
  local text = ns.SignedMoney(sn.profit)
  return (sn.profit >= 0 and GREEN or RED) .. (sn.unpriced > 0 and "~" or "") .. text .. "|r"
end
