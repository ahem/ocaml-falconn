open Bigarray
open Ctypes
open Foreign

let libfalconn = Dl.dlopen ~flags:[Dl.RTLD_LAZY] ~filename:"./libfalconn-wrapper.so"

module LSHConstructionParameters = struct

  type lsh_family_t = Unknown | CrossPolytope | Hyperplane
  type distance_function_t = Unknown | EuclideanSquared | NegativeInnerProduct
  type storage_hash_table_t = Unknown | BitPackedFlatHashTable | FlatHashTable | LinearProbingHashTable | STLHashTable
  type t = {
    dimension: int;
    lsh_family: lsh_family_t;
    distance_function: distance_function_t;
    k: int;
    l: int;
    storage_hash_table: storage_hash_table_t;
    num_setup_threads: int;
    seed: int;
    last_cp_dimension: int;
    num_rotations: int;
    feature_hashing_dimension: int;
  }

  type params
  let params : params structure typ = structure "LSHConstructionParameters"
  let dimension                 = field params "dimension" int32_t
  let lsh_family                = field params "lsh_family" int32_t
  let distance_function         = field params "distance_function" int32_t
  let k                         = field params "k" int32_t
  let l                         = field params "l" int32_t
  let storage_hash_table        = field params "storage_hash_table" int32_t
  let num_setup_threads         = field params "num_setup_threads" int32_t
  let seed                      = field params "seed" int64_t
  let last_cp_dimension         = field params "last_cp_dimension" int32_t
  let num_rotations             = field params "num_rotations" int32_t
  let feature_hashing_dimension = field params "feature_hashing_dimension" int32_t
  let () = seal params

  let to_struct (a : t) =
    let p = make params in
    setf p dimension (Int32.of_int a.dimension);
    setf p lsh_family (Int32.of_int (match a.lsh_family with Unknown -> 0 | Hyperplane -> 1 | CrossPolytope -> 2));
    setf p distance_function (Int32.of_int (match a.distance_function with Unknown -> 0 | NegativeInnerProduct -> 1 | EuclideanSquared -> 2));
    setf p k (Int32.of_int a.k);
    setf p l (Int32.of_int a.l);
    setf p storage_hash_table (Int32.of_int (match a.storage_hash_table with
      | Unknown -> 0 | FlatHashTable -> 1 | BitPackedFlatHashTable -> 2 | STLHashTable -> 3 | LinearProbingHashTable -> 4));
    setf p num_setup_threads (Int32.of_int a.num_setup_threads);
    setf p seed (Int64.of_int a.seed);
    setf p last_cp_dimension (Int32.of_int a.last_cp_dimension);
    setf p num_rotations (Int32.of_int a.num_rotations);
    setf p feature_hashing_dimension (Int32.of_int a.feature_hashing_dimension);
    p

  let from_struct p = {
    dimension = Int32.to_int (getf p dimension);
    lsh_family = (match (Int32.to_int (getf p lsh_family)) with 1 -> Hyperplane | 2 -> CrossPolytope | _ -> Unknown);
    distance_function = (match (Int32.to_int (getf p distance_function)) with 1 -> NegativeInnerProduct | 2 -> EuclideanSquared | _ -> Unknown);
    k = Int32.to_int (getf p k);
    l = Int32.to_int (getf p l);
    storage_hash_table = (match (Int32.to_int (getf p storage_hash_table)) with
      1 -> FlatHashTable | 2 -> BitPackedFlatHashTable | 3 -> STLHashTable | 4 -> LinearProbingHashTable | _ -> Unknown);
    num_setup_threads = Int32.to_int (getf p num_setup_threads);
    seed = Int64.to_int (getf p seed);
    last_cp_dimension = Int32.to_int (getf p last_cp_dimension);
    num_rotations = Int32.to_int (getf p num_rotations);
    feature_hashing_dimension = Int32.to_int (getf p feature_hashing_dimension);
  }

  let empty = {
    dimension = (-1);
    lsh_family = Unknown;
    distance_function = Unknown;
    k = (-1);
    l = (-1);
    storage_hash_table = Unknown;
    num_setup_threads = (-1);
    seed = 409556018;
    last_cp_dimension = (-1);
    num_rotations = (-1);
    feature_hashing_dimension = (-1);
  }

  let _get_default_parameters =
    foreign ~from:libfalconn "get_default_parameters"
      (int64_t @-> int32_t @-> int32_t @-> int32_t @-> returning (ptr params))

  let get_default_parameters (dataset_size: int) (dimension: int) (distance_function: distance_function_t) (is_sufficiently_dense: bool) : t = 
    let dataset_size = Int64.of_int dataset_size in
    let dimension = Int32.of_int dimension in
    let distance_function = Int32.of_int (match distance_function with Unknown -> 0 | NegativeInnerProduct -> 1 | EuclideanSquared -> 2) in
    let is_sufficiently_dense = (Int32.of_int (match is_sufficiently_dense with true -> 1 | false -> 0)) in
    _get_default_parameters dataset_size dimension distance_function is_sufficiently_dense |> fun p -> (from_struct !@p)

  let _compute_number_of_hash_functions =
    foreign ~from:libfalconn "compute_number_of_hash_functions"
      (ptr params @-> int32_t @-> returning (ptr params))

  let compute_number_of_hash_functions (p: t) (num_of_hash_bits: int) : t =
    _compute_number_of_hash_functions (to_struct p |> addr) (Int32.of_int num_of_hash_bits) |> fun p -> (from_struct !@p)

end

module LSHNearestNeighborTable = struct
  type t = unit ptr
  let t : t typ = ptr void

  let _create_table =
    foreign ~from:libfalconn "create_table"
      ((ptr LSHConstructionParameters.params) @-> int @-> int @-> ptr float @-> returning t)

  let create params dataset =
    let num_points = Array2.dim1 dataset in
    let num_dimensions = Array2.dim2 dataset in
    let dataset_ptr = bigarray_start array2 dataset in
    _create_table (LSHConstructionParameters.to_struct params |> addr) num_points num_dimensions dataset_ptr
end

type results
let results : results structure typ = structure "results"
let arr     = field results "arr" (ptr int32_t)
let length  = field results "length" uint64_t
let ()      = seal results

module LSHNearestNeighborQuery = struct
  type t = unit ptr
  let t : t typ = ptr void

  let _create =
    foreign ~from:libfalconn "create_query_object"
      (LSHNearestNeighborTable.t @-> int @-> int @-> returning t)

  let create ?(num_probes=(-1)) ?(max_num_candidates=(-1)) table =
    _create table num_probes max_num_candidates

  let _find_k_nearest_neighbors =
    foreign ~from:libfalconn "qobj_find_k_nearest_neighbors"
      (t @-> ptr float @-> int @-> int @-> returning results)

  let find_k_nearest_neighbors qobj query k =
    let r = _find_k_nearest_neighbors qobj (bigarray_start array1 query) k (Array1.dim query) in
    bigarray_of_ptr array1 (getf r length |> Unsigned.UInt64.to_int) int32 (getf r arr)

  let set_num_probes =
    foreign ~from:libfalconn "qobj_set_num_probes"
      (t @-> int @-> returning void)
end

module LSHNearestNeighborQueryPool = struct
  type t = unit ptr
  let t : t typ = ptr void

  let _create =
    foreign ~from:libfalconn "create_query_pool"
      (LSHNearestNeighborTable.t @-> int @-> int @-> int @-> returning t)

  let create ?(num_probes=(-1)) ?(max_num_candidates=(-1)) ?(num_query_objects=0) table =
    _create table num_probes max_num_candidates num_query_objects

  let _find_k_nearest_neighbors =
    foreign ~from:libfalconn "qpool_find_k_nearest_neighbors"
      (t @-> ptr float @-> int @-> int @-> returning results)

  let find_k_nearest_neighbors qobj query k =
    let r = _find_k_nearest_neighbors qobj (bigarray_start array1 query) k (Array1.dim query) in
    bigarray_of_ptr array1 (getf r length |> Unsigned.UInt64.to_int) int32 (getf r arr)

  let set_num_probes =
    foreign ~from:libfalconn "qpool_set_num_probes"
      (t @-> int @-> returning void)
end

