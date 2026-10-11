-- Post-expedition mysteries. Capture authority is an exact live battle,
-- never a serializable flag or a general exception for a species/map.
return function(S,ui,opts)
  local M={sites={},LEVEL=70,KEY='heatran'}
  function M.level(game)return S.scaling and S.scaling.legend(game,M.LEVEL)or M.LEVEL end
  local tr,box=ui.tr,ui.box
  local active=setmetatable({},{__mode='k'})
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{}
    s.mysteries[M.KEY]=s.mysteries[M.KEY]or{readings={}}
    local q=s.mysteries[M.KEY];q.readings=q.readings or{}
    return s,q
  end
  function M.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing mystery site '..id)
    assert(S.walkable(map,lx,ly),'blocked mystery site '..id)
    for _,n in ipairs(S.maps[map].objects)do assert(n.x~=lx or n.y~=ly,'occupied mystery site '..id)end
    for _,w in ipairs(S.links[map])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'mystery obstructs door '..id)end
    M.sites[id]={map=map,x=lx,y=ly}
    ui.npc(map,'KA_SEVII_HEATRAN_'..id,sprite,'KA_SEVII_HEATRAN_'..id,lx,ly)
  end
  add('RESEARCHER','MtEmber_RubyPath_1F',22,15,'SPRITE_SCIENTIST')
  add('UPPER','MtEmber_RubyPath_1F',21,10,'SPRITE_PAPER')
  add('MIDDLE','MtEmber_RubyPath_B3F',6,14,'SPRITE_PAPER')
  add('LOWER','MtEmber_RubyPath_B5F',7,4,'SPRITE_PAPER')
  add('VENT','MtEmber_RubyPath_B5F',7,9,'SPRITE_POKEDEX')
  local function near(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return p and ow and ow.map and a and ow.map.id==p.map
      and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  function M.storyReady(game)
    if not S.unlocked(game)then return false,'league-required'end
    local s=S.state()
    if not s.expeditionComplete or not s.seviiRiftSealed then return false,'finale-required'end
    if opts.beyondKanto and not opts.beyondKanto.peekIsActive(game)then return false,'beyond-kanto-sealed'end
    return true
  end
  function M.availability(game)
    local ok,why=M.storyReady(game);if not ok then return false,why end
    local owner=opts.backendSpecies and opts.backendSpecies()
    local species=owner and owner.byKey['dex:485'];local def=species and game.data.pokemon[species]
    if not def or owner.bySpecies[species]~='dex:485'then return false,'species-unavailable'end
    if not opts.generationRules.peekSpeciesAvailable(game,species,def)then return false,'generation-profile'end
    if not S.assetsReady(species,def)then return false,'missing-art'end
    local history=S.legendPolicy and S.legendPolicy.history
    if not history then return false,'legend_history_unavailable'end
    local owned,why=(history.ownedThisRun or history.owned)(game,species)
    if owned then return false,'legend_owned'end
    if why then return false,'legend_history_unavailable'end
    return true,species
  end
  local function message(reason)
    local messages={
      ['league-required']={'The survey begins after the Pokemon League.','Die Untersuchung beginnt nach der Pokemon-Liga.'},
      ['finale-required']={'The rift is still feeding these tremors. Finish MARA\'s expedition and return after the local crossing is sealed.',
        'Der Riss speist noch diese Beben. Beende MARAS Expedition und kehre zurück, wenn der örtliche Übergang versiegelt ist.'},
      ['beyond-kanto-sealed']={'This survey needs BEYOND KANTO to be open in this journey.',
        'Diese Untersuchung setzt voraus, dass JENSEITS VON KANTO in dieser Reise geöffnet ist.'},
      ['generation-profile']={'This discovery needs a generation profile that includes Sinnoh Pokemon.',
        'Diese Entdeckung braucht ein Generationsprofil, das Sinnoh-Pokemon einschliesst.'},
      ['legend_owned']={'Your records already attest to HEATRAN. These traces belong to that unique legend; there is no second specimen waiting here.',
        'Deine Aufzeichnungen belegen HEATRAN bereits. Diese Spuren gehören zu dieser einzigartigen Legende; hier wartet kein zweites Exemplar.'},
      ['legend_history_unavailable']={'Your earlier records are unavailable. Try again once your Legacy archive and bank can be read.',
        'Deine früheren Aufzeichnungen sind nicht lesbar. Versuche es erneut, sobald Vermächtnisarchiv und Bank erreichbar sind.'},
      ['save-failed']={'The expedition could not be saved. The encounter has not begun; you can try again.',
        'Die Expedition konnte nicht gespeichert werden. Die Begegnung hat noch nicht begonnen; du kannst es erneut versuchen.'},
      ['no-healthy-party']={'Rest your team before approaching the heat source.',
        'Erhole dein Team, bevor du dich der Hitzequelle näherst.'},
    }
    local t=messages[reason]
    return t and tr(t[1],t[2])or tr('The survey is not ready. Return to the researcher at the cave entrance.',
      'Die Untersuchung ist noch nicht bereit. Kehre zur Forscherin am Höhleneingang zurück.')
  end
  function M.begin(game)
    if not near(game,M.sites.RESEARCHER)then return false,'not-at-researcher'end
    local ok,why=M.storyReady(game);if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  function M.read(game,id)
    if not ({UPPER=true,MIDDLE=true,LOWER=true})[id]or not near(game,M.sites[id])then return false,'not-at-reading'end
    local ok,why=M.storyReady(game);if not ok then return false,why end
    local s,q=state();if not q.briefed then return false,'briefing-required'end
    q.readings[id]=true;S.persist(s);return true
  end
  local order={'MIDDLE','UPPER','LOWER'}
  function M.tune(game,id)
    if not near(game,M.sites.VENT)then return false,'not-at-vent'end
    local ok,why=M.storyReady(game);if not ok then return false,why end
    local s,q=state()
    if not q.briefed or not(q.readings.UPPER and q.readings.MIDDLE and q.readings.LOWER)then return false,'readings-required'end
    if q.open then return false,'already-open'end
    if id~=order[(q.tuned or 0)+1]then
      q.tuned=0;S.persist(s);return false,'wrong-order'
    end
    q.tuned=(q.tuned or 0)+1;q.open=q.tuned==#order;S.persist(s);return true
  end
  function M.canCapture(game,battle,species)
    local a=game and active[game]
    if not a or a.battle~=battle or a.save~=game.save or a.finished
        or battle.game~=game or battle.kind~='wild' or species~=a.species
        or not battle.enemy or battle.enemy.mon.species~=a.species
        or not game.overworld or game.overworld.map.id~=M.sites.VENT.map then return false end
    local ok,resolved=M.availability(game)
    if not ok or resolved~=species then return false end
    for _,screen in ipairs(game.stack.states or{})do if screen==battle then return true end end
    return false
  end
  function M.start(game)
    if not near(game,M.sites.VENT)then return false,'not-at-vent'end
    if game.stack:top()~=game.overworld then return false,'not-in-overworld'end
    local ok,species=M.availability(game);if not ok then return false,species end
    if not M.record().open then return false,'vent-closed'end
    local healthy=false
    for _,mon in ipairs(game.save.party or{})do
      if (mon.hp or 0)>0 and not(mon.isEgg or mon.egg or mon.eggSpecies)then healthy=true end
    end
    if not healthy then return false,'no-healthy-party'end
    -- A reload can discard a previous battle without calling its callback.
    -- Revoke that runtime capability and retain only the saved puzzle state.
    if active[game]then active[game].finished=true;active[game]=nil end
    if type(game.writeSave)~='function'or game:writeSave()==false then return false,'save-failed'end
    local battle=require('src.battle.BattleState').newWild(game,species,M.level(game),{
      encounterSource='sevii-heatran',randomizerProtected=true})
    local a={battle=battle,save=game.save,species=species};active[game]=a
    battle.onFinish=function(result)
      if a.finished then return end;a.finished=true
      if active[game]==a then active[game]=nil end
      -- A discarded battle must never write to a newly adopted save.
      if game.save~=a.save then return end
      if result=='caught'and S.legendPolicy.history.owned(game,species)then
        local s,q=state();q.caught=true;S.persist(s)
      end
      game.overworld:afterBattle(result,battle)
    end
    game.overworld:pushBattle(battle);return true,battle
  end
  local clues={
    UPPER={'UPPER GAUGE: The upper vent responds only after the middle vent releases pressure. The needle is steady. Reading recorded.',
      'OBERES MANOMETER: Der obere Schlot reagiert erst, nachdem der mittlere Druck abgelassen hat. Die Nadel steht ruhig. Messung notiert.'},
    MIDDLE={'MIDDLE GAUGE: Pressure builds here first. Open the middle vent before either of the others. Reading recorded.',
      'MITTLERES MANOMETER: Hier staut sich der Druck zuerst. Öffne den mittleren Schlot vor den beiden anderen. Messung notiert.'},
    LOWER={'LOWER GAUGE: This vent must open last. Something with a metal shell moves behind the hot rock. Reading recorded.',
      'UNTERES MANOMETER: Dieser Schlot muss zuletzt geöffnet werden. Hinter dem heissen Gestein bewegt sich etwas mit einem Metallpanzer. Messung notiert.'},
  }
  function M.journal()
    local q=M.record()
    if q.caught then return tr('EMBER SURVEY: HEATRAN recorded. The pressure is balanced; no further specimen is expected.',
      'GLUTBERG-MESSUNG: HEATRAN erfasst. Der Druck ist ausgeglichen; ein weiteres Exemplar ist nicht zu erwarten.')end
    if not q.briefed then return tr('After the expedition, a researcher awaits in MT. EMBER\'s eastern cave on ONE ISLAND. Metal tracks remain after the rift closed.',
      'Nach der Expedition wartet eine Forscherin in der östlichen Höhle des GLUTBERGS auf EILAND EINS. Metallische Spuren bleiben nach dem geschlossenen Riss zurück.')end
    if q.open then return tr('The pressure is balanced; the survey is complete without a capture. HEATRAN may be approached at the lower valve panel if your records do not already attest to it. An encounter without a capture can be retried.',
      'Der Druck ist ausgeglichen; die Untersuchung ist ohne Fang abgeschlossen. Am unteren Ventilfeld kannst du HEATRAN begegnen, sofern deine Aufzeichnungen es nicht bereits belegen. Eine Begegnung ohne Fang kann wiederholt werden.')end
    return tr('Read the gauges in the entrance cave, the third basement and the deepest chamber. Their notes give the valve order. Use the panel in the deepest chamber.',
      'Lies die Manometer in der Eingangshöhle, im dritten Untergeschoss und in der tiefsten Kammer. Ihre Notizen verraten die Ventilfolge. Bediene das Ventilfeld in der tiefsten Kammer.')
  end
  local function menu(game,done)
    local q=M.record();local rows={}
    if q.open then
      rows[1]={label=tr('APPROACH HEATRAN','HEATRAN NÄHERN'),value='BATTLE',right='Lv '..M.level(game)}
    else
      for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do
        local names={UPPER=tr('UPPER VENT','OBERER SCHLOT'),MIDDLE=tr('MIDDLE VENT','MITTLERER SCHLOT'),LOWER=tr('LOWER VENT','UNTERER SCHLOT')}
        rows[#rows+1]={label=names[id],value=id}
      end
    end
    rows[#rows+1]={label=tr('FIELD NOTES','MESSNOTIZEN'),value='NOTES'}
    rows[#rows+1]={label=tr('LEAVE','VERLASSEN'),value='LEAVE'}
    local panel=ui.menu.new(game,tr('EMBER PRESSURE','GLUTBERG-DRUCK')..' '..(q.tuned or 0)..'/3',rows,{
      onCancel=done,onChoose=function(choice,list)
        list:close()
        if choice.value=='LEAVE'then if done then done()end;return end
        if choice.value=='BATTLE'then
          if done then done()end
          local ok,why=M.start(game);if not ok then box(game,message(why))end
          return
        end
        if choice.value=='NOTES'then
          local notes={M.journal()}
          for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do if q.readings[id]then notes[#notes+1]=tr(clues[id][1],clues[id][2])end end
          box(game,table.concat(notes,'\n\n'),function()menu(game,done)end);return
        end
        local ok,why=M.tune(game,choice.value)
        local text=ok and(M.record().open and tr('The rock cools enough to pass. HEATRAN\'s deep call echoes from the fissure. You may prepare before approaching.',
          'Das Gestein kühlt ab und gibt den Weg frei. HEATRANS tiefer Ruf hallt aus der Spalte. Du kannst dich vorbereiten, bevor du dich näherst.')or tr('The pressure drops. Choose the next vent.',
          'Der Druck sinkt. Wähle den nächsten Schlot.'))or(why=='wrong-order'and tr('The safety valve closes all three vents. Nobody is hurt. Read your notes and start again.',
          'Das Sicherheitsventil schließt alle drei Schlote. Niemand wird verletzt. Lies die Notizen und beginne erneut.')or message(why))
        box(game,text,function()menu(game,done)end)
      end})
    panel.__vascHeaderLabel=tr('EMBER MYSTERY','GLUTBERG-MYSTERIUM');game.stack:push(panel)
  end
  ui.talks.KA_SEVII_HEATRAN_RESEARCHER=function(game,ow,n,done)
    local ok,why=M.storyReady(game)
    if not ok then box(game,message(why),done)
    elseif M.record().briefed then box(game,M.journal(),done)
    else
      M.begin(game)
      box(game,tr('INA: See these tracks? They are fresh, and the rock beneath them is still warm. Heatran may have found its way into the mountain.\n\nI set three gauges along the old pipes: one here, one three floors down, and one in the deepest chamber. Read them before you touch the vent panel below. If we ease the pressure, whatever is down there can breathe.',
        'INA: Siehst du die Spuren? Sie sind frisch, und der Fels darunter ist noch warm. Vielleicht hat Heatran einen Weg in den Berg gefunden.\n\nAn den alten Rohren habe ich drei Manometer angebracht: eines hier, eines drei Stockwerke tiefer und eines in der tiefsten Kammer. Lies sie, bevor du unten die Ventile bedienst. Wenn wir den Druck senken, kann dort unten wieder etwas atmen.'),done)
    end
    return true
  end
  for id,clue in pairs(clues)do
    local siteId,text=id,clue
    ui.talks['KA_SEVII_HEATRAN_'..siteId]=function(game,ow,n,done)
      local ok,why=M.read(game,siteId)
      box(game,ok and tr(text[1],text[2])or message(why),done);return true
    end
  end
  ui.talks.KA_SEVII_HEATRAN_VENT=function(game,ow,n,done)
    local ok,why=M.storyReady(game);local q=M.record()
    if not ok then box(game,message(why),done)
    elseif not(q.readings.UPPER and q.readings.MIDDLE and q.readings.LOWER)then box(game,M.journal(),done)
    else menu(game,done)end
    return true
  end
  return M
end
