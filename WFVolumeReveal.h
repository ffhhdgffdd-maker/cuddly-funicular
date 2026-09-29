#pragma once
#include <stdbool.h>

typedef struct {
    unsigned count;
    double started;
    double last;
} WFVolumeRevealSequence;

// Input is one deduplicated button press, using monotonic time.
static inline bool WFVolumeRevealRecord(WFVolumeRevealSequence *sequence, double now, bool hidden) {
    if (!hidden) { sequence->count = 0; return false; }
    if (sequence->count && now >= sequence->last && now - sequence->last < 0.08) return false;
    if (!sequence->count || now < sequence->started || now - sequence->started > 1.5) {
        sequence->count = 0;
        sequence->started = now;
    }
    sequence->last = now;
    if (++sequence->count < 3) return false;
    sequence->count = 0;
    return true;
}
