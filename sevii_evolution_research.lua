-- One field find per usable Hoenn/Sinnoh evolution item. The Six Island
-- researcher can source replacements only after that item was discovered.
-- Existing HEVO package gates remain authoritative for character paths.
return function(S, ui, opts)
  opts = opts or {}
  local R = {sites={}, fields={}}
  local tr, box = ui.tr, ui.box
  local hevo = opts.hevoPackages
  local Bag = require('src.inventory.Bag')
  local rows = {
    {id='PRISM_SCALE',gen=3,price=2100,source='SixIsland_WaterPath',x=14,y=25},
    {id='DEEP_SEA_TOOTH',gen=3,price=2100,source='SixIsland_WaterPath',x=10,y=62},
    {id='DEEP_SEA_SCALE',gen=3,price=2100,source='SixIsland_WaterPath',x=17,y=72},
    {id='PROTECTOR',gen=4,price=9800,source='SevenIsland_SevaultCanyon',x=10,y=55},
    {id='MAGMARIZER',gen=4,price=9800,source='MtEmber_RubyPath_1F',x=21,y=9},
    {id='RAZOR_FANG',gen=4,price=9800,source='SevenIsland_SevaultCanyon',x=14,y=36},
    {id='ELECTIRIZER',gen=4,price=9800,source='FiveIsland_RocketWarehouse',x=24,y=22},
    {id='RAZOR_CLAW',gen=4,price=9800,source='FourIsland_IcefallCave_1F',x=5,y=16},
    {id='DUBIOUS_DISC',gen=4,price=9800,source='FiveIsland_RocketWarehouse',x=17,y=11},
    {id='SHINY_STONE',gen=4,price=9800,source='ThreeIsland_BerryForest',x=31,y=26},
    {id='DUSK_STONE',gen=4,price=9800,source='SixIsland_DottedHole_1F',x=8,y=3},
    {id='DAWN_STONE',gen=4,price=3000,source='FourIsland_IcefallCave_1F',x=16,y=8},
    {id='REAPER_CLOTH',gen=4,price=3500,source='FiveIsland_MemorialPillar',x=14,y=20},
    {id='OVAL_STONE',gen=4,price=2000,source='FourIsland_PokemonDayCare',x=7,y=6},
    -- KASC's item adaptations for Feebas and Probopass are deliberately
    -- included. Magneton itself evolves at a magnetic FIELD, not by item.
    {id='MAGNETIC_CORE',gen=4,price=3500,source='FiveIsland_RocketWarehouse',x=25,y=24},
  }
  R.rows=rows
  local byId={};for _,row in ipairs(rows)do byId[row.id]=row end
  local function state()
    local s=S.state();s.evolutionResearch=s.evolutionResearch or{}
    s.evolutionResearch.found=s.evolutionResearch.found or{}
    return s,s.evolutionResearch.found
  end
  local function epoch(game)
    local rules=opts.generationRules
    local profile=rules and rules.peek and rules.peek(game)
    return profile and tonumber(profile.activeEpoch) or 1
  end
  local function beyond(game)
    local owner=opts.beyondKanto
    return not owner or not owner.peekIsActive or owner.peekIsActive(game)
  end
  local function legacy(game)
    return opts.legacyJourney and opts.legacyJourney.isActive(game and game.save)==true
  end
  local function near(game,site)
    local ow=game and game.overworld;local a=ow and ow.player
    return site and ow and ow.map and a and ow.map.id==site.map
      and math.abs(a.cellX-site.x)+math.abs(a.cellY-site.y)==1
  end
  local function registered(game,row)
    local d=game and game.data and game.data.items and game.data.items[row.id]
    if not d or d.keyItem then return false end
    if row.id=='OVAL_STONE'then
      local exports=game.mods and game.mods.exports and game.mods.exports.kanto_ascendant
      local h=exports and exports.wave1Happiny67
      return h and h.ready==true and d.price==2000 or false
    end
    local effect=game.data.item_effects and game.data.item_effects[d.effect]
    return d.needsTarget==true and effect and type(effect.use)=='function' or false
  end
  function R.available(game,id)
    local row=byId[id]
    if not row or not S.unlocked(game) or not registered(game,row)then return false end
    if not legacy(game)and(not beyond(game)or epoch(game)<row.gen)then return false end
    local package=hevo and hevo.byItem and hevo.byItem[id]
    if package and not hevo.unlocked(game.save,package.id)then return false end
    return true
  end
  function R.discovered(game,id)
    if legacy(game)then return true end
    local s,found=state()
    if found[id]then return true end
    if s.evolutionResearch.legacyMarine and
        (id=='PRISM_SCALE'or id=='DEEP_SEA_TOOTH'or id=='DEEP_SEA_SCALE')then return true end
    -- Before this expansion the marine items were already sold here. An old
    -- save that still carries one keeps its replacement route.
    if (id=='PRISM_SCALE'or id=='DEEP_SEA_TOOTH'or id=='DEEP_SEA_SCALE')
        and (tonumber((game.save.inventory or{})[id])or 0)>0 then return true end
    return false
  end
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y)
    assert(map and S.walkable(map,lx,ly),'blocked evolution site '..id)
    for _,n in ipairs(S.maps[map].objects)do
      assert(n.x~=lx or n.y~=ly,'occupied evolution site '..id)
    end
    for _,link in ipairs(S.links[map]or{})do
      assert(math.abs(link.x-lx)+math.abs(link.y-ly)>1,'evolution site obstructs door '..id)
    end
    local site={id=id,map=map,x=lx,y=ly,source=source}
    ui.npc(map,'KA_SEVII_EVOLUTION_'..id,sprite,'KA_SEVII_EVOLUTION_'..id,lx,ly)
    return site
  end
  function R.claim(game,id)
    local row=byId[id];local site=R.sites[id]
    if not row or not near(game,site)then return false,'not-at-find'end
    if not R.available(game,id)then return false,'locked'end
    local s,found=state()
    if found[id]then return false,'already-found'end
    if not Bag.add(game.save,id,1,game.data)then return false,'bag-full'end
    found[id]=true;S.persist(s)
    return true,id
  end
  for _,row in ipairs(rows)do
    local id=row.id
    R.sites[id]=add(id,row.source,row.x,row.y,'SPRITE_POKE_BALL')
    ui.talks['KA_SEVII_EVOLUTION_'..id]=function(game,ow,n,done)
      local ok,why=R.claim(game,id)
      if ok then
        box(game,tr('Found ','Gefunden: ')..game.data.items[id].name..tr(
          '!\nThe evolution researcher on SIX ISLAND can now source another one.',
          '!\nDer Entwicklungsforscher auf EILAND SECHS kann dir nun Nachschub besorgen.'),done)
      elseif why=='already-found'then
        box(game,tr('Only the empty case remains. Ask the researcher on SIX ISLAND for another.',
          'Nur das leere Etui ist geblieben. Frag den Forscher auf EILAND SECHS nach Nachschub.'),done)
      elseif why=='bag-full'then
        box(game,tr('Your Bag is full. The item remains here.',
          'Dein Beutel ist voll. Das Item bleibt hier liegen.'),done)
      else
        box(game,tr('The case will not open. Maybe another clue on your journey will help.',
          'Das Etui lässt sich nicht öffnen. Vielleicht findest du auf deiner Reise noch einen Hinweis.'),done)
      end
      return true
    end
  end
  function R.stock(game)
    local out={}
    for _,row in ipairs(rows)do
      if R.available(game,row.id)and R.discovered(game,row.id)then
        out[#out+1]=row.id
      end
    end
    return out
  end
  function R.buy(game,id)
    local row=byId[id];local shop=S.population and S.population.evolutionShop
    if not row or not near(game,shop)or not R.available(game,id)
        or not R.discovered(game,id)then return false,'locked'end
    if (tonumber(game.save.money)or 0)<row.price then return false,'money'end
    local package=hevo and hevo.byItem and hevo.byItem[id]
    if package and beyond(game)then return hevo.purchase(game,package.id,true)end
    local save=game.save;local oldMoney=save.money
    local oldInventory={};for k,v in pairs(save.inventory or{})do oldInventory[k]=v end
    local oldOrder={};for i,v in ipairs(save.bagOrder or{})do oldOrder[i]=v end
    if not Bag.add(save,id,1,game.data)then return false,'bag-full'end
    save.money=oldMoney-row.price
    if game.writeSave and game:writeSave()==false then
      save.inventory=oldInventory;save.bagOrder=oldOrder;save.money=oldMoney
      return false,'save'
    end
    return true,id
  end
  local function openShop(game,done)
    local stock=R.stock(game)
    if #stock==0 then
      box(game,tr('Bring me an evolution item you found on the islands. Then I can source replacements.',
        'Bring mir ein Entwicklungsitem, das du auf den Inseln gefunden hast. Danach besorge ich dir Nachschub.'),done)
      return
    end
    local menu=require('src.ui.ListMenu');local items={}
    for _,id in ipairs(stock)do
      items[#items+1]={label=game.data.items[id].name,
        right=('¥%d'):format(byId[id].price),value=id}
    end
    items[#items+1]={label=tr('Back','Zurück'),value='BACK'}
    local panel=menu.new(game,tr('EVOLUTION ITEMS','ENTWICKLUNGSITEMS'),items,{
      kind='sevii-evolution-shop',onCancel=done,onChoose=function(chosen)
        game.stack:pop()
        if chosen.value=='BACK'then if done then done()end;return end
        local id=chosen.value;local def=game.data.items[id]
        game.stack:push(require('src.render.TextBox').new(game,
          tr('Buy another ','Noch ein ')..def.name..('? ¥%d'):format(byId[id].price),nil,
          {defaultNo=true,choice=function(yes)
            if not yes then openShop(game,done);return end
            local ok,why=R.buy(game,id)
            local message=ok and tr('Here you go! Take good care of it.',
              'Bitte sehr! Geh gut damit um.') or why=='money'and tr(
              'You do not have enough money.','Du hast nicht genug Geld.')
              or why=='bag-full'and tr('Your Bag is full.','Dein Beutel ist voll.')
              or tr('This item is not available right now.',
                'Dieses Item ist gerade nicht erhältlich.')
            box(game,message,function()openShop(game,done)end)
          end}))
      end})
    game.stack:push(panel)
  end
  local shop=S.population and S.population.evolutionShop
  assert(shop,'Sevii evolution researcher missing')
  ui.talks[shop.name]=function(game,ow,n,done)
    if not S.unlocked(game)or not near(game,shop)then
      box(game,tr('Research is open to League Champions.',
        'Die Forschung steht Liga-Champs offen.'),done)
    else
      local clue=''
      if hevo and hevo.unlocked(game.save,'magnetic_field')then
        clue=S.state().chapterFiveComplete and tr(
          '\fMAGNETON reacts to the repaired coils on FIVE ISLAND. Bring one to the old ROCKET WAREHOUSE.',
          '\fMAGNETON reagiert auf die reparierten Spulen auf EILAND FÜNF. Nimm eines mit ins alte RAKETENLAGER.')
          or tr('\fThe coils on FIVE ISLAND may hold a clue about MAGNETON. We need to repair them first.',
            '\fDie Spulen auf EILAND FÜNF könnten MAGNETONs Geheimnis lüften. Zuerst müssen wir sie reparieren.')
      end
      box(game,tr('Every island has its own evolutionary secrets. Show me what you found, and I can source another.',
        'Jede Insel hat ihre eigenen Entwicklungsgeheimnisse. Zeig mir deinen Fund, dann besorge ich Nachschub.')..clue,
        function()openShop(game,done)end)
    end
    return true
  end
  local fields={
    {id='MAGNETIC',package='magnetic_field',chapter='chapterFiveComplete',
      source='FiveIsland_RocketWarehouse',x=22,y=21,
      en='The repaired coils pull at MAGNETON. Choose one to test the magnetic field.',
      de='Die reparierten Spulen ziehen MAGNETON an. Wähle eines für das Magnetfeld.'},
    {id='MOSS',package='moss_field',chapter='chapterThreeComplete',
      source='ThreeIsland_BerryForest',x=29,y=20,
      en='The moss hums with new life. Choose EEVEE to test this field.',
      de='Das Moos summt voller Leben. Wähle EVOLI für dieses Feld.'},
    {id='ICE',package='ice_field',chapter='chapterTwoComplete',
      source='FourIsland_IcefallCave_1F',x=7,y=16,
      en='The ice gives off a strange chill. Choose EEVEE to test this field.',
      de='Das Eis strahlt seltsame Kälte aus. Wähle EVOLI für dieses Feld.'},
  }
  for _,row in ipairs(fields)do
    local id=row.id;local site=add('FIELD_'..id,row.source,row.x,row.y,'SPRITE_POKEDEX')
    R.fields[id]=site
    ui.talks['KA_SEVII_EVOLUTION_FIELD_'..id]=function(game,ow,n,done)
      local s=S.state()
      if not near(game,site)or not S.unlocked(game)then
        box(game,tr('The field is quiet.','Das Feld ist still.'),done)
      elseif not s[row.chapter]then
        box(game,tr('The island research here is unfinished.',
          'Die Inselforschung hier ist noch nicht abgeschlossen.'),done)
      elseif epoch(game)<4 or not beyond(game)then
        box(game,tr('The field crackles, but its energy still feels strange to you.',
          'Das Feld knistert, aber seine Kraft ist dir noch fremd.'),done)
      elseif not hevo or not hevo.unlocked(game.save,row.package)then
        box(game,tr('The field hums softly. Your notes do not explain it yet.',
          'Das Feld summt leise. In deinen Notizen steht noch nichts darüber.'),done)
      else
        box(game,tr(row.en,row.de),function()
          hevo.useFieldAltar(game,row.package,nil,done)
        end)
      end
      return true
    end
  end
  return R
end
