#ifndef _VALLOC_TRACKER_H_
#define _VALLOC_TRACKER_H_

#include <stdlib.h>

// Some metrics
struct valloc_tracker_stats
{
    size_t malloc_number;
    size_t free_number;
    size_t realloc_number;
    size_t calloc_number;
    size_t bytes_allocated;
};

// Tracker into bss section
static struct valloc_tracker_stats stats;

// Custom malloc, free, realloc, calloc
// Here you can add your own code to track memory allocations or swap out the
// memory allocator

// malloc wrapper
void *vt_alloc(size_t size)
{
    return malloc(size);
}

// Free wrapper
void vt_free(void *ptr)
{
    free(ptr);
}

// Realloc wrapper
void *vt_realloc(void *ptr, size_t size)
{
    return realloc(ptr, size);
}

// Calloc wrapper
void *vt_calloc(size_t nmemb, size_t size)
{
    return calloc(nmemb, size);
}

// Which stats to track
enum valloc_stats
{
    STAT_MALLOC,
    STAT_FREE,
    STAT_REALLOC,
    STAT_CALLOC
};

// Return the stats struct from bss, this works because the stats struct is
// static
struct valloc_tracker_stats *valloc_tracker_get_stats(void)
{
    return &stats;
}

// Increment the stats for how many bytes has been allocated
void byte_counter_alloc(int size)
{
    stats.bytes_allocated += size;
}

// Increment the stats for the given stat
void increment_stat_type(int type)
{
    switch (type)
    {
    case STAT_MALLOC:
        stats.malloc_number++;
        break;
    case STAT_FREE:
        stats.free_number++;
        break;
    case STAT_REALLOC:
        stats.realloc_number++;
        break;
    case STAT_CALLOC:
        stats.calloc_number++;
        break;
    }
}

#endif
