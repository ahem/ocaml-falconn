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
using falconn::LSHNearestNeighborQueryPool;
using falconn::LSHNearestNeighborTable;
using falconn::PlainArrayPointSet;
using falconn::StorageHashTable;

typedef DenseVector<float> Point;
extern "C" {

    struct results {
        int *arr;
        uint64_t length;
    };

    void* create_params(
            int32_t l,
            int32_t k,
            int32_t num_dimensions,
            int32_t num_rotations,
            int32_t num_setup_threads,
            int32_t lsh_family,
            int32_t distance_function,
            int32_t storage_hash_table) {
        auto params = new LSHConstructionParameters();
        params->l = l;
        params->k = k,
        params->dimension = num_dimensions;
        params->num_rotations = num_rotations;
        params->num_setup_threads = num_setup_threads;
        params->lsh_family = static_cast<LSHFamily>(lsh_family);
        params->distance_function = static_cast<DistanceFunction>(distance_function);
        params->storage_hash_table = static_cast<StorageHashTable>(storage_hash_table);
        return params;
    }

    void* compute_number_of_hash_functions(void *params_ptr, int32_t num_hash_bits) {
        auto params = *((LSHConstructionParameters*)params_ptr);
        auto new_params = new LSHConstructionParameters(params);
        falconn::compute_number_of_hash_functions<Point>(num_hash_bits, new_params);
        return new_params;
    }

    void* create_table(void *params_ptr, int32_t num_points, int32_t num_dimensions, float *dataset) {
        LSHConstructionParameters params = *((LSHConstructionParameters*)params_ptr);

        PlainArrayPointSet<float> converted_points;
        converted_points.data = dataset;
        converted_points.num_points = num_points;
        converted_points.dimension = num_dimensions;

        return falconn::construct_table<Point>(converted_points, params).release();
    }

    // =============================================
    // QueryObject
    // =============================================

    // TODO: max_num_candidates
    void* create_query_object(void *table_ptr, int32_t num_probes) {
        auto *table = (LSHNearestNeighborTable<Point>*)table_ptr;
        return table->construct_query_object(num_probes).release();
    }

    void qobj_set_num_probes(void *query_object_ptr, int32_t num_probes) {
        auto *query_object = (LSHNearestNeighborQuery<Point>*)query_object_ptr;
        query_object->set_num_probes(num_probes);
    }

    results qobj_find_k_nearest_neighbors(void* query_object_ptr, float *p, int32_t k, int32_t num_dimensions) {
        auto q = Eigen::Map<Point>(p, num_dimensions, 1);
        auto *query_object = (LSHNearestNeighborQuery<Point>*)query_object_ptr;
        auto result = new std::vector<int>();
        query_object->find_k_nearest_neighbors(q, k, result);
        return results { result->data(), result->size() };
    }

    // =============================================
    // QueryObject
    // =============================================
 
    void* create_query_pool(void *table_ptr, int32_t num_probes, int32_t max_num_candidates, int32_t num_query_objects) {
        auto *table = (LSHNearestNeighborTable<Point>*)table_ptr;
        return table->construct_query_pool(num_probes, max_num_candidates, num_query_objects).release();
    }

    results qpool_find_k_nearest_neighbors(void* query_pool_ptr, float *p, int32_t k, int32_t num_dimensions) {
        auto q = Eigen::Map<Point>(p, num_dimensions, 1);
        auto *query_pool = (LSHNearestNeighborQueryPool<Point>*)query_pool_ptr;
        auto result = new std::vector<int>();
        query_pool->find_k_nearest_neighbors(q, k, result);
        return results { result->data(), result->size() };
    }

}

