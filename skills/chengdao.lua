-- packages/zhuge_diy/skills/chengdao.lua
local skill = fk.CreateSkill({
    name = "zhuge_diy__chengdao",
})

skill:addEffect(fk.TurnEnd, {
    can_trigger = function(self, event, target, player, data)
        if target == player then return false end
        if not player:hasSkill(self) then return false end
        -- 修正：必须用小写 c 的 getHandcardNum，否则会静默报错导致触发失败
        return target.hp > player.hp
            or target:getHandcardNum() > player:getHandcardNum()
    end,
    on_use = function(self, event, target, player, data)
        player:drawCards(1, self.name)
    end,
})

return skill