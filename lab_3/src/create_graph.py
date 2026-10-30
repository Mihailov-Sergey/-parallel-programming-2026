import os
import matplotlib.pyplot as plt

os.makedirs("../reports", exist_ok=True)

sizes = [200, 400, 800, 1200, 1600, 2000]
cores = [1, 2, 4, 8, 12, 16]

time_data = {
    200:  [0.010274, 0.005542, 0.002911, 0.001992, 0.001750, 0.001416],
    400:  [0.064514, 0.033140, 0.017260, 0.009957, 0.007676, 0.006348],
    800:  [0.402511, 0.204377, 0.105143, 0.070045, 0.062723, 0.058676],
    1200: [1.350834, 0.686186, 0.457645, 0.273287, 0.206417, 0.189076],
    1600: [3.608402, 1.796845, 1.140199, 0.643061, 0.483149, 0.445296],
    2000: [8.786574, 4.212135, 2.214973, 1.259845, 0.929721, 0.854055]
}

gflops_data = {
    200:  [1.5573, 2.8868, 5.4961, 8.0315, 9.1412, 11.2999],
    400:  [1.9841, 3.8624, 7.4159, 12.8549, 16.6752, 20.1628],
    800:  [2.5440, 5.0103, 9.7391, 14.6192, 16.3258, 17.4519],
    1200: [2.5584, 5.0365, 7.5517, 12.6460, 16.7428, 18.2784],
    1600: [2.2703, 4.5591, 7.1847, 12.7391, 16.9554, 18.3967],
    2000: [1.8210, 3.7985, 7.2236, 12.7000, 17.2095, 18.7342]
}

plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

# ГРАФИК 1: Ускорение S(p) = T(1) / T(p)
plt.figure(figsize=(7, 5))
plt.plot(cores, cores, 'k--', alpha=0.5, label="Идеальное ускорение")

for n in sizes:
    t1 = time_data[n][0]
    speedup = [t1 / tp for tp in time_data[n]]
    plt.plot(cores, speedup, marker='o', linewidth=2, label=f"N = {n}")

plt.title("Зависимость ускорения S(p) от числа ядер", fontsize=12, fontweight='bold')
plt.xlabel("Количество ядер (p)", fontsize=10)
plt.ylabel("Ускорение S", fontsize=10)
plt.xticks(cores)
plt.legend(frameon=True)
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig("../reports/speedup_plot.png", dpi=300)
plt.close()

# ГРАФИК 2: Эффективность E(p) = S(p) / p
plt.figure(figsize=(7, 5))
for n in sizes:
    t1 = time_data[n][0]
    efficiency = [(t1 / tp) / p for tp, p in zip(time_data[n], cores)]
    plt.plot(cores, efficiency, marker='s', linewidth=2, label=f"N = {n}")

plt.title("Эффективность использования ядер E(p)", fontsize=12, fontweight='bold')
plt.xlabel("Количество ядер (p)", fontsize=10)
plt.ylabel("Эффективность E", fontsize=10)
plt.xticks(cores)
plt.ylim(0, 1.1)
plt.legend(frameon=True)
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig("../reports/efficiency_plot.png", dpi=300)
plt.close()

# ГРАФИК 3: Производительность (GFLOPS)
plt.figure(figsize=(7, 5))
for n in sizes:
    plt.plot(cores, gflops_data[n], marker='^', linewidth=2, label=f"N = {n}")

plt.title("Производительность вычислений (GFLOPS)", fontsize=12, fontweight='bold')
plt.xlabel("Количество ядер (p)", fontsize=10)
plt.ylabel("Производительность (GFLOPS)", fontsize=10)
plt.xticks(cores)
plt.legend(frameon=True)
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig("../reports/gflops_plot.png", dpi=300)
plt.close()

