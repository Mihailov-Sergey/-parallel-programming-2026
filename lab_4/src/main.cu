#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <chrono>
#include <string>
#include <thread>
#include <cstdio>
#include <iomanip>
#include "GenerateMatrix.h"

#define CUDA_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            std::cerr << "Ошибка CUDA (" << __FILE__ << ":" << __LINE__ << "): " \
                      << cudaGetErrorString(err) << std::endl; \
            return 1; \
        } \
    } while (0)

bool read_matrix_flat(const std::string& filename, std::vector<double>& flat_matrix, unsigned int n) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Ошибка: Не удалось открыть файл " << filename << std::endl;
        return false;
    }
    flat_matrix.resize(n * n);
    for (unsigned int i = 0; i < n * n; ++i) {
        if (!(file >> flat_matrix[i])) {
            std::cerr << "Ошибка: некорректное чтение матрицы в файле " << filename << std::endl;
            return false;
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

// CUDA-ядро перемножения матриц (каждый поток вычисляет один элемент C[row][col])
__global__ void matrixMulKernel(const double* A, const double* B, double* C, unsigned int n) {
    unsigned int row = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n) {
        double sum = 0.0;
        for (unsigned int k = 0; k < n; ++k) {
            sum += A[row * n + k] * B[k * n + col];
        }
        C[row * n + col] = sum;
    }
}

int main(int argc, char* argv[]) {
    unsigned int n = 1000;
    unsigned int block_size = 16; 
    bool need_generation = false;

    if (argc > 1) {
        try {
            n = std::stoi(argv[1]);
        } catch (...) {
            std::cerr << "Ошибка: неверный формат N. Использовано N=1000\n";
        }
    }

    if (argc > 2) {
        std::string arg2 = argv[2];
        if (arg2 == "--generate") {
            need_generation = true;
        } else {
            try {
                block_size = std::stoi(arg2);
            } catch (...) {
                std::cerr << "Ошибка: неверный размер блока. Использован блок 16x16\n";
            }
        }
    }

    std::string file_a = "matrixA.txt";
    std::string file_b = "matrixB.txt";
    std::string file_c = "resultC.txt";

    if (need_generation) {
        std::cout << "Генерация исходных матриц размером " << n << "x" << n << "...\n";
        generate_test_file(file_a, n);
        generate_test_file(file_b, n);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        return 0;
    }

    std::ifstream f_a(file_a), f_b(file_b);
    if (!f_a.good() || !f_b.good()) {
        std::cerr << "Критическая ошибка: Файлы данных не найдены! Запустите с флагом --generate\n";
        return -1;
    }
    f_a.close();
    f_b.close();

    std::vector<double> flat_A, flat_B;
    if (!read_matrix_flat(file_a, flat_A, n) || !read_matrix_flat(file_b, flat_B, n)) {
        std::cerr << "Ошибка: Чтение исходных матриц некорректно\n";
        return 1;
    }
    std::vector<double> flat_C(n * n, 0.0);

    size_t bytes = n * n * sizeof(double);
    double *d_A = nullptr, *d_B = nullptr, *d_C = nullptr;

    // Инициализация контекста GPU перед замером времени
    CUDA_CHECK(cudaFree(0));

    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));

    // Настройка двумерной конфигурации сетки и блоков
    dim3 threadsPerBlock(block_size, block_size);
    dim3 blocksPerGrid((n + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (n + threadsPerBlock.y - 1) / threadsPerBlock.y);

    // Старт замера (включает пересылку данных по PCIe + вычисления на GPU)
    auto calc_start_time = std::chrono::steady_clock::now();

    CUDA_CHECK(cudaMemcpy(d_A, flat_A.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, flat_B.data(), bytes, cudaMemcpyHostToDevice));

    matrixMulKernel<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaMemcpy(flat_C.data(), d_C, bytes, cudaMemcpyDeviceToHost));

    auto calc_end_time = std::chrono::steady_clock::now();

    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));

    std::chrono::duration<double> past = calc_end_time - calc_start_time;
    double time_spent = past.count();
    long long num_operations = 2LL * n * n * n;
    double gflops = (time_spent > 0) ? (num_operations / (time_spent * 1e9)) : 0.0;

    // Вывод результатов и параметров сетки для автоматического отчета
    std::printf("RESULT: N=%u, Block=%ux%u, Grid=%ux%u, Time=%.6f, GFLOPS=%.4f\n", 
                n, block_size, block_size, blocksPerGrid.x, blocksPerGrid.y, time_spent, gflops);
    
    write_matrix(file_c, flat_C, n);

    return 0;
}
