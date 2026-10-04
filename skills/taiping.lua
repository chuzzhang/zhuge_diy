-- packages/zhuge_diy/skills/taiping.lua
local skill = fk.CreateSkill({
    name = "zhuge_diy__taiping",
})

skill:addEffect(fk.PreCardUse, {
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        if not data.tos or #data.tos == 0 then return false end
        for _, id in ipairs(player:getCardIds("h")) do
            if Fk:getCardById(id).color == Card.Black then
                return true
            end
        end
        return false
    end,
    on_cost = function(self, event, target, player, data)
        local cardId = player.room:askToCards(player, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            pattern = ".|.|black|hand",
            skill_name = self.name,
            cancelable = true,
            prompt = "#taiping-choose",
        })[1]
        if cardId then
            data.taiping_black_card = cardId
            return true
        end
        return false
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local blackCardId = data.taiping_black_card
        local blackCard = Fk:getCardById(blackCardId)
        local from = data.from
        local tos = data.tos
        local originalCard = data.card

        local function canUseBlackCard()
            if from:prohibitUse(blackCard) then return false end
            local cardSkill = blackCard:getSkill(from)
            if not cardSkill:canUse(from, blackCard, data.extra_data) then return false end

            local minTarget = cardSkill:getMinTargetNum(from)
            local maxTarget = cardSkill:getMaxTargetNum(from, blackCard)
            if #tos < minTarget or #tos > maxTarget then return false end

            for _, to in ipairs(tos) do
                if from:isProhibited(to, blackCard) then return false end
                if not Util.CardTargetFilter(cardSkill, from, to, {}, blackCard.subcards, blackCard, data.extra_data) then
                    return false
                end
            end
            return true
        end

        if canUseBlackCard() then
            -- 替换成功：正常走黑牌结算
            data.card = blackCard

            if not data.extraUse then
                from:addCardUseHistory(originalCard.trueName, -1)
                from:addCardUseHistory(blackCard.trueName, 1)
            end

            data.subcardsFromInfo = {
                {
                    cardId = blackCard.id,
                    beforeCard = blackCard,
                    from = player,
                    fromArea = Player.Hand,
                }
            }
        else
            -- 替换失败：弃置黑牌，清空原牌目标，中断本次使用（达到“取消”效果）
            room:moveCardTo(blackCard, Card.DiscardPile, nil, fk.ReasonDiscard, self.name)
            room:sendLog({
                type = "#UseCardCancelled",
                from = from.id,
                arg = originalCard,
                toast = true,
            })
            data:removeAllTargets()  -- 关键：清空原牌目标，使引擎无法结算
            room.logic:breakEvent()  -- 中断当前使用流程
        end
    end,
})

return skill