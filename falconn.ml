open Bigarray
open Ctypes
open Foreign

let libfalconn = Dl.dlopen ~flags:[Dl.RTLD_LAZY] ~filename:"./libfalconn-wrapper.so";;

module LSHConstructionParameters = struct
  type t = unit ptr
  let t : t typ = ptr void

  let _create_params =
    foreign ~from:libfalconn "create_params"
      (int @-> int @-> int @-> int @-> int @-> int @-> int @-> int @-> returning t)

  let create ~l ~dimension ~lsh_family ~distance_function ~num_rotations ~storage_hash_table ~num_setup_threads ?(k = -1) () =
    let lsh_family' = match lsh_family with
      | `Unknown -> 0
      | `Hyperplane -> 1
      | `CrossPolytope -> 2
    in
    let distance_function' = match distance_function with
      | `Unknown -> 0
      | `NegativeInnerProduct -> 1
      | `EuclideanSquared -> 2
    in
    let storage_hash_table' = match storage_hash_table with
      | `Unknown -> 0
      | `FlatHashTable -> 1
      | `BitPackedFlatHashTable -> 2
      | `STLHashTable -> 3
      | `LinearProbingHashTable -> 4
    in
    _create_params l k dimension num_rotations num_setup_threads lsh_family' distance_function' storage_hash_table'

  let compute_number_of_hash_functions =
    foreign ~from:libfalconn "compute_number_of_hash_functions"
      (t @-> int @-> returning t)
end

module LSHNearestNeighborTable = struct
  type t = unit ptr
  let t : t typ = ptr void

  let _create_table =
    foreign ~from:libfalconn "create_table"
      (LSHConstructionParameters.t @-> int @-> int @-> ptr float @-> returning t)

  let create params dataset =
    let num_points = Array2.dim1 dataset in
    let num_dimensions = Array2.dim2 dataset in
    let dataset_ptr = bigarray_start array2 dataset in
    _create_table params num_points num_dimensions dataset_ptr
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

