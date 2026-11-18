#!/bin/bash
#SBATCH --job-name=cuda_matrix_lab       
#SBATCH --output=cuda_report.txt 
#SBATCH --error=cuda_errors.err 
#SBATCH --partition=batch
#SBATCH --gres=gpu:tesla:1
#SBATCH --nodes=1                       
#SBATCH --ntasks=1             
#SBATCH --time=00:20:00                 

module purge
module load cuda/8.0

# Компилируем прямо на вычислительном узле под C++11
nvcc -O3 -std=c++11 GenerateMatrix.cpp main.cu -o cuda_matrix

echo ""
echo "=== ХАРАКТЕРИСТИКИ ВЫЧИСЛИТЕЛЬНОГО УЗЛА И GPU ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo ""
echo "=== СТАРТ СЕРИИ ЭКСПЕРИМЕНТОВ CUDA ==="
echo "Дата и время запуска: $(date)"
echo ""

SIZES=(200 400 800 1200 1600 2000)
BLOCKS=(4 8 16 32)

echo "---------------------------------------------------------------------------------"
printf "| %-10s | %-12s | %-14s | %-15s | %-15s |\n" "Размер (N)" "Блок (BxB)" "Сетка (GxG)" "Время (сек)" "GFLOPS"
echo "---------------------------------------------------------------------------------"

for n in "${SIZES[@]}"; do
    # Генерируем исходные матрицы один раз для текущего размера N
    ./cuda_matrix $n --generate > /dev/null

    for b in "${BLOCKS[@]}"; do
        RUN_OUTPUT=$(./cuda_matrix $n $b)
        
        # Парсим параметры из строки RESULT
        BLOCK_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*Block=([^,]*).*/\1/')
        GRID_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*Grid=([^,]*).*/\1/')
        TIME_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*Time=([^,]*).*/\1/')
        GFLOPS_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*GFLOPS=(.*)/\1/')
        
        printf "| %-10d | %-12s | %-14s | %-15s | %-15s |\n" $n "$BLOCK_VAL" "$GRID_VAL" "$TIME_VAL" "$GFLOPS_VAL"
    done
    echo "---------------------------------------------------------------------------------"
done

echo ""
echo "=== ВСЕ ЭКСПЕРИМЕНТЫ УСПЕШНО ЗАВЕРШЕНЫ ==="

rm -f matrixA.txt matrixB.txt resultC.txt
