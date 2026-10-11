-- Matched native PP Max owner regression. Purchases have a separate full proof.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'));local U=require('tests.drivers.util')
 local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true;game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 assert(K.beyondKanto.activate(game,{decision='qa-pp-max-owner'}))
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}});S.install(game);K.generationRules.resolve(game)
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)
 mon.moves={{id='TACKLE',pp=3},{id='WITHDRAW',pp=2,ppUps=1}};game.save.party={mon};game.save.inventory.PP_MAX=2
 U.teleport(game,S.harbors[1],8,5,'down');Q.settle()
 local function open()
  game.stack:push(require('src.ui.BagMenu').new(game));U.wait(10)
  local found=false
  for _=1,8 do
   local t=game.stack:top()
   for _,row in ipairs(t.items or{})do if row.value=='PP_MAX'then found=true end end
   if found then Q.choose(function(row)return row.value=='PP_MAX'end);break end
   Q.tap('right')
  end
  assert(found,'native Bag has fixture PP Max');U.wait(10)
  local t=game.stack:top()
  if t.items then Q.choose(function(row)return row.value=='use'or row.label=='USE'end)elseif t.labels then Q.tap('a')end
  U.wait(10);assert(game.stack:top().pickOnly,'native party picker');Q.tap('a')
  for _=1,1800 do local top=game.stack:top();if top.mon==mon and top.prompt and top.ready then return top end;U.wait(1)end
  error('native PP Max move menu did not become ready')
 end
 local function close()
  for _=1,240 do
   local t=game.stack:top()
   if t==game.overworld then Q.settle();return true end
   if t.isTextBox then Q.tap('a')else Q.tap('b')end
  end
  return false
 end
 open();Q.tap('b');assert(close()and game.save.inventory.PP_MAX==2 and not mon.moves[1].ppUps,'native cancel preserves item/moves')
 open();Q.tap('down');Q.tap('a');local returned=close();local top=game.stack:top()
 local before=os.getenv('SEVII_PP_MAX_EXPECT_BEFORE')=='1'
 assert(mon.moves[2].ppUps==3 and game.save.inventory.PP_MAX==1 and mon.moves[1].pp==3,'chosen move and one native consumption')
 assert(U.shot(game,out..'/pp-max-after-application.png'))
 local d={before=before,returned=returned,held=top.held==true,ready=top.ready==true,ownerPresent=top.owner~=nil,chosenMovePpUps=mon.moves[2].ppUps,itemCount=game.save.inventory.PP_MAX,x=8,y=5,cancelPreserves=true,
  scope='Same native Bag, target and selected move; champion/unlocks, initial harbor, team/moves and two PP Max items are fixtures. No forced stack pop or result handling.'}
 if before then
  assert(not returned and top.mon==mon and top.held and not top.ready and top.owner==nil,'original PP Max held menu softlock reproduced')
  print('SEVII_PP_MAX_OWNER_BEFORE_REPRODUCED')
 else
  assert(returned,'native successful use returns to world')
  open();Q.tap('down');Q.tap('a');assert(close()and game.save.inventory.PP_MAX==1,'maxed move refusal returns without consumption')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(game.save.party[1].moves[2].ppUps==3 and game.save.inventory.PP_MAX==1,'PP Max use/refusal state reload')
  d.maxedRefusal=true;d.saved=true;print('SEVII_PP_MAX_OWNER_NATIVE_PASS')
 end
 local f=assert(io.open(out..'/pp-max-owner.json','wb'));f:write(require('src.link.Json').encode(d));f:close();love.event.quit()
end
