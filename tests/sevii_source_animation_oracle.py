"""Private oracle: original static compositor + independently patched VRAM."""
import argparse,collections,hashlib,importlib.util,json,struct,sys
from pathlib import Path
from PIL import Image
parser=argparse.ArgumentParser(description=__doc__)
for name in ('importer','rom','export','baseline','output'):
 parser.add_argument('--'+name,type=Path,required=True)
args=parser.parse_args()
p=args.importer.resolve()
sys.path.insert(0,str(p.parent));sp=importlib.util.spec_from_file_location('importer',p)
m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
from sevii_tile_animations_bprd import AnimationCompiler
rom=m.Rom(args.rom.read_bytes())
c=AnimationCompiler(rom,args.output.parent/'.animation-oracle-scratch')
# Original callback schedules, independent of the exporter's BANKS table.
channels=[('flower',508,128,5,16,2,0x3a722c,0x80700b9),
 ('water',416,1536,8,16,1,0x3a74c0,0x80700b9),
 ('sand',464,576,8,8,0,0x3aa4c0,0x80700b9),
 ('steam',896,256,4,16,0,0x3ac044,0x8070219),
 ('fountain',976,256,4,10,0,0x3abc14,0x80701b5)]
cfg=json.loads(m.MANIFEST.read_text())['maps'];selected={(s['group'],s['number']):s for s in cfg}
rows=[];samples=0;backgrounds=0;flips=collections.Counter()
for config in cfg:
 src=m.decode_source(rom,config,selected);pair,callbacks=c.source(src);row={'source':config['source'],'animatedMetatiles':0,'sampledStates':0}
 for mid in sorted({v&1023 for v in src['cells']}):
  a=c.metatile(src,mid)
  if not a:continue
  row['animatedMetatiles']+=1
  if a['kinds'] in (['flower'],['steam']):
   clean=[dict(t)for t in pair]
   for name,start,size,count,period,phase,bank,callback in channels:
    if name not in a['kinds']:continue
    owner=int(start>=640);raw=bytearray(clean[owner]['raw']);offset=(start-owner*640)*32
    raw[offset:offset+size]=bytes(size);clean[owner]['raw']=raw
   assert m.metatile(rom,clean,mid)[0].tobytes()==a['background'].tobytes(),('background',config['source'],mid)
   backgrounds+=1
  ts=pair[mid>=640];entries=struct.unpack_from('<8H',rom.data,ts['metatiles']+(mid-640 if mid>=640 else mid)*16)
  for e in entries:flips['horizontal']+=bool(e&1024);flips['vertical']+=bool(e&2048);flips['palettesOver6']+=(e>>12)>=7
  # One original compositor invocation for every distinct phase state,
  # including source intervals that phase-0/1-only comparisons can miss.
  checked=set()
  for tick,index in enumerate(a['sequence']):
   if index in checked:continue
   checked.add(index);patched=[dict(t) for t in pair]
   for name,start,size,count,period,phase,base,callback in channels:
    owner=int(start>=640)
    if callbacks[owner]!=callback:continue
    # Replay the last callback update by walking backward in the wrapping
    # native 640-tick counter, instead of the exporter's floor arithmetic.
    update=tick
    while update%period!=phase:update=(update-1)%640
    frame=(update//period)%count
    raw=bytearray(patched[owner]['raw']);offset=(start-owner*640)*32
    raw[offset:offset+size]=rom.data[base+frame*size:base+(frame+1)*size]
    patched[owner]['raw']=raw
   expected=m.metatile(rom,patched,mid)[0]
   assert expected.tobytes()==a['images'][index-1].tobytes(),(config['source'],mid,tick,index)
   samples+=1;row['sampledStates']+=1
 rows.append(row)
base=args.baseline
export=args.export
a,b=json.loads((base/'bundle.json').read_text()),json.loads((export/'bundle.json').read_text())
assert a['maps']==b['maps']
for old,new in zip(a['tilesets'],b['tilesets']):
 assert old=={k:v for k,v in new.items()if k not in ('animatedTiles','kaSeviiTileAnimations')},old['id']
 name=Path(old['image']).name;assert (base/name).read_bytes()==(export/name).read_bytes(),name
report=dict(completed=True,sourceMaps=len(rows),affectedSources=sum(r['animatedMetatiles']>0 for r in rows),
 sampledStates=samples,foregroundBackgrounds=backgrounds,coverage=dict(flips),mapsUnchanged=True,staticTilesetsUnchanged=True,staticPNGsUnchanged=True,
 scope='Exact BPRD ROM identity and authenticated pointer/frame banks; all distinct exported source states versus original static compositor with independently replayed wrapping callback schedule. No ROM or artwork is published.',rows=rows)
out=args.output
out.write_text(json.dumps(report,indent=2)+'\n')
print('SEVII_SOURCE_ANIMATION_EXPORT_PROOF_PASS',report['sourceMaps'],report['affectedSources'],samples,dict(flips),flush=True)
