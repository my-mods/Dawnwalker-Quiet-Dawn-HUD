// Quiet Dawn - Configurable HUD. MIT.
#pragma once
#include <array>
#include <cstdint>
#include <cstddef>
#include "ObjectIdentity.hpp"

namespace QuietDawn {
// Owned scalars and an opaque object address, never a borrowed FFrame,
// parameter address, property, or Lua object. Deletion removes queued owners.
struct Event {
    int id{}, index{}, serial{};
    double value{}, previous{};
    bool resource{}, priority{};
    uintptr_t address{};
};
class EventQueue {
    std::array<Event, 128> events{};
    size_t first{}, count{};
    ObjectInterest interest;
    void remove(size_t n) {
        interest.remove(events[(first+n)%events.size()].index);
        if (!n) first=(first+1)%events.size();
        else for(size_t i=n;i+1<count;++i) events[(first+i)%events.size()]=events[(first+i+1)%events.size()];
        --count;
    }
public:
    bool track{};
    uint64_t merged{}, overflow{};
    void clear() { first = count = 0; interest.clear(); }
    bool mayContain(int index) const { return interest.contains(index); }
    size_t invalidate(int index, uintptr_t address) {
        size_t removed=0;
        for(size_t n=0;n<count;) {
            const auto& event=events[(first+n)%events.size()];
            if(event.index==index && event.address==address) { remove(n);++removed; }
            else ++n;
        }
        return removed;
    }
    bool empty() const { return count == 0; }
    size_t size() const { return count; }
    void push(Event event) {
        for (size_t n=0; n<count; ++n) {
            auto& prior=events[(first+n)%events.size()];
            if (prior.id!=event.id || prior.index!=event.index || prior.serial!=event.serial || prior.address!=event.address) continue;
            // Keep the largest loss until delivery. Recovery or a later tiny
            // blood fluctuation must not erase a meaningful damage alert.
            // Lua reads current resources separately; these scalars latch loss.
            if (!prior.resource || prior.value>=prior.previous ||
                event.previous-event.value>prior.previous-prior.value) prior=event;
            if (track) ++merged;
            return;
        }
        if (count==events.size()) {
            // An enemy-widget burst must not evict a queued player HUD alert.
            size_t victim=0;
            while(victim<count && (events[(first+victim)%events.size()].priority || events[(first+victim)%events.size()].resource)) ++victim;
            if (victim==count && !(event.priority || event.resource)) { if(track) ++overflow; return; }
            remove(victim==count ? 0 : victim); if (track) ++overflow;
        }
        events[(first+count++)%events.size()]=event;
        interest.add(event.index);
    }
    bool pop(Event& event) {
        if (!count) return false;
        size_t chosen=0;
        for(size_t n=0;n<count;++n) if(events[(first+n)%events.size()].priority || events[(first+n)%events.size()].resource) { chosen=n;break; }
        event=events[(first+chosen)%events.size()];remove(chosen);
        return true;
    }
};
}
