-- Isolated roster difficulty probe: full enemy HP, native AI/RNG/damage,
-- legal pre-League Kanto move access, six ordinary Pokemon, no combat items.
-- Travel and a fresh healed team per match are explicit fixtures.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T=S.trainers
 local Pokemon=require('src.pokemon.Pokemon');local Pilot=dofile(root..'/tests/sevii_battle_pilot.lua')(game,Q)
 local seed=tonumber(os.getenv('SEVII_BALANCE_SEED')or'90228')
 love.math.setRandomSeed(seed) -- reproducible uniform sequence, never forced outcomes
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game.save.options.battleStyle='set';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 assert(K.beyondKanto.activate(game,{decision='qa-roster-balance'}))
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
 K.generationRules.resolve(game);S.install(game)
 local roster={
  {'CHARIZARD',{'FLAMETHROWER','FLY','SLASH','FIRE_BLAST'}},
  {'LAPRAS',{'SURF','ICE_BEAM','BODY_SLAM','THUNDERBOLT'}},
  {'JOLTEON',{'THUNDERBOLT','PIN_MISSILE','DOUBLE_KICK','QUICK_ATTACK'}},
  {'NIDOKING',{'EARTHQUAKE','ROCK_SLIDE','SURF','STRENGTH'}},
  {'SNORLAX',{'BODY_SLAM','HYPER_BEAM','SURF','REST'}},
  {'EXEGGUTOR',{'PSYCHIC_M','MEGA_DRAIN','STOMP','SLEEP_POWDER'}},
 }
 local function fresh(level)
  local party={}
  for _,row in ipairs(roster)do
   local mon=Pokemon.new(game.data,row[1],level);mon.moves={}
   for _,id in ipairs(row[2])do
    local move=assert(game.data.moves[id],'ordinary native move '..id)
    assert(K.generationRules.monMoveAvailable(game,mon,id,4,true),'move profile '..id)
    mon.moves[#mon.moves+1]={id=id,pp=move.pp}
   end
   party[#party+1]=mon
  end
  game.save.party=party
 end
 local report={seed=seed,profile=4,rows={},roster=roster,
  scope='Native full-HP opponents and ordinary RNG; six fresh ordinary Kanto Pokemon per match with default training and full PP, no held items or combat medicine. Fixed seed reproduces uniform RNG, not fixed favorable outcomes. Travel, unlocks and between-match restoration are fixtures. Simple damage/type player policy; no forced damage, enemy HP edits or guaranteed wins.'}
 local function write()
  local f=assert(io.open(out..'/trainer-balance-'..seed..'.json','wb'))
  f:write(require('src.link.Json').encode(report));f:close()
 end
 local towerBlocked=false
 for _,row in ipairs(T.allRows)do
  if not(row.group=='tower'and towerBlocked)then
   local level=row.group=='tower'and 75 or 62;fresh(level)
   U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle()
   local ok,b=T.start(game,row.id);assert(ok,b)
   local entry={id=row.id,group=row.group or'island',playerLevel=level,enemies={}}
   for _,m in ipairs(b.enemyParty)do
    assert(m.hp==m.stats.hp,'full opponent HP')
    entry.enemies[#entry.enemies+1]={species=m.species,level=m.level,hp=m.hp,moves=m.moves}
   end
   local finish=b.onFinish
   b.onFinish=function(result)
    entry.result=result;entry.party={};entry.fainted=0
    for _,m in ipairs(game.save.party)do
     entry.party[#entry.party+1]={species=m.species,hp=m.hp,maxHp=m.stats.hp,level=m.level,status=m.status}
     if m.hp==0 then entry.fainted=entry.fainted+1 end
    end
    return finish(result)
   end
   entry.decisions=Pilot.run(b);assert(entry.result=='win'or entry.result=='lose','terminal native combat result')
   report.rows[#report.rows+1]=entry
   if row.group=='tower'and entry.result~='win'then towerBlocked=true end
   write();print('SEVII_BALANCE_RESULT',row.id,entry.result,entry.decisions,entry.fainted)
  end
 end
 report.attempted=#report.rows;report.completedAll=#report.rows==#T.allRows
 report.wins=0;for _,r in ipairs(report.rows)do if r.result=='win'then report.wins=report.wins+1 end end
 report.finished=true;write();print('SEVII_BALANCE_PROBE_FINISHED',report.attempted,report.wins)
 love.event.quit()
end
