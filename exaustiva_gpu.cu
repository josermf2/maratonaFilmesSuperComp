#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/remove.h>

using namespace std;

struct Movie {
    int startTime;
    int endTime;
    int category;
};

struct CompareEndTime {
    __host__ __device__
    bool operator()(const Movie& a, const Movie& b) const {
        return a.endTime < b.endTime;
    }
};

struct IsNotOvernight {
    __host__ __device__
    bool operator()(const Movie& movie) const {
        return movie.endTime <= movie.startTime;
    }
};

bool validateArgs(int argc, char *argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <filename>" << endl;
        return false;
    }
    return true;
}

bool openFile(const char* filename, ifstream& infile) {
    infile.open(filename);

    if (!infile.is_open()) {
        cerr << "Error: could not open file " << filename << endl;
        return false;
    }

    return true;
}


struct Combination {
    int count;
    vector<Movie> movies;
};

vector<int> getCategoryCounts(const Combination& combination) {
    vector<int> categoryCounts(10, 0);
    for (const auto& movie : combination.movies) {
        categoryCounts[movie.category]++;
    }
    return categoryCounts;
}

bool checkCategoryLimits(const Combination& combination, const vector<int>& categoriesMax) {
    vector<int> categoryCounts = getCategoryCounts(combination);
    for (int i = 1; i <= categoriesMax.size(); i++) {
        if (categoryCounts[i] > categoriesMax[i - 1]) {
            return false;
        }
    }
    return true;
}

bool checkOverlap(const Movie& movie1, const Movie& movie2) {
    return movie1.startTime < movie2.endTime && movie2.startTime < movie1.endTime;
}

Combination findMaxCombination(const thrust::device_vector<Movie>& deviceMovies, const vector<int>& categoriesMax,
                        Combination& currentCombination, int currentIndex) {
    if (currentIndex >= deviceMovies.size()) {
        return currentCombination;
    }

    const Movie& currentMovie = deviceMovies[currentIndex];
    bool canAddMovie = true;

    for (const auto& movie : currentCombination.movies) {
        if (checkOverlap(movie, currentMovie)) {
            canAddMovie = false;
            break;
        }
    }

    Combination maxCombination = currentCombination;

    if (canAddMovie) {
        Combination withMovie = currentCombination;
        withMovie.movies.push_back(currentMovie);
        withMovie.count++;

        if (checkCategoryLimits(withMovie, categoriesMax)) {
            Combination combinationWithMovie = findMaxCombination(deviceMovies, categoriesMax, withMovie, currentIndex + 1);

            if (combinationWithMovie.count > maxCombination.count) {
                maxCombination = combinationWithMovie;
            }
        }
    }

    Combination withoutMovie = currentCombination;
    Combination combinationWithoutMovie = findMaxCombination(deviceMovies, categoriesMax, withoutMovie, currentIndex + 1);

    if (combinationWithoutMovie.count > maxCombination.count) {
        maxCombination = combinationWithoutMovie;
    }

    return maxCombination;
}



int main(int argc, char *argv[]) {
    if (!validateArgs(argc, argv)) {
        return 1;
    }

    ifstream infile;
    if (!openFile(argv[1], infile)) {
        return 1;
    }

    int N;
    int M;
    vector<Movie> movies;
    vector<int> categoriesMax;

    infile >> N >> M;

    for (int i = 0; i < M; i++) {
        int categoryMax;
        infile >> categoryMax;
        categoriesMax.push_back(categoryMax);
    }

    for (int i = 0; i < N; i++) {
        Movie movie;
        infile >> movie.startTime >> movie.endTime >> movie.category;
        movies.push_back(movie);
    }

    infile.close();

    thrust::host_vector<Movie> hostMovies = movies;
    thrust::device_vector<Movie> deviceMovies = hostMovies;

    thrust::sort(deviceMovies.begin(), deviceMovies.end(), CompareEndTime());

    deviceMovies.erase(thrust::remove_if(deviceMovies.begin(), deviceMovies.end(), IsNotOvernight()), deviceMovies.end());

    thrust::host_vector<Movie> hostMoviesResult = deviceMovies;

        Combination currentCombination;
    Combination maxCombination = findMaxCombination(deviceMovies, categoriesMax, currentCombination, 0);

    cout << maxCombination.movies.size() << endl;
    for (const auto& movie : maxCombination.movies) {
        cout << movie.startTime << " " << movie.endTime << " " << movie.category << endl;
    }

    return 0;
}
