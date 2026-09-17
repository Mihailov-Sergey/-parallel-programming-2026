import GenerateMatrix;
import std;

using Matrix = std::vector<std::vector<double>>;

bool read_matrix(const std::string& filename, Matrix& matrix, unsigned int n) {
	std::ifstream file(filename);
	if (!file.is_open()) {
		std::println(std::cerr, "Ошибка: Не удалось открыть файл {}", filename);
		return false;
	}
	matrix.assign(n, std::vector<double>(n));
	for (int i = 0; i < n; ++i) {
		for (int j = 0; j < n; ++j) {
			if (!(file >> matrix[i][j])) {
				std::println(std::cerr, "Ошибка: некорректное чтение матрицы в файле {}", filename);
				return false;
			}
		}
	}
	file.close();
	return true;
}

bool write_matrix(const std::string& filename, const Matrix& matrix) {
	std::ofstream file(filename);
	if (!file.is_open()) {
		std::println(std::cerr, "Ошибка: Не удалось открыть файл для вывода {}", filename);
		return false;
	}
	for (const auto& row : matrix) {
		for (const auto& val : row) {
			std::print(file, "{:.6f} ", val);
		}
		std::print(file, "\n");
	}
	file.close();
	return true;
}

int main() {
	unsigned int n = 1000; 
	std::println("Генерация матриц размером {}x{}...", n, n);
	std::string file_a = "matrixA.txt";
	std::string file_b = "matrixB.txt";
	std::string file_c = "resultC.txt";
	generate_test_file("matrixA.txt", n);
	generate_test_file("matrixB.txt", n);

	std::this_thread::sleep_for(std::chrono::milliseconds(50));
	if (!std::filesystem::exists(file_a) || !std::filesystem::exists(file_b)) {
		std::println(std::cerr, "Ошибка: Исходные файлы не найдены");
		return -1;
	}

	Matrix A, B;
	if (!read_matrix(file_a, A, n) || !read_matrix(file_b, B, n)) {
		std::println(std::cerr, "Ошибка: Чтение исходных матриц некорректно");
		return 1;
	}
	Matrix C(n, std::vector<double>(n, 0.0));

	auto start_time = std::chrono::steady_clock::now();
	for (int i = 0; i < n; ++i) {
		for (int k = 0; k < n; ++k) {
			double a = A[i][k];
			for (int j = 0; j < n; ++j) {
				C[i][j] += a * B[k][j];
			}
		}
	}
	auto end_time = std::chrono::steady_clock::now();
	std::chrono::duration<double> past = end_time - start_time;
	double time_spent = past.count();
	std::println("{}", time_spent);

	long long num_operations = 2LL * n * n * n;
	double gflops = (time_spent > 0) ? (num_operations / (time_spent * 1e9)) : 0.0;
	double memory_mb = static_cast<double>(3 * n * n * sizeof(double)) / (1024 * 1024);

	if (!write_matrix(file_c, C)) {
		std::println(std::cerr, "Ошибка: Запись результирующей матрицы не удалась");
		return 1;
	}

	std::println("Размерность матриц (N x N): {} x {}", n, n);
	std::println("Объем выделенной памяти: {:.2f} МБ", memory_mb);
	std::println("Количество операций (FLOP): {}", num_operations);
	std::println("Время выполнения: {:.6f} сек", time_spent);
	std::println("Производительность: {:.4f}  GFLOPS", gflops);
	std::println("");
	std::println("Результат успешно сохранен в файл: {}", file_c);

	return 0;
}

