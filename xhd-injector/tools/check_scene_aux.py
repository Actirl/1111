"""Structural check for scene auxiliary shader. Does not prove visual correctness."""
import sys
from check_xhdlook_abi import sections, sig, bindings
from pathlib import Path

def verify(path):
    data=Path(path).read_bytes()
    parts=sections(data)
    input_names={(n,i) for n,i,*_ in sig(parts.get('ISGN'))}
    minimum={('SV_POSITION',0),('NORMAL',0),('TANGENT',0),('BINORMAL',0),('TEXCOORD',0)}
    if not minimum.issubset(input_names):
        raise ValueError(f'Missing required live shader inputs {minimum-input_names}')
    output={(n,i) for n,i,*_ in sig(parts.get('OSGN'))}
    if output!={('SV_TARGET',0),('SV_TARGET',1)}:
        raise ValueError(f'Wrong dual MRT output {output}')
    resources=bindings(parts.get('RDEF'))
    required={'ShaderState':0,'Scene':1,'Batch':2,'XHDControl':12}
    for name,slot in required.items():
        value=resources.get(name)
        if value is None or value[0]!=0 or value[2]!=slot:
            raise ValueError(f'Constant buffer {name} not at b{slot}: {value}')
    if any(row[0]==0 and row[2]==13 for row in resources.values()):
        raise ValueError('b13 must be reserved for MMShader')
    print('PASS structural validation (not pixel equivalence):',path)

if __name__=='__main__':
    try:verify(sys.argv[1])
    except Exception as exc:
        print('FAIL:',exc,file=sys.stderr)
        sys.exit(1)
