open Core
open Bigarray
open Falconn

let read_lda_list filename =
  let Npy.P2 arr = Npy.read_mmap2 filename ~shared:false in
  match (Array2.layout arr), (Array2.kind arr) with
  | C_layout, Float32 -> Some (arr: (float, float32_elt, c_layout) Array2.t)
  | _ -> None

let () =
  let dataset = (Option.value_exn (read_lda_list "./lda_list.npy")) in
  let params = LSHConstructionParameters.create
    ~l:10
    ~dimension:(Array2.dim2 dataset)
    ~num_rotations:1
    ~num_setup_threads:0
    ~lsh_family: `CrossPolytope
    ~distance_function: `EuclideanSquared
    ~storage_hash_table: `BitPackedFlatHashTable
    ()
  in
  let params = LSHConstructionParameters.compute_number_of_hash_functions params 20 in
  let table = LSHNearestNeighborTable.create params dataset in
  let query_object = LSHNearestNeighborQuery.create table 80 in

  let q = Array2.slice_left dataset 3 in
  let result = LSHNearestNeighborQuery.find_k_nearest_neighbors query_object q 10 in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int_exn result.{i}) done;

  let query_pool = LSHNearestNeighborQueryPool.create table 80 (-1) 0 in
  let result = LSHNearestNeighborQueryPool.find_k_nearest_neighbors query_pool q 10 in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int_exn result.{i}) done
