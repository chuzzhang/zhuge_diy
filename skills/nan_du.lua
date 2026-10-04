local nan_du = fk.CreateSkill {
  name = "nan_du",
  tags = { Skill.Wake },
}

local function countLostCards(player, data)
  local count = 0
  for _, move in ipairs(data or {}) do
    if move.from == player then
      for _, info in ipairs(move.moveInfo or {}) do
        local area = info.fromArea
        if area == Card.PlayerHand
          or area == Card.PlayerEquip
          or area == Card.PlayerJudge then
          count = count + 1
        end
      end
    end
  end
  return count
end

local function doWake(self, player)
  local room = player.room
  local cur_max = player.maxHp
  if cur_max ~= 1 then
    room:changeMaxHp(player, 1 - cur_max)
  end

  room:setPlayerMark(player, "huang_si_bonus", 1)
  room:setPlayerMark(player, "huang_si_awakened", 1)

  local recoverNum = player.maxHp - player.hp
  if recoverNum > 0 then
    room:recover({ who = player, num = recoverNum, skillName = "nan_du" })
  end

  room:handleAddLoseSkills(player, "fu_jin")
end

-- 累计受到伤害：每次受伤累加，达到 4 点则觉醒
nan_du:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if not player:hasSkill(self) then return false end
    if player:getMark("nan_du_awakened") > 0 then return false end
    -- 累加到 mark（服务端私有，不会广播给客户端）
    player:addMark("nan_du_damage_acc", data.damage)
    return player:getMark("nan_du_damage_acc") >= 4
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "nan_du_awakened", 1)
    doWake(self, player)
  end,
})

-- 累计失去牌：回合外累计失去 8 张牌则觉醒
nan_du:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if player:getMark("nan_du_awakened") > 0 then return false end
    if player.room.current == player then return false end
    local lost = countLostCards(player, data)
    if lost <= 0 then return false end
    player:addMark("nan_du_cards_acc", lost)
    return player:getMark("nan_du_cards_acc") >= 8
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "nan_du_awakened", 1)
    doWake(self, player)
  end,
})

return nan_du