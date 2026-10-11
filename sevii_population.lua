-- Island residents, native shops/PCs and recoverable expedition supplies.
-- All additions use fixed, approachable cells and the existing item owners.
return function(S,ui)
  local P={sites={},shops={},pcs={},residents={},rewards={
    {id='SURVEY',flag='chapterOneComplete',item='ULTRA_BALL',qty=5,en='Survey supplies',de='Messfahrt-Vorrat'},
    {id='RESCUE',flag='chapterThreeComplete',item='FULL_RESTORE',qty=3,en='Rescue supplies',de='Rettungsvorrat'},
    {id='CLEANSE',flag='chapterThreeComplete',item='CLEANSE_TAG',qty=1,en='Forest keepsake',de='Wald-Andenken'},
    {id='STATION',flag='chapterFiveComplete',item='MAX_REPEL',qty=5,en='Ruin supplies',de='Ruinenvorrat'},
    {id='EXPEDITION',flag='expeditionComplete',item='RARE_CANDY',qty=3,en='Expedition thanks',de='Expeditionsdank'},
  }}
  local tr,box=ui.tr,ui.box
  local stock={'ULTRA_BALL','FULL_RESTORE','REVIVE','FULL_HEAL','MAX_REPEL','ESCAPE_ROPE'}
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing population site '..id)
    for _,n in ipairs(S.maps[map].objects)do assert(n.x~=lx or n.y~=ly,'occupied population site '..id)end
    local p={id=id,map=map,x=lx,y=ly,source=source,name='KA_SEVII_LIFE_'..id,
      island=S.maps[map].kaSeviiIsland};P.sites[id]=p
    if sprite then ui.npc(map,p.name,sprite,p.name,lx,ly)end
    return p
  end
  local function near(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return p and ow and ow.map and a and ow.map.id==p.map and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  local function access(game,p)return S.unlocked(game)and near(game,p)end
  local function unavailable(game,done)
    box(game,tr('The expedition services are available to League Champions.',
      'Die Expeditionsdienste stehen Liga-Champs offen.'),done)
  end
  local names={'One','Two','Three','Four','Five','Six','Seven'}
  P.spa=add('EMBER_SPA','OneIsland_KindleRoad_EmberSpa',12,12,'SPRITE_GRAMPS')
  function P.rest(game)
    if not access(game,P.spa)then return false end
    for _,mon in ipairs(game.save.party or{})do require('src.pokemon.Pokemon').heal(mon)end
    return true
  end
  ui.talks[P.spa.name]=function(game,ow,n,done)
    if not access(game,P.spa)then unavailable(game,done);return true end
    local save=game.save
    game.stack:push(require('src.render.TextBox').new(game,
      tr('Welcome to Ember Spa. A quiet rest restores your team. Take a break?',
        'Willkommen in der Gluttherme. Eine ruhige Pause macht dein Team wieder fit. Möchtest du rasten?'),nil,
      {defaultNo=true,choice=function(yes)
        if game.save~=save then if done then done()end;return end
        if yes and P.rest(game)then
          box(game,tr('Your Pokemon are rested. The warm spring will be here on your return.',
            'Deine Pokemon sind wieder fit. Die warme Quelle wartet auch auf deinem Rückweg.'),done)
        elseif done then done()end
      end}))
    return true
  end
  P.nursery=add('NURSERY','FourIsland_PokemonDayCare',6,5,'SPRITE_GENTLEMAN')
  ui.talks[P.nursery.name]=function(game,ow,n,done)
    if not access(game,P.nursery)then unavailable(game,done);return true end
    local save=game.save
    box(game,tr('Welcome! We keep in touch with the Day-Care on Route 5. Leave a Pokemon here, pick it up there, or the other way around. We will look after any Eggs, too.',
      'Willkommen! Wir stehen mit der Pension an Route 5 in Verbindung. Gib ein Pokemon hier ab und hol es dort wieder ab, oder umgekehrt. Um Eier kümmern wir uns auch.'),function()
      if game.save~=save or not access(game,P.nursery)then if done then done()end;return end
      if not(ui.daycare and ui.daycare.openNursery(game,done,tr('FOUR ISLAND DAY-CARE','EILAND-VIER-PENSION')))then
        box(game,tr('The Day-Care service is currently disabled. Your partners remain safely recorded.',
          'Der Pensionsdienst ist gerade ausgeschaltet. Deine Partner bleiben sicher vermerkt.'),done)
      end
    end)
    return true
  end
  for island,prefix in ipairs(names)do
    -- The large One Island network Center places its terminal at (10,6);
    -- the other six compact Centers place it at (8,6). Keep the interaction
    -- marker on the artwork and let the player speak to it from the aisle.
    local p=add('PC_'..island,prefix..'Island_PokemonCenter_1F',island==1 and 10 or 8,6)
    P.pcs[island]=p
    local archive=add('JOURNAL_'..island,prefix..'Island_PokemonCenter_2F',6,5,'SPRITE_SCIENTIST')
    ui.talks[archive.name]=function(game,ow,n,done)
      if not access(game,archive)then unavailable(game,done)
      else box(game,tr('ISLAND FIELD OFFICE\nYour latest expedition entry:\n\n',
        'INSEL-FELDBÜRO\nDein letzter Expeditionseintrag:\n\n')..S.chapters.journal(),done)end
      return true
    end
  end
  function P.openPCAt(game,map,x,y)
    for _,p in ipairs(P.pcs)do
      if p.map==map and p.x==x and p.y==y then
        if not access(game,p)then unavailable(game);return true end
        game.overworld:openPC();return true
      end
    end
    return false
  end
  local shopSources={'OneIsland_House1','TwoIsland_House','ThreeIsland_Mart',
    'FourIsland_Mart','FiveIsland_House1','SixIsland_Mart','SevenIsland_Mart'}
  for island,source in ipairs(shopSources)do
    local house=source:find('House',1,true)~=nil
    local p=add('SHOP_'..island,source,house and 8 or 4,3,'SPRITE_CLERK');P.shops[island]=p
    ui.talks[p.name]=function(game,ow,n,done)
      if not access(game,p)then unavailable(game,done);return true end
      local items=P.stock(game)
      if #items==0 then box(game,tr('The supply boat has not unloaded yet.',
        'Das Versorgungsschiff ist noch nicht entladen.'),done);return true end
      game.stack:push(require('src.ui.ShopMenu').new(game,items,done));return true
    end
  end
  function P.stock(game)
    local out={}
    for _,id in ipairs(stock)do
      local def=game.data.items[id]
      -- A missing/zero-price definition must not turn a supply into a gift.
      if def and type(def.price)=='number'and def.price>0 and not def.keyItem then out[#out+1]=id end
    end
    return out
  end
  P.berryShops={}
  local berryGroups={
    {id='JOHTO_BERRIES',source='ThreeIsland_House3',generation=2,items={
      'BERRY','GOLD_BERRY','PSNCUREBERRY','PRZCUREBERRY','BURNT_BERRY','ICE_BERRY',
      'MINT_BERRY','BITTER_BERRY','MIRACLEBERRY','MYSTERYBERRY'}},
    {id='HOENN_BERRIES',source='SixIsland_WaterPath_House2',generation=3,items={
      'ORAN_BERRY','SITRUS_BERRY','CHERI_BERRY','CHESTO_BERRY','PECHA_BERRY','RAWST_BERRY',
      'ASPEAR_BERRY','PERSIM_BERRY','LUM_BERRY','LEPPA_BERRY',
      'LIECHI_BERRY','GANLON_BERRY','SALAC_BERRY','PETAYA_BERRY','APICOT_BERRY'}},
  }
  function P.berryStock(game,id)
    local epoch=ui.epoch and ui.epoch(game)or 1;local out={}
    for _,group in ipairs(berryGroups)do if group.id==id and epoch>=group.generation then
      for _,item in ipairs(group.items)do
        local def=game.data.items[item];local ready=def and def.kascEquipmentRewardEpochs
        if ready and ready[epoch]==true and type(def.price)=='number'and def.price>0
            and def.kascConsumableBerry67==true then out[#out+1]=item end
      end
    end end
    return out
  end
  for _,group in ipairs(berryGroups)do
    local p=add(group.id,group.source,8,3,'SPRITE_CLERK');p.generation=group.generation
    P.berryShops[#P.berryShops+1]=p
    ui.talks[p.name]=function(game,ow,n,done)
      if not access(game,p)then unavailable(game,done);return true end
      local stock=P.berryStock(game,p.id)
      if #stock==0 then
        box(game,tr('The right berries for your journey have not come in yet. Try me again when your next set of discoveries opens up.',
          'Die passenden Beeren für deine Reise sind noch nicht eingetroffen. Schau wieder vorbei, wenn du auf deiner Reise Neues entdeckt hast.'),done)
      else
        box(game,tr('A Berry is best kept close. Let a Pokemon hold one, and it will eat it when the time is right. Take a look at what grew in Johto and Hoenn!',
          'Eine Beere trägt man am besten bei sich. Gib einem Pokemon eine zum Tragen, dann isst es sie im richtigen Moment. Sieh dir an, was in Johto und Hoenn wächst!'),function()
          game.stack:push(require('src.ui.ShopMenu').new(game,stock,done))
        end)
      end
      return true
    end
  end
  -- Johto's existing ball owner supplies the real formulas and catch
  -- metadata. This stall adds a renewable route, not a second effect owner.
  P.apricornShop=add('APRICORN_BALLS','ThreeIsland_House1',8,3,'SPRITE_CLERK')
  function P.apricornStock(game)
    local out={};if (ui.epoch and ui.epoch(game)or 1)<2 then return out end
    for _,id in ipairs({'HEAVY_BALL','LEVEL_BALL','LURE_BALL','FAST_BALL',
        'LOVE_BALL','FRIEND_BALL','MOON_BALL'})do
      local def=game.data.items[id]
      local effect=def and game.data.item_effects and game.data.item_effects[def.effect]
      local ball=def and game.data.balls and game.data.balls[def.ball]
      if def and def.price>0 and ball and type(ball.attempt)=='function'
          and effect and type(effect.use)=='function'then out[#out+1]=id end
    end
    return out
  end
  ui.talks[P.apricornShop.name]=function(game,ow,n,done)
    if not access(game,P.apricornShop)then unavailable(game,done);return true end
    local items=P.apricornStock(game)
    if #items==0 then box(game,tr('My Apricorn Balls need the Johto rules or later.',
      'Meine Aprikokobälle brauchen die Johto-Regeln oder spätere Regeln.'),done)
    else box(game,tr('Apricorn Balls, made by hand in Johto! Each one has its favourite kind of encounter. Check your Bag before you throw, and pick the one that fits.',
      'Aprikokobälle, von Hand in Johto gefertigt! Jeder hat seine Lieblingsbegegnung. Sieh vor dem Wurf in deinen Beutel und wähle den passenden.'),function()
        game.stack:push(require('src.ui.ShopMenu').new(game,items,done))
      end)end
    return true
  end
  P.researchBallShop=add('RESEARCH_BALLS','FiveIsland_House2',8,3,'SPRITE_FISHER')
  function P.researchBallStock(game)
    local out={};if (ui.epoch and ui.epoch(game)or 1)<3 then return out end
    for _,id in ipairs({'NET_BALL','NEST_BALL','REPEAT_BALL','TIMER_BALL','PREMIER_BALL','DIVE_BALL','LUXURY_BALL'})do
      local d=game.data.items[id];local e=d and game.data.item_effects and game.data.item_effects[d.effect]
      local b=d and game.data.balls and game.data.balls[d.ball]
      if d and d.kascSeviiBall=='kasc.sevii-balls/v1'and d.price>0
          and b and type(b.attempt)=='function'and e and type(e.use)=='function'then out[#out+1]=id end
    end
    return out
  end
  ui.talks[P.researchBallShop.name]=function(game,ow,n,done)
    if not access(game,P.researchBallShop)then unavailable(game,done);return true end
    local stock=P.researchBallStock(game)
    if #stock==0 then box(game,tr('My research balls need generation 3 rules or later.',
      'Meine Forschungsbälle brauchen die Regeln ab Generation 3.'),done)
    else box(game,tr('Fishing for a Water Pokemon? Try a Net Ball, or a Dive Ball out on the water. A Timer Ball rewards patience; a Repeat Ball helps with an old acquaintance. I have a few more kinds here. The Bag tells you what each one does.',
      'Angelst du nach einem Wasser-Pokemon? Versuch es mit einem Netzball oder draußen auf dem Wasser mit einem Tauchball. Ein Timerball belohnt Geduld, ein Wiederball hilft bei einem alten Bekannten. Ich habe noch mehr Sorten. Im Beutel steht, was sie können.'),function()
        game.stack:push(require('src.ui.ShopMenu').new(game,stock,done))
      end)end
    return true
  end
  -- Separate small businesses give otherwise decorative houses a purpose.
  -- The item registry must expose the real medicine owner before a sale.
  P.medicineShops={}
  local medicines={
    {id='DAIRY',source='FourIsland_House1',gen=2,items={'MOOMOO_MILK','BERRY_JUICE'},
      en='Fresh milk and berry juice restore HP. Use them from your Bag.',
      de='Frische Milch und Beerensaft geben KP zurück. Wende sie aus dem Beutel an.'},
    {id='HERBS',source='ThreeIsland_House4',gen=2,
      items={'ENERGY_POWDER','ENERGY_ROOT','HEAL_POWDER','REVIVAL_HERB'},
      en='Our herbs heal well, but their bitter taste lowers friendship. Vital herbs revive a fainted Pokemon at full HP.',
      de='Unsere Kräuter heilen gut, aber ihr bitterer Geschmack senkt die Freundschaft. Vitalkraut belebt ein besiegtes Pokemon mit vollen KP wieder.'},
    {id='LAVA_BAKERY',source='TwoIsland_CapeBrink_House',gen=3,items={'LAVA_COOKIE'},
      en='Lava Cookies from Hoenn! They cure status problems without a bitter aftertaste.',
      de='Lavakekse aus Hoenn! Sie heilen Statusprobleme ohne bitteren Nachgeschmack.'},
  }
  function P.medicineStock(game,id)
    local out={};local gen=ui.epoch and ui.epoch(game)or 1
    for _,r in ipairs(medicines)do if r.id==id and gen>=r.gen then
      for _,item in ipairs(r.items)do
        local d=game.data.items[item];local e=d and game.data.item_effects and game.data.item_effects[d.effect]
        if d and d.kascSeviiMedicine=='kasc.sevii-medicine/v1'and e
            and e.kascSeviiMedicine==d.kascSeviiMedicine and type(e.use)=='function'
            and type(d.price)=='number'and d.price>0 then out[#out+1]=item end
      end
    end end
    return out
  end
  for _,r in ipairs(medicines)do
    local p=add(r.id,r.source,8,3,'SPRITE_CLERK');P.medicineShops[#P.medicineShops+1]=p
    ui.talks[p.name]=function(game,ow,n,done)
      if not access(game,p)then unavailable(game,done);return true end
      local items=P.medicineStock(game,p.id)
      if #items==0 then box(game,tr('Come back with the corresponding generation rules enabled.',
        'Komm mit den passenden Generationsregeln wieder.'),done)
      else box(game,tr(r.en,r.de),function()
        game.stack:push(require('src.ui.ShopMenu').new(game,items,done))
      end)end
      return true
    end
  end
  P.recoveryShops={}
  local recoveryRows={
    {id='GLASS_FLUTES',source='OneIsland_House2',y=6,items={'BLUE_FLUTE','YELLOW_FLUTE','RED_FLUTE','BLACK_FLUTE','WHITE_FLUTE'},
      en='Hear that? I make these glass flutes to help Pokemon on the road. Blue can wake a sleepy partner; the black and white ones change how often wild Pokemon come near. You can play them again and again.',
      de='Hörst du das? Ich mache diese Glasflöten für Pokemon auf Reisen. Blau weckt einen müden Partner; Schwarz und Weiß beeinflussen, wie oft wilde Pokemon auftauchen. Du kannst sie immer wieder spielen.'},
    {id='MOVE_TRAINING',source='SevenIsland_House_Room1',items={'PP_MAX','FLUFFY_TAIL','ZINC'},
      en='Training for a long climb? PP Max helps a move last longer, and Zinc strengthens Special Defense training. A Fluffy Tail can get you out of a wild battle.',
      de='Trainierst du für einen langen Aufstieg? AP-Top gibt einer Attacke mehr Ausdauer, Zink stärkt das Spezial-Verteidigungstraining. Eine Eneco-Rute hilft dir, wilden Pokemon zu entkommen.'},
  }
  function P.recoveryStock(game,id)
    local out={};if(ui.epoch and ui.epoch(game)or 1)<3 then return out end
    for _,row in ipairs(recoveryRows)do if row.id==id then
      for _,item in ipairs(row.items)do
        local d=game.data.items[item];local e=d and game.data.item_effects and game.data.item_effects[d.effect]
        local owned=d and e and(d.kascSeviiRecovery=='kasc.sevii-recovery/v1'
            and e.kascSeviiRecovery==d.kascSeviiRecovery
          or item=='ZINC'and d.kascSeviiZinc=='kasc.sevii-zinc/v1'
            and e.kascSeviiZinc==d.kascSeviiZinc)
        if owned
            and type(e.use)=='function'and type(d.price)=='number'and d.price>0 then out[#out+1]=item end
      end
    end end
    return out
  end
  for _,r in ipairs(recoveryRows)do
    local p=add(r.id,r.source,8,r.y or 3,'SPRITE_CLERK');P.recoveryShops[#P.recoveryShops+1]=p
    ui.talks[p.name]=function(game,ow,n,done)
      if not access(game,p)then unavailable(game,done);return true end
      local items=P.recoveryStock(game,p.id)
      if #items==0 then box(game,tr('These supplies need generation 3 rules or later.',
        'Diese Waren brauchen die Regeln ab Generation 3.'),done)
      else box(game,tr(r.en,r.de),function()game.stack:push(require('src.ui.ShopMenu').new(game,items,done))end)end
      return true
    end
  end
  P.evolutionShop=add('MARINE_EVOLUTION','SixIsland_WaterPath_House1',8,3,'SPRITE_SCIENTIST')
  function P.evolutionStock(game)
    local out={};if(ui.epoch and ui.epoch(game)or 1)<3 then return out end
    if ui.beyondActive and not ui.beyondActive(game)then return out end
    for _,id in ipairs({'PRISM_SCALE','DEEP_SEA_TOOTH','DEEP_SEA_SCALE'})do
      local d=game.data.items[id];local e=d and game.data.item_effects and game.data.item_effects[d.effect]
      if d and(d.effect=='KA_HOENN_EVOLUTION_ITEM_EFFECT'or d.effect=='KA_BACKEND_EVOLUTION_'..id)and d.needsTarget==true
          and e and type(e.use)=='function'and type(d.price)=='number'and d.price>0 then
        out[#out+1]=id
      end
    end
    return out
  end
  ui.talks[P.evolutionShop.name]=function(game,ow,n,done)
    if not access(game,P.evolutionShop)then unavailable(game,done);return true end
    local items=P.evolutionStock(game)
    if #items==0 then box(game,tr('Our marine research needs BEYOND KANTO and the Hoenn rules or later.',
      'Unsere Meeresforschung braucht JENSEITS VON KANTO und die Hoenn-Regeln oder spätere Regeln.'),done)
    else box(game,tr('A Prism Scale can bring out Feebas\'s beauty. And Clamperl? With a Deep Sea Tooth it becomes Huntail; with a Deep Sea Scale, Gorebyss. Try the item from your Bag.',
      'Eine Schönschuppe bringt Barschwas Schönheit hervor. Und Perlu? Mit einem Abysszahn wird es zu Aalabyss, mit einer Abyssplatte zu Saganabyss. Probier das Item aus deinem Beutel.'),function()
        game.stack:push(require('src.ui.ShopMenu').new(game,items,done))
      end)end
    return true
  end
  P.finds={}
  local findRows={
    {'BEACH_PEARL','OneIsland_TreasureBeach',9,18,'PEARL'},
    {'CAPE_STARDUST','TwoIsland_CapeBrink',8,26,'STARDUST'},
    {'BRIDGE_MUSHROOM','ThreeIsland_BondBridge',55,13,'TINYMUSHROOM'},
    {'GARDEN_MUSHROOM','ThreeIsland',13,23,'BIG_MUSHROOM'},
    {'RESORT_PEARL','FiveIsland_ResortGorgeous',43,13,'BIG_PEARL'},
    {'CANYON_STAR','SevenIsland_SevaultCanyon',12,56,'STAR_PIECE'},
    {'EMBER_ASH','MtEmber_RubyPath_1F',22,9,'SACRED_ASH'},
    {'NURSERY_BELL','FourIsland_PokemonDayCare',7,4,'SOOTHE_BELL'},
    {'ICE_EVERSTONE','FourIsland_IcefallCave_1F',6,17,'EVERSTONE'},
    {'WAREHOUSE_COIN','FiveIsland_RocketWarehouse',25,22,'AMULET_COIN'},
    {'COLLECTOR_BELT','ThreeIsland_House5',8,6,'BLACKBELT_I'},
    {'RUBBING_ICE','FourIsland_House2',8,6,'NEVER_MELT_ICE'},
    {'RESORT_GLASSES','FiveIsland_ResortGorgeous_House',8,6,'BLACK_GLASSES'},
    {'STUDENT_SPOON','SevenIsland_House_Room2',5,5,'TWISTED_SPOON'},
  }
  local battleSouvenirs={COLLECTOR_BELT=true,RUBBING_ICE=true,
    RESORT_GLASSES=true,STUDENT_SPOON=true}
  function P.claimFind(game,id)
    local p=P.sites[id]
    if not p or not p.item or not access(game,p)then return false,'not-at-find'end
    local s=S.state();s.population=s.population or{};s.population.finds=s.population.finds or{}
    if id=='WAREHOUSE_COIN'and not s.chapterFourComplete then return false,'chapter-required'end
    if s.population.finds[id]then return false,'already-collected'end
    local def=game.data.items[p.item]
    if not def or def.keyItem or not def.price or def.price<=0 then return false,'item-unavailable'end
    if battleSouvenirs[id]then
      local epoch=ui.epoch and ui.epoch(game)or 1
      if not(def.kascEquipmentRewardEpochs
          and def.kascEquipmentRewardEpochs[epoch]==true)then
        return false,'generation-required'
      end
    end
    if not require('src.inventory.Bag').add(game.save,p.item,1,game.data)then return false,'bag-full'end
    s.population.finds[id]=true;S.persist(s);return true,p.item
  end
  for _,r in ipairs(findRows)do
    local p=add(r[1],r[2],r[3],r[4],'SPRITE_POKE_BALL');p.item=r[5];P.finds[#P.finds+1]=p
    ui.talks[p.name]=function(game,ow,n,done)
      local ok,why=P.claimFind(game,p.id)
      local text
      if ok then
        if p.id=='NURSERY_BELL'then
          text=tr('Found: ','Gefunden: ')..game.data.items[why].name..tr(
            '\nA partner holding this bell grows closer during your travels.',
            '\nEin Partner mit dieser Glocke gewinnt auf Reisen schneller Freundschaft.')
        elseif p.id=='ICE_EVERSTONE'then
          text=tr('Found: ','Gefunden: ')..game.data.items[why].name..tr(
            '\nA partner holding this stone will not evolve until you take it back.',
            '\nEin Partner mit diesem Stein entwickelt sich erst wieder, wenn du ihn ablegst.')
        elseif p.id=='WAREHOUSE_COIN'then
          text=tr('Found: ','Gefunden: ')..game.data.items[why].name..tr(
            '\nThe station crew left this training fund behind. A participating holder doubles Trainer prize money.',
            '\nDie Stationsbesatzung ließ diese Trainingskasse zurück. Nimmt der Träger teil, verdoppelt sie Preisgeld aus Trainerkämpfen.')
        elseif battleSouvenirs[p.id]then
          text=tr('Found: ','Gefunden: ')..game.data.items[why].name..tr(
            '\nLet a Pokemon hold it to strengthen matching-type attacks.',
            '\nLass es ein Pokemon tragen, um Attacken des passenden Typs zu stärken.')
        else text=tr('Found: ','Gefunden: ')..game.data.items[why].name..tr(
          '\nA shop will buy this natural treasure.','\nEin Laden kauft dir diesen Naturschatz ab.')end
      elseif why=='bag-full'then text=tr('Your Bag is full. The find remains here.',
        'Dein Beutel ist voll. Der Fund bleibt hier liegen.')
      elseif why=='already-collected'then text=tr('You have already searched this spot.',
        'Du hast diese Stelle bereits abgesucht.')
      elseif why=='chapter-required'then text=tr('The station is still sealed. Finish the earlier island work first.',
        'Die Station ist noch versiegelt. Schließ zuerst die frühere Inselarbeit ab.')
      elseif why=='generation-required'then text=tr('This battle item needs its matching generation rules. It will remain here.',
        'Dieses Kampfitem braucht die passenden Generationsregeln. Es bleibt hier liegen.')
      else text=tr('There is nothing you can collect here yet.','Hier kannst du noch nichts mitnehmen.')end
      box(game,text,done);return true
    end
  end
  local quartermaster=add('QUARTERMASTER','OneIsland_House2',8,3,'SPRITE_SCIENTIST')
  P.quartermaster=quartermaster
  local function rewardState()
    local s=S.state();s.population=s.population or{};s.population.rewards=s.population.rewards or{}
    return s,s.population.rewards
  end
  function P.pending()
    local s,claimed=rewardState();local out={}
    for _,row in ipairs(P.rewards)do if s[row.flag]and not claimed[row.id]then out[#out+1]=row end end
    return out
  end
  function P.claim(game,id)
    if not access(game,quartermaster)then return false,'not-at-quartermaster'end
    local row;for _,r in ipairs(P.rewards)do if r.id==id then row=r end end
    if not row then return false,'unknown-reward'end
    local s,claimed=rewardState()
    if not s[row.flag]then return false,'chapter-required'end
    if claimed[id]then return false,'already-claimed'end
    if not game.data.items[row.item]then return false,'item-unavailable'end
    if not require('src.inventory.Bag').add(game.save,row.item,row.qty,game.data)then return false,'bag-full'end
    claimed[id]=true;S.persist(s);return true,row
  end
  local function rewardsMenu(game,done)
    local pending=P.pending()
    if #pending==0 then box(game,tr('SUPPLY KEEPER: Nothing waiting for you today. Mara sends a parcel whenever your expedition needs one. I will keep it safe if your Bag is full.',
      'QUARTIERMEISTER: Heute liegt nichts für dich bereit. Mara schickt immer wieder Pakete für deine Reise. Ist dein Beutel voll, bewahre ich sie für dich auf.'),done);return end
    local rows={}
    for _,row in ipairs(pending)do rows[#rows+1]={label=tr(row.en,row.de),value=row.id}end
    rows[#rows+1]={label=tr('Back','Zurück'),value='BACK'}
    local Menu=ui.menu or require('src.ui.ListMenu')
    local panel=Menu.new(game,tr('EXPEDITION SUPPLIES','EXPEDITIONSVORRAT'),rows,{
      kind='sevii-expedition-supplies',onCancel=done,onChoose=function(item)
        game.stack:pop();if item.value=='BACK'then if done then done()end;return end
        local ok,why=P.claim(game,item.value)
        if ok then
          box(game,tr('Received ','Erhalten: ')..why.qty..' x '..game.data.items[why.item].name,
            function()rewardsMenu(game,done)end)
        else
          local text=why=='bag-full'and tr('Your Bag has no room for the complete package. Store or use some items and return. I will keep the package for you.',
            'In deinem Beutel ist kein Platz für das ganze Paket. Lagere oder benutze einige Items und komm wieder. Ich bewahre das Paket für dich auf.')or tr('This package is not available yet. Your other supplies remain here.',
            'Dieses Paket ist noch nicht verfügbar. Deine anderen Vorräte bleiben hier.')
          box(game,text,done)
        end
      end})
    panel.__vascHeaderLabel=tr('EXPEDITION SUPPLIES','EXPEDITIONSVORRAT');game.stack:push(panel)
  end
  ui.talks[quartermaster.name]=function(game,ow,n,done)
    if not access(game,quartermaster)then unavailable(game,done)else rewardsMenu(game,done)end
    return true
  end
  -- Each house has a local reason to visit. The before/after lines are
  -- intentionally tied to the island's work, landscape or completed rescue.
  local residents={
    {'NETMAKER','OneIsland_House1','SPRITE_FISHER',
      'I mend the fishing nets. Lately the floats pull against the tide. Mara is checking the buoys; our neighbour keeps the expedition supplies.',
      'Ich flicke die Fischernetze. Seit kurzem ziehen die Schwimmer gegen die Flut. Mara prüft die Bojen; unser Nachbar verwaltet die Expeditionsvorräte.',
      'The floats follow the tide again. Some unfamiliar Pokemon have learned where we mend the nets. We leave them a quiet stretch of beach.',
      'Die Schwimmer folgen wieder der Flut. Einige fremde Pokemon wissen inzwischen, wo wir die Netze flicken. Wir lassen ihnen einen ruhigen Strandabschnitt.'},
    {'LOGKEEPER','OneIsland_House2','SPRITE_GRAMPS',
      'Mara keeps leaving supply parcels in my care. If your Bag is full, I will hold yours until you come back.',
      'Mara lässt dauernd Vorratspakete bei mir. Wenn dein Beutel voll ist, bewahre ich deins auf, bis du wiederkommst.',
      'Your expedition commendation has its own page now. The supply keeper still has any packages you have not collected.',
      'Deine Expeditionsauszeichnung hat jetzt eine eigene Seite. Noch nicht abgeholte Pakete liegen weiterhin beim Quartiermeister.'},
    {'BAKER','TwoIsland_House','SPRITE_MIDDLE_AGED_WOMAN',
      'I bake for the harbour crews. Our small supply counter keeps medicine and Balls too. The old island records are in the building east of the square.',
      'Ich backe für die Hafenleute. Unser kleiner Vorratsladen hat auch Medizin und Bälle. Die alten Inselberichte liegen im Gebäude östlich des Platzes.',
      'The first ferry arrived on time this morning. I almost burned the bread watching it come in!',
      'Heute Morgen kam die erste Fähre pünktlich. Beim Zuschauen hätte ich beinahe das Brot verbrannt!'},
    {'CAPE_READER','TwoIsland_CapeBrink_House','SPRITE_GRAMPS',
      'The song speaks of a reflection. A reflection reads from the other end. At the upper pool, the marked stone is on the eastern bank.',
      'Das Lied spricht von einem Spiegelbild. Ein Spiegelbild liest vom anderen Ende. Am oberen Becken steht der markierte Stein am Ostufer.',
      'Only our own clouds are in the pool now. I still teach the old song. A warning should outlive the danger it prevented.',
      'Jetzt stehen nur unsere eigenen Wolken im Wasser. Ich lehre das alte Lied trotzdem weiter. Eine Warnung sollte die Gefahr überdauern, die sie verhindert hat.'},
    {'BOAT_REPAIR','ThreeIsland_House1','SPRITE_SAILOR',
      'I repair the boats that cross to Bond Bridge. In the forest, mark the way you came. A familiar-looking turning may lead somewhere else.',
      'Ich repariere die Boote zur Brückenverbindung. Markiere im Wald deinen Hinweg. Eine vertraute Abzweigung kann plötzlich woanders enden.',
      'We have replaced the missing trail signs. Lina checked the route herself. Travellers can follow the forest paths again.',
      'Die fehlenden Wegweiser sind ersetzt. Lina hat die Strecke selbst geprüft. Reisende können den Waldwegen wieder vertrauen.'},
    {'LINA_FAMILY','ThreeIsland_House2','SPRITE_MIDDLE_AGED_WOMAN',
      'Lina took an old survey map into Berry Forest. She said she would be back before supper. If you find her, stay close on the way out.',
      'Lina nahm eine alte Vermessungskarte mit in den Beerenforst. Sie wollte vor dem Abendessen zurück sein. Wenn du sie findest, bleib auf dem Rückweg bei ihr.',
      'Lina is home. She has drawn the forest again, with every uncertain path clearly marked. Thank you for not leaving her behind.',
      'Lina ist zu Hause. Sie hat den Wald neu gezeichnet und jeden unsicheren Weg markiert. Danke, dass du sie nicht zurückgelassen hast.'},
    {'HERBALIST','ThreeIsland_House3','SPRITE_GRAMPS',
      'Plants have moved into clearings where they never grew before. I mark the newcomers instead of pulling them out. Ask the harbour guide which Pokemon have settled here.',
      'In manchen Lichtungen wachsen plötzlich fremde Pflanzen. Ich markiere die Neuankömmlinge, statt sie auszureißen. Der Hafenführer kennt die hier angesiedelten Pokemon.',
      'The newcomers survived the first calm week. We are learning which plants and Pokemon can share the same clearings.',
      'Die Neuankömmlinge haben die erste ruhige Woche überstanden. Wir lernen, welche Pflanzen und Pokemon sich die Lichtungen teilen können.'},
    {'FOREST_WALKER','ThreeIsland_House4','SPRITE_HIKER',
      'I got turned around in that forest and nearly missed supper. Next time I am bringing a friend and plenty of food.',
      'Im Wald habe ich mich verlaufen und beinahe das Abendessen verpasst. Nächstes Mal nehme ich jemanden und genug Proviant mit.',
      'I walked the forest twice today. Both times I came out where I expected. That used to be too ordinary to mention.',
      'Heute bin ich zweimal durch den Wald gegangen. Beide Male kam ich dort heraus, wo ich es erwartet hatte. Früher war das nicht der Rede wert.'},
    {'YOUNG_COLLECTOR','ThreeIsland_House5','SPRITE_YOUNGSTER',
      'The harbour guide has a whole book of Pokemon locations! It even tells you whether to search on land or on the water.',
      'Der Hafenführer hat ein ganzes Buch mit Pokemon-Fundorten! Darin steht sogar, ob du an Land oder im Wasser suchen musst.',
      'I am filling my own island notebook now. Finishing the expedition did not make the Pokemon disappear!',
      'Jetzt fülle ich mein eigenes Inselheft. Nur weil die Expedition fertig ist, verschwinden die Pokemon doch nicht!'},
    {'ICE_FAMILY','FourIsland_House1','SPRITE_MIDDLE_AGED_WOMAN',
      'Hagen is studying the cave ice. A crack is a warning: crossing that same thin patch again can drop you to the floor below.',
      'Hagen untersucht das Höhleneis. Ein Riss warnt dich: Trittst du noch einmal auf dieselbe dünne Stelle, kannst du eine Etage tiefer fallen.',
      'The strange pulses have stopped. Thin ice is still thin ice, though. The cave deserves care even in peaceful weather.',
      'Die seltsamen Impulse sind verstummt. Dünnes Eis bleibt trotzdem dünnes Eis. Auch bei ruhigem Wetter braucht die Höhle Vorsicht.'},
    {'LORELEI_CURATOR','FourIsland_LoreleisHouse','SPRITE_GIRL',
      'I look after Lorelei\'s house while she is away. People keep asking if she has seen a legendary Pokemon out here. If she had, do you think she would tell me?',
      'Ich hüte Loreleis Haus, solange sie fort ist. Ständig fragt jemand, ob sie hier ein legendäres Pokemon gesehen hat. Glaubst du, sie würde es mir verraten?',
      'I left Lorelei a careful account of the expedition. Protecting the islands was worth more than bringing home a legendary trophy.',
      'Ich habe Lorelei einen genauen Expeditionsbericht hinterlegt. Die Inseln zu schützen war mehr wert als eine legendäre Trophäe.'},
    {'RUBBING_KEEPER','FourIsland_House2','SPRITE_SUPER_NERD',
      'Old stone rubbings survive when spoken directions do not. Copy the whole boundary before trying to trace it.',
      'Alte Steinabdrücke überdauern mündliche Wegbeschreibungen. Schreibe die ganze Grenze ab, bevor du sie nachzeichnest.',
      'Your new drawings are stored with the old rubbings. The next expedition will know what held the boundary closed.',
      'Deine neuen Zeichnungen liegen bei den alten Abdrucken. Die nächste Expedition wird wissen, was die Grenze geschlossen hielt.'},
    {'DOCK_SUPPLIER','FiveIsland_House1','SPRITE_SAILOR',
      'Our house supplies the station crews. There is medicine and travel gear at the counter. The warehouse has gone quiet; the engineers are worried.',
      'Unser Haus versorgt die Stationsleute. Am Tresen gibt es Medizin und Reisebedarf. Im Lagerhaus ist es still geworden; die Techniker machen sich Sorgen.',
      'The station crew ordered ordinary provisions today. No emergency cable, no rescue lamps. I liked packing that order.',
      'Heute bestellte die Stationsbesatzung normalen Proviant. Kein Notkabel, keine Rettungslampen. Diese Bestellung habe ich gern gepackt.'},
    {'MEMORIAL_KEEPER','FiveIsland_House2','SPRITE_GRAMPS',
      'The memorial on the southern shore reminds us to make room for grief. Leave a little quiet around it when you explore.',
      'Das Denkmal an der südlichen Küste erinnert uns daran, der Trauer Raum zu lassen. Lass dort etwas Ruhe, wenn du die Insel erkundest.',
      'We remember those we lost, and welcome those who made it home. Both belong to an island story.',
      'Wir erinnern uns an die Verlorenen und begrüßen die Heimgekehrten. Beides gehört zur Geschichte einer Insel.'},
    {'RUIN_CARTOGRAPHER','SixIsland_House','SPRITE_SUPER_NERD',
      'Iona went south of WATER PATH, into RUIN VALLEY. She said the stones in DOTTED HOLE point the way. I hope they point her back out, too.',
      'Iona ist südlich des WASSERPFADS ins RUINENTAL gezogen. Sie sagte, die Steine im PUNKTLOCH zeigen den Weg. Hoffentlich zeigen sie ihr auch wieder hinaus.',
      'The route through Dotted Hole is finally documented. We mark it as a warning, not an invitation to cross the boundary.',
      'Der Weg durch das Punktloch ist endlich dokumentiert. Wir markieren ihn als Warnung, nicht als Einladung, die Grenze zu übertreten.'},
    {'WATERPATH_DIVER','SixIsland_WaterPath_House1','SPRITE_FISHER',
      'A new Pokemon in familiar water can still surprise an experienced swimmer. Rest your team before a long crossing.',
      'Ein neues Pokemon in vertrautem Wasser kann auch erfahrene Schwimmer überraschen. Ruhe dein Team vor einer langen Überfahrt aus.',
      'The crossings are calm. The unfamiliar Pokemon are still here, so I keep notes instead of assuming the water is empty.',
      'Die Überfahrten sind ruhig. Die fremden Pokemon sind noch da. Deshalb mache ich mir Notizen, statt leeres Wasser zu erwarten.'},
    {'WATERPATH_GARDENER','SixIsland_WaterPath_House2','SPRITE_GIRL',
      'I keep a patch of garden for the visiting Pokemon. If you want to meet a particular species, the harbour guide knows its actual search area.',
      'Ich lasse den besuchenden Pokemon ein Stück Garten. Suchst du eine bestimmte Art, kennt der Hafenführer ihr genaues Suchgebiet.',
      'They are not visitors any more. Some have made nests. I moved the vegetable beds a little to give them room.',
      'Sie sind keine Besucher mehr. Manche haben Nester gebaut. Ich habe die Gemüsebeete etwas versetzt, damit sie Platz haben.'},
    {'TANOBY_ARCHIVIST','SevenIsland_House_Room1','SPRITE_GRAMPS',
      'The canyon house is an expedition field camp now. The calibration cave is farther north. Tanoby itself lies beyond the southern shore.',
      'Das Canyon-Haus ist jetzt ein Expeditionslager. Die Kalibrierhöhle liegt weiter nördlich. Tanoby selbst liegt hinter der südlichen Küste.',
      'The field camp sent its final report. A closed crossing, three tended anchors, and a whole island chain still open to travellers.',
      'Das Feldlager hat seinen Abschlussbericht geschickt. Ein geschlossener Übergang, drei bewachte Anker und eine ganze Inselkette, die Reisenden offen bleibt.'},
    {'ISLAND_STUDENT','SevenIsland_House_Room2','SPRITE_YOUNGSTER',
      'I used to think a sealed ruin was hiding a treasure. Now I wonder whether somebody was keeping danger out.',
      'Früher dachte ich, versiegelte Ruinen verstecken einen Schatz. Jetzt frage ich mich, ob jemand eine Gefahr draußen halten wollte.',
      'My teacher asked what a hero looks like. I wrote about the people who brought everyone home.',
      'Meine Lehrerin fragte, wie ein Held aussieht. Ich habe über die Leute geschrieben, die alle nach Hause brachten.'},
    {'CANYON_COOK','SevenIsland_SevaultCanyon_House','SPRITE_MIDDLE_AGED_WOMAN',
      'I keep the kettle warm while Selma coordinates the teams. Check your medicine before heading north to the cave or south to the ruins.',
      'Ich halte den Kessel warm, während Selma die Teams koordiniert. Prüfe deine Medizin, bevor du nach Norden zur Höhle oder nach Süden zu den Ruinen gehst.',
      'Everyone finally sat down for a meal together. We left a place for the next traveller. The expedition is over; the islands are still here.',
      'Endlich haben alle gemeinsam gegessen. Wir haben einen Platz für den nächsten Reisenden freigelassen. Die Expedition ist vorbei; die Inseln sind noch da.'},
  }
  for _,r in ipairs(residents)do
    local side=r[1]=='LINA_FAMILY'or r[1]=='CANYON_COOK'
    local p=add(r[1],r[2],side and 8 or 2,3,r[3]);P.residents[#P.residents+1]=p
    local row=r
    ui.talks[p.name]=function(game,ow,n,done)
      local s=S.state();local after=s.seviiRiftSealed
      if row[1]=='LINA_FAMILY'and s.chapterThreeComplete then after=true end
      box(game,after and tr(row[6],row[7])or tr(row[4],row[5]),done);return true
    end
  end
  return P
end
