#ifndef VEC_UTILS_HPP
#define VEC_UTILS_HPP

#include <vector>
#include "math.hpp"

template <typename Fn>
inline std::vector<int> map_vec(const std::vector<int>& v, Fn fn) {
    std::vector<int> out;
    out.reserve(v.size());
    for (auto x : v) out.push_back(fn(x));
    return out;
}

inline std::vector<int> squares(const std::vector<int>& v) {
    return map_vec(v, square);
}

inline std::vector<int> cubes(const std::vector<int>& v) {
    return map_vec(v, cube);
}

#endif // VEC_UTILS_HPP
