---
attr_reveal: ':frag (none none appear)'
author:
- Janne Blomqvist
title: Building code
theme: white
---

Scope
=====

-   How to go from a bunch of source files to an application?
-   This is about how to compile standalone C/C++/Fortran/etc. code
    -   python/R/Matlab etc. extensions have their own ways

---

## Simple single-file program

Say you have a program consisting of a single source file:

``` {.c}
#include <stdio.h>
int main() {
    printf("Hello world!");
    return 0;
}
```

---

-   Compile it with `gcc -O2 -Wall -g hello.c`
-   This generates a binary called `a.out`
-   Run it with `./a.out`
-   Don't like `a.out`? Choose your own name with `gcc -o myprog -O2
     -Wall -g hello.c`

---

## Multiple source files

-   Most non-trivial programs consist of several source files.
-   Separate compilation model: In languages like C/C++/Fortran/etc.
    source files can be compiled separately, creating *object* files
    (.o). In the end, the object files are *linked* together to create
    the final binary.

---

-   Typically you don't run the linker directly, the *compiler driver*
    takes care of it.

``` {.bash}
gcc -c -O2 -g -Wall a.c
gcc -c -O2 -g -Wall b.c
gcc a.o b.o
```

---

## Compilers

- GCC: The default. Most common choice, so most code most likely will
  work with it. Includes compilers for C (gcc), C++ (g++), and Fortran
  (gfortran).

- clang: Another increasingly popular open source compiler
  collection. C and C++ compilers (clang/clang++). 
  
- Intel: Commercial compilers by Intel. Often generates fast code, so
  please try it on your code if it works!

---

## make

-   If only `a.c` has changed, you don't need to recompile `b.c`. It's
    enough to recompile `a.c` and relink the object files.
    -   For large projects, this saves a lot of time compared to
        recompiling everything all the time.
    -   Manually keeping track of what needs to be recompiled is tedious
        and error-prone..

---

-   **make**: A tool to control how generation of files from other files
    is done.
    -   A *makefile* describes *targets*, *sources*, and *rules* to
        transform sources into targets
        -   When a *source* file has changed and make is run, it
            regenerates the corresponding *target* by running specified
            commands.

---

### Makefile example (simple)

[comment]: # An example will make this more clear.  This is manually creating all Makefile rules.  Format is output: dependencies  \n  instructions.

``` {.makefile}
a.o: a.c
    gcc -c -O2 -g -Wall a.c

b.o: b.c
    gcc -c -O2 -g -Wall b.c

myprog: a.o b.o
    gcc -o myprog a.o b.o
```

---

### Makefile example (more typical)

[comment2]: # Here's a more realistic example.  There is aggressive use of variables, templating, and implicit rules.

``` {.makefile}
CC=gcc
CFLAGS=-O2 -Wall -g
LDFLAGS=
LDLIBS=-lm
PROGRAM=myprog
OBJS=a.o b.o
$(PROGRAM): $(OBJS)
    $(CC) -o $(PROGRAM) $(OBJS) $(LDFLAGS) $(LDLIBS)
b.o: b.h
a.o: b.h
.PHONY: clean
clean: 
    -rm $(PROGRAM) $(OBJS)
```

---

Magic in the Makefile in the previous slide: Implicit GNU make rules
(don't need to specify source files), implicit targets for .o files.

---

### Compiling in parallel

- Note that make supports running individual targets in parallel
```{.makefile}
make -j MAX_NUMBER_OF_PARALLEL_JOBS
```
  - This requires that the dependencies are correct!
  - Often not the case in practice...
    - Sometimes it works to iterate...

---

## Makefile generation tools

So what about a tool that generates Makefiles?  Such tools exist, the
most popular ones are:

- autotools
- CMake

---

## Software configuration

As part of the build procedure one often wants to detect features of
the target system and adapt the build procedure accordingly (e.g. if a
library X is available, build the program with support for X). The
tools mentioned in the previous slide (autotools/CMake) also provide
functionality for this.

---

### CMake

There is an excellent introduction to CMake
[by Radovan Bast/coderefinery](http://cicero.xyz/v2/remark/github/coderefinery/lessons/master/cmake-basics.mkd/#1)

We won't go into CMake here, but if you prefer you're welcome to do
the autotools homework exercise using CMake instead.

---

### Autotools - Automake

-  A tool to generate Makefiles
-  Write an automake file, `Makefile.am`
-  Run automake, and a Makefile is generated

---

### Autotools - Autoconf

-   How to compile differently for different target systems?
-   A tool called **autoconf**
    -   You write `configure.ac`
        -   autoconf generates a script called `configure` that does a
            bunch of tests
        -   Running `configure` generates a file `config.h` that you can
            include in your source

``` {.c}
#ifdef HAVE_FOO
/* Do something */
#endif
```

---

Autotools
---------

-   The combination of Autoconf, Automake, and another useful tool
    called libtool, is called **Autotools**.
-   See <https://autotools.io> for a decent introduction.
    - Beware: There is a lot of outdated autotools info out there, and
      many projects cargo-cult stuff that isn't relevant today, making
      autotools seem more complex and confusing than it already is by
      itself.


---

### Autotools (or CMake) exercise

-   "Autotoolify" the simple example with a.c, b.c and b.h
    -   You can find these files at /scratch/scip/building
-   If you want credits: Email us a .tar.gz file with a project folder
    containing configure, Makefile.am, configure.ac, source files, and
    other needed files. 

---

### Autotools exercise...

- That is, this should be a typical software package that one could
  install with

``` {.bash}
./configure; make; make install
```

- Don't include the binaries or object files!

- Hint: If you have your autotools project setup correctly you can
  create the distribution package with

``` {.bash}
make dist
```

---

### Autotools exercise (CMake version)

- Your tar.gz should contain the source files, and CMakeLists.txt.

- It should be possible to build the code with

~~~bash
mkdir build; cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/some/install_path ..
make; make install
~~~


---

# Building parallel programs

- For parallel programs, there are some *small* additions to the
previous instructions.

---

## OpenMP

- To enable OpenMP, you need to add a special compile (and link) flag to the compiler.
  - GNU: `-fopenmp`
  - Intel: `-qopenmp`

---

## MPI

- To compile MPI applications, you use "special" MPI compilers.
  - When you load an MPI environment via the module system, the appropriate MPI compilers turn up on your `$PATH`.
  - (These are not actually separate compilers, but rather wrapper programs that add various libraries etc. So e.g. if you have loaded a GNU MPI environment, the MPI compilers will use GCC.)
- C: `mpicc`
- C++: `mpicxx` or `mpiCC` or `mpic++`
- Fortran: `mpifort`
