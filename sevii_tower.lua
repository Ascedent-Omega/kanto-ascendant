-- Eight persistent, sequential native trainer challenges. Leaving the tower
-- or losing does not erase earned victories or pending floor prizes.
return function(S,ui)
  local C={rows={},roofReward='LUCKY_EGG'};local T=S.trainers;local tr=ui.tr
  local rewardNames={{'Black Glasses','Schwarzglas'},{'Soft Sand','Pudersand'},
    {'Magnet','Magnet'},{'Never-Melt Ice','Ewiges Eis'},{'Focus Band','Fokus-Band'},
    {'Scope Lens','Scope-Linse'},{'Leftovers','Überreste'},{'Light Ball','Kugelblitz'}}
  local floors={
    {'NORA','BLACKGLASSES',{{42,169,169,430},{53,197,262,461},{94,94,359,442}},
      'Read the opponent before choosing your move.','Lies deinen Gegner, bevor du eine Attacke wählst.'},
    {'OLE','SOFT_SAND',{{28,232,330,450},{51,208,344,472},{112,112,260,464}},
      'An immunity can turn a battle.','Eine Immunität kann einen Kampf wenden.'},
    {'JARA','MAGNET',{{26,181,310,405},{101,171,171,462},{125,125,82,466}},
      'Speed alone does not decide every turn.','Tempo allein entscheidet nicht jede Runde.'},
    {'SVEN','NEVERMELTICE',{{87,221,365,473},{91,225,362,478},{124,124,364,460}},
      'Cover your weaknesses before climbing higher.','Decke deine Schwächen ab, bevor du höher steigst.'},
    {'IDA','FOCUS_BAND',{{68,214,297,448},{106,237,308,475},{107,210,286,454}},
      'A partner can still stand after a difficult turn.','Ein Partner kann auch nach einer schweren Runde noch stehen.'},
    {'MALTE','SCOPE_LENS',{{123,212,348,469},{83,198,359,430},{127,214,373,445}},
      'A balanced team can answer an unexpected hit.','Ein ausgewogenes Team kann auf einen unerwarteten Treffer antworten.'},
    {'RIEKE','LEFTOVERS',{{80,199,350,423},{113,242,272,468},{143,143,365,450}},
      'Plan for the next turn as well as this one.','Plane die nächste Runde genauso wie diese.'},
    {'ENNO','LIGHT_BALL',{{25,25,25,25},{59,248,376,395},{149,149,373,445}},
      'This last match honours the partners who brought you here.','Dieser letzte Kampf ehrt die Partner, die dich hierher gebracht haben.'},
  }
  for i,f in ipairs(floors)do
    local row=T.register({'TOWER_'..i,f[1],'TrainerTower_'..i..'F',6,12,
      i%2==1 and'OPP_COOLTRAINER_F'or'OPP_COOLTRAINER_M',
      i%2==1 and'SPRITE_COOLTRAINER_F'or'SPRITE_COOLTRAINER_M',66+i*2,f[2],f[3],
      f[4],f[5],
      i==8 and'The eight floors are cleared. Meet the recorder on the roof.'or'This floor is cleared. Rest if you need to, then continue upstairs.',
      i==8 and'Alle acht Etagen sind bestanden. Triff die Protokollantin auf dem Dach.'or'Diese Etage ist bestanden. Ruhe dich bei Bedarf aus und steige dann weiter hinauf.'},
      {group='tower',requiredId=i>1 and'TOWER_'..(i-1)or nil})
    row.floor=i;row.rewardEn=rewardNames[i][1];row.rewardDe=rewardNames[i][2];C.rows[#C.rows+1]=row
  end
  function C.progress()
    local won,pending=0,0
    for _,r in ipairs(C.rows)do local record=T.record(r.id)
      if record.won then won=won+1;if not record.claimed then pending=pending+1 end end
    end
    return won,pending
  end
  local journal=S.chapters.journal
  S.chapters.journal=function()
    local text=journal();local won=C.progress()
    if S.state().towerComplete then return text..tr('\n\nSEVII TOWER: Champion.',
      '\n\nSEVII-TRAINERTURM: Turmchamp.')end
    if won>0 then return text..tr('\n\nSEVII TOWER: ','\n\nSEVII-TRAINERTURM: ')..won..'/8'end
    return text
  end
  local function site(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map,'tower site '..id)
    for _,n in ipairs(S.maps[map].objects)do assert(n.x~=lx or n.y~=ly,'occupied tower site '..id)end
    local p={map=map,x=lx,y=ly,npc='KA_SEVII_'..id}
    ui.npc(map,p.npc,sprite,p.npc,lx,ly);return p
  end
  C.lobby=site('TOWER_RECEPTION','TrainerTower_Lobby',6,12,'SPRITE_CLERK')
  C.roof=site('TOWER_RECORDER','TrainerTower_Roof',7,8,'SPRITE_SCIENTIST')
  local function access(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return S.unlocked(game)and ow and ow.map and ow.map.id==p.map and a
      and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  function C.complete(game)
    if not access(game,C.roof)then return false,'not-at-roof'end
    if C.progress()<8 then return false,'floors-required'end
    local s=S.state();if s.towerComplete then return false,'already-complete'end
    local item=game.data.items[C.roofReward]
    if not(item and item.kascSeviiTrainingItem=='kasc.sevii-training-items/v1')then
      return false,'reward-unavailable'
    end
    if not require('src.inventory.Bag').add(game.save,C.roofReward,1,game.data)then
      return false,'bag-full'
    end
    s.towerComplete=true;S.persist(s);return true
  end
  ui.talks[C.lobby.npc]=function(game,ow,n,done)
    local won,pending=C.progress()
    ui.box(game,tr('RECEPTION: Eight floors, eight Trainers! Take them on in order. Feel free to leave and heal between matches; your victories will still be here when you return. Each Trainer has a prize for you. Make it to the roof, and I will be waiting!\n\nFloors cleared: ',
      'EMPFANG: Acht Etagen, acht Trainer! Fordere sie der Reihe nach heraus. Geh ruhig zwischendurch heilen; deine Siege bleiben dir erhalten. Jeder Trainer hat einen Preis für dich. Auf dem Dach warte ich auf dich!\n\nBestandene Etagen: ')..won..'/8'..
      tr('\nUncollected prizes: ','\nOffene Preise: ')..pending,done);return true
  end
  ui.talks[C.roof.npc]=function(game,ow,n,done)
    local ok,why=C.complete(game)
    local text
    if ok then text=tr('RECEPTION: You made it through all eight floors! Sevii has a new Tower Champion. Take this Lucky Egg for the partners who got you here. And do not forget any prizes you left with the Trainers below!',
      'EMPFANG: Du hast alle acht Etagen geschafft! Sevii hat einen neuen Turmchamp. Nimm dieses Glücks-Ei für die Partner, die dich hierhergebracht haben. Und vergiss deine Preise bei den Trainern unten nicht!')
    elseif why=='already-complete'then text=tr('Welcome back, Sevii Tower Champion. Your record and any uncollected prizes are safe.',
      'Willkommen zurück, Sevii-Turmchamp. Dein Rekord und offene Preise bleiben erhalten.')
    elseif why=='bag-full'then text=tr('Your Bag is full. Make room and return for the Lucky Egg and your champion record.',
      'Dein Beutel ist voll. Schaffe Platz und komm für das Glücks-Ei und den Champ-Eintrag zurück.')
    elseif why=='reward-unavailable'then text=tr('The tower prize is not available under the current item rules. Your eight wins remain recorded.',
      'Der Turmpreis ist unter den aktuellen Itemregeln nicht verfügbar. Deine acht Siege bleiben verzeichnet.')
    else text=tr('The title requires all eight floor victories. The reception desk keeps track of your progress.',
      'Der Titel verlangt Siege auf allen acht Etagen. Der Empfang kennt deinen Fortschritt.')end
    ui.box(game,text,done);return true
  end
  return C
end
