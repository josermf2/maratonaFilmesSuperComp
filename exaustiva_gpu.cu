#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>

using namespace std;

struct movie {
    int startTime;
    int endTime;
    int category;
};

bool validateArgs(int argc, char* argv[]) {
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

struct movieCompareByEndTime {
    __host__ __device__
    bool operator()(const movie& a, const movie& b) const {
        return a.endTime < b.endTime;
    }
};

struct isMovieInvalid {
    int* categoryCounts;
    int* categoriesMax;

    __host__ __device__
    isMovieInvalid(int* categoryCounts, int* categoriesMax)
        : categoryCounts(categoryCounts), categoriesMax(categoriesMax) {}

    __host__ __device__
    bool operator()(const movie& m) const {
        return categoryCounts[m.category - 1] >= categoriesMax[m.category - 1];
    }
};

struct isTimeAvailable {
    movie* chosenMovies;
    int numChosenMovies;

    __host__ __device__
    isTimeAvailable(movie* chosenMovies, int numChosenMovies)
        : chosenMovies(chosenMovies), numChosenMovies(numChosenMovies) {}

    __host__ __device__
    bool operator()(const movie& currentMovie) const {
        for (int i = 0; i < numChosenMovies; i++) {
            const movie& movie = chosenMovies[i];
            if (currentMovie.startTime < movie.endTime && currentMovie.endTime > movie.startTime) {
                return false;
            }
        }
        return true;
    }
};

thrust::host_vector<movie> chooseMovies(thrust::host_vector<movie>& movies, thrust::host_vector<int>& categoriesMax) {
    thrust::host_vector<movie> chosenMovies;
    int maxMovies = 0;

    // Generate all possible subsets of movies
    int numMovies = movies.size();
    for (int mask = 0; mask < (1 << numMovies); mask++) {
        thrust::host_vector<movie> currentSelection;
        thrust::host_vector<int> categoryCounts(categoriesMax.size(), 0);
        bool isValid = true;

        // Check if the number of movies in each category is within the limits
        for (int i = 0; i < numMovies; i++) {
            if (mask & (1 << i)) {
                movie currentMovie = movies[i];

                // Check if the maximum limit for the category of the current movie has been reached
                if (categoryCounts[currentMovie.category - 1] >= categoriesMax[currentMovie.category - 1]) {
                    isValid = false;
                    break;
                }

                // Check if the time slot is available
                if (!isTimeAvailable(thrust::raw_pointer_cast(currentSelection.data()), currentSelection.size())(currentMovie)) {
                    isValid = false;
                    break;
                }

                categoryCounts[currentMovie.category - 1]++;
                currentSelection.push_back(currentMovie);
            }
        }

        // Update the maximum number of movies if the current selection is valid and has more movies
        if (isValid && currentSelection.size() > maxMovies) {
            maxMovies = currentSelection.size();
            chosenMovies = currentSelection;
        }
    }

    return chosenMovies;
}

int main(int argc, char* argv[]) {
    if (!validateArgs(argc, argv)) {
        return 1;
    }

    ifstream infile;
    if (!openFile(argv[1], infile)) {
        return 1;
    }

    int N;
    int M;
    thrust::host_vector<movie> movies;
    thrust::host_vector<int> categoriesMax;

    infile >> N >> M;

    for (int i = 0; i < M; i++) {
        int categoryMax;
        infile >> categoryMax;
        categoriesMax.push_back(categoryMax);
    }

    for (int i = 0; i < N; i++) {
        movie movie;
        infile >> movie.startTime >> movie.endTime >> movie.category;
        movies.push_back(movie);
    }

    infile.close();

    thrust::sort(thrust::host, movies.begin(), movies.end(), movieCompareByEndTime());

    movies.erase(thrust::remove_if(thrust::host, movies.begin(), movies.end(), [](const movie& m) {
        return m.endTime <= m.startTime;
    }), movies.end());

    thrust::host_vector<movie> chosenMovies = chooseMovies(movies, categoriesMax);

    cout << chosenMovies.size() << endl;
    for (int i = 0; i < chosenMovies.size(); i++) {
        cout << chosenMovies[i].startTime << " " << chosenMovies[i].endTime << " " << chosenMovies[i].category << endl;
    }

    return 0;
}
