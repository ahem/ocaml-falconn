#include <vector>
#include <fstream>
#include <iterator>
#include <memory>
#include <iostream>

#include <falconn/lsh_nn_table.h>

using falconn::DenseVector;
using falconn::DistanceFunction;
using falconn::LSHConstructionParameters;
using falconn::LSHFamily;
using falconn::LSHNearestNeighborQuery;
using falconn::LSHNearestNeighborTable;
using falconn::PlainArrayPointSet;
using falconn::StorageHashTable;
using falconn::compute_number_of_hash_functions;
using falconn::construct_table;

typedef DenseVector<float> Point;

extern "C" void* create_table(int num_hash_tables, int num_hash_bits, int num_rotations, int num_points, int num_dimensions, float *dataset) {
    PlainArrayPointSet<float> converted_points;
    converted_points.data = dataset;
    converted_points.num_points = num_points;
    converted_points.dimension = num_dimensions;

    LSHConstructionParameters params;
    params.l = num_hash_tables;
    params.dimension = num_dimensions;
    params.lsh_family = LSHFamily::CrossPolytope;
    params.distance_function = DistanceFunction::EuclideanSquared;
    params.num_rotations = num_rotations;
    params.storage_hash_table = StorageHashTable::BitPackedFlatHashTable;
    params.num_setup_threads = 0; // 0 means all available threads
    compute_number_of_hash_functions<Point>(num_hash_bits, &params);
    return construct_table<Point>(converted_points, params).release();
}

extern "C" void* create_query_object(void *table_ptr, int num_probes) {
    auto *table = (LSHNearestNeighborTable<Point>*)table_ptr;
    return table->construct_query_object(num_probes).release();
}

// FIXME: this should probably return a struct with both a count and the indexes
extern "C" int* find_k_nearest_neighbors(void* query_object_ptr, float *p, int k, int num_dimensions) {
    auto q = Eigen::Map<Point>(p, num_dimensions, 1);
    auto *query_object = (LSHNearestNeighborQuery<Point>*)query_object_ptr;
    auto result = new std::vector<int>();
    query_object->find_k_nearest_neighbors(q, k, result);
    return result->data();
}

