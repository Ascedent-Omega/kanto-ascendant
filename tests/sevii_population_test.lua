package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
local J=require('src.link.Json')
local f=assert(io.open('assets/sevii_local/bundle.json','rb'));local bundle=J.decode(f:read('*a'));f:close()
local function clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
local stored={stage=3,chapterOneComplete=true,samples={heat=true,drift=true}}
local S={maps={},links={}}
local tiles={};for _,row in ipairs(bundle.tilesets)do tiles[row.id]=row end
for _,row in ipairs(bundle.maps)do S.maps[row.id]=row end
function S.location(source,x,y)
  for id,m in pairs(S.maps)do local o,z=m.kaSeviiSourceOrigin,m.kaSeviiSourceSize
    if m.kaSeviiSource==source and x>=o[1]and y>=o[2]and x<o[1]+z[1]and y<o[2]+z[2]then return id,x-o[1],y-o[2]end
  end
end
function S.walkable(id,x,y)
  local m=S.maps[id];if not m or x<0 or y<0 or x>=m.width*2 or y>=m.height*2 then return false end
  local k=tiles[m.tileset].sourceCellCollision[m.blocks[math.floor(y/2)*m.width+math.floor(x/2)+1]+1][y%2*2+x%2+1]
  return k=='FLOOR'or k=='GRASS'
end
function S.state()return clone(stored)end
function S.persist(s)stored=clone(s)end
function S.unlocked(g)return g.save.flags.EVENT_BEAT_CHAMPION_RIVAL==true end
local game={save={flags={}},overworld={map={id='VERMILION_CITY'},player={cellX=0,cellY=0}}}

local epoch=3;local said
S.chapters={journal=function()return 'journal' end}
local sprites=dofile(assert(os.getenv('KASC_ENGINE'))..'/data/generated/sprites.lua')
local ui={talks={},tr=function(en)return en end,box=function(_,text,done)said=text;if done then done()end end,
 epoch=function()return epoch end,npc=function(map,name,sprite,text,x,y)
  assert(S.walkable(map,x,y),'population NPC floor');assert(sprites[sprite],'native NPC sprite '..sprite)
  table.insert(S.maps[map].objects,{name=name,x=x,y=y})
 end}
local P=dofile('sevii_population.lua')(S,ui)
for island,pc in ipairs(P.pcs)do
  assert(pc.x==(island==1 and 10 or 8)and pc.y==6,
    'island '..island..' PC must guard the visible console')
  assert(ui.talks[pc.name]==nil,'Center PC must not add a duplicate object')
end
game.data={items=dofile(assert(os.getenv('KASC_ENGINE'))..'/data/generated/items.lua')}
game.data.items.CLEANSE_TAG={name='Cleanse Tag',price=200}
game.save.inventory={};game.save.money=9000
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function withFullBag(item,callback)
 local Bag=require('src.inventory.Bag')
 local inventory,order,stacks=game.save.inventory,game.save.bagOrder,game.save.inventoryStacks
 local pocket=Bag.pocketOf(item,game.data)
 game.save.inventory={[item]=99};game.save.bagOrder=nil;game.save.inventoryStacks=nil
 for i=1,Bag.capacity(game.data,pocket)-1 do
  local id='QA_FULL_'..i;game.data.items[id]={pocket=pocket}
  game.save.inventory[id]=1
 end
 callback()
 game.save.inventory,game.save.bagOrder,game.save.inventoryStacks=inventory,order,stacks
end
local function place(p)game.overworld.map.id=p.map;game.overworld.player.cellX=p.x;game.overworld.player.cellY=p.y+1 end
place(P.quartermaster);check(not P.claim(game,'SURVEY'),'League gate')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;stored.chapterOneComplete=false
local pcOpens=0;game.overworld.openPC=function()pcOpens=pcOpens+1 end
place(P.pcs[2]);check(P.openPCAt(game,P.pcs[2].map,8,6)and pcOpens==1,
  'aligned Center cabinet opens the PC from the aisle')
check(not P.openPCAt(game,P.pcs[2].map,10,6),
  'obsolete offset cannot open an invisible second PC')
place(P.quartermaster)
check(not P.claim(game,'SURVEY'),'chapter gate');stored.chapterOneComplete=true
check(#P.pending()==1,'available unclaimed milestone')
place(P.shops[1]);check(not P.claim(game,'SURVEY'),'remote claim rejected');place(P.quartermaster)
withFullBag('ULTRA_BALL',function()
 check(not P.claim(game,'SURVEY')and #P.pending()==1,'full bag preserves entire reward')
end)
game.save.inventory.ULTRA_BALL=0;check(P.claim(game,'SURVEY'),'claim after room made')
check(game.save.inventory.ULTRA_BALL==5 and #P.pending()==0,'correct quantity and receipt')
check(not P.claim(game,'SURVEY')and game.save.inventory.ULTRA_BALL==5,'no duplicate supply')
stored=J.decode(J.encode(stored));check(not P.claim(game,'SURVEY'),'receipt survives serialization')
stored.chapterThreeComplete=true;stored.chapterFiveComplete=true;stored.expeditionComplete=true
check(#P.pending()==4,'later milestone packages include the forest keepsake')
for _,r in ipairs(P.pending())do check(P.claim(game,r.id),'claim '..r.id)end
check(#P.pending()==0 and game.save.inventory.RARE_CANDY==3
  and game.save.inventory.CLEANSE_TAG==1,'all supplies and the Cleanse Tag collected')
check(#P.stock(game)==6,'six native supply types')
local price=game.data.items.ULTRA_BALL.price;game.data.items.ULTRA_BALL.price=0
check(#P.stock(game)==5,'no accidental zero-price gift');game.data.items.ULTRA_BALL.price=price
local list={BERRY=2,ORAN_BERRY=3,LIECHI_BERRY=3}
for id,gen in pairs(list)do game.data.items[id]={name=id,price=80,kascConsumableBerry67=true,kascEquipmentRewardEpochs={[gen]=true,[3]=true}}end
check(#P.berryStock(game,'JOHTO_BERRIES')==1 and #P.berryStock(game,'HOENN_BERRIES')==2,'only registered working berries offered')
epoch=2;check(#P.berryStock(game,'HOENN_BERRIES')==0,'Gen3 berries respect explicit Gen2 profile')
epoch=1;check(#P.berryStock(game,'JOHTO_BERRIES')==0,'Gen2 berries respect classic profile')
epoch=3;game.data.items.LIECHI_BERRY.kascEquipmentRewardEpochs[3]=false
check(#P.berryStock(game,'HOENN_BERRIES')==1,'absent effect readiness not sold')
for _,p in ipairs(P.residents)do
 stored.seviiRiftSealed=false;stored.chapterThreeComplete=false;ui.talks[p.name](game,game.overworld,nil);local before=said
 stored.seviiRiftSealed=true;ui.talks[p.name](game,game.overworld,nil)
 check(before~=said,'resident has a real aftermath '..p.id)
end
game.data.balls={FRIEND_BALL={attempt=function()end}};game.data.item_effects={QA={use=function()end}}
game.data.items.FRIEND_BALL={price=1000,ball='FRIEND_BALL',effect='QA'}
check(#P.apricornStock(game)==1,'only functional registered balls offered')
epoch=1;check(#P.apricornStock(game)==0,'Apricorn profile gate');epoch=3
game.data.item_effects.QA.use=nil;check(#P.apricornStock(game)==0,'missing real ball effect excluded')
for _,p in ipairs(P.finds)do
 game.data.items[p.item]={name=p.item,price=1000}
 if ({COLLECTOR_BELT=true,RUBBING_ICE=true,
     RESORT_GLASSES=true,STUDENT_SPOON=true})[p.id]then
  game.data.items[p.item].kascEquipmentRewardEpochs={[3]=true,[4]=true}
 end
 place(P.shops[1]);check(not P.claimFind(game,p.id),'remote find refused')
 place(p);game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=false
 check(not P.claimFind(game,p.id),'pre-League find refused');game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 if game.data.items[p.item].kascEquipmentRewardEpochs then
  epoch=1;check(not P.claimFind(game,p.id),'inactive type item remains for later')
  epoch=3
 end
 if p.id=='WAREHOUSE_COIN'then
  stored.chapterFourComplete=false
  check(not P.claimFind(game,p.id),'warehouse coin requires station chapter')
  stored.chapterFourComplete=true
 end
 withFullBag(p.item,function()
  check(not P.claimFind(game,p.id)and not((S.state().population or{}).finds or{})[p.id],'full bag preserves find')
 end)
 game.save.inventory[p.item]=nil;check(P.claimFind(game,p.id),'find can be collected later')
 game.save.inventory[p.item]=nil;stored=J.decode(J.encode(stored))
 check(not P.claimFind(game,p.id),'selling and reload do not reset find')
end
check(#P.medicineShops==3,'three medicine businesses')
game.data.items.MOOMOO_MILK={price=500,kascSeviiMedicine='kasc.sevii-medicine/v1',effect='MEDICINE_QA'}
game.data.item_effects.MEDICINE_QA={kascSeviiMedicine='kasc.sevii-medicine/v1',use=function()end}
check(#P.medicineStock(game,'DAIRY')==1,'medicine with a real effect offered')
epoch=1;check(#P.medicineStock(game,'DAIRY')==0,'classic profile medicine gate');epoch=3
game.data.item_effects.MEDICINE_QA.use=nil
check(#P.medicineStock(game,'DAIRY')==0,'inert medicine cannot be sold')
game.data.items.PRISM_SCALE={price=2100,needsTarget=true,effect='KA_BACKEND_EVOLUTION_PRISM_SCALE'}
game.data.item_effects.KA_BACKEND_EVOLUTION_PRISM_SCALE={use=function()end}
check(#P.evolutionStock(game)==1,'canonical backend adapter accepted for existing Hoenn item')
ui.beyondActive=function()return false end
check(#P.evolutionStock(game)==0,'sealed save cannot buy unusable evolution supplies')
ui.beyondActive=function()return true end;epoch=2
check(#P.evolutionStock(game)==0,'Hoenn evolution supplies respect generation profile');epoch=3
game.data.items.PRISM_SCALE.effect='FOREIGN'
game.data.item_effects.FOREIGN={use=function()end}
check(#P.evolutionStock(game)==0,'unreviewed effect owner not sold')
game.data.items.NET_BALL={price=1000,kascSeviiBall='kasc.sevii-balls/v1',ball='NET_BALL',effect='NET_QA'}
game.data.balls.NET_BALL={attempt=function()end};game.data.item_effects.NET_QA={use=function()end}
check(#P.researchBallStock(game)==1,'research ball with actual formula offered')
epoch=2;check(#P.researchBallStock(game)==0,'Hoenn research ball profile gate');epoch=3
game.data.balls.NET_BALL.attempt=nil
check(#P.researchBallStock(game)==0,'inert research ball cannot be sold')
game.data.items.PREMIER_BALL={price=200,kascSeviiBall='kasc.sevii-balls/v1',ball='PREMIER_BALL',effect='PREMIER_QA'}
game.data.balls.PREMIER_BALL={attempt=function()end};game.data.item_effects.PREMIER_QA={use=function()end}
check(P.researchBallStock(game)[1]=='PREMIER_BALL','neutral ball offered with functional owner')
epoch=2;check(#P.researchBallStock(game)==0,'Premier not sold under Gen2 rules');epoch=3
game.data.items.PREMIER_BALL.price=0;check(#P.researchBallStock(game)==0,'Premier cannot become a free purchase')
game.data.items.DIVE_BALL={price=1000,kascSeviiBall='kasc.sevii-balls/v1',ball='DIVE_BALL',effect='DIVE_QA'}
game.data.balls.DIVE_BALL={attempt=function()end};game.data.item_effects.DIVE_QA={use=function()end}
check(P.researchBallStock(game)[1]=='DIVE_BALL','Dive Ball sold only with native formula and preflight')
game.data.item_effects.DIVE_QA.use=nil;check(#P.researchBallStock(game)==0,'inert Dive Ball excluded')
check(#P.recoveryShops==2,'two recovery businesses')
game.data.items.PP_MAX={price=10000,kascSeviiRecovery='kasc.sevii-recovery/v1',effect='RECOVERY_QA'}
game.data.item_effects.RECOVERY_QA={kascSeviiRecovery='kasc.sevii-recovery/v1',use=function()end}
check(#P.recoveryStock(game,'MOVE_TRAINING')==1,'real PP Max effect offered')
epoch=2;check(#P.recoveryStock(game,'MOVE_TRAINING')==0,'recovery shop profile gate');epoch=3
game.data.item_effects.RECOVERY_QA.use=nil;check(#P.recoveryStock(game,'MOVE_TRAINING')==0,'inert recovery item not sold')
local heals=0
package.loaded['src.pokemon.Pokemon']={heal=function(mon)heals=heals+1;mon.hp=mon.stats.hp end}
game.save.party={{hp=1,stats={hp=20}}};place(P.spa)
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=false;check(not P.rest(game)and heals==0,'spa requires League completion')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(P.rest(game)and heals==1 and game.save.party[1].hp==20,'spa delegates to existing healing owner')
place(P.quartermaster);check(not P.rest(game)and heals==1,'spa requires physical adjacency')
local opened,title=0
ui.daycare={openNursery=function(_,_,name)opened=opened+1;title=name;return true end}
place(P.nursery);game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=false
ui.talks[P.nursery.name](game,nil,nil,function()end);check(opened==0,'island pension pre-League gate')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
ui.talks[P.nursery.name](game,nil,nil,function()end)
check(opened==1 and title=='FOUR ISLAND DAY-CARE','existing pension opened with local heading')
ui.daycare.openNursery=function()return false end
ui.talks[P.nursery.name](game,nil,nil,function()end)
check(said:find('disabled',1,true),'disabled old owner is reported, never replaced by another nursery')
print('PASS population: '..checks..' checks; '..#P.residents..' residents, '..#P.shops..' supply shops, '..#P.berryShops..' berry shops, '..#P.medicineShops..' medicine shops, '..#P.pcs..' PCs')
