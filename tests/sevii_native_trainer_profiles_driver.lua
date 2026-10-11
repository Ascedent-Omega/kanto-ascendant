-- Isolated roster/profile and reward-policy checks; not a battle playthrough.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T=S.trainers
  game:startNewGame{intro=false};game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  -- BEACH is a native double battle and requires two usable party members.
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70),require('src.pokemon.Pokemon').new(game.data,'CHARIZARD',70)}
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  U.teleport(game,S.harbors[1],8,5,'right');Q.settle();K.generationRules.resolve(game)
  local checked=0
  local unsupported={}
  local maximum={151,251,386,493}
  for era=1,4 do
    assert(K.generationRules.switchMode(game,'gen'..era));Q.settle()
    for _,row in ipairs(T.allRows)do
      local team=assert(T.team(game,row));assert(#team==3)
      for _,slot in ipairs(team)do
        local key=assert(K.backendGiftSpecies67.bySpecies[slot.species])
        local dex=assert(tonumber(key:match('^dex:(%d+)$')))
        assert(dex<=maximum[era],'future-era trainer member '..row.id)
        assert(slot.level>=60 and slot.level<=84,'post-League levels')
        local mon=require('src.pokemon.Pokemon').new(game.data,slot.species,slot.level)
        for _,move in ipairs(mon.moves)do
          local def=game.data.moves[move.id]
          if not def or tostring(def.effect):find('UNSUPPORTED',1,true)then
            unsupported[#unsupported+1]={trainer=row.id,epoch=era,species=slot.species,move=move.id}
          end
        end
        checked=checked+1
      end
    end
  end
  local f=assert(io.open(out..'/sevii-trainer-move-audit.json','wb'))
  f:write(require('src.link.Json').encode({checkedSlots=checked,unsupported=unsupported}));f:close()
  assert(#unsupported==0,'unsupported trainer moves require authored replacements; inspect move audit')
  -- A Gen-1 victory must keep the incompatible item reserved. Model just
  -- this earned receipt; actual victories were exercised by trainers_driver.
  local row=T.byId.SQUARE
  assert(K.generationRules.switchMode(game,'gen1'));Q.settle()
  local s=S.state();s.trainers={[row.id]={won=true}};S.persist(s)
  U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle()
  game.save.inventory[row.reward]=0
  local ok,why=T.claim(game,row.id);assert(not ok and why=='profile-required')
  assert(not T.record(row.id).claimed and(game.save.inventory[row.reward]or 0)==0)
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(K.generationRules.switchMode(game,'auto'));Q.settle()
  assert(T.claim(game,row.id));assert(game.save.inventory[row.reward]==1 and T.record(row.id).claimed)
  assert(not T.claim(game,row.id),'reward remains once-only after profile change')
  -- Render the challenge menu without commencing the battle.
  local other=T.byId.BEACH
  U.teleport(game,other.map,other.x,other.y+1,'up');Q.settle();Q.tap('a');U.wait(20)
  assert(game.stack:top().items);assert(U.shot(game,out..'/sevii-trainer-challenge.png'));Q.tap('b');Q.settle()
  assert(game.stack:top()==game.overworld,'cancel releases conversation')
  local started,battle=T.start(game,other.id);assert(started)
  local safe,reason=require('src.battle.BattleSafety').inspect(game,battle)
  assert(not safe and reason=='battle_origin_unsupported','native checkpoint guard protects custom completion')
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  U.teleport(game,other.map,other.x,other.y+1,'up');Q.settle()
  assert(not T.record(other.id).won,'discarded battle has no victory')
  assert(T.start(game,other.id),'loading a save clears abandoned battle lock')
  print('SEVII_TRAINER_PROFILES_PASS',checked,'slots across Gen1-4, no unsupported move placeholders, deferred reward, profile change, reload, cancel, checkpoint guard, abandoned battle reload')
  love.event.quit()
end
