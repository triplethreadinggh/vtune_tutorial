#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include <omp.h>

int min(int a, int b) {
    return (a < b) ? a : b;
}

int main(int argc, char *argv[]){
    int N, block_size, num_threads;
    struct timeval start, end;
    
    if (argc < 2) {
        printf("Usage: %s <matrix_size> [block_size] [num_threads]\n", argv[0]);
        return 1;
    }
    
    srand(time(NULL));
    N = atoi(argv[1]);
    block_size = (argc > 2) ? atoi(argv[2]) : 64;  // Default block size = 64
    num_threads = (argc > 3) ? atoi(argv[3]) : omp_get_max_threads();
    
    omp_set_num_threads(num_threads);
    
    // Dynamically allocate memory for matrices
    double (*A)[N] = malloc(N * sizeof(*A));
    double (*B)[N] = malloc(N * sizeof(*B));
    double (*C)[N] = malloc(N * sizeof(*C));
    
    if (!A || !B || !C) {
        printf("Memory allocation failed!\n");
        return 1;
    }
    
    // Initialize matrices
    for(int i = 0; i < N; i++){
        for(int j = 0; j < N; j++){
            A[i][j] = (double)rand() / RAND_MAX * 10.0;
            B[i][j] = (double)rand() / RAND_MAX * 10.0;
            C[i][j] = 0.0;
        }
    }
    
    printf("=== Parallel Blocked Matrix Multiplication ===\n");
    printf("Matrix size: %dx%d\n", N, N);
    printf("Block size: %d\n", block_size);
    printf("Number of threads: %d\n", num_threads);
    printf("Starting multiplication...\n");
    
    gettimeofday(&start, NULL);
    
    // Parallel blocked matrix multiplication
    #pragma omp parallel for schedule(dynamic)
    for(int ii = 0; ii < N; ii += block_size){
        for(int jj = 0; jj < N; jj += block_size){
            for(int kk = 0; kk < N; kk += block_size){
                // Multiply block
                for(int i = ii; i < min(ii + block_size, N); i++){
                    for(int j = jj; j < min(jj + block_size, N); j++){
                        double sum = C[i][j];
                        for(int k = kk; k < min(kk + block_size, N); k++){
                            sum += A[i][k] * B[k][j];
                        }
                        C[i][j] = sum;
                    }
                }
            }
        }
    }
    
    gettimeofday(&end, NULL);
    
    // Calculate elapsed time
    long seconds = end.tv_sec - start.tv_sec;
    long microseconds = end.tv_usec - start.tv_usec;
    
    // Handle microsecond wrap around
    if(microseconds < 0){
        seconds -= 1;
        microseconds += 1000000;
    }
    
    double elapsed_sec = seconds + microseconds / 1000000.0;
    long total_usec = seconds * 1000000 + microseconds;
    
    printf("Time elapsed: %.3f seconds\n", elapsed_sec);
    printf("Elapsed time in microseconds: %ld\n", total_usec);
    
    // Calculate GFLOPS
    double gflops = (2.0 * N * N * N) / (elapsed_sec * 1e9);
    printf("Performance: %.2f GFLOPS\n", gflops);
    
    // Free memory
    free(A);
    free(B);
    free(C);
    
    return 0;
}
