#!/bin/bash
#SBATCH --job-name=mpi_matrix_lab       
#SBATCH --output=matrix_report.txt 
#SBATCH --error=matrix_errors.err 
#SBATCH --partition=batch             
#SBATCH --nodes=1                       
#SBATCH --ntasks-per-node=16             
#SBATCH --time=00:20:00                 

module purge
module load intel/icc18
module load intel/mpi5

echo ""
echo "=== СТАРТ СЕРИИ ЭКСПЕРИМЕНТОВ ==="
echo "Дата и время запуска: $(date)"
echo ""

SIZES=(200 400 800 1200 1600 2000)
CORES=(1 2 4 8 12 16)

echo "-----------------------------------------------------------------"
printf "| %-10s | %-8s | %-15s | %-15s |\n" "Размер (N)" "Ядра (p)" "Время (сек)" "GFLOPS"
echo "-----------------------------------------------------------------"

for n in "${SIZES[@]}"; do
    # Запускаем генерацию матриц на готовом исполняемом файле
    mpirun -np 1 ./mpi_matrix $n --generate > /dev/null

    for c in "${CORES[@]}"; do
        RUN_OUTPUT=$(mpirun -np $c -bootstrap slurm ./mpi_matrix $n)
        
        # Парсим строку вида "RESULT: N=200, Cores=4, Time=0.012345, GFLOPS=1.2345"
        TIME_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*Time=([^,]*).*/\1/')
        GFLOPS_VAL=$(echo "$RUN_OUTPUT" | grep "RESULT:" | sed -E 's/.*GFLOPS=(.*)/\1/')
        
        # Форматируем строку и дописываем её в таблицу отчета
        printf "| %-10d | %-8d | %-15s | %-15s |\n" $n $c "$TIME_VAL" "$GFLOPS_VAL"
    done
    echo "-----------------------------------------------------------------"
done

echo ""
echo "=== ВСЕ ЭКСПЕРИМЕНТЫ УСПЕШНО ЗАВЕРШЕНЫ ==="

rm -f matrixA.txt matrixB.txt resultC.txt
