"""XHDLook DXBC preflight. MMShader-inspired interface; NOT XHD visual correctness."""
import argparse, pathlib, struct, sys

def sections(data):
    if len(data)<36 or data[:4]!=b'DXBC': raise ValueError('Invalid DXBC header')
    n=struct.unpack_from('<I',data,28)[0]
    if n>256 or 32+4*n>len(data):raise ValueError('Invalid chunk table')
    out={}
    for (offset,) in struct.iter_unpack('<I',data[32:32+4*n]):
        if offset+8>len(data):raise ValueError('Bad chunk offset')
        key=data[offset:offset+4].decode('ascii',errors='replace')
        size=struct.unpack_from('<I',data,offset+4)[0]
        if offset+8+size>len(data):raise ValueError('Bad chunk size')
        out[key]=data[offset+8:offset+8+size]
    return out

def sig(blob):
    if blob is None:raise ValueError('Missing shader signature')
    n=struct.unpack_from('<I',blob,0)[0]
    if n>64:raise ValueError('Invalid signature count')
    entries=[]
    for i in range(n):
        offset=8+24*i
        if offset+24>len(blob):raise ValueError('Truncated signature')
        name_off,idx,sys,component,reg,mask=struct.unpack_from('<IIIII I',blob,offset)
        if name_off>=len(blob):raise ValueError('Invalid semantic offset')
        name=blob[name_off:].split(b'\0',1)[0].decode('ascii').upper()
        entries.append((name,idx,mask&255,component))
    return entries

def bindings(blob):
    if blob is None: raise ValueError('Missing RDEF')
    if len(blob)<32: raise ValueError('Truncated RDEF')
    count,offset=struct.unpack_from('<II',blob,8)
    if count>128 or offset+count*32>len(blob): raise ValueError('Invalid RDEF binding table')
    result={}
    for i in range(count):
        nameoff,kind,ret,dimension,samples,slot,nslots,flags=struct.unpack_from('<8I',blob,offset+i*32)
        if nameoff>=len(blob): raise ValueError('Invalid RDEF resource name')
        name=blob[nameoff:].split(bytes([0]),1)[0].decode('ascii',errors='replace')
        result[name]=(kind,dimension,slot,nslots)
    return result

def verify(path,variant):
    chunks=sections(pathlib.Path(path).read_bytes())
    inputs=sig(chunks.get('ISGN'))
    outputs=sig(chunks.get('OSGN'))
    required={('SV_POSITION',0),('NORMAL',0),('TANGENT',0),('BINORMAL',0),
              ('TEXCOORD',0),('TEXCOORD',1),('TEXCOORD',2),('COLOR',0),('COLOR',1)}
    actual={(n,i) for n,i,_,_ in inputs}
    if not actual.issubset(required) or ('SV_POSITION',0) not in actual:
        raise ValueError('Unexpected or missing input semantic: '+str(actual))
    out={(n,i,mask) for n,i,mask,_ in outputs}
    expect={('SV_TARGET',0,15)}
    if variant=='nonsss':expect.add(('SV_TARGET',1,15))
    if out!=expect:raise ValueError(f'Wrong MRT layout: {out}, expected {expect}')
    resources=bindings(chunks.get('RDEF'))
    expected={'XHDControl':(0,12),'Diffuse':(2,0),'NormalMap':(2,2),
              'SpecMap':(2,3),'S0':(3,0),'S2':(3,2),'S3':(3,3)}
    for name,(kind,slot) in expected.items():
        match=resources.get(name)
        if match is None or match[0]!=kind or match[2]!=slot or match[3]!=1:
            raise ValueError(f'RDEF binding mismatch for {name}: {match}, expected type={kind}, slot={slot}')
    # Deliberately not testing numerical meaning of auxiliary RT.
    print(f'PASS structural DXBC {variant}: {path}. Not a rendering fidelity assertion.')

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('shader');p.add_argument('--variant',choices=['chara','nonsss'],required=True)
    a=p.parse_args()
    try:verify(a.shader,a.variant)
    except Exception as e:print('FAIL DXBC ABI:',e,file=sys.stderr);sys.exit(1)
