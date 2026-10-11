return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition)
  local P=assert(S.population)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  game.save.money=90000
  game.save.inventory.ULTRA_BALL=3
  S.install(game)
  local shop=P.shops[1]
  U.teleport(game,shop.map,5,6,'up');Q.settle()
  Q.faceObject(shop.x,shop.y);Q.tap('a');U.wait(10)
  local menu=Q.menuReady()
  assert(menu.items and not menu.kind,'first island clerk must open the mart menu')
  local labels={};for _,row in ipairs(menu.items)do labels[row.label]=true end
  assert(labels.BUY and labels.SELL,'first island clerk has BUY and SELL')
  assert(U.shot(game,out..'/shop-menu.png'))
  Q.choose(function(row)return row.label=='SELL'end);U.wait(10)
  local selling=Q.menuReady()
  print('SEVII_SELL_UI',tostring(selling.kind),tostring(selling.title),
    tostring(selling.screenId),tostring(selling.dialogue),#(selling.items or{}))
  for i,row in ipairs(selling.items or{})do print('SEVII_SELL_ROW',i,row.label,row.value)end
  assert(U.shot(game,out..'/shop-sell.png'))
  assert(selling.items and selling.dialogue and type(selling.money)=='function'
      and not selling.__vascOrasBagPresentation,
    'SELL must open the mart item list, not the field Bag')
  Q.settle()
  U.teleport(game,shop.map,1,3,'up');Q.settle()
  for _=1,30 do U.hold(game,'up',1)end
  assert(game.overworld.player.cellY==3,'house PC cabinet can be walked through')
  local pc=P.pcs[1]
  U.teleport(game,pc.map,7,8,'up');Q.settle()
  assert(not game.overworld.map:isWalkableCell(pc.x,pc.y),
    'One Island Center PC is still walkable')
  U.teleport(game,pc.map,pc.x,pc.y+1,'up');Q.settle()
  local function upvalue(fn,name,seen)
    if type(fn)~='function'then return end
    seen=seen or{};if seen[fn]then return end;seen[fn]=true
    for i=1,200 do
      local key,value=debug.getupvalue(fn,i);if not key then break end
      if key==name then return value end
    end
    for i=1,200 do
      local key,value=debug.getupvalue(fn,i);if not key then break end
      local found=upvalue(value,name,seen);if found then return found end
    end
  end
  local voxel=game.mods.exports.VOXEL_ASCENDANT
  local V=assert(upvalue(voxel.lib.require('VoxelScene').render,'V'))
  local hold=V.require('WorldSceneHold')
  for _=1,1800 do
    if not hold.loading(game.overworld)then break end
    U.wait(1)
  end
  assert(not hold.loading(game.overworld),'Center scene failed to become playable')
  U.wait(15)
  Q.tap('a');U.wait(10)
  for _=1,30 do
    local top=game.stack:top()
    if top.items then break end
    assert(top.isTextBox or top.pages,'Center PC left the interaction flow')
    Q.tap('a')
  end
  assert(game.stack:top().items,'Center terminal no longer opens storage')
  Q.settle()
  for island=2,#P.pcs do
    local other=P.pcs[island]
    U.teleport(game,other.map,7,8,'up');Q.settle()
    assert(other.x==8 and not game.overworld.map:isWalkableCell(other.x,other.y),
      'Island '..island..' Center PC is not aligned with its cabinet')
    U.teleport(game,other.map,other.x,other.y+1,'up');Q.settle()
    for _=1,1800 do if not hold.loading(game.overworld)then break end;U.wait(1)end
    assert(not hold.loading(game.overworld),
      'Island '..island..' Center scene failed to become playable')
    U.wait(15)
    Q.tap('a');U.wait(10)
    for _=1,30 do
      local top=game.stack:top()
      if top.items then break end
      assert(top.isTextBox or top.pages,
        'Island '..island..' PC left the interaction flow: '..tostring(top.screenId))
      Q.tap('a')
    end
    assert(game.stack:top().items,
      'Island '..island..' Center terminal no longer opens storage')
    Q.settle()
  end
  local camera=require('src.render.Pipelines')
  camera.setLevel('voxel',5)
  U.teleport(game,shop.map,5,6,'down');Q.settle()
  for _=1,1800 do if not hold.loading(game.overworld)then break end;U.wait(1)end
  assert(camera.level('voxel')==5,'Sevii map change reset the chosen Voxel camera')
  U.teleport(game,pc.map,7,8,'down');Q.settle()
  for _=1,1800 do if not hold.loading(game.overworld)then break end;U.wait(1)end
  assert(camera.level('voxel')==5,'Center map change reset the chosen Voxel camera')
  print('SEVII_SERVICES_PASS','shop buy/sell','house PC collision',
    'Center PC access','camera persistence')
  love.event.quit()
end
