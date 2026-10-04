-- packages/zhuge_diy/skills/bianzhen.lua
local skill = fk.CreateSkill({
    name = "bianzhen",
    tags = { Skill.Compulsory },
})

skill:addEffect(fk.CardUsing, {
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        local use = data
        local original_suit = use.card.suit
        -- 无花色的牌不判断
        if original_suit == Card.NoSuit then return end

        for _, p in ipairs(player.room.alive_players) do
            if p ~= player then
                -- 检查该角色手牌、装备区、判定区是否有同花色牌
                local has_same_suit = false
                for _, id in ipairs(p:getCardIds("hej")) do
                    local card = Fk:getCardById(id)
                    if card.suit == original_suit then
                        has_same_suit = true
                        break
                    end
                end
                if has_same_suit then
                    use:setDisresponsive(p)
                end
            end
        end
    end,
})

return skill