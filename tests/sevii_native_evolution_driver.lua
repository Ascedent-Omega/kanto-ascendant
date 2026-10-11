-- Start with Pokemon actually acquired through their Sevii encounter pools.
return function(game)
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  dofile(root..'/tests/sevii_native_capture_driver.lua')(game,function(game,report)
    local K=game.mods.exports.kanto_ascendant;local J=require('src.link.Json')
    print('SEVII_EVOLUTION_BOUNDARY',K.beyondKanto.isActive(game))
    if not K.beyondKanto.isActive(game)then
      assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
    end
    -- Storage relocation is test setup: move each actual captured record,
    -- without cloning it or replacing its acquisition/provenance fields.
    for _,box in ipairs(require('src.pokemon.Boxes').ensure(game.save))do
      for i=#box,1,-1 do
        local mon=box[i]
        if mon.species=='FEEBAS'or mon.species=='CLAMPERL'then
          assert(#game.save.party<6);table.insert(game.save.party,table.remove(box,i))
        end
      end
    end
    local S=K.seviiExpedition;local P=S.population
    local U=require('tests.drivers.util')
    local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
    Q.extraWarpAt=function(m,x,y)
      for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end
      return false
    end
    local function choose(match)
      for _=1,1800 do local t=game.stack:top();if t.items then break end;Q.tap('a')end
      local t=game.stack:top();local wanted
      for i,r in ipairs(t.submenu and t.subItems or t.items or{})do if match(r)then wanted=i;break end end
      if not wanted then for _,r in ipairs(t.submenu and t.subItems or t.items or{})do print('EVOLUTION_MENU',t.title,r.label,r.value)end end
      assert(wanted,'evolution menu option')
      for _=1,100 do local index=t.submenu and t.subIndex or t.index;if index==wanted then Q.tap('a');return end;Q.tap(index>wanted and'up'or'down')end
      error('evolution choice stuck')
    end
    local branch=os.getenv('SEVII_EVOLUTION_BRANCH')or'DEEP_SEA_TOOTH'
    assert(branch=='DEEP_SEA_TOOTH'or branch=='DEEP_SEA_SCALE')
    local cases={{species='FEEBAS',item='PRISM_SCALE',target='MILOTIC'},
      {species='CLAMPERL',item=branch,target=branch=='DEEP_SEA_TOOTH'and'HUNTAIL'or'GOREBYSS'}}
    game.save.money=10000
    assert(#P.evolutionStock(game)==3,'three registered usable evolution supplies')
    for _,r in ipairs(cases)do
      local mon,index
      for i,m in ipairs(game.save.party)do if m.species==r.species then mon=m;index=i end end
      assert(mon,'actual capture in party '..r.species)
      assert(require('src.pokemon.Evolution').pendingFor(game,mon,{kind='item',item=r.item})==r.target,'real eligible route')
      local p=P.evolutionShop;U.teleport(game,p.map,4,6,'up');Q.settle()
      Q.faceObject(p.x,p.y);Q.tap('a');U.wait(8)
      choose(function(row)return row.label=='BUY'end)
      choose(function(row)return row.value==r.item end)
      assert(game.stack:top().qty==1);Q.tap('a');local money=game.save.money;Q.tap('a');Q.settle()
      assert(game.save.inventory[r.item]==1 and game.save.money==money-2100,'actual evolution-item purchase')
      local origin=J.encode(mon.kascGiftReceipt or{})
      game.stack:push(require('src.ui.BagMenu').new(game));U.wait(10)
      local found=false
      for _=1,8 do
        for _,v in ipairs(game.stack:top().items or{})do if v.value==r.item then found=true end end
        if found then break end;Q.tap('right')
      end
      assert(found);choose(function(row)return row.value==r.item end);U.wait(10)
      if game.stack:top().items then choose(function(row)return row.value=='use'or row.label=='USE'end)
      elseif game.stack:top().labels then Q.tap('a')end
      U.wait(10);local picker=game.stack:top();assert(picker.pickOnly)
      -- KASC's field Team screen is a two-column grid.
      for _=1,12 do
        if picker.index==index then break end
        local row=math.floor((picker.index-1)/2);local targetRow=math.floor((index-1)/2)
        if row~=targetRow then Q.tap(row>targetRow and'up'or'down')
        else Q.tap(picker.index>index and'left'or'right')end
      end
      assert(picker.index==index,'correct evolution target');Q.tap('a')
      for _=1,5000 do
        local t=game.stack:top()
        if mon.species==r.target and(t.items or t==game.overworld)then break end
        -- Existing moves are kept when a branch learns an extra attack.
        if t.items then Q.tap('b')elseif t.labels and not t.isTextBox then Q.tap('b')else Q.tap('a')end
      end
      Q.settle()
      assert(mon.species==r.target,'actual native evolution animation completed '..r.target)
      assert((game.save.inventory[r.item]or 0)==0,'evolution item consumed once')
      assert(J.encode(mon.kascGiftReceipt or{})==origin,'no gift provenance fabricated')
      assert(game.save.pokedex.owned[r.target],'evolved identity owned')
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      assert(game.save.party[index].species==r.target and(game.save.inventory[r.item]or 0)==0,'evolution and consumption survive reload')
      print('SEVII_EVOLUTION_ITEM_PASS',r.species,r.item,r.target)
    end
    print('SEVII_NATIVE_EVOLUTION_PASS',branch,'actual Sevii captures, store purchase, native Bag evolution and reload; storage relocation fixture')
  end)
end
