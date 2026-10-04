-- packages/zhuge_diy/skills/qingtian.lua
local skill = fk.CreateSkill({
    name = "zhuge_diy__qingtian",
})

local function triggerQingtian(skill, player)
    local room = player.room

    -- 1. 先展示牌堆顶两张牌
    local ids = room:getNCards(2)
    if #ids < 2 then return end
    room:showCards(ids, player)

    -- 2. 再选择一名角色
    local targets = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        skill_name = skill.name,
        prompt = "#qingtian-choose",
        cancelable = false,
    })
    if #targets == 0 then return end
    local target = targets[1]

    -- 3. 将展示的牌交给目标
    room:moveCardTo(ids, Player.Hand, target, fk.ReasonJustMove, skill.name)

    local c1 = Fk:getCardById(ids[1])
    local c2 = Fk:getCardById(ids[2])
    local sameColor = (c1.color == c2.color)

    if sameColor then
        for _, id in ipairs(ids) do
            local card = Fk:getCardById(id)
            if target:canUse(card) then
                room:askToUseRealCard(target, {
                    pattern = card.name,
                    skill_name = skill.name,
                    cancelable = false,
                    extra_data = { cardIds = { id } }
                })
            else
                room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonDiscard, skill.name)
            end
        end
    else
        room:recover({
            who = target,
            num = 1,
            recoverBy = player,
            skillName = skill.name,
        })

        local useId = room:askToCards(target, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            pattern = ".",
            skill_name = skill.name,
            prompt = "#qingtian-use-one",
            cancelable = false,
        })[1]

        if useId then
            local card = Fk:getCardById(useId)
            if target:canUse(card) then
                room:askToUseRealCard(target, {
                    pattern = card.name,
                    skill_name = skill.name,
                    cancelable = false,
                    extra_data = { cardIds = { useId } }
                })
            else
                room:moveCardTo(useId, Card.DiscardPile, nil, fk.ReasonDiscard, skill.name)
            end
        end

        for _, id in ipairs(ids) do
            if id ~= useId then
                room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonDiscard, skill.name)
            end
        end
    end
end

local function addCount(skill, player)
    local room = player.room
    room.qingtian_count = room.qingtian_count or {}
    room.qingtian_count[player.id] = (room.qingtian_count[player.id] or 0) + 1
    if room.qingtian_count[player.id] >= 3 then
        room.qingtian_count[player.id] = room.qingtian_count[player.id] - 3
        triggerQingtian(skill, player)
    end
end

skill:addEffect(fk.CardUseFinished, {
    can_trigger = function(self, event, target, player, data)
        if target ~= player then return false end
        if not player:hasSkill(self) then return false end
        local card = data.card
        return card ~= nil and card.color == Card.Red
    end,
    on_use = function(self, event, target, player, data)
        addCount(self, player)
    end,
})

skill:addEffect(fk.CardRespondFinished, {
    can_trigger = function(self, event, target, player, data)
        if target ~= player then return false end
        if not player:hasSkill(self) then return false end
        local card = data.card
        return card ~= nil and card.color == Card.Red
    end,
    on_use = function(self, event, target, player, data)
        addCount(self, player)
    end,
})

return skill