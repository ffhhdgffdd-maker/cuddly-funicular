#include "../WFVolumeReveal.h"
#include <cassert>
#include <cstdio>
int main() {
    WFVolumeRevealSequence s = {};
    assert(!WFVolumeRevealRecord(&s, 10, true));
    assert(!WFVolumeRevealRecord(&s, 10.03, true)); // Duplicate delivery.
    assert(!WFVolumeRevealRecord(&s, 10.15, true));
    assert(WFVolumeRevealRecord(&s, 10.30, true));
    assert(!WFVolumeRevealRecord(&s, 11, false)); // Visible tool cannot be hidden by volume.
    assert(!WFVolumeRevealRecord(&s, 11.2, false));
    assert(!WFVolumeRevealRecord(&s, 11.4, false));
    assert(!WFVolumeRevealRecord(&s, 20, true));
    assert(!WFVolumeRevealRecord(&s, 20.9, true));
    assert(!WFVolumeRevealRecord(&s, 21.8, true)); // Whole sequence exceeds 1.5 s.
    assert(!WFVolumeRevealRecord(&s, 22, true));
    assert(WFVolumeRevealRecord(&s, 22.2, true));
    assert(!WFVolumeRevealRecord(&s, 30, true));
    assert(!WFVolumeRevealRecord(&s, 30.2, false)); // Visibility transition clears partial count.
    assert(!WFVolumeRevealRecord(&s, 30.4, true));
    assert(!WFVolumeRevealRecord(&s, 30.6, true));
    assert(WFVolumeRevealRecord(&s, 30.8, true));
    puts("Volume reveal: rapid triples, duplicates, timeout and visibility passed");
}
