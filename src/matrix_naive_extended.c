#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

int main(int argc, char *argv[]){
    int N;
    struct timeval start, end;
    
    if (argc < 2) {
        printf("Usage: %s <matrix_size>\n", argv[0]);
        return 1;
    }
    
    srand(time(NULL));
    N = atoi(argv[1]);
    
    // Dynamically allocate memory for matrices
    double (*A)[N] = malloc(N * sizeof(*A));
    double (*B)[N] = malloc(N * sizeof(*B));
    double (*C)[N] = malloc(N * sizeof(*C));
    
    if (!A || !B || !C) {
        printf("Memory allocation failed!\n");
        return 1;
    }
    
    // Initialize matrices with normalized random values
    for(int i = 0; i < N; i++){
        for(int j = 0; j < N; j++){
            A[i][j] = (double)rand() / RAND_MAX * 10.0;  // 0-10 range
            B[i][j] = (double)rand() / RAND_MAX * 10.0;
            C[i][j] = 0.0;
        }
    }
    
    printf("=== Naive Matrix Multiplication ===\n");
    printf("Matrix size: %dx%d\n", N, N);
    printf("Starting multiplication...\n");
    
    gettimeofday(&start, NULL);

    for(int i=0; i < 100000; i++){
    // Matrix multiplication
    for(int i = 0; i < N; i++){
        for(int j = 0; j < N; j++){
            for(int k = 0; k < N; k++){
                C[i][j] += A[i][k] * B[k][j];
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
