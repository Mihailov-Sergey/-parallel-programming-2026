export module GenerateMatrix;

import std;

export void generate_test_file(const std::string& filename, unsigned int n) {
	std::ofstream file(filename);
	if (!file.is_open()) {
		std::print(std::cerr, "Ошибка: Файл не сгенерирован {}", filename);
		return;
	}
	std::random_device rd;
	std::mt19937 gen(rd());
	std::uniform_real_distribution<double> dis(-10.0, 10.0);
	for (unsigned int i = 0; i < n; ++i) {
		for (unsigned int j = 0; j < n; ++j) {
			std::print(file, "{:.6f} ", dis(gen));
		}
		std::print(file, "\n");
	}
	file.close();
}