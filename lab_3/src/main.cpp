#include <mpi.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <chrono>
#include <string>
#include <thread>
#include <cstdio>
#include <iomanip>
#include "GenerateMatrix.h"

using Matrix = std::vector<std::vector<double>>;

std::vector<double> flatten(const Matrix& m) {
    std::vector<double> res;
    res.reserve(m.size() * m.size());
    for (const auto& row : m) {
        res.insert(res.end(), row.begin(), row.end());
    }
    return res;
}

bool read_matrix(const std::string& filename, Matrix& matrix, unsigned int n) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Ошибка: Не удалось открыть файл " << filename << std::endl;
        return false;
    }
    matrix.assign(n, std::vector<double>(n));
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int j = 0; j < n; ++j) {
            if (!(file >> matrix[i][j])) {
                std::cerr << "Ошибка: некорректное чтение матрицы в файле " << filename << std::endl;
                return false;
            }
        }
    }
    file.close();
    return true;
}

bool write_matrix(const std::string& filename, const std::vector<double>& flat_matrix, unsigned int n) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Ошибка: Не удалось открыть файл для вывода " << filename << std::endl;
        return false;
    }
	file << std::fixed << std::setprecision(6);
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int j = 0; j < n; ++j) {
            file << flat_matrix[i * n + j] << " ";
        }
        file << "\n";
    }
    file.close();
    return true;
}

int main(int argc, char* argv[]) {
    MPI_Init(&argc, &argv);
    int num_procs, rank;
    MPI_Comm_size(MPI_COMM_WORLD, &num_procs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	
    unsigned int n = 1000; 
    bool need_generation = false;
    if (argc > 1) {
        try {
            n = std::stoi(argv[1]);
        } catch (...) {
            if (rank == 0) std::cerr << "Ошибка: неверный формат N. Использовано N=1000\n";
        }
    }
    if (argc > 2 && std::string(argv[2]) == "--generate") {
        need_generation = true;
    }
    std::string file_a = "matrixA.txt";
    std::string file_b = "matrixB.txt";
    std::string file_c = "resultC.txt";
	
    std::vector<double> flat_A;
    std::vector<double> flat_B(n * n);
    std::vector<double> flat_C;

    std::vector<int> send_counts(num_procs);
    std::vector<int> displacements(num_procs);

    int rows_per_proc = n / num_procs;
    int remaining_rows = n % num_procs;
    int current_disp = 0;

    for (int i = 0; i < num_procs; ++i) {
        int rows = rows_per_proc + (i < remaining_rows ? 1 : 0);
        send_counts[i] = rows * n;
        displacements[i] = current_disp;
        current_disp += send_counts[i];
    }

    int local_rows = send_counts[rank] / n;
    std::vector<double> local_A(send_counts[rank]);
    std::vector<double> local_C(send_counts[rank], 0.0);

    if (rank == 0) {
        if (need_generation) {
            std::cout << "Генерация исходных матриц размером " << n << "x" << n << "...\n";
            generate_test_file(file_a, n);
            generate_test_file(file_b, n);
            std::this_thread::sleep_for(std::chrono::milliseconds(100)); 
        }

        std::ifstream f_a(file_a), f_b(file_b);
        if (!f_a.good() || !f_b.good()) {
            std::cerr << "Критическая ошибка: Файлы данных не найдены! Запустите с флагом --generate\n";
            MPI_Abort(MPI_COMM_WORLD, -1);
            return -1;
        }
        f_a.close(); f_b.close();

        Matrix A, B;
        if (!read_matrix(file_a, A, n) || !read_matrix(file_b, B, n)) {
            std::cerr << "Ошибка: Чтение исходных матриц некорректно\n";
            MPI_Abort(MPI_COMM_WORLD, 1);
            return 1;
        }

        flat_A = flatten(A);
        flat_B = flatten(B);
        flat_C.resize(n * n, 0.0);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    auto calc_start_time = std::chrono::steady_clock::now();

    MPI_Bcast(flat_B.data(), n * n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    
    MPI_Scatterv(flat_A.data(), send_counts.data(), displacements.data(), MPI_DOUBLE,
                 local_A.data(), send_counts[rank], MPI_DOUBLE, 0, MPI_COMM_WORLD);

    for (int i = 0; i < local_rows; ++i) {
        for (unsigned int k = 0; k < n; ++k) {
            double a = local_A[i * n + k];
            for (unsigned int j = 0; j < n; ++j) {
                local_C[i * n + j] += a * flat_B[k * n + j];
            }
        }
    }

    MPI_Gatherv(local_C.data(), send_counts[rank], MPI_DOUBLE,
                flat_C.data(), send_counts.data(), displacements.data(), MPI_DOUBLE, 0, MPI_COMM_WORLD);

    MPI_Barrier(MPI_COMM_WORLD);
    auto calc_end_time = std::chrono::steady_clock::now();

    if (rank == 0) {
        std::chrono::duration<double> past = calc_end_time - calc_start_time;
        double time_spent = past.count();
        long long num_operations = 2LL * n * n * n;
        double gflops = (time_spent > 0) ? (num_operations / (time_spent * 1e9)) : 0.0;
        std::printf("RESULT: N=%u, Cores=%d, Time=%.6f, GFLOPS=%.4f\n", n, num_procs, time_spent, gflops);
        write_matrix(file_c, flat_C, n);
    }
    MPI_Finalize();
    return 0;
}


