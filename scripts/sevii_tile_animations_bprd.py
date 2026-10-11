"""Authenticated BPRD animation export. Generated artwork stays local.

VRAM ranges and schedules: pret/pokefirered/src/tileset_anims.c.
Offsets are verified against this importer's exact German revision-0 ROM,
including pointer tables, code references and complete frame-bank hashes.
"""
import hashlib
import math
import struct

from PIL import Image

# name: base, bytes/frame, frames, pointer table, code literal, SHA-256,
#       destination VRAM tile, period, update phase, owning callback.
BANKS = {
 'flower': (0x3a722c,128,5,0x3a74ac,0x7002c,
  '3c104d93af7b7cc4fa3d45ed6fabfc577d2a2e561c03f59f5593399ba7cd1cbe',508,16,2,0x80700b9),
 'water': (0x3a74c0,1536,8,0x3aa4a0,0x70054,
  '0803d7e31a62dab1dbe2d96b967d62cc46d2daf4db37046021e8802fa16da0a9',416,16,1,0x80700b9),
 'sand': (0x3aa4c0,576,8,0x3ab6c0,0x7007c,
  'dfc8c05d0903ee787b30d88474f948af8c95abefbd6dae5e309b8762df402acf',464,8,0,0x80700b9),
 'steam': (0x3ac044,256,4,0x3ac444,0x701f8,
  '762acbb677a161f647dcf81f83dc610a7527b1618c805e92750a7aa9c5738ba5',896,16,0,0x8070219),
 'fountain': (0x3abc14,256,4,0x3ac034,0x70180,
  'e831e65d5408dde8045b1ad3254cdb4143d2f3f55b9c0b738176b9e04d0102b1',976,10,0,0x80701b5),
}


class AnimationCompiler:
    def __init__(self, rom, output):
        self.rom, self.output = rom, output
        self.cache, self.sources, self.written = {}, {}, set()
        self.output.joinpath('animations').mkdir(parents=True, exist_ok=True)
        for name, b in BANKS.items():
            base, size, count, table, code, digest = b[:6]
            pointers = b''.join(struct.pack('<I',0x8000000+base+i*size) for i in range(count))
            assert rom.data[table:table+len(pointers)] == pointers, name+' frame pointers'
            assert rom.u32(code) == 0x8000000+table, name+' callback reference'
            assert hashlib.sha256(rom.data[base:base+size*count]).hexdigest() == digest, name+' frame bank'

    def asset(self, image):
        # Deduplicate identical pixels across source palettes and fragments.
        size = struct.pack('<II',*image.size)
        digest = hashlib.sha256(size+image.tobytes()).hexdigest()
        if digest not in self.written:
            image.save(self.output/'animations'/f'{digest}.png')
            self.written.add(digest)
        return f'assets/sevii_local/animations/{digest}.png'

    def source(self, src):
        name = src['spec']['source']
        if name not in self.sources:
            positions = [self.rom.ptr(src['layout']+off) for off in (16,20)]
            callbacks = [self.rom.u32(p+16) for p in positions]
            supported = {0}|{b[9] for b in BANKS.values()}
            assert all(c in supported for c in callbacks), ('unsupported animation callback',name,callbacks)
            self.sources[name] = ([self.rom.tileset(p) for p in positions],callbacks)
        return self.sources[name]

    def metatile(self, src, mid):
        key = src['spec']['source'],mid
        if key in self.cache:
            return self.cache[key]
        rom = self.rom
        pair, callbacks = self.source(src)
        ts = pair[mid>=640]
        index = mid-640 if mid>=640 else mid
        entries = struct.unpack_from('<8H',rom.data,ts['metatiles']+index*16)
        kinds = {}
        for entry in entries:
            tid = entry&1023
            owner = 1 if tid>=640 else 0
            for name,b in BANKS.items():
                if callbacks[owner] == b[9] and b[6]<=tid<b[6]+b[1]//32:
                    kinds[name] = True
        if not kinds:
            self.cache[key] = None
            return None
        if set(kinds) in ({'flower'}, {'steam'}):
            for entry in entries[:4]:
                tid = entry&1023
                assert not any(callbacks[int(tid>=640)]==BANKS[name][9]
                               and BANKS[name][6]<=tid<BANKS[name][6]+BANKS[name][1]//32
                               for name in kinds), ('foreground animation in base layer',key)
        cycle = 1
        for name in kinds:
            b = BANKS[name];length = b[2]*b[7]
            cycle = cycle*length//math.gcd(cycle,length)
        assert cycle<=640 and 640%cycle==0, (key,cycle)
        images, overlays, sequence = [], [], []
        states, seen = {}, {}
        for tick in range(cycle):
            phases = tuple((name,((tick-BANKS[name][8])//BANKS[name][7])%BANKS[name][2])
                           for name in sorted(kinds))
            if phases not in states:
                animated = [dict(t) for t in pair]
                for name,phase in phases:
                    b = BANKS[name];owner = 1 if b[6]>=640 else 0
                    raw = bytearray(animated[owner]['raw'])
                    at = (b[6]-(640 if owner else 0))*32
                    raw[at:at+b[1]] = rom.data[b[0]+phase*b[1]:b[0]+(phase+1)*b[1]]
                    animated[owner]['raw'] = raw
                full = Image.new('RGBA',(16,16))
                overlay = Image.new('RGBA',(16,16))
                background = Image.new('RGBA',(16,16))
                for layer in range(2):
                    for q in range(4):
                        entry = entries[layer*4+q]
                        tid,pal = entry&1023,entry>>12
                        owner = 1 if tid>=640 else 0
                        local = tid-(640 if owner else 0)
                        raw = animated[owner]['raw']
                        palette = pair[0 if pal<7 else 1]['palettes']+pal*32
                        dynamic = any(callbacks[owner]==b[9] and b[6]<=tid<b[6]+b[1]//32
                                      for b in BANKS.values())
                        for y in range(8):
                            for x in range(8):
                                sx,sy = (7-x if entry&1024 else x),(7-y if entry&2048 else y)
                                c = (raw[local*32+sy*4+sx//2]>>(4*(sx%2)))&15
                                if layer==0 or c!=0:
                                    value = rom.u16(palette+c*2)
                                    rgba = tuple(round(((value>>s)&31)*255/31) for s in (0,5,10))+(255,)
                                    pos = q%2*8+x,q//2*8+y
                                    full.putpixel(pos,rgba)
                                    overlay.putpixel(pos,rgba if dynamic else (0,0,0,0))
                                    if not dynamic:
                                        background.putpixel(pos,rgba)
                pixels = full.tobytes(),overlay.tobytes()
                if pixels not in seen:
                    seen[pixels] = len(images)+1
                    images.append(full);overlays.append(overlay)
                states[phases] = seen[pixels]
            sequence.append(states[phases])
        # No opaque pixel change means a static upper layer hides this source
        # animation. Do not register needless animation over that fixed art.
        result = None
        if len({im.tobytes() for im in images})>1:
            result = dict(images=images,overlays=overlays,sequence=sequence,
                          kinds=sorted(kinds),cycle=cycle,background=background)
        self.cache[key] = result
        return result

    def register(self, tileset, src, keys):
        specs, groups = [], []
        for bid,key in enumerate(keys):
            px,py = bid%16*32,(bid//16)*32
            for q,(value,_) in enumerate(key):
                animation = self.metatile(src,value&1023)
                if not animation:
                    continue
                x,y = px+q%2*16,py+q//2*16
                full,overlay = animation['images'],animation['overlays']
                slots = []
                changing = False
                for dy in range(2):
                    for dx in range(2):
                        tile = (y//8+dy)*64+x//8+dx
                        slots.append(tile)
                        cropped = [im.crop((dx*8,dy*8,dx*8+8,dy*8+8)) for im in full]
                        if len({im.tobytes() for im in cropped})<2:
                            continue
                        changing = True
                        paths, indices = [], []
                        for im in cropped:
                            path = self.asset(im)
                            if path not in paths:
                                paths.append(path)
                            indices.append(paths.index(path)+1)
                        specs.append(dict(tile=tile,kind='frames',period=1,
                            sequence=[indices[i-1] for i in animation['sequence']],images=paths,
                            kaSeviiAnimationKinds=animation['kinds']))
                if changing:
                    groups.append(dict(tiles=slots,kind='flower' if animation['kinds']==['flower'] else
                        'steam' if animation['kinds']==['steam'] else 'surface',
                        sourceMid=value&1023,kinds=animation['kinds'],period=1,
                        sequence=animation['sequence'],images=[self.asset(im) for im in full],
                        overlays=[self.asset(im) for im in overlay],
                        background=self.asset(animation['background'])))
        if specs:
            # Native TileRenderer can batch identical streams over multiple
            # atlas slots. Collapsed metatile atlases repeat these drawings;
            # one stream per duplicate slot would multiply draw calls.
            streams = {}
            for spec in specs:
                key = tuple(spec['images']),tuple(spec['sequence'])
                old = streams.get(key)
                if old:
                    old.setdefault('tiles',[old['tile']]).append(spec['tile'])
                else:
                    streams[key] = spec
            tileset['animatedTiles'] = list(streams.values())
            tileset['kaSeviiTileAnimations'] = dict(schema='kasc.sevii-tile-animation/v1',
                counterMax=640,groups=groups)
