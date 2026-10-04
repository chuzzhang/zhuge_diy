---@diagnostic disable: undefined-global
local skill = fk.CreateSkill({
    name = "gengxue",
})

local SHI_NAME = "gengxue_shi"
local SHI_MAX = 7

local function shiCount(player)
    local count = #player:getPile(SHI_NAME)
    local room = player.room
    if room and room.gengxue_pending then
        local pending = room.gengxue_pending[player.id]
        if pending then
            local hand = player:getCardIds("h")
            for _, id in ipairs(hand) do
                if pending[id] then count = count + 1 end
            end
        end
    end
    return count
end

local function moveShiToHand(self, player)
    local room = player.room
    local shi = player:getPile(SHI_NAME)
    if not shi or #shi == 0 then return end
    room.gengxue_pending = room.gengxue_pending or {}
    room.gengxue_pending[player.id] = room.gengxue_pending[player.id] or {}
    for _, id in ipairs(shi) do
        room.gengxue_pending[player.id][id] = true
    end
    room:moveCardTo(shi, Player.Hand, player, fk.ReasonJustMove, self.name)
    print("【耕学】识移入手牌：" .. #shi .. " 张")
end

local function restoreShi(self, player)
    local room = player.room
    if not room.gengxue_pending or not room.gengxue_pending[player.id] then return end
    local pending = room.gengxue_pending[player.id]
    local hand = player:getCardIds("h")
    local toRestore = {}
    for _, id in ipairs(hand) do
        if pending[id] then table.insert(toRestore, id) end
    end
    if #toRestore > 0 then
        room:moveCardTo(
            toRestore, Player.Special, player, fk.ReasonJustMove, self.name,
            SHI_NAME, true, player, nil, nil
        )
    end
    room.gengxue_pending[player.id] = nil
    print("【耕学】剩余的识已还回：" .. #toRestore .. " 张")
end

local function getShiPoints(player)
    local points = {}
    local pile = player:getPile(SHI_NAME)
    if pile then
        for i = 1, #pile do
            local c = Fk:getCardById(pile[i])
            if c then points[c.number] = true end
        end
    end
    local room = player.room
    if room and room.gengxue_pending then
        local pending = room.gengxue_pending[player.id]
        if pending then
            local hand = player:getCardIds("h")
            for i = 1, #hand do
                if pending[hand[i]] then
                    local c = Fk:getCardById(hand[i])
                    if c then points[c.number] = true end
                end
            end
        end
    end
    return points
end

-- ① 每轮开始时：将任意张牌置于武将牌上作为"识"（总数量至多7张）
skill:addEffect(fk.RoundStart, {
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and #player:getCardIds("he") > 0
            and shiCount(player) < SHI_MAX
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askToSkillInvoke(player, { skill_name = self.name })
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local avail = player:getCardIds("he")
        local canPlace = SHI_MAX - shiCount(player)
        local maxPick = math.min(#avail, canPlace)
        if maxPick <= 0 then return end
        local cards = room:askToChooseCards(player, {
            target = player, flag = "he", min = 1, max = maxPick, skill_name = self.name,
        })
        if not cards or #cards == 0 then return end
        room:moveCardTo(cards, Player.Special, player, fk.ReasonJustMove, self.name,
            SHI_NAME, true, player, nil, nil)
        print("【耕学】将 " .. #cards .. " 张牌置于武将牌上作为识")
    end,
})

-- ② 牌进入弃牌堆时：同点数则置入牌堆顶一张作为"识"（总数量至多7张）
skill:addEffect(fk.AfterCardsMove, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        if shiCount(player) >= SHI_MAX then return false end
        local points = getShiPoints(player)
        if next(points) == nil then return false end
        for _, moveData in ipairs(data or {}) do
            if moveData.toArea == Card.DiscardPile then
                for _, info in ipairs(moveData.moveInfo or {}) do
                    local c = Fk:getCardById(info.cardId)
                    if c and points[c.number] then return true end
                end
            end
        end
        return false
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local top = room.draw_pile and room.draw_pile[1]
        if not top then return end
        room:moveCardTo({ top }, Player.Special, player, fk.ReasonJustMove, self.name,
            SHI_NAME, true, player, nil, nil)
        print("【耕学】同点数，牌堆顶置入识")
        if room.gengxue_pending and room.gengxue_pending[player.id] then
            local shi = player:getPile(SHI_NAME)
            if shi and #shi > 0 then
                for _, id in ipairs(shi) do
                    room.gengxue_pending[player.id][id] = true
                end
                room:moveCardTo(shi, Player.Hand, player, fk.ReasonJustMove, self.name)
            end
        end
    end,
})

-- ③ 回合外点出牌时：借出识
skill:addEffect(fk.AskForCardUse, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        if player.room.current == player then return false end
        return #player:getPile(SHI_NAME) > 0
    end,
    on_use = function(self, event, target, player, data)
        moveShiToHand(self, player)
    end,
})

-- ④ 回合外点打出时：借出识
skill:addEffect(fk.AskForCardResponse, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        if player.room.current == player then return false end
        return #player:getPile(SHI_NAME) > 0
    end,
    on_use = function(self, event, target, player, data)
        moveShiToHand(self, player)
    end,
})

-- ⑤ 使用/打出牌后：剩余的识立即还回
skill:addEffect(fk.AfterCardUseDeclared, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        return player.room.gengxue_pending and player.room.gengxue_pending[player.id]
    end,
    on_use = function(self, event, target, player, data)
        restoreShi(self, player)
    end,
})

-- ⑥ 回合结束时兜底还回
skill:addEffect(fk.TurnEnd, {
    can_trigger = function(self, event, target, player, data)
        if target ~= player or not player:hasSkill(self) then return false end
        return player.room.gengxue_pending and player.room.gengxue_pending[player.id]
    end,
    on_use = function(self, event, target, player, data)
        restoreShi(self, player)
    end,
})

-- ⑦ 每轮结束时：获得相同点数最多的"识"
skill:addEffect(fk.RoundEnd, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        -- 先把借出的识收回来
        restoreShi(self, player)
        return #player:getPile(SHI_NAME) > 0
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local shi = player:getPile(SHI_NAME)
        if #shi == 0 then return end

        -- 按点数分组
        local byNum = {}
        for _, id in ipairs(shi) do
            local c = Fk:getCardById(id)
            if c then
                byNum[c.number] = byNum[c.number] or {}
                table.insert(byNum[c.number], id)
            end
        end

        -- 找最大数量
        local maxCount = 0
        for _, ids in pairs(byNum) do
            if #ids > maxCount then maxCount = #ids end
        end

        -- 收集所有数量等于 maxCount 的点数组
        local toGain = {}
        local gainedNums = {}
        for num, ids in pairs(byNum) do
            if #ids == maxCount then
                table.insert(gainedNums, num)
                for _, id in ipairs(ids) do
                    table.insert(toGain, id)
                end
            end
        end

        if #toGain > 0 then
            room:moveCardTo(toGain, Player.Hand, player, fk.ReasonJustMove, self.name)
        end
        print("【耕学】本轮结束，获得相同点数最多的识 " .. #toGain .. " 张")
    end,
})

return skill