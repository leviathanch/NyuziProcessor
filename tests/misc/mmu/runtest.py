#!/usr/bin/env python
# 
# Copyright 2011-2015 Jeff Bush
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

import sys
import subprocess

sys.path.insert(0, '../..')
import test_harness

DUMP_FILE='obj/memdump.bin'
EXPECT_STRING='Test String'

def mmu_test_verilator(name):
	test_harness.compile_test(['mmu.c', 'tlb_miss_handler.s'])
	result = test_harness.run_verilator(dump_file=DUMP_FILE, dump_base=0x100000,
		dump_length=32)
	if result.find('read 00900000 "Test String"') == -1:
		raise test_harness.TestException('did not get correct read string:\n' + result)

	with open(DUMP_FILE, 'r') as f:
		if f.read(len(EXPECT_STRING)) != EXPECT_STRING:
			raise test_harness.TestException('memory contents did not match')

def mmu_test_emulator(name):
	test_harness.compile_test(['mmu.c', 'tlb_miss_handler.s'])
	result = test_harness.run_emulator(dump_file=DUMP_FILE, dump_base=0x100000,
		dump_length=32)
	if result.find('read 00900000 "Test String"') == -1:
		raise test_harness.TestException('did not get correct read string:\n' + result)

	with open(DUMP_FILE, 'r') as f:
		if f.read(len(EXPECT_STRING)) != EXPECT_STRING:
			raise test_harness.TestException('memory contents did not match')

test_harness.register_tests(mmu_test_verilator, ['mmu (verilator)'])
test_harness.register_tests(mmu_test_emulator, ['mmu (emulator)'])
test_harness.execute_tests()