#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <bitset>
#include <algorithm>

using namespace std;

struct movie {
    int startTime;
    int endTime;
    int category;
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

void sortMoviesByEndTime(vector<movie>& movies) {
    sort(movies.begin(), movies.end(), [](const movie& a, const movie& b) {
        return a.endTime < b.endTime;
    });
}

void filterMovies(vector<movie>& movies) {
    movies.erase(remove_if(movies.begin(), movies.end(), [](const movie& m) {
        return m.endTime <= m.startTime;
    }), movies.end());
}

bool isTimeAvailable(const vector<movie>& chosenMovies, const movie& currentMovie) {
    for (const auto& movie : chosenMovies) {
        if (currentMovie.startTime < movie.endTime && currentMovie.endTime > movie.startTime) {
            return false;
        }
    }
    return true;
}

vector<movie> chooseMovies(vector<movie>& movies, vector<int>& categoriesMax) {
    vector<movie> chosenMovies;
    int maxMovies = 0;

    // Generate all possible subsets of movies
    int numMovies = movies.size();
    for (int mask = 0; mask < (1 << numMovies); mask++) {
        vector<movie> currentSelection;
        vector<int> categoryCount(categoriesMax.size(), 0);
        bool isValid = true;

        // Check if the number of movies in each category is within the limits
        for (int i = 0; i < numMovies; i++) {
            if (mask & (1 << i)) {
                movie currentMovie = movies[i];

                // Check if the maximum limit for the category of the current movie has been reached
                if (categoryCount[currentMovie.category - 1] >= categoriesMax[currentMovie.category - 1]) {
                    isValid = false;
                    break;
                }

                // Check if the time slot is available
                if (!isTimeAvailable(currentSelection, currentMovie)) {
                    isValid = false;
                    break;
                }

                categoryCount[currentMovie.category - 1]++;
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
    vector<movie> movies;
    vector<int> categoriesMax;

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

    sortMoviesByEndTime(movies);

    filterMovies(movies);
    
    vector<movie> chosenMovies = chooseMovies(movies, categoriesMax);
    
    cout << chosenMovies.size() << endl;
    for (int i = 0; i < chosenMovies.size(); i++) {
        cout << chosenMovies[i].startTime << " " << chosenMovies[i].endTime << " " << chosenMovies[i].category << endl;
    }
    
    return 0;
}