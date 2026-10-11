-- Optional capstone: seven completed acts of repair, never seven captures.
return function(S,ui)
  local A={KEY='sevenTestimonies',sites={}};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box
  A.rows={
    {key='heatran',flag='open',en='The quiet mountain',de='Der ruhige Berg'},
    {key='lakeGuardians',flag='complete',en='Three voices',de='Drei Stimmen'},
    {key='forestGarden',flag='complete',en='What grows again',de='Was wieder wächst'},
    {key='moonlitNight',flag='complete',en='A peaceful night',de='Eine friedliche Nacht'},
    {key='tidalReturn',flag='complete',en='A safe journey home',de='Ein sicherer Heimweg'},
    {key='timeSpace',flag='complete',en='Rhythm and boundary',de='Takt und Grenze'},
    {key='sleepingGiant',flag='complete',en='The steady ruins',de='Die ruhenden Ruinen'},
  }
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[A.KEY]=s.mysteries[A.KEY]or{}
    return s,s.mysteries[A.KEY]
  end
  function A.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked testimony site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied testimony site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'testimony site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_TESTIMONY_'..id};A.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);return p
  end
  add('SORA','SevenIsland_House_Room2',8,6,'SPRITE_SCIENTIST')
  for i,prefix in ipairs{'One','Two','Three','Four','Five','Six','Seven'}do
    add('BOOK_'..i,prefix..'Island_PokemonCenter_2F',8,6,'SPRITE_PAPER')
  end
  add('ARCEUS','SevenIsland_TanobyRuins_MoneanChamber',6,8,'SPRITE_BOULDER')
  local function gate(game,id)
    if not E.near(game,A.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not A.record().briefed then return false,'briefing-required'end
    return true
  end
  function A.sourceReady(index)
    local r=A.rows[index];if not r then return false end
    local s=S.state();local q=s.mysteries and s.mysteries[r.key]
    return type(q)=='table'and q[r.flag]==true
  end
  function A.begin(game)
    local ok,why=gate(game,'SORA');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;q.pages={};S.persist(s);return true
  end
  function A.collect(game,index)
    if not A.rows[index]then return false,'unknown-report'end
    local ok,why=begun(game,'BOOK_'..index);if not ok then return false,why end
    local s,q=state();q.pages=q.pages or{}
    if q.pages[tostring(index)]then return false,'already-copied'end
    if not A.sourceReady(index)then return false,'research-required'end
    q.pages[tostring(index)]=true;S.persist(s);return true
  end
  function A.compile(game)
    local ok,why=begun(game,'SORA');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    for i=1,7 do if not(q.pages and q.pages[tostring(i)])then return false,'pages-required'end end
    q.complete=true;q.title='SEVII_SEVEN_TESTIMONIES';S.persist(s);return true
  end
  function A.witness(game)
    local ok,why=begun(game,'ARCEUS');if not ok then return false,why end
    local s,q=state();if not q.complete then return false,'book-required'end
    if q.witnessed then return false,'already-witnessed'end
    q.witnessed=true;S.persist(s);return true
  end
  E.register('ARCEUS',{dex=493,level=80,site=A.sites.ARCEUS,owner='sevii_seven_testimonies.lua',
    ready=function()local q=A.record();return q.complete==true and q.witnessed==true end})
  function A.journal()
    local q=A.record()
    if not q.briefed then return tr('SEVEN TESTIMONIES: After the expedition, visit SORA in the back room of SEVEN ISLAND\'s village house. She is collecting the islands\' recovery reports.',
      'SIEBEN ZEUGNISSE: Besuche nach der Expedition SORA im Hinterzimmer des Wohnhauses auf EILAND SIEBEN. Sie sammelt Berichte über die Erholung der Inseln.')end
    if q.complete then return tr('SEVEN TESTIMONIES COMPLETE: The island book records seven acts of repair without requiring any legendary capture. Read it at the stone in MONEAN CHAMBER, the easternmost Tanoby chamber. ARCEUS may answer there. An earlier owner receives no second specimen. The local crossing stays sealed; GIRATINA remains beyond it.',
      'SIEBEN ZEUGNISSE ABGESCHLOSSEN: Das Inselbuch bewahrt sieben wiederhergestellte Dinge, ohne einen legendären Fang zu verlangen. Lies es am Stein in der MONEAN-KAMMER, der östlichsten Tanoby-Kammer. Dort kann ARCEUS antworten. Früherer Besitz erlaubt kein zweites Exemplar. Der örtliche Übergang bleibt versiegelt; GIRATINA bleibt dahinter.')end
    local lines={tr('The field offices exchanged their reports by ferry. Find one bound report upstairs in each island Pokemon Center. Copy it after completing its research, then bring all seven to SORA. No report requires capturing a Pokemon.',
      'Die Feldbüros haben ihre Berichte per Fähre ausgetauscht. Im Obergeschoss jedes Insel-Pokemon-Centers liegt ein gebundener Bericht. Kopiere ihn nach Abschluss seiner Forschung und bring alle sieben zu SORA. Kein Bericht verlangt einen Pokemon-Fang.')}
    for i,r in ipairs(A.rows)do
      local status=q.pages and q.pages[tostring(i)]and tr('COPIED','KOPIERT')or(A.sourceReady(i)and tr('READY TO COPY','BEREIT ZUM KOPIEREN')or tr('RESEARCH OPEN','FORSCHUNG OFFEN'))
      lines[#lines+1]=tr('ISLAND ','EILAND ')..i..': '..tr(r.en,r.de)..' - '..status
    end
    return table.concat(lines,'\n\n')
  end
  local function explain(why)
    local rows={
      ['legend_owned']={'Your records already attest to ARCEUS. The stone honours that bond; it does not create a second specimen. The island book remains complete.',
        'Deine Aufzeichnungen belegen ARCEUS bereits. Der Stein ehrt diese Bindung; er erzeugt kein zweites Exemplar. Das Inselbuch bleibt vollständig.'},
      ['generation-profile']={'This encounter needs a generation profile including Sinnoh Pokemon. The island book is preserved.',
        'Diese Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Das Inselbuch bleibt erhalten.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.','Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
    }
    local r=rows[why];return r and tr(r[1],r[2])or A.journal()
  end
  ui.talks[A.sites.SORA.name]=function(game,ow,n,done)
    local ok,why=gate(game,'SORA');if not ok then box(game,explain(why),done);return true end
    local q=A.record()
    if not q.briefed then
      A.begin(game);box(game,tr('SORA: The crossing is closed, but I do not want the children to remember only the shadow. I want them to know who brought people home and cared for the islands afterwards.\n\nEach Pokemon Center keeps an account upstairs. Bring me all seven when they are ready, and I will make them into a book.',
        'SORA: Der Übergang ist geschlossen, aber die Kinder sollen sich nicht nur an den Schatten erinnern. Sie sollen wissen, wer Menschen heimgebracht und sich danach um die Inseln gekümmert hat.\n\nJedes Pokemon-Center bewahrt oben einen Bericht auf. Bring mir alle sieben, wenn sie fertig sind, dann mache ich ein Buch daraus.'),done)
    elseif not q.complete then
      local compiled,err=A.compile(game)
      box(game,compiled and tr('SORA: Seven stories. Seven islands. And people who will keep looking after them. The book is ready.\n\nThere is an inscription in MONEAN, the easternmost Tanoby chamber. It asks to hear how a world is cared for, and it names Arceus. Perhaps you should take the book there. I would like to know what answers.',
        'SORA: Sieben Geschichten. Sieben Inseln. Und Menschen, die sich weiter um sie kümmern. Das Buch ist fertig.\n\nIn MONEAN, der östlichsten Tanoby-Kammer, steht eine Inschrift. Sie fragt, wie man eine Welt behütet, und nennt Arceus. Vielleicht solltest du das Buch dorthin bringen. Ich wüsste gern, was darauf antwortet.')or explain(err),done)
    else box(game,A.journal(),done)end;return true
  end
  for i,r in ipairs(A.rows)do local index=i;local row=r
    ui.talks[A.sites['BOOK_'..i].name]=function(game,ow,n,done)
      local ok,why=A.collect(game,index)
      box(game,ok and(tr('Copied: ','Abgeschrieben: ')..tr(row.en,row.de)..'\n\n'..A.journal())or explain(why),done);return true
    end
  end
  ui.talks[A.sites.ARCEUS.name]=function(game,ow,n,done)
    local ok,why=begun(game,'ARCEUS');local q=A.record()
    if not ok or not q.complete then box(game,ok and A.journal()or explain(why),done);return true end
    if not q.witnessed then
      box(game,tr('You read the seven accounts aloud. The final page names the people who will continue the work.\n\nA pale shape stands beyond the old stone: ARCEUS. It listens. No command is given, no crossing opens. Somewhere beyond the sealed boundary, Giratina remains.\n\nThe island book is yours to keep. You may approach when ready, or leave in peace.',
        'Du liest die sieben Berichte vor. Die letzte Seite nennt die Menschen, die die Arbeit fortsetzen werden.\n\nEine helle Gestalt steht hinter dem alten Stein: ARCEUS. Es hört zu. Kein Befehl wird erteilt, kein Übergang öffnet sich. Irgendwo jenseits der versiegelten Grenze bleibt Giratina.\n\nDas Inselbuch bleibt bei dir. Du kannst dich nähern, wenn du bereit bist, oder friedlich gehen.'),function()
          A.witness(game);if done then done()end
        end);return true
    end
    ok,why=E.availability(game,'ARCEUS');if not ok then box(game,explain(why),done);return true end
    local panel=ui.menu.new(game,'ARCEUS',{{value='battle',label=tr('APPROACH','NÄHERN'),right='Lv '..E.level(game,'ARCEUS')},
      {value='leave',label=tr('LATER','SPÄTER')}},{onCancel=done,onChoose=function(choice,list)
      list:close();if done then done()end
      if choice.value=='battle'then local started,err=E.start(game,'ARCEUS');if not started then box(game,explain(err))end end
    end});panel.__vascHeaderLabel=tr('SEVEN TESTIMONIES','SIEBEN ZEUGNISSE');game.stack:push(panel);return true
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..A.journal()end;return text end
  return A
end
