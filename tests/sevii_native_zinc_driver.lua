return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant
  local S=assert(K.seviiExpedition)
  local P=assert(S.population)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  game.save.money=90000
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  S.install(game);K.generationRules.resolve(game)
  local mon=game.save.party[1]
  mon.statExp=mon.statExp or{};mon.statExp.special=0
  local shop
  for _,row in ipairs(P.recoveryShops)do if row.id=='MOVE_TRAINING'then shop=row end end
  assert(shop and K.seviiZinc.supports(game),'native Zinc owner available')
  assert((function()for _,id in ipairs(P.recoveryStock(game,shop.id))do if id=='ZINC'then return true end end end)(),
    'Seven Island shop offers usable Zinc')
  local landing
  for _,links in pairs(S.links)do for _,w in ipairs(links)do
    if w.map==shop.map then landing={w.toX,w.toY,w.facing};break end
  end;if landing then break end end
  landing=landing or{shop.x,shop.y+1,'up'}
  U.teleport(game,shop.map,landing[1],landing[2],landing[3]);Q.settle()
  Q.faceObject(shop.x,shop.y);Q.tap('a');U.wait(8)
  local function menu()
    for _=1,1800 do local t=game.stack:top()
      if t.items then return t end
      if t.isTextBox or t.pages then Q.tap('a')else U.wait(1)end
    end;error('Zinc menu missing')
  end
  local function choose(match)
    local t=menu();local wanted
    for i,row in ipairs(t.items)do if match(row)then wanted=i;break end end
    assert(wanted,'Zinc menu row missing')
    for _=1,100 do if t.index==wanted then Q.tap('a');return end
      Q.tap(t.index>wanted and'up'or'down')end
    error('Zinc menu stuck')
  end
  choose(function(row)return row.label=='BUY'end)
  choose(function(row)return row.value=='ZINC'end)
  assert(game.stack:top().qty==1,'native quantity picker')
  Q.tap('a') -- current native price text then YES/NO
  local money=game.save.money
  Q.answerChoice(true);Q.settle()
  assert(game.save.inventory.ZINC==1 and game.save.money==money-game.data.items.ZINC.price,
    'actual Zinc purchase and price')
  local before=assert(K.backendSplitSpecial67.preview(game,mon))
  local function useFromBag(id)
    game.stack:push(require('src.ui.BagMenu').new(game));U.wait(10)
    local found=false
    for _=1,8 do
      local t=game.stack:top()
      for _,row in ipairs(t.items or{})do if row.value==id then found=true end end
      if found then break end;Q.tap('right')
    end
    assert(found,'Bag item missing '..id)
    choose(function(row)return row.value==id end);U.wait(5)
    local top=game.stack:top()
    if top.items then choose(function(row)return row.value=='use'or row.label=='USE'end)
    elseif top.labels then Q.tap('a')end
    U.wait(10);assert(game.stack:top().pickOnly,'native party picker '..id)
    Q.tap('a')
    for _=1,1800 do local t=game.stack:top()
      if t==game.overworld then Q.settle();return end
      if t.isTextBox or t.pages then Q.tap('a')else Q.tap('b')end
    end
    error('Bag use did not finish '..id)
  end
  useFromBag('ZINC')
  assert((game.save.inventory.ZINC or 0)==0 and mon.statExp.special==0
    and mon.statExp.specialDefense==2560,'native Zinc consumed once and separate training saved')
  local after=assert(K.backendSplitSpecial67.preview(game,mon))
  assert(after.specialAttack==before.specialAttack and after.specialDefense>before.specialDefense,
    'status projection raises only Special Defense')
  game.save.inventory.CALCIUM=1
  useFromBag('CALCIUM')
  local calcium=assert(K.backendSplitSpecial67.preview(game,mon))
  print('ZINC_CALCIUM_NATIVE_VALUES',mon.statExp.special,mon.statExp.specialDefense,
    calcium.specialAttack,calcium.specialDefense)
  assert(game.save.inventory.CALCIUM==nil or game.save.inventory.CALCIUM==0,
    'native Calcium consumed')
  assert(mon.statExp.special==2560 and mon.statExp.specialDefense==5120,
    'native Calcium carries shared training into separate Defense track')
  assert(calcium.specialAttack>after.specialAttack and calcium.specialDefense>after.specialDefense,
    'Calcium raises both Gen3 special stats after Zinc')
  local genetics=assert(K.daycare.breedingIVs)
  local packet=assert(genetics.reserve(game,'BLASTOISE',mon,mon,function(lo)return lo end))
  local bred=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)
  assert(genetics.attach(game,bred,{ivs=packet.ivs,breedingIVs67=packet.receipt})
    and genetics.apply(game,bred,3),'authentic breeding receipt and stat projection')
  game.save.party[2]=bred
  local bredAttack,bredDefense=bred.stats.specialAttack,bred.stats.specialDefense
  assert(K.seviiZinc.use{data=game.data,save=game.save,target=bred}=='consumed',
    'Zinc applies to an actual bred party member')
  assert(bred.stats.specialAttack==bredAttack and bred.stats.specialDefense>bredDefense,
    'bred Special Defense refreshes without changing Special Attack')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  mon=game.save.party[1]
  assert(mon.statExp.specialDefense==5120 and mon.statExp.special==2560
    and(game.save.inventory.ZINC or 0)==0,
    'separate training and consumption survive load')
  local saved=assert(K.backendSplitSpecial67.preview(game,mon))
  assert(saved.specialAttack==calcium.specialAttack and saved.specialDefense==calcium.specialDefense,
    'loaded status projection is identical')
  local loadedBred=game.save.party[2]
  assert(genetics.valid(game,loadedBred)and loadedBred.stats.specialAttack==bredAttack
    and loadedBred.stats.specialDefense==bred.stats.specialDefense,
    'bred separate stats and receipt survive load')
  local oak,reason=K.legacyOakFinale.normaliseMon(game.data,mon)
  assert(oak and oak.statExp.specialDefense==5120,
    'Oak Legacy trial keeps Zinc training: '..tostring(reason))
  print('SEVII_NATIVE_ZINC_PASS','purchase, Zinc and Calcium Bag use, bred stats, Oak trial, save/load')
  love.event.quit()
end
