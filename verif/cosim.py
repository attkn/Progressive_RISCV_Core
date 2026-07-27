#!/usr/bin/env python3
# ============================================================================
#  cosim.py — RTL <-> altin model lockstep karsilastirici
#  rtl_trace.log (vvp'den) ile golden_trace.log (iss.py'den) satir satir diff.
#  Ilk ayrisma noktasini baglamli gosterir. Spike icin: --golden spike
#  (spike --log-commits ciktisini ayni formata parse eden stub asagida).
# ============================================================================
import sys, subprocess

def load(path):
    return [l.rstrip("\n") for l in open(path) if l.strip()]

def parse_spike(log_path):
    # Spike `--log-commits` satirlarini kanonik formata cevirir (STUB — Spike
    # ciktisina gore ince ayar gerekir). Ornek Spike satiri:
    #   core   0: 3 0x00000000 (0x00000093) x 1 0x00000000
    out = []
    import re
    for line in open(log_path):
        m = re.search(r'0x([0-9a-f]+) \(0x([0-9a-f]+)\)(?:\s+(\w+)\s*(\d+)\s+0x([0-9a-f]+))?', line)
        if not m: continue
        pc = int(m.group(1),16); rd=0; rdv=0
        if m.group(3) and m.group(3).startswith('x'):
            rd=int(m.group(4)); rdv=int(m.group(5),16)
        out.append(f"{pc:08x} {rd} {rdv:08x} 0 00000000 00000000 0")
    return out

def compare(rtl, gold):
    n = min(len(rtl), len(gold))
    for i in range(n):
        if rtl[i] != gold[i]:
            print(f"\n  X AYRISMA @ komut {i}:")
            lo = max(0, i-2)
            for j in range(lo, min(n, i+2)):
                mark = " <-- " if j==i else "     "
                print(f"   [{j:3}]{mark}RTL:  {rtl[j]}")
                print(f"        {'    '}GOLD: {gold[j]}")
            return False
    if len(rtl) != len(gold):
        print(f"  ! uzunluk farki: RTL={len(rtl)} GOLD={len(gold)} (ilk {n} eslesti)")
    return True

if __name__ == "__main__":
    rtl  = load(sys.argv[1] if len(sys.argv)>1 else "rtl_trace.log")
    gold = load(sys.argv[2] if len(sys.argv)>2 else "golden_trace.log")
    print(f"RTL={len(rtl)} satir, GOLD={len(gold)} satir")
    ok = compare(rtl, gold)
    print("\n" + ("="*40))
    if ok: print("  LOCKSTEP: ESLESTI  --  co-sim PASS")
    else:  print("  LOCKSTEP: AYRISTI  --  co-sim FAIL")
    print("="*40)
    sys.exit(0 if ok else 1)
