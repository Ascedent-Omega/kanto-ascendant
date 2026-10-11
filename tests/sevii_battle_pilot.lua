-- QA player policy only: choose a usable damaging move using public move
-- power/type data. Native battle code owns accuracy, damage, AI and RNG.
return function(game,Q)
 local U=Q.U;local Chart=require('src.battle.TypeChart')
 local P={}
 function P.score(mon,move,targetTypes)
  if not move or (move.pp or 0)<=0 then return -1 end
  local d=game.data.moves[move.id];if not d then return -1 end
  local score=tonumber(d.power)or 0
  if score<=0 then return 0 end
  score=score*Chart.effectiveness(d.type,targetTypes)/10
  for _,kind in ipairs(game.data.pokemon[mon.species].types or{})do if kind==d.type then score=score*1.5;break end end
  if move.id=='HYPER_BEAM'then score=score*.6 end -- public recharge cost
  return score
 end
 function P.bestMove(b)
  local best,score
  for i,m in ipairs(b.player.curMoves)do
   if b.player.disabledSlot~=i and(m.pp or 0)>0 then
    local value=P.score(b.player.mon,m,b.enemy.curTypes)
    if not score or value>score then best,score=i,value end
   end
  end
  return best or 1
 end
 function P.bestReplacement(b,party)
  local best,score
  for i,m in ipairs(party)do if m.hp>0 and m~=b.player.mon then
   local value=0
   for _,move in ipairs(m.moves or{})do value=math.max(value,P.score(m,move,b.enemy.curTypes))end
   value=value*(.5+.5*m.hp/m.stats.hp)
   if not score or value>score then best,score=i,value end
  end end
  return assert(best,'healthy native replacement missing')
 end
 function P.selectReplacement(menu,wanted)
  local grid=menu.__vascOrasPartyDecorated or type(menu.gridNavigation)=='function'and menu:gridNavigation()
  for attempt=1,12 do
   if menu.index==wanted then Q.tap('a');return end
   local direction
   if grid then
    local col=(menu.index-1)%2;local targetCol=(wanted-1)%2
    if col~=targetCol then direction=targetCol==0 and'left'or'right'
    else direction=menu.index>wanted and'up'or'down'end
   else direction=menu.index>wanted and'up'or'down'end
   Q.tap(direction)
  end
  error('native replacement cursor cannot reach '..wanted..' from '..tostring(menu.index))
 end
 function P.run(b,opts)
  opts=opts or{}
  local decisions=0
  for tick=1,48000 do
   local top=game.stack:top()
   if top==game.overworld then Q.settle();return decisions end
   if top==b and b.phase=='menu'then
    local ok=b:chooseMenu(opts.choice and opts.choice(b)or'fight')
    if ok then decisions=decisions+1 else Q.tap('a')end
    if decisions%25==0 then print('SEVII_BALANCE_TURNS',b.seviiTrainerKey,decisions,b.player.mon.species,b.enemy.mon.species)end
    assert(decisions<=300,'player policy exceeded bounded combat decisions')
   elseif top==b and b.phase=='moveSelect'then
    assert(b:chooseMove(P.bestMove(b)));U.wait(1)
   elseif top.battle==b and top.forceSwitch and top.onSwitch then
    local wanted=P.bestReplacement(b,top.party or game.save.party)
    print('SEVII_NATIVE_REPLACEMENT',top.index,wanted,b.player.mon.species,b.player.mon.hp)
    P.selectReplacement(top,wanted)
   elseif top.labels and top.onChoose then Q.tap('b')
   elseif top.items or top.party and top~=b then Q.tap('b')
   else Q.tap('a')end
  end
  error('native battle did not finish: '..tostring(b.seviiTrainerKey))
 end
 return P
end
