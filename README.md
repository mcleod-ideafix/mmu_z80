# mmu_z80
A simple MMU chip for Z80 and possibly other CPUs, from a spec description by Peter Wilson

## Registers
8 x 8 bit registers for address translation
A control register to enable/disable translation

## Control
- CS: A chip-select line for writing to or reading from those registers
- R/W: signal to distinguish between read/write to one of the registers
- 4 control address bits to select the target for read/write operations
- 8 data lines for read/write to the control registers (the CPU data bus)
- RESET: on reset address translation is disabled

![image](https://github.com/mcleod-ideafix/mmu_z80/blob/main/mmu_pinout.png)

## Translation
3 input address lines for translation
8 output address lines
- with translation enabled, the content of the addressed register
- with translation disabled, the content input three address lines are transparently passed through to the 
low order 3 output address lines, all other address lines output zero
OE: When low the output 8 address lines are active, tri-state when inactive
