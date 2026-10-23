#!/usr/bin/env python3
"""Derive accessible seasonal inks. Run with OUTPUT.csv; prints Swift catalog entries.
WCAG 2.1 luminance and real 15% tile composition; no saved user colors are changed.
Seasonal hue/chroma is retained: accessibility adjusts HSL lightness, not a white overlay.
Dark saturation is reduced slightly; variants are audited against real 15% tiles.
"""
import csv,sys,colorsys,math
from pathlib import Path
PALETTES = {
 'primavera': [('ciliegio','Ciliegio','D85B91'),('germoglio','Germoglio','68A833'),('glicine','Glicine','A675D1'),('pesco','Pesco','E99274'),('cielo-aprile',"Cielo d’aprile",'70BDE0'),('primula','Primula','D6B52D')],
 'estate': [('mare','Mare','008FBA'),('corallo','Corallo','F05D45'),('oleandro','Oleandro','CA249C'),('menta','Menta','00A784'),('cobalto','Cobalto','235CD6'),('agrume','Agrume','EF9D00')],
 'autunno': [('zucca','Zucca','C76A1C'),('acero','Acero','AE3426'),('senape','Senape','A58422'),('castagna','Castagna','805038'),('vino','Vino','79334D'),('bosco','Bosco','626E32')],
 'inverno': [('ardesia','Ardesia','526C89'),('mirtillo','Mirtillo','5451A1'),('agrifoglio','Agrifoglio','23663E'),('bacca','Bacca','9E3654'),('brina','Brina','62B6CA'),('cenere','Cenere','92928A')]
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
 h,l,s=colorsys.rgb_to_hls(*base)
 # Keep the source hue; dark mode retains chroma rather than converging on beige.
 if mode=='dark': l=max(l,.58);s*=.92
 for n in range(1001):
  lightness=l*(1-n/1000) if mode=='light' else l+(1-l)*n/1000
  candidate=rgb(hexrgb(colorsys.hls_to_rgb(h,lightness,s)))
  if all(ratio(candidate,surface)>=4.5 and ratio(candidate,blend(candidate,surface))>=4.5 for surface in SURFACES[mode]):return candidate
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
