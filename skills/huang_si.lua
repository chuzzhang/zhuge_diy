local huang_si = fk.CreateSkill {
  name = "huang_si",
  tags = { Skill.Compulsory },
}

local function getBonus(player)
  return player:getMark("huang_si_bonus") or 0
end

huang_si:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "huang_si_bonus", 4)
    room:changeMaxHp(player, 4)
  end,
})

huang_si:addEffect(fk.DrawInitialCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 4
  end,
})

huang_si:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    if player:hasSkill(self) and card and card.trueName == "slash" then
      return getBonus(player)
    end
    return 0
  end,
})

huang_si:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(self) then
      return getBonus(player)
    end
    return 0
  end,
})

local function onDamageOrDamaged(self, player)
  player:drawCards(1, self.name)
  local room = player.room
  local bonus = getBonus(player)
  if bonus > 0 and player:getMark("huang_si_awakened") == 0 then
    room:setPlayerMark(player, "huang_si_bonus", bonus - 1)
    room:changeMaxHp(player, -1)
  end
end

huang_si:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from == player
  end,
  on_use = function(self, event, target, player, data)
    onDamageOrDamaged(self, player)
  end,
})

huang_si:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.to == player
  end,
  on_use = function(self, event, target, player, data)
    onDamageOrDamaged(self, player)
  end,
})

return huang_si