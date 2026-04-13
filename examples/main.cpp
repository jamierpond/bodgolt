#include <vector>
#include <algorithm>
#include <numeric>

int sum(const std::vector<int>& v) {
    return std::accumulate(v.begin(), v.end(), 0);
}

int square(int x) {
    return x * x;
}
