module main

/*******************************************************************************
 MIT License

 Copyright (c) 2022 SheatNoisette

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*******************************************************************************/

// Header definitions
fn C.vt_alloc(u64) voidptr
fn C.vt_free(voidptr)
fn C.vt_realloc(voidptr, u64) voidptr
fn C.vt_calloc(u64, u64) voidptr

// Stats
fn C.increment_stat_type(int)
fn C.byte_counter_alloc(int)
fn C.valloc_tracker_get_stats() &C.valloc_tracker_stats

// Stats exposed
struct C.valloc_tracker_stats {
	malloc_number   u64
	free_number     u64
	realloc_number  u64
	calloc_number   u64
	bytes_allocated u64
}

// C library functions
fn C.puts(&u8) int
fn C.putchar(byte)

// Every malloc call will be replaced with a call to vt_alloc, this is to avoid
// that the preprocessor overwrites the malloc calls. See this as a passthrough.
#include "valloctracker.h"

// Override the malloc calls
#define malloc(size) custom_malloc(size, __LINE__)
#define free(ptr) custom_free(ptr, __LINE__)
#define realloc(ptr, size) custom_realloc(ptr, size, __LINE__)
#define calloc(n, size) custom_calloc(n, size, __LINE__)

// ----------------------------
// Custom malloc calls
// ----------------------------

[export: 'custom_malloc']
[markused]
fn custom_malloc(size u64, line u64) voidptr {
	$if debug {
		C.puts(c'> malloc {')
		C.puts(c' size: ')
		print_number_noalloc(u64(size))
		C.puts(c',line: ')
		print_number_noalloc(u64(line))
		C.puts(c'};')
	}
	C.increment_stat_type(C.STAT_MALLOC)
	C.byte_counter_alloc(size)
	return C.vt_alloc(size)
}

[export: 'custom_free']
[markused]
fn custom_free(ptr voidptr, line u64) {
	$if debug {
		C.puts(c'< freeing {')
		C.puts(c' ptr: ')
		print_number_noalloc(u64(ptr))
		C.puts(c',line: ')
		print_number_noalloc(u64(line))
		C.puts(c'};')
	}
	C.increment_stat_type(C.STAT_FREE)
	C.vt_free(ptr)
}

[export: 'custom_realloc']
[markused]
fn custom_realloc(ptr voidptr, size u64, line u64) voidptr {
	$if debug {
		C.puts(c'> realloc {')
		C.puts(c' ptr: ')
		print_number_noalloc(u64(ptr))
		C.puts(c',size: ')
		print_number_noalloc(u64(size))
		C.puts(c',line: ')
		print_number_noalloc(u64(line))
		C.puts(c'};')
	}
	C.increment_stat_type(C.STAT_REALLOC)
	return C.vt_realloc(ptr, size)
}

[export: 'custom_calloc']
[markused]
fn custom_calloc(n u64, size u64, line int) voidptr {
	$if debug {
		C.puts(c'> calloc {')
		C.puts(c' n: ')
		print_number_noalloc(u64(n))
		C.puts(c',size: ')
		print_number_noalloc(u64(size))
		C.puts(c',line: ')
		print_number_noalloc(u64(line))
		C.puts(c'};')
	}

	buffer := C.vt_calloc(n, size)

	if buffer == 0 {
		$if debug {
			C.puts(c'calloc failed!')
		}
		return 0
	}

	C.increment_stat_type(C.STAT_CALLOC)
	C.byte_counter_alloc(n * size)
	return buffer
}

// ----------------------------
// Simples functions to print without using the heap
// ----------------------------

// Print without allocating memory a string
fn print_noalloc(str &u8) {
	unsafe {
		for i := 0; str[i] != 0; i++ {
			C.putchar(str[i])
		}
	}
}

// String a number without allocating memory
fn print_number_noalloc(number u64) {
	mut i := 0
	mut digits := [20]u8{}
	mut n := number

	if n == 0 {
		C.puts(c'0')
		return
	}

	for n > 0 {
		digits[i] = u8(n % 10) + u8(`0`)
		n /= 10
		i++
	}
	for i > 0 {
		i--
		C.putchar(digits[i])
	}
	C.putchar(u8(`\n`))
}

// Print the stats at the end of the program for a program for example
fn custom_alloc_print_stats() {
	malloc_alloc := C.valloc_tracker_get_stats().malloc_number
	free_alloc := C.valloc_tracker_get_stats().free_number
	realloc_alloc := C.valloc_tracker_get_stats().realloc_number
	calloc_alloc := C.valloc_tracker_get_stats().calloc_number
	bytes_allocated := C.valloc_tracker_get_stats().bytes_allocated

	C.puts(c'-------------------')
	C.puts(c'    alloc stats')
	C.puts(c'-------------------')

	C.puts(c'* malloc:')
	C.puts(c'** Allocations number:')
	print_number_noalloc(malloc_alloc)
	C.puts(c'* free:')
	print_number_noalloc(free_alloc)
	C.puts(c'* realloc:')
	print_number_noalloc(realloc_alloc)
	C.puts(c'* calloc:')
	print_number_noalloc(calloc_alloc)
	C.puts(c'* Total allocated size:')
	print_number_noalloc(bytes_allocated)

	if (malloc_alloc + calloc_alloc) != free_alloc {
		C.puts(c'WARNING: potential memory leaks detected')
	}
}
