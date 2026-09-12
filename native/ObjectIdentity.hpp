// Quiet Dawn - Configurable HUD. MIT.
#pragma once
#include <array>
#include <atomic>
#include <cstdint>

namespace QuietDawn {
// Address is an opaque comparison value, never dereferenced. A zero serial is
// allowed: the deletion listener invalidates identities before slot reuse.
struct ObjectIdentity {
    uintptr_t address{};
    int index{-1}, serial{};
    bool matches(uintptr_t currentAddress, int currentSerial) const {
        return address && address==currentAddress && (!serial || serial==currentSerial);
    }
    bool invalidate(int deletedIndex, uintptr_t deletedAddress) {
        if (index!=deletedIndex || address!=deletedAddress || !address) return false;
        *this={}; return true;
    }
};

// Writers hold the owner's mutex. Deletion notifications can reject unrelated
// indices without that lock. Hash collisions only cause an extra exact check.
class ObjectInterest {
    std::array<uint16_t,512> counts{};
    std::array<std::atomic<uint64_t>,8> bits{};
    static unsigned slot(int index) { return (uint32_t(index)*2654435761u)>>23; }
public:
    void add(int index) {
        auto at=slot(index);
        if (!counts[at]++) bits[at/64].fetch_or(uint64_t{1}<<(at%64),std::memory_order_release);
    }
    void remove(int index) {
        auto at=slot(index);
        if (!--counts[at]) bits[at/64].fetch_and(~(uint64_t{1}<<(at%64)),std::memory_order_release);
    }
    bool contains(int index) const {
        auto at=slot(index);
        return (bits[at/64].load(std::memory_order_acquire)>>(at%64))&1;
    }
    void clear() {
        counts.fill(0);
        for(auto& word:bits) word.store(0,std::memory_order_release);
    }
};
}
