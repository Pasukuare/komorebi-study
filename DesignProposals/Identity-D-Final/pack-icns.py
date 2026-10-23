"""Pack standard PNG-backed ICNS entries; avoids the iconutil service dependency."""
from pathlib import Path
import struct
p=Path(__file__).resolve().parent
entries=[('icp4','icon_16x16.png'),('ic11','icon_16x16@2x.png'),('icp5','icon_32x32.png'),('ic12','icon_32x32@2x.png'),('ic07','icon_128x128.png'),('ic13','icon_128x128@2x.png'),('ic08','icon_256x256.png'),('ic14','icon_256x256@2x.png'),('ic09','icon_512x512.png'),('ic10','icon_512x512@2x.png')]
chunks=[]
for kind,name in entries:
 data=(p/'AppIcon.iconset'/name).read_bytes()
 assert data[:8]==b'\x89PNG\r\n\x1a\n'
 chunks.append(kind.encode()+struct.pack('>I',len(data)+8)+data)
body=b''.join(chunks)
(p/'AppIcon.icns').write_bytes(b'icns'+struct.pack('>I',len(body)+8)+body)
