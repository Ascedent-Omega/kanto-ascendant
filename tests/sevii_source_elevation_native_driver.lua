return function(game)
 io.stdout:setvbuf('no');local U=require('tests.drivers.util');local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true;love.window.hasFocus=function()return true end
 local P=require('src.render.Pipelines');local camera=tonumber(os.getenv('SEVII_ELEVATION_CAMERA')or'0');P.setLevel('voxel',camera);P.setLevel('tiltshift',0);P.syncOptions(game.save.options)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('off',game);V.require('Gen1Stairs').setting:setValue(true,game)
 local J=require('src.link.Json');local f=assert(io.open(assert(os.getenv('SEVII_ELEVATION_ORACLE'))));local oracle=J.decode(f:read('*a'));f:close()
 local Loader=require('src.world.MapLoader');local Collision=require('src.world.Collision');local S=Q.K.seviiExpedition;local fixed=os.getenv('SEVII_ELEVATION_FIXED')=='1'
 local report={maps={},walks={},mismatches=0,cells=0,blocked=0,exceptions=0,seams={},seamMismatches=0,scope='Authenticated original movement labels versus actual native Collision.canMove in all 266 maps; three real blocked edge inputs, rock-stair traversal and admitted Center stair warp. QA teleports and no random encounters; no journey balance/mobile claim.'}
 local function write()local f=assert(io.open(out..'/source-elevation.json','wb'));f:write(J.encode(report));f:close()end
 for _,row in ipairs(oracle.maps)do
  local map=Loader.load(game.data,row.map);local blocked,exceptions,mismatch=0,0,0
  if fixed then assert(S.sourceElevation,'source movement adapter absent')end
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
   report.cells=report.cells+1;if fixed then assert(S.sourceElevation.at(map,x,y)==row.rows[y+1]:byte(x+1)-33,'original label differs '..row.map)end
  end end
  for _,edge in ipairs(row.blockedEdges)do
   local x,y,dir,tx,ty,a,b=unpack(edge);local mover={cellX=x,cellY=y,surfing=map:isWaterCell(x,y)}
   local exception=map:warpAtCell(tx,ty)~=nil or mover.surfing and b==3
   local allowed,reason=Collision.canMove(map,{},mover,dir)
   local expected=exception and true or false
   if allowed~=expected then mismatch=mismatch+1 end
   if allowed then exceptions=exceptions+1 else blocked=blocked+1 end
   if fixed then assert(allowed==expected,'original elevation collision mismatch '..row.map..' '..x..','..y..' '..dir..' '..tostring(reason))end
  end
  report.maps[#report.maps+1]={map=row.map,source=row.source,edges=#row.blockedEdges,blocked=blocked,allowed=exceptions,mismatches=mismatch}
  report.blocked=report.blocked+blocked;report.exceptions=report.exceptions+exceptions;report.mismatches=report.mismatches+mismatch
 end
 local OW=require('src.world.OverworldController');local NativeMap=require('src.world.Map')
 if fixed then assert(OW.__kascSeviiElevationOwner==S.sourceElevation,'native seam adapter absent')end
 for _,edge in ipairs(oracle.drySeams)do
  local map=Loader.load(game.data,edge.map);local ow=setmetatable({map=map,player={cellX=edge.x,cellY=edge.y,surfing=false}},{__index=OW})
  local dest,ts,x,y,conn=ow:connectionLanding(edge.dir);assert(dest.id==edge.dest and x==edge.toX and y==edge.toY,'native seam offset differs')
  local allowed=fixed and S.sourceElevation.canCross(ow,edge.dir)or not fixed and NativeMap.defPassable(dest,ts,x,y,false)
  if allowed~=edge.expected then report.seamMismatches=report.seamMismatches+1 end
  if fixed then assert(allowed==edge.expected,'original seam collision differs '..edge.map);if not allowed then assert(OW.crossConnection(ow,edge.dir,conn)==false,'native seam wrapper did not stop crossing')end end
  report.seams[#report.seams+1]={map=edge.map,x=edge.x,y=edge.y,dir=edge.dir,dest=edge.dest,expected=edge.expected,actual=allowed}
 end
 print('SEVII_NATIVE_ELEVATION_SEAMS',#report.seams,report.seamMismatches)
 write();print('SEVII_NATIVE_ELEVATION_AUDIT',#report.maps,report.cells,report.blocked,report.exceptions,report.mismatches)
 local function capture(label)
  Q.settle();U.wait(camera==0 and 20 or 120);assert(U.still(game,out..'/'..label..'.png'))
 end
 for _,source in ipairs{'SixIsland_RuinValley','SevenIsland_SevaultCanyon_Entrance','OneIsland_KindleRoad'}do
  local chosen
  for _,r in ipairs(oracle.maps)do if r.source==source then
   local m=Loader.load(game.data,r.map)
   for _,edge in ipairs(r.blockedEdges)do local x,y,dir,tx,ty=unpack(edge)
    if m:isWalkableCell(x,y)and m:isWalkableCell(tx,ty)and not m:warpAtCell(x,y)and not m:warpAtCell(tx,ty)and x>0 and y>0 then chosen={map=r.map,edge=edge};break end
   end;if chosen then break end
  end end
  assert(chosen,'dry original edge absent '..source);local x,y,dir,tx,ty=unpack(chosen.edge)
  U.teleport(game,chosen.map,x,y,dir);Q.settle();capture(source..'-edge')
  local p=game.overworld.player;local clear=not Collision.occupied(game.overworld.entities,tx,ty,p);assert(clear,'QA edge occupied')
  for i=1,30 do if p.cellX==tx and p.cellY==ty then break end;U.hold(game,dir,1)end
  Q.settle();local moved=p.cellX==tx and p.cellY==ty
  assert(moved~=fixed,'real original edge input differs '..source)
  report.walks[#report.walks+1]={source=source,map=chosen.map,x=x,y=y,dir=dir,moved=moved};write()
 end
 for _,source in ipairs{'SixIsland_RuinValley','SixIsland_WaterPath'}do
  local edge;for _,e in ipairs(oracle.drySeams)do if e.expected==false and S.maps[e.map].kaSeviiSource==source then edge=e;break end end;assert(edge)
  U.teleport(game,edge.map,edge.x,edge.y,edge.dir);Q.settle();capture(source..'-seam')
  for i=1,30 do if game.overworld.map.id~=edge.map then break end;U.hold(game,edge.dir,1)end
  Q.settle();local crossed=game.overworld.map.id~=edge.map;assert(crossed~=fixed,'real source seam input differs '..source)
  report.walks[#report.walks+1]={source=source,seam=true,map=edge.map,x=edge.x,y=edge.y,dir=edge.dir,crossed=crossed};write()
 end
 local id,x,y=S.location('SixIsland_RuinValley',28,12);U.teleport(game,id,x,y,'down');Q.settle();capture('RuinValley-stair');Q.walkTo(x,y+2);Q.settle();report.walks[#report.walks+1]={source='SixIsland_RuinValley',map=id,rockStair=true,x=x,y=y,toY=y+2}
 U.teleport(game,S.CENTER,1,4,'down');Q.settle();Q.walkTo(1,5,'KA_SEVII_CENTER_2F');Q.settle();assert(game.overworld.map.id=='KA_SEVII_CENTER_2F','Center directional stair warp blocked');report.walks[#report.walks+1]={centerWarp=true,map=game.overworld.map.id}
 assert(#report.maps==266 and report.cells==73868);if fixed then assert(report.mismatches==0 and report.seamMismatches==0)end
 report.completed=true;write();print('SEVII_NATIVE_SOURCE_ELEVATION_PROOF_COMPLETE',report.mismatches,#report.walks);love.event.quit()
end
