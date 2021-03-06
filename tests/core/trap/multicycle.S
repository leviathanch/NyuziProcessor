//
// Copyright 2011-2016 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include "../../asm_macros.inc"

//
// Ensure that gather instructions resume from the correct lane after
// an interrupt. In this test, v0 is both the vector of pointers and the
// destination. If it restarted from 0 after returning from the interrupt, it would
// use the data value as a pointer. The data value is an odd number, which will
// cause an alignment exception if it used as a pointer.
//

.set TIMER_INTERVAL, 100

                    .globl _start
_start:             getcr s0, 0                 // Find my thread ID
                    bnz s0, spinner_thread    // If it is 1, jump to spinner thread

                    // Start spinner thread, which is described below
                    li s0, REG_THREAD_RESUME
                    li s1, 3    // Two threads enabled
                    store_32 s1, (s0)

                    // Set up interrupts
                    li s24, 2
                    setcr s24, CR_INTERRUPT_ENABLE

                    // Reset timer
                    li s24, TIMER_INTERVAL
                    li s25, REG_TIMER_COUNT
                    store_32 s24, (s25)

                    lea s10, interrupt_handler
                    setcr s10, CR_TRAP_HANDLER     // Set fault handler address
                    li s10, 5
                    setcr s10, CR_FLAGS             // Enable interrupts

                    li s0, 1024                   // Number of loops
loop0:
                    // Invalidate the second page so we will miss the cache part way through
                    // fetching these
                    lea s1, dataloc2
                    dinvalidate s1
                    lea s2, ptrvec
                    load_v v0, (s2)        // Get vector of pointers
                    load_gath v0, (v0)     // Gather load from pointers
                    sub_i s0, s0, 1        // Decrement counter and loop if not done
                    bnz s0, loop0

                    call pass_test

interrupt_handler:  getcr s12, CR_TRAP_CAUSE
                    cmpeq_i s13, s12, TT_INTERRUPT
                    bz s13, bad_int

                    // Ack interrupt
                    move s25, 2
                    setcr s25, CR_INTERRUPT_ACK

                    // Reset timer
                    li s24, TIMER_INTERVAL
                    li s25, REG_TIMER_COUNT
                    store_32 s24, (s25)

                    eret

bad_int:            call fail_test

// The purpose of the spinner thread is to issue instructions in between the gather
// instructions from thread 0 and reset the subcycle counter. Otherwise it is still
// the value of the last instruction and the test appears to pass.
spinner_thread:     b spinner_thread

                    .align 64

// There will be a cache miss between dataloc1 and dataloc2, which will allow the interrupt to
// be dispatched.
ptrvec:             .long dataloc1, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2
                    .long dataloc2, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2, dataloc2
dataloc1:           .long 7     // Odd address, will generate fault if used as pointer
                    .align 64
dataloc2:           .long 5     // Also odd, but this is on a different cache line
