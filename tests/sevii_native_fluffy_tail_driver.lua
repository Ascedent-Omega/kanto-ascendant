return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;game.save.money=90000
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',5)}
 assert(K.beyondKanto.activate(game,{decision='qa-fluffy-tail'}))
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
 S.install(game);K.generationRules.resolve(game)
 local function choose(match)
  for _=1,1800 do if game.stack:top().items then Q.choose(match);return end;Q.tap('a')end
  error('native menu missing')
 end
 local shop=S.population.recoveryShops[2]
 U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle();Q.tap('a')
 choose(function(r)return r.label=='BUY'end);choose(function(r)return r.value=='FLUFFY_TAIL'end)
 Q.tap('up');assert(game.stack:top().qty==2);Q.tap('a');local money=game.save.money;Q.answerChoice(true);Q.settle()
 assert(game.save.inventory.FLUFFY_TAIL==2 and game.save.money==money-2*game.data.items.FLUFFY_TAIL.price,'two native purchases')
 Q.bag('FLUFFY_TAIL');Q.settle();assert(game.save.inventory.FLUFFY_TAIL==2,'field refusal retains item')
 local function settleBattle(b)
  for _=1,2400 do local t=game.stack:top()
   if t==b and b.phase=='menu'then return end
   if t.items or t.party and t~=b then Q.tap('b')else Q.tap('a')end
  end
  error('native battle menu missing')
 end
 local function use(b)
  assert(b:chooseMenu('item'));U.wait(12);local found=false
  for _=1,8 do
   for _,r in ipairs(game.stack:top().items or{})do if r.value=='FLUFFY_TAIL'then found=true;break end end
   if found then choose(function(r)return r.value=='FLUFFY_TAIL'end);break end;Q.tap('right')
  end
  assert(found);U.wait(10)
  if game.stack:top().items then choose(function(r)return r.value=='use'or r.label=='USE'end)end
 end
 local records={}
 for attempt=1,2 do
  U.teleport(game,S.harbors[7],8,5,'down');Q.settle()
  local b=require('src.battle.BattleState').newWild(game,'JOLTEON',80,{randomizerProtected=true})
  b.onFinish=function(result)records[#records+1]={result=result,hp=game.save.party[1].hp};game.overworld:afterBattle(result,b)end
  game.overworld:pushBattle(b);settleBattle(b)
  local count=game.save.inventory.FLUFFY_TAIL;local hp=game.save.party[1].hp
  if attempt==1 then
   b.kaRocketNoEscape=true;use(b);settleBattle(b)
   assert(not b.result and game.save.inventory.FLUFFY_TAIL==count,'live raid lock refuses without consumption')
   b.kaRocketNoEscape=nil;b.kaMythicEcho='JOLTEON';use(b);settleBattle(b)
   assert(not b.result and game.save.inventory.FLUFFY_TAIL==count,'live echo lock refuses without consumption')
   b.kaMythicEcho=nil
  end
  use(b)
  for _=1,2400 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  Q.settle();assert(records[attempt].result=='run'and game.save.party[1].hp==hp,'actual escape without enemy turn')
  assert((game.save.inventory.FLUFFY_TAIL or 0)==count-1,'exactly one toy consumed')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert((game.save.inventory.FLUFFY_TAIL or 0)==count-1,'consumption retained on reload')
 end
 local f=assert(io.open(out..'/fluffy-tail.json','wb'));f:write(require('src.link.Json').encode({passed=true,purchased=2,escapes=records,fieldRejected=true,raidRejected=true,echoRejected=true,
  scope='Native shop purchase, Bag field refusal, two actual wild escapes and save/load; raid/echo restrictions exercised through Bag with explicit lock fixtures. Post-League, travel, team and opponent are QA fixtures, not played raid/echo quests.'}));f:close()
 print('SEVII_NATIVE_FLUFFY_TAIL_PASS');love.event.quit()
end
