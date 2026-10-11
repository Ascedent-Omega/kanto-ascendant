-- Optional island challenges. Native battle/blackout/prize handling remains
-- authoritative; this module owns only its roster, victory and item receipt.
return function(mod,S,ui,opts)
  local T={rows={},allRows={},byId={},byClass={}}
  local tr=ui.tr
  local function copy(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
  -- Each slot chooses the latest available era, retaining a complete themed
  -- team under explicit older profiles. All entries are ordinary species.
  local rows={
    {'BEACH','MIRA','OneIsland_TreasureBeach',10,19,'OPP_FISHER','SPRITE_FISHER',60,'MYSTIC_WATER',
      {{55,55,279,279},{99,171,171,419},{130,230,230,230}},
      'I record how the new arrivals hunt along this shore. Shall we compare our water teams?',
      'Ich beobachte die Jagd der Neuankömmlinge an dieser Küste. Vergleichen wir unsere Wasserteams?',
      'Even a familiar shore rewards careful observation.','Auch eine vertraute Küste belohnt genaue Beobachtung.'},
    {'VOLCANO','ARNO','OneIsland_KindleRoad',11,110,'OPP_HIKER','SPRITE_HIKER',62,'CHARCOAL',
      {{75,219,323,323},{126,126,324,324},{112,112,112,464}},
      'My patrol checks the warm vents. A sturdy team matters as much as a map.',
      'Meine Patrouille prüft die warmen Erdspalten. Ein robustes Team ist genauso wichtig wie eine Karte.',
      'You kept your footing. I will keep watching the vents.','Du hast standgehalten. Ich behalte die Erdspalten im Blick.'},
    {'CAPE','ALVA','TwoIsland_CapeBrink',7,25,'OPP_COOLTRAINER_F','SPRITE_COOLTRAINER_F',62,'SHARP_BEAK',
      {{22,164,334,334},{26,181,181,181},{36,176,176,468}},
      'The birds notice a changing wind before we do. Let me show you my lookout team.',
      'Die Vögel bemerken einen Windwechsel vor uns. Ich zeige dir mein Aussichtsteam.',
      'The sky needs patient observers, even after the rifts close.','Der Himmel braucht geduldige Beobachter, auch nach dem Schließen der Risse.'},
    {'SQUARE','JONTE','TwoIsland',28,15,'OPP_SUPER_NERD','SPRITE_SUPER_NERD',63,'POLKADOT_BOW',
      {{122,122,122,122},{36,190,272,424},{40,235,235,235}},
      'I organise friendly matches for the island children. Will the Champion join one?',
      'Ich organisiere Freundschaftskämpfe für die Inselkinder. Macht der Champ mit?',
      'That was a lesson worth sharing. Your ribbon is a thank-you from the club.',
      'Das war eine Lektion zum Weitergeben. Dein Band ist ein Dankeschön vom Verein.'},
    {'BRIDGE','TAMMO','ThreeIsland_BondBridge',54,12,'OPP_COOLTRAINER_M','SPRITE_COOLTRAINER_M',64,'MIRACLE_SEED',
      {{24,168,168,168},{45,182,275,275},{71,71,286,470}},
      'We protect the forest trail without driving its Pokemon away. Test my patrol team?',
      'Wir schützen den Waldweg, ohne seine Pokemon zu vertreiben. Prüfst du mein Patrouillenteam?',
      'Strength is useful when it leaves room for others.','Stärke hilft, wenn sie anderen Platz lässt.'},
    {'GARDEN','NELA','ThreeIsland',12,22,'OPP_BEAUTY','SPRITE_BEAUTY',64,'LIECHI_BERRY',
      {{12,166,267,416},{47,192,286,286},{114,114,315,465}},
      'My garden feeds both old residents and newcomers. These are its guardians.',
      'Mein Garten ernährt alte Bewohner und Neuankömmlinge. Das sind seine Wächter.',
      'A seed can begin a new home. Take care of what grows here.','Ein Samen kann ein neues Zuhause begründen. Achte darauf, was hier wächst.'},
    {'DAYCARE','FENJA','FourIsland',18,24,'OPP_BEAUTY','SPRITE_BEAUTY',65,'LUM_BERRY',
      {{36,184,184,184},{40,210,301,428},{80,80,326,326}},
      'I help young trainers learn to care for their teams. Care and strength belong together.',
      'Ich helfe jungen Trainern, für ihre Teams zu sorgen. Fürsorge und Stärke gehören zusammen.',
      'Your Pokemon trust you. That is something no shortcut can replace.','Deine Pokemon vertrauen dir. Dafür gibt es keine Abkürzung.'},
    {'ICE','SILKE','FourIsland',27,16,'OPP_COOLTRAINER_F','SPRITE_COOLTRAINER_F',66,'GANLON_BERRY',
      {{87,87,365,365},{91,221,362,478},{124,124,124,473}},
      'I watch the cave entrance. Our practice match stays out here, away from the thin ice.',
      'Ich bewache den Höhleneingang. Unser Übungskampf bleibt hier draußen, fern vom dünnen Eis.',
      'A calm decision can save a whole team.','Eine ruhige Entscheidung kann ein ganzes Team retten.'},
    {'RESORT','LEV','FiveIsland_ResortGorgeous',42,12,'OPP_SAILOR','SPRITE_SAILOR',66,'SALAC_BERRY',
      {{73,171,319,319},{80,199,199,419},{130,230,321,321}},
      'I escort supply boats through the reefs. Fancy a match before the next crossing?',
      'Ich begleite Versorgungsschiffe durch die Riffe. Lust auf einen Kampf vor der nächsten Überfahrt?',
      'There is always another crossing to prepare for.','Es gibt immer eine weitere Überfahrt vorzubereiten.'},
    {'MEMORIAL','RUNA','FiveIsland_MemorialPillar',12,42,'OPP_COOLTRAINER_F','SPRITE_COOLTRAINER_F',67,'SPELL_TAG',
      {{105,105,105,105},{93,200,354,429},{42,169,356,426}},
      'I tend the memorial. A respectful match celebrates the partners still beside us.',
      'Ich pflege das Denkmal. Ein respektvoller Kampf feiert die Partner, die noch an unserer Seite sind.',
      'We remember the absent and care for the living.','Wir erinnern uns an die Abwesenden und sorgen für die Lebenden.'},
    {'GREEN','BORIS','SixIsland_GreenPath',39,12,'OPP_COOLTRAINER_M','SPRITE_COOLTRAINER_M',67,'SILVERPOWDER',
      {{123,212,212,212},{127,193,291,469},{15,168,348,348}},
      'The green path has more wings than ever. My survey team would like a challenge.',
      'Auf dem Grünen Pfad schwirren mehr Flügel denn je. Mein Erkundungsteam sucht eine Herausforderung.',
      'We will map their habitats without disturbing their nests.','Wir kartieren ihre Lebensräume, ohne ihre Nester zu stören.'},
    {'RUINS','TILDA','SixIsland_RuinValley',28,27,'OPP_SUPER_NERD','SPRITE_SUPER_NERD',68,'PETAYA_BERRY',
      {{28,232,344,344},{82,205,376,437},{97,178,178,475}},
      'I catalogue the ruins from this side of the boundary. Will you test my field team?',
      'Ich katalogisiere die Ruinen von dieser Seite der Grenze aus. Prüfst du mein Feldteam?',
      'Some discoveries are instructions to stop digging.','Manche Entdeckungen sind eine Aufforderung, nicht weiterzugraben.'},
    {'CANYON','KIAN','SevenIsland_SevaultCanyon',11,55,'OPP_COOLTRAINER_M','SPRITE_COOLTRAINER_M',69,'APICOT_BERRY',
      {{68,214,214,448},{112,208,306,306},{115,217,289,450}},
      'I carry supplies to the canyon camp. Our team must be ready for a long return journey.',
      'Ich trage Vorrat zum Canyon-Lager. Unser Team muss für einen langen Rückweg bereit sein.',
      'You planned beyond the first exchange. The expedition needs that.','Du hast über den ersten Schlag hinaus geplant. Das braucht die Expedition.'},
    {'TOWER','ELIN','SevenIsland_TrainerTower',50,27,'OPP_COOLTRAINER_F','SPRITE_COOLTRAINER_F',70,'CHOICE_BAND',
      {{59,229,359,359},{131,181,350,350},{65,196,282,468}},
      'I train by the tower while the island teams are away. A Champion is a welcome opponent.',
      'Ich trainiere am Turm, solange die Inselteams unterwegs sind. Ein Champ ist ein willkommener Gegner.',
      'Keep exploring. There is more to these islands than any scorecard.','Erkunde weiter. Diese Inseln sind mehr als jede Ergebnisliste.'},
  }
  local function epoch(game)local r=opts.generationRules.peek(game);return r and r.activeEpoch or 1 end
  local function near(game,row)
    local ow=game and game.overworld;local p=ow and ow.player
    return row and ow and ow.map and p and ow.map.id==row.map and math.abs(p.cellX-row.x)+math.abs(p.cellY-row.y)==1
  end
  local function menuLevels(game,row)
    local boost=T.rematchBoost(row.id)
    local first=math.min(100,(S.scaling and S.scaling.trainer(game,row.level,false)or row.level)+boost)
    local ace=math.min(100,(S.scaling and S.scaling.trainer(game,row.level+2,true)or row.level+2)+boost)
    if opts.difficulty then
      local badges=opts.difficulty.progressBadges(game)
      first=opts.difficulty.adjustLevel(first,'trainer',badges)
      ace=opts.difficulty.adjustLevel(ace,'trainer',badges)
    end
    return 'Lv '..first..'-'..ace
  end
  function T.record(id)local s=S.state();return s.trainers and s.trainers[id]or{}end
  function T.remaining(id)
    local clock=mod.exports and mod.exports.trainerStepClock
    local ready=T.record(id).readyAt
    return ready and clock and math.max(0,ready-clock())or 0
  end
  function T.rematchBoost(id)
    local record=T.record(id)
    if not record.won then return 0 end
    local configured=mod.options and mod.options.get and mod.options:get('level_gain')
    local gain=math.max(0,math.min(20,math.floor(tonumber(configured)or 2)))
    return math.min(99,(math.max(0,math.floor(tonumber(record.rematches)or 0))+1)*gain)
  end
  function T.team(game,row)
    local out={};local owner=opts.backendSpecies();local e=math.max(1,math.min(4,epoch(game)))
    local boost=T.rematchBoost(row.id)
    for i,slot in ipairs(row.slots)do
      local species=owner and owner.byKey['dex:'..slot[e]]
      if not species or not game.data.pokemon[species]then return nil,'species-unavailable'end
      local authored=row.level+(i==3 and 2 or 0)
      out[#out+1]={species=species,level=math.min(100,
        (S.scaling and S.scaling.trainer(game,authored,i==3)or authored)+boost)}
    end
    return out
  end
  function T.claim(game,id)
    local row=T.byId[id];if not S.unlocked(game)or not near(game,row)then return false,'not-at-trainer'end
    local s=S.state();local record=s.trainers and s.trainers[id]
    if not record or not record.won then return false,'not-won'end
    if record.claimed then return false,'already-claimed'end
    local def=game.data.items[row.reward];local ready=def and def.kascEquipmentRewardEpochs
    if not ready or ready[epoch(game)]~=true then return false,'profile-required'end
    if not require('src.inventory.Bag').add(game.save,row.reward,1,game.data)then return false,'bag-full'end
    record.claimed=true;record.item=row.reward;S.persist(s);return true
  end
  local function rewardText(game,row)
    local ok,why=T.claim(game,row.id)
    if ok then return tr('Your reward: ','Deine Belohnung: ')..
      (row.rewardEn and tr(row.rewardEn,row.rewardDe)or game.data.items[row.reward].name:gsub('_',' '))..'!'
    elseif why=='bag-full'then return tr('Make room in your Bag. I will keep your reward here.',
      'Schaffe Platz im Beutel. Ich bewahre deine Belohnung hier auf.')
    elseif why=='profile-required'then return tr('Your reward is reserved. It needs a compatible generation profile.',
      'Deine Belohnung ist reserviert. Sie braucht ein passendes Generationsprofil.')end
    return tr(row.afterEn,row.afterDe)
  end
  local building={};local active=setmetatable({},{__mode='k'})
  function T.start(game,id)
    local row=T.byId[id]
    if not S.unlocked(game)or not near(game,row)then return false,'not-at-trainer'end
    if active[game]then
      for _,state in ipairs(game.stack.states or{})do if state==active[game]then return false,'battle-active'end end
      -- Loading a different save discards the old stack without invoking
      -- that battle's finish callback. Do not retain a stale local lock.
      active[game]=nil
    end
    if game.stack:top()~=game.overworld then return false,'not-in-overworld'end
    if T.remaining(id)>0 then return false,'resting'end
    if row.requiredId and not T.record(row.requiredId).won then return false,'previous-floor-required'end
    local healthy=false;for _,mon in ipairs(game.save.party or{})do if (mon.hp or 0)>0 and not mon.isEgg and not mon.egg and not mon.eggSpecies then healthy=true end end
    if not healthy then return false,'no-healthy-party'end
    local previous=T.record(id)
    local rematch=previous.won==true
    local team,why=T.team(game,row);if not team then return false,why end
    building[row.class]=team
    local ok,battle=pcall(require('src.battle.BattleState').newTrainer,game,row.class,1)
    building[row.class]=nil
    if not ok then error(battle,0)end
    active[game]=battle;battle.seviiTrainerKey=id
    if row.doubleArena then
      battle.seviiDoubleArena=row.doubleArena
      if S.doubleVisualReady(game) and opts.doubleBattle then
        local ready=opts.doubleBattle.canAttach(battle,game,row.doubleArena)
        if not ready then
          active[game]=nil
          return false,'two-pokemon-required'
        end
        opts.doubleView.translate=tr
        local attached,reason=opts.doubleBattle.attach(
          battle,game,row.doubleArena,opts.doubleView)
        if not attached then
          active[game]=nil
          return false,reason
        end
      end
    end
    if rematch then
      battle.rematch=true
      battle.rematchTrainerKey='SEVII:'..id
      battle.rematchTrainerClass=row.class
      battle.rematchNumber=(tonumber(previous.rematches)or 0)+1
    end
    battle.endBattleText=tr(row.afterEn,row.afterDe)
    local finished=false
    battle.onFinish=function(result)
      if finished then return end;finished=true;active[game]=nil
      local s
      if result=='win'or rematch then
        s=S.state();s.trainers=s.trainers or{};s.trainers[id]=s.trainers[id]or{}
        if result=='win'then
          if s.trainers[id].won then
            s.trainers[id].rematches=math.max(0,math.floor(tonumber(s.trainers[id].rematches)or 0))+1
          end
          s.trainers[id].won=true
        end
        local clock=mod.exports and mod.exports.trainerStepClock
        local range=mod.exports and mod.exports.configuredRematchRestRange
        if clock and range then
          local minimum,maximum=range()
          local random=love and love.math and love.math.random or math.random
          s.trainers[id].readyAt=clock()+random(minimum,maximum)
        end
        S.persist(s)
      end
      local extras={}
      if result=='win'and rematch then
        for _,owner in ipairs({'fieldTech','explorationDevice','rematchRewards',
            'johtoResearch','shinySystem'})do
          local controller=mod.exports and mod.exports[owner]
          local call=controller and (controller.afterRematch or controller.afterWin)
          if call then
            local message
            if owner=='rematchRewards'then message=call(game,battle,s.trainers[id])
            else message=call(game,battle)end
            if type(message)=='string'and message~=''then extras[#extras+1]=message end
          end
        end
        S.persist(s)
      end
      game.overworld:afterBattle(result,battle)
      if result=='win'then
        if rematch then
          if #extras>0 then ui.box(game,table.concat(extras,'\f'))end
        else ui.box(game,rewardText(game,row))end
      end
    end
    game.overworld:pushBattle(battle);return true,battle
  end
  function T.register(r,extra)
    local row={id=r[1],name=r[2],source=r[3],level=r[8],reward=r[9],slots=r[10],
      introEn=r[11],introDe=r[12],afterEn=r[13],afterDe=r[14],class='OPP_KA_SEVII_'..r[1]}
    assert(not T.byId[row.id],'duplicate Sevii trainer '..row.id)
    row.requiredId=extra and extra.requiredId;row.group=extra and extra.group
    row.map,row.x,row.y=S.location(row.source,r[4],r[5]);assert(row.map,'trainer map '..row.id)
    if S.doubleArenas then row.doubleArena=S.doubleArenas.find(S,row)end
    for _,n in ipairs(S.maps[row.map].objects)do assert(n.x~=row.x or n.y~=row.y,'occupied trainer '..row.id)end
    for _,w in ipairs(S.links[row.map])do assert(math.abs(w.x-row.x)+math.abs(w.y-row.y)>1,'trainer at door '..row.id)end
    row.npc='KA_SEVII_TRAINER_'..row.id;ui.npc(row.map,row.npc,r[7],row.npc,row.x,row.y)
    local base=assert(mod.content.trainers:get(r[6]),'trainer portrait '..r[6])
    local occupied={};for _,def in mod.content.trainers:each()do if def.index~=nil then occupied[def.index]=true end end
    local index;for n=200,255 do if not occupied[n]then index=n;break end end
    assert(index,'Sevii trainer class capacity exhausted')
    local aiClass=base.aiClass or r[6]
    if not mod.content.ai_classes or not mod.content.ai_classes:get(aiClass)then aiClass=nil end
    mod.content.trainers:register(row.class,{id=row.class,index=index,name=row.name,pic=base.pic,
      aiMods={1,2,3},aiClass=aiClass,baseMoney=15,parties={{{species='PIDGEOT',level=row.level}}}})
    if not row.group then T.rows[#T.rows+1]=row end
    T.allRows[#T.allRows+1]=row;T.byId[row.id]=row;T.byClass[row.class]=row
    ui.talks[row.npc]=function(game,ow,n,done)
      if not S.unlocked(game)then ui.box(game,tr('Come back after the Pokemon League.','Komm nach der Pokemon-Liga wieder.'),done);return true end
      if row.requiredId and not T.record(row.requiredId).won then
        ui.box(game,tr('Finish the previous tower floor first. Your victories remain recorded when you leave or lose.',
          'Besiege zuerst den Trainer auf der vorigen Turmetage. Deine Siege bleiben auch nach einer Pause oder Niederlage erhalten.'),done);return true
      end
      local won=T.record(row.id).won
      local function openMenu()
        local rewards=mod.exports and mod.exports.rematchRewards
        if won and rewards and rewards.hasPending(game,T.record(row.id))then
          local s=S.state();local record=s.trainers and s.trainers[row.id]
          local message=rewards.deliverPending(game,record)
          S.persist(s)
          if message then ui.box(game,message,done);return end
        end
        local remaining=T.remaining(row.id)
        if remaining>0 then
          ui.box(game,tr('I am training for our next match. Come back after ',
            'Ich trainiere für unseren nächsten Kampf. Komm in ')..remaining..
            tr(' more steps.',' Schritten wieder.'),done)
          return
        end
        local menu=ui.menu.new(game,row.name,{
        {label=won and tr('REMATCH','REVANCHE')or tr('CHALLENGE','HERAUSFORDERN'),
          value='battle',right=menuLevels(game,row),
          help=won and tr('Let us see how much our teams have grown.','Mal sehen, wie sehr unsere Teams gewachsen sind.')
            or tr(row.introEn,row.introDe)},
        {label=tr('NOT NOW','SPÄTER'),value='leave',help=tr('You can return at any time.','Du kannst jederzeit wiederkommen.')},
      },{onChoose=function(choice,list)
        list:close();if done then done()end
        if choice.value=='battle'then local ok,reason=T.start(game,row.id)
          if not ok then
            local message=reason=='two-pokemon-required'
              and tr('Bring two Pokemon ready to battle. Then we can fight as pairs.',
                'Bring zwei kampfbereite Pokemon mit. Dann treten wir als Paare an.')
              or tr('Rest your team and check your generation profile before challenging me.',
                'Erhole dein Team und prüfe dein Generationsprofil, bevor du mich herausforderst.')
            ui.box(game,message)
          end
        end
      end,onCancel=done})
      menu.__vascHeaderLabel=row.group=='tower'and tr('TRAINER TOWER','TRAINERTURM')or tr('ISLAND MATCH','INSELKAMPF')
        game.stack:push(menu)
      end
      if won and not T.record(row.id).claimed then
        ui.box(game,rewardText(game,row),openMenu)
      else openMenu()end
      return true
    end
    return row
  end
  for _,r in ipairs(rows)do T.register(r)end
  -- A scoped roster supply uses the native constructor without rewriting
  -- another trainer's registry or granting generic rematch rewards.
  mod.hooks:wrap('trainer.party',function(nextParty,class,index,party,...)
    if building[class]then return copy(building[class])end
    return nextParty(class,index,party,...)
  end,1000000)
  return T
end
