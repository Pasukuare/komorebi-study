#!/usr/bin/env python3
"""Measure the preserved Komorebi tokens; never edits colors or user data.
WCAG 2.1 relative luminance, compositing translucent fills in sRGB first.
Usage: python3 Scripts/audit-contrast.py OUTPUT.csv
Vibrancy depends on the backdrop: its exact ratio is intentionally not asserted.
"""
from pathlib import Path
import re, csv, sys
source=(Path(__file__).resolve().parents[1]/'Sources/Components/Style.swift').read_text()
colors={}
for name, light, dark in re.findall(r'static let (\w+) = Color\.adaptive\(\(([^)]+)\), \(([^)]+)\)\)',source):
    colors[name]=[tuple(float(v.strip()) for v in part.split(',')) for part in (light,dark)]
colors.update(accent=colors['sage'], accentSurface=colors['sageFill'], interval=colors['softTeal'])
subjects={'Salvia':colors['sage'],'Tramonto':colors['softAmber']}
for name,light,dark in re.findall(r'\.init\(id: "([^"]+)", name: "[^"]+", ink: \.adaptive\(\(([^)]+)\), \(([^)]+)\)\)',source):
    subjects[name]=[tuple(float(v.strip()) for v in part.split(',')) for part in (light,dark)]
def blend(fg,bg,alpha):return tuple(f*alpha+b*(1-alpha) for f,b in zip(fg,bg))
def luminance(rgb):
    c=[v/12.92 if v<=0.04045 else ((v+0.055)/1.055)**2.4 for v in rgb]
    return sum(v*w for v,w in zip(c,(0.2126,0.7152,0.0722)))
def ratio(a,b):
    a,b=sorted((luminance(a),luminance(b)))
    return (b+0.05)/(a+0.05)
rows=[]
def add(mode,role,fg,bg,threshold,note=''):
    value=ratio(fg,bg);rows.append([mode,role,','.join(map(str,fg)),','.join(map(str,bg)),f'{value:.3f}',threshold,'OK' if value>=threshold else 'SOTTO SOGLIA',note])
for index,mode in enumerate(['chiaro','scuro']):
    for surface in ['background','surface','elevatedSurface']:
        bg=colors[surface][index]
        for text in ['textPrimary','textSecondary','textTertiary','accent','mutedRed','softAmber']:
            add(mode,text+' su '+surface,colors[text][index],bg,4.5)
        add(mode,'focus/accento su '+surface,colors['accent'][index],bg,3)
        add(mode,'bordo unico del campo su '+surface,colors['border'][index],bg,3)
        add(mode,'disabled testo primario 40% su '+surface,blend(colors['textPrimary'][index],bg,.4),bg,4.5,'Misurato per richiesta; componente disabilitato normalmente esente WCAG.')
        for name,pair in subjects.items():
            tile=blend(pair[index],bg,.15)
            add(mode,'icona '+name+' sul tile 15% sopra '+surface,pair[index],tile,3)
            add(mode,'titolo '+name+' su '+surface,pair[index],bg,4.5)
        # State fills used by the existing secondary and prominent buttons.
        for alpha,state in [(.055,'normale'),(.13,'premuto')]:
            fill=blend(colors['accent'][index],bg,alpha)
            add(mode,'bottone secondario '+state+' su '+surface,colors['accent'][index],fill,4.5)
        for alpha,state in [(1,'normale'),(.76,'premuto')]:
            fill=blend(colors['accentSurface'][index],bg,alpha)
            add(mode,'bottone prominente '+state+' su '+surface,colors['textPrimary'][index],fill,4.5)
        for alpha,state in [(.07,'normale'),(.16,'premuto')]:
            fill=blend(colors['mutedRed'][index],bg,alpha)
            add(mode,'bottone distruttivo '+state+' su '+surface,colors['mutedRed'][index],fill,4.5)
    for name in ['action','actionHover']:
        add(mode,'testo bianco su '+name,(1,1,1),colors[name][index],4.5)
        add(mode,'disabled CTA 40% (riempimento e testo)',blend((1,1,1),colors['background'][index],.4),blend(colors[name][index],colors['background'][index],.4),4.5,'Opacità del gruppo, non soltanto del testo.')
    active=blend(colors['accentSurface'][index],colors['background'][index],.65)
    add(mode,'sidebar attiva testo (backdrop uniforme di riferimento)',colors['textPrimary'][index],active,4.5,'Vibrancy: riferimento su background; sfondo macOS reale variabile.')
    add(mode,'sidebar attiva icona (backdrop uniforme di riferimento)',colors['accent'][index],active,3,'Vibrancy: riferimento su background; sfondo macOS reale variabile.')
out=Path(sys.argv[1]);out.parent.mkdir(parents=True,exist_ok=True)
with out.open('w',newline='') as f:
    writer=csv.writer(f);writer.writerow(['modalita','utilizzo','foreground_sRGB','background_effettivo_sRGB','rapporto','soglia','esito','nota']);writer.writerows(rows)
print(f'{len(rows)} misure, {sum(r[6]!="OK" for r in rows)} sotto soglia. Nessun colore modificato.')
