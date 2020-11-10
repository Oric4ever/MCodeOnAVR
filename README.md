# MCodeOnAVR

This is the MCode interpreter for the ATmega162 platform (with 64KB of external static RAM).
Thanks to the efficient design of the AVR core, typical Modula-2 bytecode can be run at approximately the same speed as a 100 MHz Z80.

Caveats:
- It has no Z80 emulation in it, so it can only run Modula-2 systems that are entirely compiled into MCode (Modula-2 bytecode, see my Turbo Modula-2 Reloaded repository for an example of such a system).
- LONGREAL support is missing (double precision floats) for now. I might add it in the future, it wasn't needed to get a fully functional system. REAL support (simple precision floats) is in, using the float library of the AVR LibC.
