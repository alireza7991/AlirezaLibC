/* Copyright (C)  2014 Alireza Forouzandeh Nezhad <alirezafn@gmx.us>
 * See LICENSE.md at root of alirezalibc directory for full license info
 * An interface to ARM asm in C */

#ifndef _CASM_H
#define _CASM_H
#endif

#define r0 "r0"
#define r1 "r1"
#define r2 "r2"
#define r3 "r3"
#define r4 "r4"
#define r5 "r5"
#define r6 "r6"
#define r7 "r7"
#define r8 "r8"
#define r9 "r9"
#define sl "r10"
#define fp "r11"
#define ip "r12"
#define sp "r13"
#define lr "r14"
#define pc "r15"

// start/end an casm section
#define casm_start __asm__ __volatile__(
#define casm_end );

// simple mov
#define mov(x,y) "mov " x "," y "\n"
// mov with condition support
#define imov(w,x,y) "mov " w " " x "," y "\n"

// software interrupt / supervisor call
#define swi() "swi #1\n"
#define svc() swi()


