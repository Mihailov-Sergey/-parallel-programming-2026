import matplotlib.pyplot as plt
import numpy as np

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4))

# 1. Сравнение ускорения (View 1 и View 2)
labels = ['Serial', 'ISPC\n(1 core)', 'ISPC\n(2 tasks)', 'ISPC\n(80 tasks)']
v1 = [1.00, 5.21, 8.86, 36.43]
v2 = [1.00, 6.65, 9.68, 37.75]

x = np.arange(len(labels))
w = 0.35

ax1.bar(x - w/2, v1, w, label='View 1')
ax1.bar(x + w/2, v2, w, label='View 2')
ax1.axhline(32, color='r', linestyle='--', label='32x target')
ax1.set_ylabel('Speedup')
ax1.set_title('Speedup comparison')
ax1.set_xticks(x)
ax1.set_xticklabels(labels)
ax1.legend()
ax1.grid(axis='y')

# 2. Зависимость ускорения от числа задач (View 1)
tasks = ['1', '2', '4', '8', '16', '32', '80', '160', '400']
speedups = [5.21, 8.86, 16.40, 27.15, 32.80, 35.60, 36.43, 36.35, 35.80]

ax2.plot(tasks, speedups, marker='o')
ax2.axhline(32, color='r', linestyle='--', label='32x target')
ax2.set_xlabel('Number of tasks')
ax2.set_ylabel('Speedup (View 1)')
ax2.set_title('Speedup vs number of tasks')
ax2.legend()
ax2.grid(True)

plt.tight_layout()
plt.savefig('program3_speedup.png')

