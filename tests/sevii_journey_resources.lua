-- QA journey policy: no post-start stock/stat edits, ordinary encounters and
-- battle RNG. Rest only by walking to the island's actual Pokemon Center.
return function(game,S,Q,N)
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local Pilot=dofile(root..'/tests/sevii_battle_pilot.lua')(game,Q)
 local Pokemon=require('src.pokemon.Pokemon');local Json=require('src.link.Json')
 local R={rows={},rests={},seen={},seed=tonumber(os.getenv('SEVII_JOURNEY_SEED')or'90230')}
 R.scope='Continuous seven-chapter physical journey with ordinary random encounters, native battle RNG and persistent team HP/PP/status/experience. Only initial champion, Orania, six level-62 Kanto Pokemon and inventory are fixtures. Visible overworld Pokemon are disabled. Fight new species while healthy, flee repeats or when weakened; rest through actual island Center dialogue on each arrival. No injected healing, item replenishment, HP edits, guaranteed escape or quest receipts after setup. Optional trainers and species acquisition are separate tests.'
 local function party()
  local result={}
  for _,m in ipairs(game.save.party)do
   local moves={};for _,v in ipairs(m.moves)do moves[#moves+1]={id=v.id,pp=v.pp}end
   result[#result+1]={species=m.species,level=m.level,hp=m.hp,maxHp=m.stats.hp,status=m.status,moves=moves}
  end
  return result
 end
 function R.snapshot()return{seed=R.seed,battles=R.rows,rests=R.rests,party=party(),money=game.save.money,inventory=game.save.inventory,scope=R.scope}end
 local function write()
  local f=assert(io.open(out..'/journey-resources-'..R.seed..'.json','wb'));f:write(Json.encode(R.snapshot()));f:close()
 end
 function R.prepare()
  love.math.setRandomSeed(R.seed)
  game.save.options.battleStyle='set';game.save.money=10000
  local roster={
   {'BLASTOISE',{'SURF','STRENGTH','BITE','ICE_BEAM'}},
   {'CHARIZARD',{'FLAMETHROWER','FLY','SLASH','FIRE_BLAST'}},
   {'JOLTEON',{'THUNDERBOLT','PIN_MISSILE','DOUBLE_KICK','QUICK_ATTACK'}},
   {'NIDOKING',{'EARTHQUAKE','ROCK_SLIDE','SURF','STRENGTH'}},
   {'SNORLAX',{'BODY_SLAM','HYPER_BEAM','SURF','REST'}},
   {'EXEGGUTOR',{'PSYCHIC_M','MEGA_DRAIN','STOMP','SLEEP_POWDER'}},
  }
  game.save.party={}
  for _,row in ipairs(roster)do
   local m=Pokemon.new(game.data,row[1],62);m.moves={}
   for _,id in ipairs(row[2])do m.moves[#m.moves+1]={id=id,pp=assert(game.data.moves[id]).pp}end
   game.save.party[#game.save.party+1]=m
  end
  write()
 end
 function R.battle(b)
  local row={map=game.overworld.map.id,species=b.enemy.mon.species,level=b.enemy.mon.level,kind=b.kind,before=party()}
  local repeatSpecies=R.seen[row.species];R.seen[row.species]=true
  local finish=b.onFinish
  b.onFinish=function(result)
   row.result=result;row.after=party()
   if finish then return finish(result)end
  end
  row.decisions=Pilot.run(b,{choice=function(battle)
   local pp=0;for _,m in ipairs(battle.player.curMoves)do pp=pp+(m.pp or 0)end
   if battle.kind=='wild'and(repeatSpecies or battle.player.mon.hp<battle.player.mon.stats.hp*.4 or pp<5)then return'run'end
   return'fight'
  end})
  R.rows[#R.rows+1]=row;write()
  print('SEVII_RESOURCE_BATTLE',#R.rows,row.species,tostring(row.result),row.decisions)
  assert(row.result and row.result~='lose','resource journey suffered a real blackout')
 end
 function R.rest()
  local island=assert(S.maps[game.overworld.map.id]).kaSeviiIsland
  local p
  for id,m in pairs(S.maps)do if m.kaSeviiIsland==island then
   for _,o in ipairs(m.objects or{})do if o.name=='KA_SEVII_MEDIC'then p={map=id,x=o.x,y=o.y};break end end
  end end
  assert(p,'island Center nurse missing')
  N.visit(p);local before=party();Q.tap('a');Q.settle()
  for _,m in ipairs(game.save.party)do
   assert(m.hp==m.stats.hp and not m.status,'native Center restored team')
   for _,v in ipairs(m.moves)do assert(v.pp>=game.data.moves[v.id].pp,'native Center restored PP')end
  end
  R.rests[#R.rests+1]={island=island,map=p.map,before=before,after=party()};write()
  print('SEVII_RESOURCE_REST',island,#R.rows)
 end
 local sail=N.sail
 N.sail=function(island)sail(island);if island~=0 then R.rest()end end
 return R
end
