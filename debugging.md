---
attr_reveal: ':frag (none none appear)'
author:
- Janne Blomqvist
title: Debugging code
theme: white
---

## Debugging code

-   My code compiles, but... when I run it, it just says "Segmentation
    fault"
    -   Help?!
-   This is about how to debug C/C++/Fortran/etc. code
    -   python/R/Matlab etc. extensions have their own debuggers
        -   Basic principles the same, details differ
-   Overview of available tools

---

### A little aside


-   Should you really be writing C/C++/Fortran, in 2018?
    -   If you have to extend/maintain existing code, sure..
    -   But for new code?
-   C wasn't state of the art in 1972, even less so today..
    -   Lack of memory safety
    -   Undefined and implementation-defined behavior everywhere
        e.g. wrt. aliasing, signed overflow
        -   New compiler optimizations frequently break old code that
            "used to work"
        -   With a modern optimizing compiler, C is **very** far from
            the original *portable macro-assembler*.

---

### What about C++ and Fortran? Alternatives?

-   C++ inherits the C mess
    -   Though careful use of "modern C++" like smart pointers,
        RAII etc. helps
        -   Check out [C++ Core
            Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
-   Fortran is a little better, but not much
    -   Similarly, "modern Fortran" style avoids some common pitfalls of
        F77 style.
-   Looking for an alternative? Check out
    [Rust](https://www.rust-lang.org/)
    -   Rust goals: safety, speed, and concurrency
    - Alternatively, higher level languages with decent performance. E.g.
      - [Julia](https://julialang.org/)
      - [Haskell](https://www.haskell.org/)

---

Tools
=====

-   What can you do to help figure out the reason for the crash?
    -   Compiler flags
    -   Sanitizers and Valgrind
    -   Using the debugger
    -   A few other useful tools

---

Compiler debug options
----------------------

-   Compilers have lots of switches to turn on warning and error
    messsages, use them!
-   For GCC: `-O2 -g -Wall -Wextra -pedantic -Werror`
-   GFortran: The above + `-fcheck=all
     -ffpe-trap=invalid,zero,overflow`. Note that `-fcheck=` makes the
    code **a lot** slower, so don't use it for production builds. Good
    for debugging, though. `-ffpe-trap=` might be problematic with
    LAPACK, otherwise useful. And it doesn't reduce performance either,
    so you can leave `-ffpte-trap=` on for production builds as well!
-   Intel compilers: See manual

---

Sanitizers
----------

-   Recent versions of GCC (and clang) support **sanitizers**
-   `-fsanitize=xxx`
    -   address: Fast memory error detector, detect out-of-bounds access
        and use-after-free
    -   thread: Data race detector
    -   undefined: Catches many common cases of UB
-   Triton: Need a newer version of gcc than the default:
    `module load GCC`

---

Valgrind
--------

-   Collection of debugging and profiling tools
-   Most common use is the memory error detector
-   Does not need any particular compile options (`-g` useful as always)
-   Slows down execution **a lot** =&gt; Make sure you have a testcase
    that runs quickly!

``` {.shell}
$ valgrind ./a.out
```

---

GDB tutorial
------------

### Introduction to GDB

-   GDB, the GNU debugger, is the standard debugger on Linux for C, C++,
    Fortran and several other languages that compile to native code
-   Continuously developed since 1986
-   LOTS of features; Here we concentrate on a VERY SMALL subset of the
    most common operations
-   Various graphical frontends also available. E.g. Eclipse, DDD.

---

### Why use a debugger

-   printf() debugging: Insert print calls in your program, deduce where
    the bug is
    -   Simple
    -   ...but time-consuming
-   A debugger lets you run the program, stop it where you want
    (breakpoints), inspect and modify the program state, etc.

---

### Getting started

Always include -g in your compile options. This adds **debug symbols**
to your executable.

-   Even if you're not explicitly debugging your code. Makes debugging
    easier if you encounter an unexpected error later.
-   Makes the executable bigger, but this is in practice never an issue
    in HPC
-   With higher optimization levels a lot of transformations are done on
    the code
-   Difficult to see how the code you're debugging corresponds to the
    source code. GCC 4.8+: -Og

---

### Simple GDB example

``` {.c}
#include <stdio.h>
int main()
{
        int *a = NULL;
        *a = 42;
        printf("%d\n", *a);
        return 0;
}
```

``` {.shell}
$ gcc -Og -g foo.c
$ ./a.out
Segmentation fault (core dumped)
$ gdb ./a.out
(gdb) r
Program received signal SIGSEGV, Segmentation fault.
main () at foo.c:5
5               *a = 42;
```

---

### Exercise

-   Try the example from the previous slide yourself.
-   Instead of GDB, try with valgrind and AddressSanitizer.
-   When would you want to use GDB, valgrind, or AddressSanitizer? Which
    one is "best"?

---

### Core dumps

-   Remember the error message: Segmentation fault (core dumped)
-   A **core** file is a snapshot of the process memory (at the time it
    crashed, typically).
-   Often shell has core file limit set to 0 =&gt; No core files
    -   bash: ulimit -c unlimited
-   Start GDB, load executable with associated core file:

``` {.shell}
$ gdb ./a.out core
```

---

### Core dumps 2

Core dump an existing process. Afterward, the process continues:

``` {.shell}
$ gcore PID
```

-   Why is it called a *core dump*? What is core?
    -   Ferrite core memory, used in early computers

---

### Breakpoints

-   Execute a program until it hits a breakpoint, then pause it at that
    point and resume the debugger.
-   Insert a breakpoint at line 5 of file foo.c, and on entry to
    function bar:

``` {.gdb}
(gdb) break foo.c:5
(gdb) break bar
```

---

### Single stepping, continuing

-   Continue executing until hitting the next breakpoint, or end of
    program: `(gdb) continue`
-   Execute next source line and pause: `(gdb) step`
-   Like **step**, but proceed through subroutine calls: `(gdb) next`
- Continue until end of current stack frame `(gdb) finish`
-   Short forms of the above: `c, s, n, fin`

---

### Program state

-   Value of a variable: `(gdb) print VAR`
-   Modify value of a variable: `(gdb) set (VAR = VALUE)`
-   Watchpoints (automatically print whenever value changes): `(gdb)
     watch VAR`

---

### Stack frames

-   Print procedure call stack: `(gdb) backtrace`
    -   Short form: `bt`
-   Jump up N stack frames: `(gdb) up N`

---

### Processes and threads

-   Attach debugger to a running process: `$ gdb -p PID`
    -   Or inside gdb: `(gdb) attach PID`
    -   Note that this pauses the process!
-   List current threads of process: `(gdb) info threads`
-   Switch to another thread: `(gdb) thread N`

---

### Debugging multi-process applications

-   While GDB supports multi-threaded applications, there's no built-in
    support for multi-process applications
-   MPI debugging with GDB:
    -   Launch MPI application
    -   For each MPI rank, start a terminal, start gdb attaching to the
        MPI process
    -   Debug!
-   If you have a CSC account, you can use TotalView (MPI debugger)
    which is less cumbersome than the above..

---

### GDB References

-   [GDB manual](http://sourceware.org/gdb/current/onlinedocs/gdb/)
-   [Beej's Quick Guide to GDB](http://beej.us/guide/bggdb)

---

### GDB Exercise 2

-   Take a look at `/scratch/scip/debug/boom.c`
-   Using what you have learned about GDB and debugging, try to find
    what's wrong

---

Other debugging tools
---------------------

-   **strace**: Prints system calls by application
-   **ltrace**: Like strace but (dynamic) library calls
-   **ldd**: List dynamic libraries used by executable/.so
-   **readelf, nm**: Tools to inspect object files

---

The dynamic linker (ld.so)
--------------------------

-   Dynamic linking: Use libraries stored separately in the filesystem
    instead of copying library code into application binary
    -   Security updates
    -   Save disk and page cache space
-   Library search path: Where to search for libraries
    -   `ldconfig -p` to print current list of system libraries
    -   `LD_LIBRARY_PATH` environment variable
-   See `ld.so(8)` man page

---

### LD_RUN_PATH

-   Alternative to `LD_LIBRARY_PATH`: Set `LD_RUN_PATH` when
    **compiling** =&gt; paths will be stored in binary, `DT_RPATH`
    section
-   Allow overriding system libraries on a per-application basis
-   Must recompile if paths change!
-   With `-Wl,rpath=your/path,--enable-new-dtags` to set `DT_RUNPATH`
    (searched **AFTER** `LD_LIBRARY_PATH`)

---

### ls.so search patch caveats

-   Order of entries in `LD_LIBRARY_PATH` matters
-   module system: Typically a module will prepend to `LD_LIBRARY_PATH`
    -   =&gt; module load order matters!
-   Various tools work similar to module, e.g. `virtualenv` (python)
-   Combining these, not being careful w.r.t. ordering can get you into
    quite a pickle. Be disciplined!
-   `ldd` is very useful to figure out where the libraries are loaded
    from

---

### Exercise: tracing

- Load a toolchain module, compile `/scratch/scip/debug/blas.c` (link
  with a suitable BLAS library such as OpenBLAS or MKL depending on
  the toolchain).
- Use *strace* to see what syscalls it makes and try to understand
  what it's doing. **Hint** If you don't know what a syscall does,
  check the manual: `man foo`
- Same as above, but run it with `OMP_NUM_THREADS=1`. What is the
  difference?
- Use ldd to check which dynamic libraries are used by the binary
- Use readelf to inspect the binary

