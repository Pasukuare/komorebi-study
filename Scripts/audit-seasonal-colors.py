#!/usr/bin/env python3
"""Derive accessible seasonal inks. Run with OUTPUT.csv; prints Swift catalog entries.
WCAG 2.1 luminance and real 15% tile composition; no saved user colors are changed.
Dark starts at CIE L* +13 points and 10% less saturation, then adjusts for contrast.
"""
import csv,sys,colorsys,math
from pathlib import Path
PALETTES = {
 'primavera': [('ciliegio','Ciliegio','C9748F'),('germoglio','Germoglio','6F9450'),('glicine','Glicine','8E7BB8'),('pesco','Pesco','CC7248'),('cielo-aprile',"Cielo d’aprile",'5590B8'),('primula','Primula','A9851A')],
 'estate': [('mare','Mare','3A8CA6'),('corallo','Corallo','D2614C'),('oleandro','Oleandro','BA5384'),('menta','Menta','3E9C86'),('cobalto','Cobalto','4F6FB5'),('agrume','Agrume','B8800F')],
 'autunno': [('zucca','Zucca','C9691A'),('acero','Acero','B03A2E'),('senape','Senape','8F7A1F'),('castagna','Castagna','7B5238'),('vino','Vino','8A3A4F'),('bosco','Bosco','5E7B4A')],
 'inverno': [('ardesia','Ardesia','5B6F82'),('mirtillo','Mirtillo','4C5FA0'),('agrifoglio','Agrifoglio','3F7355'),('bacca','Bacca','B04657'),('brina','Brina','5C92AE'),('cenere','Cenere','8B7F9E')]
}
def rgb(h):return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
def hexrgb(c):return ''.join(f'{round(max(0,min(1,v))*255):02X}' for v in c)
def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def lum(c):return sum(linear(v)*w for v,w in zip(c,(.2126,.7152,.0722)))
def ratio(a,b):
 x,y=sorted((lum(a),lum(b)));return (y+.05)/(x+.05)
def blend(c,s):return tuple(.15*x+.85*y for x,y in zip(c,s))
SURFACES={'light':[(.979,.975,.962),(.997,.994,.984),(1,.998,.99)],'dark':[(.105,.13,.112),(.145,.17,.15),(.18,.205,.18)]}
def ink(base,mode):
 c=base
 if mode=='dark':
  h,l,s=colorsys.rgb_to_hls(*base);c=colorsys.hls_to_rgb(h,l,s*.9)
  y=lum(base);L=116*y**(1/3)-16 if y>.008856 else 903.3*y;target=((min(100,L+13)+16)/116)**3
  # Lift towards white to the requested perceptual lightness before contrast correction.
  for n in range(1001):
   candidate=tuple(v+(1-v)*n/1000 for v in c)
   if lum(candidate)>=target:c=candidate;break
 for n in range(1001):
  candidate=tuple(v*(1-n/1000) if mode=='light' else v+(1-v)*n/1000 for v in c)
  candidate=rgb(hexrgb(candidate))
  if all(ratio(candidate,s)>=4.5 and ratio(candidate,blend(candidate,s))>=4.5 for s in SURFACES[mode]):return candidate
 raise ValueError(mode)
def main():
 rows=[]
 for group,entries in PALETTES.items():
  for slug,name,source in entries:
   variants=[]
   for mode in ['light','dark']:
    c=ink(rgb(source),mode);variants.append(hexrgb(c))
    for index,surface in enumerate(SURFACES[mode]):
     rows.append([group+'.'+slug,name,mode,source,hexrgb(c),index,ratio(c,surface),ratio(c,blend(c,surface)),ratio(c,blend(c,surface))>=4.5])
   print(f'        .init(id: "{group}.{slug}", name: "{name}", light: "{variants[0]}", dark: "{variants[1]}"),')
 if len(sys.argv)>1:
  p=Path(sys.argv[1]);p.parent.mkdir(parents=True,exist_ok=True)
  with p.open('w',newline='') as f:
   w=csv.writer(f);w.writerow(['id','nome','modalita','partenza','corretto','superficie','contrasto_testo','contrasto_tile','passa']);w.writerows(rows)
if __name__=='__main__':main()
