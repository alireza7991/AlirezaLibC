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
#define imov(w,x,y) "mov" w " " x "," y "\n"

// software interrupt / supervisor call
#define swi() "swi #1\n"
#define svc() swi()

// simple cmp
#define cmp(x,y) "cmp " x "," y "\n"
// cmp with condition support
#define cmp(w,x,y) "cmp" w " " x "," y "\n"

// simple cmn
#define cmn(x,y) "cmn " x "," y "\n"
// cmn with condition support
#define cmn(w,x,y) "cmn" w " " x "," y "\n"

// simple tst
#define tst(x,y) "tst " x "," y "\n"
// tst with condition support
#define tst(w,x,y) "tst" w " " x "," y "\n"


// simple teq
#define teq(x,y) "teq " x "," y "\n"
// teq with condition support
#define teq(w,x,y) "teq" w " " x "," y "\n"


