local fu_jin = fk.CreateSkill {
  name = "fu_jin",
  tags = { Skill.Compulsory },
}

fu_jin:addAcquireEffect(function(self, player, is_start, src)
  local room = player.room
  local damage_events = { fk.Damage, fk.DamageCaused, fk.DetermineDamageCaused }
  local damaged_events = { fk.Damaged, fk.DamageInflicted, fk.DetermineDamageInflicted }

  local function collectSkillPool(event_types)
    local pool = {}
    for name, skel in pairs(Fk.skill_skels) do
      if name:sub(1, 1) ~= "#" and not skel.mode_skill then
        local skill = Fk.skills[name]
        if skill and not skill:hasTag(Skill.Lord) then
          local pkg = skill.package
          if pkg and not table.contains(room.disabled_packs, pkg.name) then
            if not player:hasSkill(name, true, true) then
              for _, effect in ipairs(skel.effects) do
                if effect:isInstanceOf(TriggerSkill)
                  and table.contains(event_types, effect.event) then
                  table.insert(pool, name)
                  break
                end
              end
            end
          end
        end
      end
    end
    return pool
  end

  local choice = room:askToChoice(player, {
    choices = { "fu_jin_weapon", "fu_jin_armor" },
    skill_name = "fu_jin",
    prompt = "#fu_jin_choice",
  })

  local slots_to_abort
  local skill_pool
  if choice == "fu_jin_weapon" then
    slots_to_abort = {
      Player.ArmorSlot, Player.OffensiveRideSlot,
      Player.DefensiveRideSlot, Player.TreasureSlot, Player.JudgeSlot,
    }
    skill_pool = collectSkillPool(damage_events)
  else
    slots_to_abort = {
      Player.WeaponSlot, Player.OffensiveRideSlot,
      Player.DefensiveRideSlot, Player.TreasureSlot, Player.JudgeSlot,
    }
    skill_pool = collectSkillPool(damaged_events)
  end

  room:abortPlayerArea(player, slots_to_abort)

  if #skill_pool > 0 then
    local picked = room:tableRandomPick(skill_pool)
    room:handleAddLoseSkills(player, picked)
  end
end)

return fu_jin