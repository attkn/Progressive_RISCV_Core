# Kucuk assembler — test programini imem.mem'e yazar
def R(op,f3,f7,rd,rs1,rs2): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def I(op,f3,rd,rs1,imm):    return ((imm&0xFFF)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def S(op,f3,rs1,rs2,imm):
    imm&=0xFFF
    return (((imm>>5)&0x7F)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1F)<<7)|op
def B(op,f3,rs1,rs2,imm):
    imm&=0x1FFF
    b12=(imm>>12)&1; b11=(imm>>11)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF
    return (b12<<31)|(b10_5<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(b4_1<<8)|(b11<<7)|op
def J(op,rd,imm):
    imm&=0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(rd<<7)|op

OP,OPI,BR,ST,JAL,SYS = 0x33,0x13,0x63,0x23,0x6F,0x73
prog = [
  I(OPI,0b000,1,0,0),        # 00 addi x1,x0,0      sum=0
  I(OPI,0b000,2,0,1),        # 04 addi x2,x0,1      i=1
  I(OPI,0b000,3,0,11),       # 08 addi x3,x0,11     limit=11
  R(OP,0b000,0b0000000,1,1,2),# 0C add x1,x1,x2  (loop) sum+=i
  I(OPI,0b000,2,2,1),        # 10 addi x2,x2,1      i++
  B(BR,0b100,2,3,-8),        # 14 blt x2,x3,-8      -> 0x0C
  # CSRRS x4, 0x301(misa), x0  (rs1=x0 -> saf okuma)
  ((0x301<<20)|(0<<15)|(0b010<<12)|(4<<7)|SYS),  # 18
  S(ST,0b010,0,1,0),         # 1C sw x1,0(x0)       mem[0]=55
  S(ST,0b010,0,4,4),         # 20 sw x4,4(x0)       mem[4]=misa
  J(JAL,0,0),                # 24 jal x0,0          self-loop
]
import os
_OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),"imem.mem")
with open(_OUT,"w") as fo:
    for w in prog: fo.write(f"{w&0xFFFFFFFF:08x}\n")
print(f"{len(prog)} komut yazildi -> imem.mem")
for i,w in enumerate(prog): print(f"  {i*4:02x}: {w&0xFFFFFFFF:08x}")
