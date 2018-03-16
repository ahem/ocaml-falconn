#pragma once
#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

EXTERNC void* create_table(int num_hash_tables, int num_hash_bits, int num_rotations, int num_points, int num_dimensions, float *dataset);
EXTERNC void* create_query_object(void *table_ptr, int num_probes);
EXTERNC int* find_k_nearest_neighbors(void* query_object_ptr, float *p, int k, int num_dimensions);

#undef EXTERNC

