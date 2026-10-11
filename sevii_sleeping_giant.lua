-- Tanoby's counterweights tell the three Regis' story without demanding
-- their capture. One authored Regigigas encounter replaces its Rocket lead.
return function(S,ui)
  local G={KEY='sleepingGiant',sites={}};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box
  local initial={4,4,2}
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[G.KEY]=s.mysteries[G.KEY]or{}
    return s,s.mysteries[G.KEY]
  end
  function G.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked giant site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied giant site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'giant site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_GIANT_'..id};G.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);return p
  end
  add('RHEA','SevenIsland_SevaultCanyon_House',8,6,'SPRITE_SCIENTIST')
  add('ROCK','SevenIsland_TanobyRuins_LiptooChamber',11,6,'SPRITE_BOULDER')
  add('ICE','SevenIsland_TanobyRuins_WeepthChamber',11,6,'SPRITE_BOULDER')
  add('STEEL','SevenIsland_TanobyRuins_ScufibChamber',11,6,'SPRITE_BOULDER')
  add('BALANCE','SevenIsland_TanobyRuins_RixyChamber',8,9,'SPRITE_POKEDEX')
  add('REGIGIGAS','SevenIsland_TanobyRuins_RixyChamber',11,6,'SPRITE_BOULDER')
  local clues={
    ROCK={'LIPTOO: The stone bearer carries twice the load of the ice bearer.',
      'LIPTOO: Der steinerne Träger hält die doppelte Last des eisigen Trägers.'},
    ICE={'WEEPTH: The ice bearer carries three times the load of the steel bearer.',
      'WEEPTH: Der eisige Träger hält die dreifache Last des stählernen Trägers.'},
    STEEL={'SCUFIB: Ten equal weights are shared among three bearers. None may be left outside the balance.',
      'SCUFIB: Zehn gleiche Gewichte verteilen sich auf drei Träger. Keines darf außerhalb der Waage bleiben.'},
  }
  local function gate(game,id)
    if not E.near(game,G.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not G.record().briefed then return false,'briefing-required'end
    return true
  end
  function G.begin(game)
    local ok,why=gate(game,'RHEA');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;q.weights={unpack(initial)};q.clues={};S.persist(s);return true
  end
  function G.read(game,id)
    if not clues[id]then return false,'unknown-inscription'end
    local ok,why=begun(game,id);if not ok then return false,why end
    local s,q=state();q.clues=q.clues or{}
    if q.clues[id]then return false,'already-read'end
    q.clues[id]=true;S.persist(s);return true
  end
  function G.weights()
    local w=G.record().weights
    if type(w)~='table'then return end
    local sum=0
    for i=1,3 do
      if type(w[i])~='number'or w[i]~=math.floor(w[i])or w[i]<0 or w[i]>10 then return end
      sum=sum+w[i]
    end
    if sum~=10 or w[4]~=nil then return end
    return {w[1],w[2],w[3]}
  end
  function G.move(game,from,to)
    local ok,why=begun(game,'BALANCE');if not ok then return false,why end
    local s,q=state();if q.balanced then return false,'already-balanced'end
    if not(from==1 or from==2 or from==3)or not(to==1 or to==2 or to==3)or from==to then return false,'invalid-transfer'end
    local w=G.weights();if not w then return false,'reset-required'end
    if w[from]==0 then return false,'empty-tray'end
    w[from]=w[from]-1;w[to]=w[to]+1;q.weights=w;S.persist(s);return true
  end
  function G.reset(game)
    local ok,why=begun(game,'BALANCE');if not ok then return false,why end
    local s,q=state();if q.balanced then return false,'already-balanced'end
    q.weights={unpack(initial)};S.persist(s);return true
  end
  function G.balance(game)
    local ok,why=begun(game,'BALANCE');if not ok then return false,why end
    local s,q=state();if q.balanced then return false,'already-balanced'end
    for id in pairs(clues)do if not(q.clues and q.clues[id])then return false,'inscriptions-required'end end
    local w=G.weights();if not w then return false,'reset-required'end
    if w[1]~=w[2]*2 or w[2]~=w[3]*3 then return false,'unbalanced'end
    q.balanced=true;S.persist(s);return true
  end
  function G.report(game)
    local ok,why=begun(game,'RHEA');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not q.balanced then return false,'balance-required'end
    q.complete=true;q.title='SEVII_SLEEPING_GIANT';S.persist(s);return true
  end
  E.register('REGIGIGAS',{dex=486,level=75,site=G.sites.REGIGIGAS,owner='sevii_sleeping_giant.lua',
    ready=function()return G.record().complete==true end})
  G.guardians={REGIROCK='ROCK',REGICE='ICE',REGISTEEL='STEEL'}
  function G.guardianReady(game,id)
    if not G.guardians[id]or not G.record().complete then return false,'trial-required'end
    -- Tanoby's inscriptions and balance puzzle are now the current-run
    -- trial. The original sanctuaries are closed; Hoenn research remains.
    local old=ui.sanctums
    if not(old and type(old.researchEligible)=='function')then
      return false,'sanctuary-unavailable'
    end
    if not old.researchEligible(game)then return false,'sanctuary-access-required'end
    return true
  end
  for id,site in pairs(G.guardians)do
    local species=id
    local dex=({REGIROCK=377,REGICE=378,REGISTEEL=379})[id]
    E.register(id,{dex=dex,level=65,site=G.sites[site],owner='sevii_sleeping_giant.lua',
      ready=function(game)return G.guardianReady(game,species)end})
  end
  function G.journal()
    local q=G.record()
    if not q.briefed then return tr('THE SLEEPING GIANT: Visit RHEA in the Sevault Canyon house on SEVEN ISLAND after the expedition. The Tanoby stones are still trembling.',
      'DER SCHLAFENDE RIESE: Besuche nach der Expedition RHEA im Haus des Sevault-Canyons auf EILAND SIEBEN. Die Tanoby-Steine zittern noch.')end
    if q.complete then return tr('THE SLEEPING GIANT COMPLETE: The counterweights hold the ruins steady. The former sanctuaries are closed. With the Hoenn Dex, the three unique guardians answer only here: REGIROCK in LIPTOO, REGICE in WEEPTH and REGISTEEL in SCUFIB. REGIGIGAS may be approached at the stone in RIXY CHAMBER. Earlier ownership prevents another specimen.',
      'DER SCHLAFENDE RIESE ABGESCHLOSSEN: Die Gegengewichte halten die Ruinen ruhig. Die alten Heiligtümer sind geschlossen. Mit dem Hoenn-Dex antworten die drei einzigartigen Hüter nur hier: REGIROCK in LIPTOO, REGICE in WEEPTH und REGISTEEL in SCUFIB. REGIGIGAS wartet am Stein der RIXY-KAMMER. Früherer Besitz verhindert ein zweites Exemplar.')end
    if q.balanced then return tr('The ruins are steady. Report the restored balance to RHEA in the Sevault Canyon house before returning to the giant\'s stone.',
      'Die Ruinen ruhen. Berichte RHEA im Haus des Sevault-Canyons vom Gleichgewicht, bevor du zum Stein des Riesen zurückkehrst.')end
    local lines={tr('RHEA: Copy the three inscriptions in LIPTOO, WEEPTH and SCUFIB, then adjust the balance in RIXY. These are the second, third, fifth and sixth Tanoby chambers from the east.',
      'RHEA: Kopiere die Inschriften in LIPTOO, WEEPTH und SCUFIB. Stelle danach die Waage in RIXY ein. Das sind die zweite, dritte, fünfte und sechste Tanoby-Kammer von Osten.')}
    for _,id in ipairs{'ROCK','ICE','STEEL'}do
      if q.clues and q.clues[id]then lines[#lines+1]=tr(clues[id][1],clues[id][2])end
    end
    lines[#lines+1]=tr('The control moves one weight at a time. CHECK tests the balance; RESET restores 4 / 4 / 2. Your inscriptions and partial arrangement survive saving.',
      'Die Steuerung verschiebt je ein Gewicht. PRÜFEN testet die Waage; RESET stellt 4 / 4 / 2 wieder her. Inschriften und Teilanordnung bleiben beim Speichern erhalten.')
    return table.concat(lines,'\n\n')
  end
  local function explain(why)
    local messages={
      ['sanctuary-unavailable']={'The original sanctuary records are unavailable. No guardian can be summoned.',
        'Die Aufzeichnungen der ursprünglichen Heiligtümer sind nicht erreichbar. Kein Hüter kann gerufen werden.'},
      ['sanctuary-access-required']={'The guardians require Hoenn research and the Hoenn Dex. Their former sanctuaries are closed.',
        'Die Hüter setzen die Hoenn-Forschung und den Hoenn-Dex voraus. Ihre alten Heiligtümer sind geschlossen.'},
      ['legend_owned']={'Your records already attest to REGIGIGAS, including earlier Rocket rescues. The old stone honours that bond; no second giant appears. The restored ruins remain safe.',
        'Deine Aufzeichnungen belegen REGIGIGAS bereits, auch aus früheren Rocket-Rettungen. Der alte Stein ehrt diese Bindung; kein zweiter Riese erscheint. Die wiederhergestellten Ruinen bleiben sicher.'},
      ['generation-profile']={'This encounter needs a generation profile including this Pokemon. Your research remains recorded.',
        'Diese Begegnung braucht ein Generationsprofil mit diesem Pokemon. Deine Forschung bleibt vermerkt.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.','Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
      ['empty-tray']={'That tray is empty. Move a weight from another tray.','Diese Schale ist leer. Verschiebe ein Gewicht aus einer anderen Schale.'},
      ['unbalanced']={'The beam tilts. Compare the copied inscriptions; your current arrangement is kept.','Der Balken kippt. Vergleiche die kopierten Inschriften; deine Anordnung bleibt erhalten.'},
      ['reset-required']={'The scales are jammed. Use RESET to restore the starting arrangement.','Die Waage klemmt. Stelle mit RESET die Ausgangsanordnung wieder her.'},
      ['inscriptions-required']={'Copy all three inscriptions before testing the old mechanism.','Kopiere alle drei Inschriften, bevor du den alten Mechanismus prüfst.'},
    }
    local row=messages[why];return row and tr(row[1],row[2])or G.journal()
  end
  local transfers={{2,1,'ICE TO ROCK','EIS ZU STEIN'},{3,1,'STEEL TO ROCK','STAHL ZU STEIN'},
    {1,2,'ROCK TO ICE','STEIN ZU EIS'},{1,3,'ROCK TO STEEL','STEIN ZU STAHL'},
    {2,3,'ICE TO STEEL','EIS ZU STAHL'},{3,2,'STEEL TO ICE','STAHL ZU EIS'}}
  local controls
  controls=function(game,done)
    local w=G.weights();local title=w and table.concat(w,' : ')or'---'
    local rows={{value='check',label=tr('CHECK','PRÜFEN')}}
    for i,r in ipairs(transfers)do rows[#rows+1]={value='move'..i,label=tr(r[3],r[4])}end
    rows[#rows+1]={value='reset',label='RESET'};rows[#rows+1]={value='leave',label=tr('LATER','SPÄTER')}
    local panel=ui.menu.new(game,title,rows,{onCancel=done,onChoose=function(choice,list)
      list:close();local id=choice.value
      if id=='leave'then if done then done()end;return end
      local ok,why
      if id=='check'then
        ok,why=G.balance(game)
        if ok then box(game,tr('The beam settles. A deep pulse answers beneath the stone. The old mechanism carries the load that the reliefs attribute to the giant. The chamber falls quiet. Report to RHEA.',
          'Der Balken ruht. Ein tiefer Puls antwortet unter dem Stein. Der alte Mechanismus trägt wieder die Last, die das Relief dem Riesen zuschreibt. Die Kammer wird ruhig. Berichte RHEA.'),done);return end
      elseif id=='reset'then ok,why=G.reset(game)
      else local index=tonumber(id:match('^move(%d)$'));local r=index and transfers[index]
        if r then ok,why=G.move(game,r[1],r[2])end
      end
      if ok then controls(game,done)else box(game,explain(why),function()controls(game,done)end)end
    end});panel.__vascHeaderLabel=tr('ROCK ICE STEEL','STEIN EIS STAHL');game.stack:push(panel)
  end
  ui.talks[G.sites.RHEA.name]=function(game,ow,n,done)
    local ok,why=gate(game,'RHEA');if not ok then box(game,explain(why),done);return true end
    local q=G.record()
    if not q.briefed then
      G.begin(game);box(game,tr('RHEA: Even with the crossing shut, TANOBY still shakes. The old counterweights have slipped.\n\nThis relief shows Regirock, Regice and Registeel bearing the weight beside something enormous: Regigigas. Their inscriptions are in LIPTOO, WEEPTH and SCUFIB. If we read them, we may be able to set the balance right in RIXY.',
        'RHEA: Obwohl der Übergang geschlossen ist, bebt TANOBY weiter. Die alten Gegengewichte sind verrutscht.\n\nAuf diesem Relief tragen Regirock, Regice und Registeel die Last neben etwas Riesigem: Regigigas. Ihre Inschriften stehen in LIPTOO, WEEPTH und SCUFIB. Vielleicht können wir damit die Waage in RIXY wieder richten.'),done)
    elseif q.balanced and not q.complete then
      G.report(game);box(game,tr('RHEA: Feel that? The floor is still. Those old counterweights are carrying the load again.\n\nThe giant may keep sleeping, or it may answer you at the RIXY stone. The other three guardians have left their old sanctuaries behind. After your Hoenn research, look for Regirock in LIPTOO, Regice in WEEPTH and Registeel in SCUFIB.',
        'RHEA: Spürst du das? Der Boden ist still. Die alten Gegengewichte tragen die Last wieder.\n\nVielleicht schläft der Riese weiter, vielleicht antwortet er dir am RIXY-Stein. Die drei anderen Hüter haben ihre alten Heiligtümer verlassen. Nach deiner Hoenn-Forschung findest du Regirock in LIPTOO, Regice in WEEPTH und Registeel in SCUFIB.'),done)
    else box(game,G.journal(),done)end;return true
  end
  local function encounter(game,id,done)
    local localOk,reason=begun(game,G.guardians[id]or id)
    if not localOk then box(game,explain(reason),done);return true end
    local ok,why=E.availability(game,id)
    if not ok then
      local text=why=='legend_owned'and G.guardians[id]and tr(
        'Your records already attest to '..id..'. This inscription honours that bond. No second guardian appears; the research is complete.',
        'Deine Aufzeichnungen belegen '..id..' bereits. Diese Inschrift ehrt die Bindung. Kein zweiter Hüter erscheint; die Forschung ist abgeschlossen.')or explain(why)
      box(game,text,done);return true
    end
    local panel=ui.menu.new(game,id,{
      {value='battle',label=tr('APPROACH','NÄHERN'),right='Lv '..E.level(game,id)},
      {value='leave',label=tr('LATER','SPÄTER')},
    },{onCancel=done,onChoose=function(choice,list)
      list:close();if done then done()end
      if choice.value=='battle'then local started,err=E.start(game,id);if not started then box(game,explain(err))end end
    end});panel.__vascHeaderLabel=tr('TANOBY GUARDIANS','TANOBY-HÜTER');game.stack:push(panel);return true
  end
  ui.talks[G.sites.REGIGIGAS.name]=function(game,ow,n,done)return encounter(game,'REGIGIGAS',done)end
  for _,id in ipairs{'ROCK','ICE','STEEL'}do local site=id
    ui.talks[G.sites[site].name]=function(game,ow,n,done)
      if G.record().complete then
        for species,key in pairs(G.guardians)do if key==site then return encounter(game,species,done)end end
      end
      local ok,why=G.read(game,site)
      box(game,(ok or why=='already-read')and tr(clues[site][1],clues[site][2])or explain(why),done);return true
    end
  end
  ui.talks[G.sites.BALANCE.name]=function(game,ow,n,done)
    local ok,why=begun(game,'BALANCE')
    if not ok then box(game,explain(why),done)
    elseif G.record().balanced then box(game,G.journal(),done)
    else controls(game,done)end;return true
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..G.journal()end;return text
  end
  return G
end
