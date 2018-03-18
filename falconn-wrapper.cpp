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

    void* compute_number_of_hash_functions(LSHConstructionParameters &params, int32_t num_hash_bits) {
        auto new_params = new LSHConstructionParameters(params);
        falconn::compute_number_of_hash_functions<Point>(num_hash_bits, new_params);
        return new_params;
    }

    void* get_default_parameters(int64_t dataset_size, int32_t dimension, int32_t distance_function, bool is_sufficiently_dense) {
        return new LSHConstructionParameters(falconn::get_default_parameters<Point>(
                dataset_size, dimension, static_cast<DistanceFunction>(distance_function), is_sufficiently_dense));
    }

    void* create_table(LSHConstructionParameters &params, int32_t num_points, int32_t num_dimensions, float *dataset) {
        PlainArrayPointSet<float> converted_points;
        converted_points.data = dataset;
        converted_points.num_points = num_points;
        converted_points.dimension = num_dimensions;
        return falconn::construct_table<Point>(converted_points, params).release();
    }

    // =============================================
    // QueryObject
    // =============================================

    LSHNearestNeighborQuery<Point>* create_query_object(LSHNearestNeighborTable<Point> &table, int32_t num_probes, int32_t max_num_candidates) {
        return table.construct_query_object(num_probes, max_num_candidates).release();
    }

    void qobj_set_num_probes(LSHNearestNeighborQuery<Point> &query_object, int32_t num_probes) {
        query_object.set_num_probes(num_probes);
    }

    results qobj_find_k_nearest_neighbors(LSHNearestNeighborQuery<Point> &query_object, float *p, int32_t k, int32_t num_dimensions) {
        auto result = new std::vector<int>();
        query_object.find_k_nearest_neighbors(Eigen::Map<Point>(p, num_dimensions, 1), k, result);
        return results { result->data(), result->size() };
    }

    // =============================================
    // QueryPool
    // =============================================
 
    LSHNearestNeighborQueryPool<Point>* create_query_pool(
            LSHNearestNeighborTable<Point> &table, int32_t num_probes, int32_t max_num_candidates, int32_t num_query_objects) {
        return table.construct_query_pool(num_probes, max_num_candidates, num_query_objects).release();
    }

    void qpool_set_num_probes(LSHNearestNeighborQueryPool<Point> &pool, int32_t num_probes) {
        pool.set_num_probes(num_probes);
    }

    results qpool_find_k_nearest_neighbors(LSHNearestNeighborQueryPool<Point> &pool, float *p, int32_t k, int32_t num_dimensions) {
        auto result = new std::vector<int>();
        pool.find_k_nearest_neighbors(Eigen::Map<Point>(p, num_dimensions, 1), k, result);
        return results { result->data(), result->size() };
    }

}

