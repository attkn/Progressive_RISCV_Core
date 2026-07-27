#!/usr/bin/env python3
# ============================================================================
#  iss.py — minimal RV32I + Zicsr(read) golden model (co-sim referansi)
#  Her komut icin kanonik trace satiri yazar:  pc rd rdval mw maddr mdata size
#  (Spike yerine gecici altin model; Spike de ayni trace formatina uyarlanir)
# ============================================================================
import sys
def u32(v): return v & 0xFFFFFFFF
def s32(v):
    v &= 0xFFFFFFFF
    return v - 0x100000000 if (v & 0x80000000) else v
def sext(v, bits):
    m = 1 << (bits-1); return (v & ((1<<bits)-1) ^ m) - m

MISA = (1<<30)|(1<<8)|(1<<12)   # RV32 + I + M  (core_config M_EN=1)
def csr_read(a):
    if a == 0x301: return MISA
    return 0                      # mhartid/vendor/arch/imp = 0 ; sayaclar programda okunmuyor

def run(imem_path, num, out_path):
    imem = {}
    for i, line in enumerate(open(imem_path)):
        line = line.strip()
        if line: imem[i] = int(line, 16)
    reg = [0]*32
    dmem = {}
    pc = 0
    fo = open(out_path, "w")
    for _ in range(num):
        w   = imem.get(pc >> 2, 0)
        op  = w & 0x7f
        rd  = (w >> 7) & 0x1f
        f3  = (w >> 12) & 0x7
        rs1 = (w >> 15) & 0x1f
        rs2 = (w >> 20) & 0x1f
        f7  = (w >> 25) & 0x7f
        a, b = reg[rs1], reg[rs2]
        immI = sext((w >> 20) & 0xFFF, 12)
        immS = sext((((w >> 25) & 0x7f) << 5) | ((w >> 7) & 0x1f), 12)
        immB = sext(((w>>31)<<12)|(((w>>7)&1)<<11)|(((w>>25)&0x3f)<<5)|(((w>>8)&0xf)<<1), 13)
        immU = w & 0xFFFFF000
        immJ = sext(((w>>31)<<20)|(((w>>12)&0xff)<<12)|(((w>>20)&1)<<11)|(((w>>21)&0x3ff)<<1), 21)
        rd_eff=0; rdv=0; mw=0; maddr=0; mdata=0; sz=0
        npc = u32(pc + 4)

        if   op == 0x37: rd_eff, rdv = rd, u32(immU)                       # LUI
        elif op == 0x17: rd_eff, rdv = rd, u32(pc + immU)                  # AUIPC
        elif op == 0x6f: rd_eff, rdv, npc = rd, u32(pc+4), u32(pc+immJ)    # JAL
        elif op == 0x67: rd_eff, rdv, npc = rd, u32(pc+4), u32((a+immI)&~1)# JALR
        elif op == 0x63:                                                   # BRANCH
            t = {0:a==b,1:a!=b,4:s32(a)<s32(b),5:s32(a)>=s32(b),
                 6:u32(a)<u32(b),7:u32(a)>=u32(b)}[f3]
            if t: npc = u32(pc + immB)
        elif op == 0x03:                                                   # LOAD
            addr = u32(a+immI); word = dmem.get(addr>>2,0); off=(addr&3)*8
            if   f3==0: rdv=u32(sext((word>>off)&0xff,8))
            elif f3==1: rdv=u32(sext((word>>off)&0xffff,16))
            elif f3==2: rdv=u32(word)
            elif f3==4: rdv=(word>>off)&0xff
            elif f3==5: rdv=(word>>off)&0xffff
            rd_eff, sz = rd, f3
        elif op == 0x23:                                                   # STORE
            addr=u32(a+immS); mw,maddr,mdata,sz = 1,addr,u32(b),f3
            word=dmem.get(addr>>2,0); off=(addr&3)*8
            if   f3==0: word=(word & ~(0xff<<off))  |((b&0xff)<<off)
            elif f3==1: word=(word & ~(0xffff<<off))|((b&0xffff)<<off)
            else:       word=u32(b)
            dmem[addr>>2]=u32(word)
        elif op == 0x13:                                                   # OP-IMM
            rd_eff=rd; sh=immI&0x1f
            if   f3==0: rdv=u32(a+immI)
            elif f3==2: rdv=1 if s32(a)<immI else 0
            elif f3==3: rdv=1 if u32(a)<u32(immI&0xFFFFFFFF) else 0
            elif f3==4: rdv=u32(a^u32(immI))
            elif f3==6: rdv=u32(a|u32(immI))
            elif f3==7: rdv=u32(a&u32(immI))
            elif f3==1: rdv=u32(a<<sh)
            elif f3==5: rdv=u32(s32(a)>>sh) if f7==0x20 else u32(a>>sh)
        elif op == 0x33:                                                   # OP
            rd_eff=rd; sh=b&0x1f
            if   f7==0x01: rdv=u32(a*b)                                    # (M: MUL low)
            elif f3==0: rdv=u32(a-b) if f7==0x20 else u32(a+b)
            elif f3==1: rdv=u32(a<<sh)
            elif f3==2: rdv=1 if s32(a)<s32(b) else 0
            elif f3==3: rdv=1 if u32(a)<u32(b) else 0
            elif f3==4: rdv=u32(a^b)
            elif f3==5: rdv=u32(s32(a)>>sh) if f7==0x20 else u32(a>>sh)
            elif f3==6: rdv=u32(a|b)
            elif f3==7: rdv=u32(a&b)
        elif op == 0x73:                                                   # SYSTEM
            csr=(w>>20)&0xFFF
            if f3 in (1,2,3,5,6,7):                                        # CSR oku-degistir
                rd_eff, rdv = rd, u32(csr_read(csr))                       # rd = eski CSR

        if rd_eff==0: rdv=0
        if rd_eff!=0: reg[rd_eff]=u32(rdv)
        reg[0]=0
        fo.write(f"{u32(pc):08x} {rd_eff} {u32(rdv):08x} {mw} {u32(maddr):08x} {u32(mdata):08x} {sz}\n")
        pc = npc
    fo.close()

if __name__ == "__main__":
    imem = sys.argv[1] if len(sys.argv)>1 else "imem.mem"
    num  = int(sys.argv[2]) if len(sys.argv)>2 else 40
    outp = sys.argv[3] if len(sys.argv)>3 else "golden_trace.log"
    run(imem, num, outp)
    print(f"golden trace: {num} komut -> {outp}")
