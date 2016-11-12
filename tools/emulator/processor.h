//
// Copyright 2011-2015 Jeff Bush
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

#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <stdbool.h>
#include <stdint.h>

#define NUM_REGISTERS 32
#define NUM_VECTOR_LANES 16
#define ALL_THREADS 0xffffffff
#define CACHE_LINE_LENGTH 64u
#define CACHE_LINE_MASK (CACHE_LINE_LENGTH - 1)

struct processor *init_processor(uint32_t memsize, uint32_t num_cores,
                                 uint32_t threads_per_core,
                                 bool randomize_memory,
                                 const char *shared_memory_file);
void enable_tracing(struct processor*);
int load_hex_file(struct processor*, const char *filename);
void write_memory_to_file(const struct processor*, const char *filename,
                          uint32_t base_address, uint32_t length);
const void *get_memory_region_ptr(const struct processor*, uint32_t address,
                                  uint32_t length);
void print_registers(const struct processor*, uint32_t thread_id);
void enable_cosimulation(struct processor*);
void raise_interrupt(struct processor*, uint32_t int_bitmap);
void clear_interrupt(struct processor*, uint32_t int_bitmap);
void cosim_interrupt(struct processor*, uint32_t thread_id, uint32_t pc);
uint32_t get_total_threads(const struct processor*);
bool proc_halted(const struct processor*);
bool stopped_on_fault(const struct processor*);

// Return false if this hit a breakpoint or crashed
// thread_id of ALL_THREADS means run all threads in a round robin fashion.
// Otherwise, run just the indicated thread.
bool execute_instructions(struct processor*, uint32_t thread_id,
                          uint64_t instructions);

void single_step(struct processor*, uint32_t thread_id);
uint32_t get_pc(const struct processor*, uint32_t thread_id);
uint32_t get_scalar_reg(const struct processor*, uint32_t thread_id,
                        uint32_t reg_id);
void set_scalar_reg(struct processor*, uint32_t thread_id,
                    uint32_t reg_id, uint32_t value);
void get_vector_reg(const struct processor*, uint32_t thread_id,
                    uint32_t reg_id, uint32_t *values);
void set_vector_reg(struct processor*, uint32_t thread_id,
                    uint32_t reg_id, uint32_t *values);
uint32_t debug_read_memory_byte(const struct processor*, uint32_t addr);
void debug_write_memory_byte(const struct processor*, uint32_t addr, uint8_t byte);
int set_breakpoint(struct processor*, uint32_t pc);
int clear_breakpoint(struct processor*, uint32_t pc);
void set_stop_on_fault(struct processor*, bool stop_on_fault);

void dump_instruction_stats(struct processor*);

#endif
