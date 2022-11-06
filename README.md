# VAllocTracker

Abusing V compiler to track memory allocations. It is a proof of concept and
it is not meant to be used in production.

This could be used to track memory allocations in a program to find
memory leaks inside the generated C source code. Or this could be a basis to
add a custom memory allocator with V without modifing the generated C code.

## Insert into your project

**Important**: This is a hack, and it may break your code. You have been warned.

```
$ cp valloc_tracker.h valloctracker.c.v /path/to/your/project
```

You may need to build your project manually to include the header file like so:
```bash
$ v . -o project.c && gcc project.c -o project
```

## Demo

A simple demo is provided.
```bash
# For the simple demo
$ make clean all && ./valloctrackerdemo
-------------------
    alloc stats
-------------------
* malloc:
** Allocations number:
2
* free:
1
* realloc:
0
* calloc:
10
* Total allocated size:
11022
WARNING: potential memory leaks detected
# Track every allocation
$ DEBUG=1 make clean all && ./valloctrackerdemo
```

A sample Dockerfile is provided to build the demo in a container.
```bash
$ docker build -f Dockerfile -t v-linux:latest .
$ docker run -it --volume=$(pwd):/work/ --workdir=/work/ --rm v-linux:latest
```

# License
This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details
