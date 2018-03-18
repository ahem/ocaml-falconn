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
  Printf.printf "loaded dataset\n";
  let params = LSHConstructionParameters.get_default_parameters
    (Array2.dim1 dataset) (Array2.dim2 dataset) LSHConstructionParameters.EuclideanSquared true
  in
  Printf.printf "got default params (l:%d k:%d num_rotations:%d)\n" params.l params.k params.num_rotations;
  let params = LSHConstructionParameters.compute_number_of_hash_functions params 20 in
  Printf.printf "computed number of hash functions (l:%d k:%d num_rotations:%d)\n" params.l params.k params.num_rotations;

  let table = LSHNearestNeighborTable.create params dataset in
  Printf.printf "constructed table\n";

  let query_object = LSHNearestNeighborQuery.create ~num_probes:80 table in
  Printf.printf "constructed query object\n";

  let q = Array2.slice_left dataset 3 in
  let result = LSHNearestNeighborQuery.find_k_nearest_neighbors query_object q 10 in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int_exn result.{i}) done;

  Printf.printf "average_total_query_time: %f\n" (LSHNearestNeighborQuery.get_query_statistics query_object).average_total_query_time;

  let query_pool = LSHNearestNeighborQueryPool.create table ~num_probes:80 in
  Printf.printf "constructed query pool\n";
  let result = LSHNearestNeighborQueryPool.find_k_nearest_neighbors query_pool q 10 in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int_exn result.{i}) done;

  ()
