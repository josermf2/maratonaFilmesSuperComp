#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <bitset>
#include <algorithm>
#include <random>

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
    // Open the file for reading
    infile.open(filename);

    // Check if the file was opened successfully
    if (!infile.is_open()) {
        cerr << "Error: could not open file " << filename << endl;
        return false;
    }

    return true;
}

vector<movie> sortMoviesByEndTime(vector<movie>& movies) {
    sort(movies.begin(), movies.end(), [](const movie& a, const movie& b) {
        return a.endTime < b.endTime;
    });
    return movies;
}

vector<movie> filterMovies(vector<movie>& movies) {
    for (int i = 0; i < movies.size(); i++) {
        if (movies[i].endTime < movies[i].startTime || movies[i].startTime == movies[i].endTime) {
            movies.erase(movies.begin() + i);
            i--;
        }
    }
    return movies;
}

bitset<24> occupiedTimes(bitset<24>& times, movie movie){
    for (int i = movie.startTime; i < movie.endTime; i++) {
        times[i] = 1;
    }
    return times;
}

bool checkIfMovieFits(bitset<24>& times, movie movie){
    for (int i = movie.startTime; i < movie.endTime; i++) {
        if (times[i] == 1) {
            return false;
        }
    }
    return true;
}

vector<movie> chooseMovies(vector<movie>& movies, vector<int>& categoriesMax){
    bitset<24> movieTimesOccupied;
    vector<movie> chosenMovies;

    int seed = 10;
    char *SEED_VAR = getenv("SEED");
    if (SEED_VAR != NULL)
    {
        seed = atoi(SEED_VAR);
    }
    default_random_engine generator(seed);
    uniform_real_distribution<double> distribution(0.0, 1.0);


    for (int i = 0; i < movies.size(); i++) {
        double rnd_num = distribution(generator); 
        if (rnd_num <= 0.25) {
            int randomMovieIndex = rand() % movies.size();
            if (checkIfMovieFits(movieTimesOccupied, movies[randomMovieIndex]) && categoriesMax[movies[randomMovieIndex].category-1] > 0) {
                chosenMovies.push_back(movies[randomMovieIndex]);
                movieTimesOccupied = occupiedTimes(movieTimesOccupied, movies[randomMovieIndex]);
                categoriesMax[movies[randomMovieIndex].category-1]--;
            }
        }
        else {
            if (checkIfMovieFits(movieTimesOccupied, movies[i]) && categoriesMax[movies[i].category-1] > 0) {
                chosenMovies.push_back(movies[i]);
                movieTimesOccupied = occupiedTimes(movieTimesOccupied, movies[i]);
                categoriesMax[movies[i].category-1]--;

            }
        }
        if (categoriesMax == vector<int>(categoriesMax.size(), 0)) {
            break;
        }
    }

    return chosenMovies;
} 

int main(int argc, char *argv[]) {
    // Validate the command line arguments
    if (!validateArgs(argc, argv)) {
        return 1;
    }

    ifstream infile;
    // Check if the file was opened successfully
    if (!openFile(argv[1], infile)) {
        return 1;
    }

    // Create the variables to store the data
    int N;
    int M;
    vector<movie> movies;
    vector<int> categoriesMax;

    // Read the first line of the file and store the first int in N and the second in M
    infile >> N >> M;

    // Read the second line of the file and store the ints in categoriesMax
    for (int i = 0; i < M; i++) {
        int categoryMax;
        infile >> categoryMax;
        categoriesMax.push_back(categoryMax);
    }

    // Read the rest of the file and store the ints of each line in movies
    for (int i = 0; i < N; i++) {
        movie movie;
        infile >> movie.startTime >> movie.endTime >> movie.category;
        movies.push_back(movie);
    }

    // Close the file
    infile.close();

    sortMoviesByEndTime(movies);

    filterMovies(movies);

    vector<movie> chosenMovies = chooseMovies(movies, categoriesMax);
    
    sortMoviesByEndTime(chosenMovies);

    cout << chosenMovies.size() << endl;
    for (int i = 0; i < chosenMovies.size(); i++) {
        cout << chosenMovies[i].startTime << " " << chosenMovies[i].endTime << " " << chosenMovies[i].category << endl;
    }

    return 0;
}