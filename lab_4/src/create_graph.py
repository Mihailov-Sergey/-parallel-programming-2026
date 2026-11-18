import matplotlib.pyplot as plt

sizes = [200, 400, 800, 1200, 1600, 2000]

time_data = {
    "4x4 (16 потоков)":    [0.001712, 0.012240, 0.098057, 0.327083, 0.776615, 1.491609],
    "8x8 (64 потока)":     [0.000855, 0.004660, 0.029630, 0.095729, 0.224813, 0.442079],
    "16x16 (256 потоков)": [0.000862, 0.004608, 0.027983, 0.082545, 0.198817, 0.386092],
    "32x32 (1024 потока)": [0.000932, 0.004791, 0.029093, 0.094169, 0.214970, 0.415075]
}

gflops_data = {
    "4x4 (16 потоков)":    [9.3472, 10.4579, 10.4429, 10.5661, 10.5483, 10.7267],
    "8x8 (64 потока)":     [18.7136, 27.4679, 34.5601, 36.1019, 36.4392, 36.1926],
    "16x16 (256 потоков)": [18.5596, 27.7806, 36.5937, 41.8681, 41.2037, 41.4409],
    "32x32 (1024 потока)": [17.1739, 26.7183, 35.1977, 36.7001, 38.1077, 38.5472]
}

styles = [
    {"color": "#d62728", "marker": "o", "linestyle": "-"},
    {"color": "#ff7f0e", "marker": "s", "linestyle": "--"},
    {"color": "#2ca02c", "marker": "^", "linestyle": "-"},
    {"color": "#1f77b4", "marker": "D", "linestyle": "-."}
]

# ==========================================
# ГРАФИК 1: Время выполнения (cuda_time.png)
# ==========================================
plt.figure(figsize=(10, 6), dpi=150)

for (label, values), style in zip(time_data.items(), styles):
    plt.plot(
        sizes, values,
        label=label,
        color=style["color"],
        marker=style["marker"],
        linestyle=style["linestyle"],
        linewidth=2.2,
        markersize=7,
        markeredgecolor="white",
        markeredgewidth=1
    )

plt.title("Зависимость времени выполнения перемножения матриц от размера (N)", fontsize=13, fontweight="bold", pad=12)
plt.xlabel("Размер матрицы N (N × N)", fontsize=11)
plt.ylabel("Время выполнения, сек", fontsize=11)
plt.xticks(sizes)
plt.ylim(-0.05, 1.62)
plt.grid(True, linestyle="--", alpha=0.6)
plt.legend(title="Конфигурация блока потоков", fontsize=10, title_fontsize=10, loc="upper left", frameon=True)
plt.tight_layout()
plt.savefig("cuda_time.png", dpi=300)
plt.show()

# ==================================================
# ГРАФИК 2: Производительность (cuda_gflops.png)
# ==================================================
plt.figure(figsize=(10, 6), dpi=150)

for (label, values), style in zip(gflops_data.items(), styles):
    plt.plot(
        sizes, values,
        label=label,
        color=style["color"],
        marker=style["marker"],
        linestyle=style["linestyle"],
        linewidth=2.2,
        markersize=7,
        markeredgecolor="white",
        markeredgewidth=1
    )

plt.title("Производительность вычислений (GFLOPS) на NVIDIA Tesla M2070", fontsize=13, fontweight="bold", pad=12)
plt.xlabel("Размер матрицы N (N × N)", fontsize=11)
plt.ylabel("Производительность, GFLOPS", fontsize=11)
plt.xticks(sizes)
plt.ylim(0, 46)
plt.grid(True, linestyle="--", alpha=0.6)
plt.legend(title="Конфигурация блока потоков", fontsize=10, title_fontsize=10, loc="lower right", frameon=True)
plt.tight_layout()
plt.savefig("cuda_gflops.png", dpi=300)
plt.show()

