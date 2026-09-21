import numpy

A = numpy.loadtxt("matrixA.txt")
B = numpy.loadtxt("matrixB.txt")
C_cpp = numpy.loadtxt("resultC.txt")

C_numpy = A @ B

if numpy.allclose(C_cpp, C_numpy, atol=1e-5):
    print("Матрицы совпадают.")
else:
    print("Результаты не совпадают.")
