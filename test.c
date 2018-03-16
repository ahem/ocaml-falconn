#include <stdio.h>
#include <stdlib.h>

#include "./falconn-wrapper.h"

int main(void) {
    const int NUM_HASH_TABLES = 10;
    const int NUM_HASH_BITS = 20;
    const int NUM_ROTATIONS = 1;
    const int NUM_PROBES = 80;

    printf("start\n");

    FILE *file = fopen("/Users/ahm/Projects/lda/lda.dat","rb");;
    float *dataset = malloc(400000 * 250 * sizeof(float));
    fread(dataset, sizeof(float), 400000 * 250, file);

    printf("loaded dataset from file\n");

    void *table = create_table(NUM_HASH_TABLES, NUM_HASH_BITS, NUM_ROTATIONS, 400000, 250, dataset);

    printf("created table\n");

    void *query_object = create_query_object(table, NUM_PROBES);

    printf("created query_object\n");

    int *results = find_k_nearest_neighbors(query_object, dataset, 10, 250);

    for (int i = 0; i < 10; i++) {
        printf("%d\n", results[i]);
    }
}


