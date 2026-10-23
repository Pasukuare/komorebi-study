from pathlib import Path
import json
P=Path(__file__).resolve().parent
LENS='M0 -44 A56 56 0 0 1 0 44 A56 56 0 0 1 0 -44 Z'
SQUIRCLE='M256 44 H768 C914 44 980 110 980 256 V768 C980 914 914 980 768 980 H256 C110 980 44 914 44 768 V256 C44 110 110 44 256 44 Z'
def wrap(body,size=1024,view=1024): return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {view} {view}">{body}</svg>'
def pages(ink='currentColor'):
 return f'<g fill="{ink}"><path d="{LENS}" transform="translate(35 73) rotate(-35) scale(.76)"/><path d="{LENS}" transform="translate(93 73) rotate(35) scale(.76)"/></g>'
def mark(ink='currentColor'):
 return pages(ink)+f'<circle cx="64" cy="28" r="14" fill="{ink}" opacity=".6"/>'
# The selected light icon replaces the earlier dark proposal; no second theme setting.
base=f'<defs><linearGradient id="base" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#EEE6D6"/><stop offset="1" stop-color="#FBF6E6"/></linearGradient><clipPath id="clip"><path d="{SQUIRCLE}"/></clipPath></defs><path d="{SQUIRCLE}" fill="url(#base)"/><path d="{SQUIRCLE}" fill="none" stroke="#14211E" stroke-opacity=".09" stroke-width="5"/>'
light=f'<defs><clipPath id="clip"><path d="{SQUIRCLE}"/></clipPath><linearGradient id="leak" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#F6D58E" stop-opacity="0"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".5"/></linearGradient><filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="32"/></filter></defs><g clip-path="url(#clip)"><path d="M700 -100 H1140 L510 790 L340 700 Z" fill="url(#leak)" filter="url(#soft)"/></g>'
art='<g transform="translate(154 154) scale(5.6)">'+mark('#14211E')+'</g>'
grain=f'<defs><clipPath id="clipgrain"><path d="{SQUIRCLE}"/></clipPath><filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".8" numOctaves="2" seed="17" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter></defs><g clip-path="url(#clipgrain)"><rect width="1024" height="1024" filter="url(#grain)" opacity=".025"/></g>'
# SVG ids are unique per layer when combined.
light_master=light.replace('id="clip"','id="cliplight"').replace('url(#clip)','url(#cliplight)')
master=wrap(base+light_master+art+grain)
(P/'icona-D-chiara-1024.svg').write_text(master)
(P/'marchio-D.svg').write_text(wrap(mark(),128,128))
(P/'marchio-D-piccolo.svg').write_text(wrap(mark(),32,128))
for name,body in [('sfondo',base),('foglie',f'<g transform="translate(154 154) scale(5.6)">{pages("#14211E")}</g>'),('luce',light_master+'<g transform="translate(154 154) scale(5.6)"><circle cx="64" cy="28" r="14" fill="#14211E" opacity=".6"/></g>'),('grana',grain)]:
 (P/'Livelli'/f'{name}.svg').write_text(wrap(body))
# Render targets contain the vector at each actual pixel size, not a blurry upscaled raster.
iconset=P/'AppIcon.iconset';iconset.mkdir(exist_ok=True)
assets=P/'AppIcon.appiconset';assets.mkdir(exist_ok=True)
targets=P/'RenderTargets';targets.mkdir(exist_ok=True)
images=[]
for points in [16,32,128,256,512]:
 for scale in [1,2]:
  size=points*scale;name=f'icon_{points}x{points}'+('@2x' if scale==2 else '')
  (targets/f'{name}.svg').write_text(master.replace('width="1024" height="1024"',f'width="{size}" height="{size}"',1))
  images.append({'idiom':'mac','size':f'{points}x{points}','scale':f'{scale}x','filename':name+'.png'})
(assets/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1}},indent=2))
# Concept comparison on simulated Dock backgrounds. This is explicitly NOT a screenshot.
board=['<rect width="1120" height="430" fill="#EEEAE0"/><text x="36" y="45" font-family="Georgia,serif" font-size="25" fill="#14211E">D · tra due pagine, icona chiara</text>']
for col,(bg,fg) in enumerate([('#E4E7E2','#14211E'),('#15211E','#FBF6E6')]):
 x=36+col*546
 board.append(f'<rect x="{x}" y="75" width="512" height="314" rx="24" fill="{bg}"/><text x="{x+22}" y="110" font-family="Helvetica,sans-serif" font-size="12" fill="{fg}">SIMULAZIONE · FONDO {"CHIARO" if col==0 else "SCURO"}</text>')
 for size,offset in [(192,30),(64,278),(32,404)]:
  content=(base+light_master+art+grain)
  # prefixes avoid collisions between icons on the same board
  for ident in ['base','cliplight','clipgrain','clip','leak','soft','grain']:
   content=content.replace(f'id="{ident}"',f'id="{ident}{col}{size}"').replace(f'url(#{ident})',f'url(#{ident}{col}{size})')
  board.append(f'<g transform="translate({x+offset} {145+(192-size)/2}) scale({size/1024})">{content}</g><text x="{x+offset+size/2}" y="366" text-anchor="middle" font-family="Helvetica,sans-serif" font-size="12" fill="{fg}">{size} px</text>')
board.append('<text x="36" y="417" font-family="Helvetica,sans-serif" font-size="12" fill="#526B61">Anteprima degli asset, non screenshot del Dock. Nessuna app sostituita in Applicazioni.</text>')
(P/'anteprima.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="1120" height="430" viewBox="0 0 1120 430">'+''.join(board)+'</svg>')
