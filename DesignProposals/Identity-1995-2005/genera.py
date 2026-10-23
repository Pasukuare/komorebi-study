from pathlib import Path
import math
from html import escape
from xml.etree import ElementTree as ET
P=Path(__file__).resolve().parent
LENS='M0 -44 A56 56 0 0 1 0 44 A56 56 0 0 1 0 -44 Z'
TITLES={'A':'Canfora e luce','B':'Il sole lascia una foglia','C':'Albero luminoso','D':'Tra due pagine'}
DESC={'A':'Una foglia inclinata scherma il sole: il vuoto tra le forme è la firma.', 'B':'La foglia è un’assenza nel disco. Un segno più astratto, netto anche in piccolo.', 'C':'Un albero essenziale regge la luce: ritmo verticale, quasi un ideogramma originale.', 'D':'Due foglie diventano pagine aperte; la luce attraversa il loro intervallo.'}
def lens(transform,attrs=''):
 return f'<path d="{LENS}" transform="{transform}" {attrs}/>'
def transformed_lens(cx,cy,angle,scale=1):
 a=math.radians(angle); dx=44*scale*math.sin(a);dy=44*scale*math.cos(a);r=56*scale
 return f'M{cx+dx:.4f} {cy-dy:.4f} A{r:.4f} {r:.4f} 0 0 1 {cx-dx:.4f} {cy+dy:.4f} A{r:.4f} {r:.4f} 0 0 1 {cx+dx:.4f} {cy-dy:.4f} Z'
def mark(k,uid,small=False,color='currentColor',sun=None):
 sun=sun or color
 if k=='A':
  outer=transformed_lens(56,72,35)
  cut=transformed_lens(56,72,35,1.18 if small else 1.15)
  circle='M109 32 A22 22 0 1 0 65 32 A22 22 0 1 0 109 32 Z'
  # Even-odd paths create genuine transparent cutouts; no bitmap masks.
  vein='' if small else transformed_lens(58,69,35,.22)
  return f'<defs><clipPath id="{uid}disc"><circle cx="87" cy="32" r="22"/></clipPath></defs><path d="{circle} {cut}" fill="{sun}" opacity=".6" fill-rule="evenodd" clip-path="url(#{uid}disc)"/><path d="{outer} {vein}" fill="{color}" fill-rule="evenodd"/>'
 if k=='B':
  cut=transformed_lens(96,38,45,.88)
  circle='M106 67 A44 44 0 1 0 18 67 A44 44 0 1 0 106 67 Z'
  return f'<defs><clipPath id="{uid}disc"><circle cx="62" cy="67" r="44"/></clipPath></defs><path d="{circle} {cut}" fill="{color}" fill-rule="evenodd" clip-path="url(#{uid}disc)"/>'
 if k=='C':
  return f'<circle cx="64" cy="28" r="18" fill="{sun}" opacity=".6"/><path d="M64 59 V112 M64 60 L33 82 M64 60 L95 82 M64 80 L43 101 M64 80 L85 101" fill="none" stroke="{color}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
 # Each page is a lens; the 10-unit central gap remains clear at 16px.
 return f'<g fill="{color}">'+lens('translate(35 73) rotate(-35) scale(.76)')+lens('translate(93 73) rotate(35) scale(.76)')+f'</g><circle cx="64" cy="28" r="14" fill="{sun}" opacity=".6"/>'
def svg(body,w=128,h=128,view='0 0 128 128'):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{view}">{body}</svg>'
SQUIRCLE='M256 44 H768 C914 44 980 110 980 256 V768 C980 914 914 980 768 980 H256 C110 980 44 914 44 768 V256 C44 110 110 44 256 44 Z'
def icon(k,uid='icon',small=False):
 defs=f'''<defs><linearGradient id="{uid}base" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#14211E"/><stop offset="1" stop-color="#6F9A8F"/></linearGradient><linearGradient id="{uid}leak" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#F6D58E" stop-opacity="0"/><stop offset="1" stop-color="#F6D58E" stop-opacity=".46"/></linearGradient><filter id="{uid}blur" x="-70%" y="-70%" width="240%" height="240%"><feGaussianBlur stdDeviation="29"/></filter><filter id="{uid}bloom" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="13"/></filter><filter id="{uid}grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".8" numOctaves="2" seed="17" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter><clipPath id="{uid}clip"><path d="{SQUIRCLE}"/></clipPath></defs>'''
 art=lambda suffix: mark(k,uid+suffix,small,color='#FBF6E6',sun='#F6D58E')
 return defs+f'<g clip-path="url(#{uid}clip)"><path d="{SQUIRCLE}" fill="url(#{uid}base)"/><path d="M690 -80 H1160 L490 790 L338 692 Z" fill="url(#{uid}leak)" filter="url(#{uid}blur)"/><g transform="translate(154 154) scale(5.6)" opacity=".25" filter="url(#{uid}bloom)">{art("glow")}</g><g transform="translate(154 154) scale(5.6)">{art("art")}</g><rect width="1024" height="1024" filter="url(#{uid}grain)" opacity=".025"/></g>'
for k in TITLES:
 for small in [False,True]:
  (P/f'marchio-{k}{"-piccolo" if small else ""}.svg').write_text(svg(mark(k,'mark'+k+str(small),small,color='#14211E')))
 (P/f'icona-{k}-1024.svg').write_text(svg(icon(k,'master'+k),1024,1024,'0 0 1024 1024'))
 for size in [128,32]:
  (P/f'icona-{k}-{size}.svg').write_text(svg(icon(k,'icon'+k+str(size),small=size<=32),size,size,'0 0 1024 1024'))
# A single self-contained SVG board, with real-size 128/32/16 symbols.
board=['<rect width="1460" height="1460" fill="#EEEAE0"/>','<text x="48" y="65" font-family="Georgia,serif" font-size="34" fill="#14211E">Komorebi · lascia passare la luce</text>','<text x="48" y="96" font-family="Helvetica,sans-serif" font-size="15" fill="#526B61">Quattro direzioni originali · esplorazione, nessun marchio applicato all’app</text>']
for row,(k,title) in enumerate(TITLES.items()):
 y=132+row*318
 board.append(f'<text x="48" y="{y+27}" font-family="Georgia,serif" font-size="25" fill="#14211E">{k} · {escape(title)}</text>')
 board.append(f'<text x="48" y="{y+53}" font-family="Helvetica,sans-serif" font-size="14" fill="#526B61">{escape(DESC[k])}</text>')
 for col,(bg,fg,name) in enumerate([('#14211E','#FBF6E6','MARCHIO · SCURO'),('#FBF6E6','#14211E','MARCHIO · CHIARO')]):
  x=48+col*448
  board.append(f'<rect x="{x}" y="{y+72}" width="428" height="220" rx="18" fill="{bg}"/><text x="{x+20}" y="{y+101}" font-family="Helvetica,sans-serif" font-size="11" letter-spacing="1.4" fill="{fg}">{name}</text>')
  for n,(size,offset) in enumerate([(128,22),(32,216),(16,328)]):
   xx=x+offset; yy=y+127+(128-size)/2
   board.append(f'<g transform="translate({xx} {yy}) scale({size/128})">{mark(k,f"board{k}{col}{size}",size<=32,color=fg)}</g><text x="{xx+size/2}" y="{y+278}" text-anchor="middle" font-family="Helvetica,sans-serif" font-size="11" fill="{fg}">{size} px</text>')
 x=944
 board.append(f'<rect x="{x}" y="{y+72}" width="468" height="220" rx="18" fill="#CCDAD1"/><text x="{x+20}" y="{y+101}" font-family="Helvetica,sans-serif" font-size="11" letter-spacing="1.4" fill="#14211E">ICONA · MASTER 1024</text>')
 for size,xx in [(128,x+34),(32,x+232)]:
  yy=y+125+(128-size)/2
  board.append(f'<g transform="translate({xx} {yy}) scale({size/1024})">{icon(k,f"boardicon{k}{size}",size<=32)}</g><text x="{xx+size/2}" y="{y+278}" text-anchor="middle" font-family="Helvetica,sans-serif" font-size="11" fill="#14211E">{size} px</text>')
board.append('<text x="48" y="1440" font-family="Helvetica,sans-serif" font-size="13" fill="#526B61">Geometria semplice, intagli trasparenti. La zucca Halloween e il wordmark rimangono invariati.</text>')
(P/'tavola.svg').write_text(svg(''.join(board),1460,1460,'0 0 1460 1460'))
(P/'tavola.html').write_text('''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Komorebi · quattro concept</title><style>body{margin:0;background:#eeeae0;color:#14211e;font:16px system-ui}main{padding:24px;max-width:1460px;margin:auto}img{max-width:100%;height:auto}p{line-height:1.5}a{color:#3b6555}</style><main><img src="tavola.svg" alt="Quattro concept Komorebi, ciascuno su chiaro e scuro a 128, 32 e 16 pixel; icone a 128 e 32 pixel"><p>Per giudicare le misure reali apri <a href="tavola.svg">la tavola SVG</a> al 100%: il ridimensionamento della pagina può alterare le dimensioni mostrate. A: canfora e luce · B: sole con intaglio a foglia · C: albero luminoso · D: pagine-foglie.</p><p>Proposte, non icone installate. Scegli A, B, C o D per la fase di implementazione.</p></main></html>''')
for f in P.glob('*.svg'): ET.parse(f)
print('Creati e validati',len(list(P.glob('*.svg'))),'SVG')
