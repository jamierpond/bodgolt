#pragma once

#include <numeric>
#include <iostream>
#include "vec_utils.hpp"
#include "math.hpp"

inline void run() {
    std::vector<int> data = {1, 2, 3, 4, 5};

    auto sq = squares(data);
    auto cu = cubes(data);

    auto sum_sq = std::accumulate(sq.begin(), sq.end(), 0);
    auto sum_cu = std::accumulate(cu.begin(), cu.end(), 0);

    std::cout << "Sum of squares: " << sum_sq << "\n";
    std::cout << "Sum of cubes:   " << sum_cu << "\n";
}
