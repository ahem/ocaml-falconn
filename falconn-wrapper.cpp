#include <vector>

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
using falconn::QueryStatistics;


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

    void free_params(LSHConstructionParameters *params) {
        delete params;
    }

    void* create_table(LSHConstructionParameters &params, int32_t num_points, int32_t num_dimensions, float *dataset) {
        PlainArrayPointSet<float> converted_points;
        converted_points.data = dataset;
        converted_points.num_points = num_points;
        converted_points.dimension = num_dimensions;
        return falconn::construct_table<Point>(converted_points, params).release();
    }

    void free_table(LSHNearestNeighborTable<Point> *table) {
        delete table;
    }

    // =============================================
    // QueryObject
    // =============================================

    LSHNearestNeighborQuery<Point>* qobj_create(LSHNearestNeighborTable<Point> &table, int32_t num_probes, int64_t max_num_candidates) {
        return table.construct_query_object(num_probes, max_num_candidates).release();
    }

    void qobj_free(LSHNearestNeighborQuery<Point> *query_object) {
        delete query_object;
    }

    void qobj_set_num_probes(LSHNearestNeighborQuery<Point> &query_object, int32_t num_probes) {
        query_object.set_num_probes(num_probes);
    }
    
    int32_t qobj_get_num_probes(LSHNearestNeighborQuery<Point> &query_object) {
        return query_object.get_num_probes();
    }

    void qobj_set_max_num_candidates(LSHNearestNeighborQuery<Point> &query_object, int64_t max_num_candidates) {
        query_object.set_max_num_candidates(max_num_candidates);
    }

    int64_t qobj_get_max_num_candidates(LSHNearestNeighborQuery<Point> &query_object) {
        return query_object.get_max_num_candidates();
    }

    int32_t qobj_find_nearest_neighbor(LSHNearestNeighborQueryPool<Point> &query_object, float *p, int32_t num_dimensions) {
        return query_object.find_nearest_neighbor(Eigen::Map<Point>(p, num_dimensions, 1));
    }

    results qobj_find_k_nearest_neighbors(LSHNearestNeighborQuery<Point> &query_object, float *p, int32_t k, int32_t num_dimensions) {
        auto result = new std::vector<int>();
        query_object.find_k_nearest_neighbors(Eigen::Map<Point>(p, num_dimensions, 1), k, result);
        return results { result->data(), result->size() };
    }

    QueryStatistics* qobj_get_query_statistics(LSHNearestNeighborQuery<Point> &query_object) {
        return new QueryStatistics(query_object.get_query_statistics());
    }

    // =============================================
    // QueryPool
    // =============================================
 
    LSHNearestNeighborQueryPool<Point>* qpool_create(
            LSHNearestNeighborTable<Point> &table, int32_t num_probes, int64_t max_num_candidates, int32_t num_query_objects) {
        return table.construct_query_pool(num_probes, max_num_candidates, num_query_objects).release();
    }

    void qpool_free(LSHNearestNeighborQueryPool<Point> *pool) {
        delete pool;
    }

    void qpool_set_num_probes(LSHNearestNeighborQueryPool<Point> &pool, int32_t num_probes) {
        pool.set_num_probes(num_probes);
    }

    int32_t qpool_get_num_probes(LSHNearestNeighborQueryPool<Point> &pool) {
        return pool.get_num_probes();
    }

    int32_t qpool_find_nearest_neighbor(LSHNearestNeighborQueryPool<Point> &pool, float *p, int32_t num_dimensions) {
        return pool.find_nearest_neighbor(Eigen::Map<Point>(p, num_dimensions, 1));
    }

    void qpool_set_max_num_candidates(LSHNearestNeighborQuery<Point> &pool, int64_t max_num_candidates) {
        pool.set_max_num_candidates(max_num_candidates);
    }

    int64_t qpool_get_max_num_candidates(LSHNearestNeighborQuery<Point> &pool) {
        return pool.get_max_num_candidates();
    }

    results qpool_find_k_nearest_neighbors(LSHNearestNeighborQueryPool<Point> &pool, float *p, int32_t k, int32_t num_dimensions) {
        auto result = new std::vector<int>();
        pool.find_k_nearest_neighbors(Eigen::Map<Point>(p, num_dimensions, 1), k, result);
        return results { result->data(), result->size() };
    }

    QueryStatistics* qpool_get_query_statistics(LSHNearestNeighborQueryPool<Point> &pool) {
        return new QueryStatistics(pool.get_query_statistics());
    }

    // =============================================
    // QueryStatistics
    // =============================================
    
    void free_query_statistics(QueryStatistics *stats) {
        delete stats;
    }
}
