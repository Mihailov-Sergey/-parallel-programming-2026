#include "GenerateMatrix.h"
#include <iostream>
#include <fstream>
#include <random>
#include <iomanip>

void generate_test_file(const std::string& filename, unsigned int n) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Ошибка: Файл не сгенерирован " << filename << std::endl;
        return;
    }
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<double> dis(-10.0, 10.0);
    file << std::fixed << std::setprecision(6);
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int j = 0; j < n; ++j) {
            file << dis(gen) << " ";
        }
        file << "\n";
    }
    file.close();
}
