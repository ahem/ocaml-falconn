open Core
open Bigarray

let read_lda_list filename =
  let Npy.P2 arr = Npy.read_mmap2 filename ~shared:false in
  match (Array2.layout arr), (Array2.kind arr) with
  | C_layout, Float32 -> Some (arr: (float, float32_elt, c_layout) Array2.t)
  | _ -> None

let () =
  let dataset = (Option.value_exn (read_lda_list "./lda_list.npy")) in
  let table = Falconn.Table.create 10 20 1 dataset in
  let query_object = Falconn.QueryObject.create table 80 in

  let q = Array2.slice_left dataset 3 in
  let result = Falconn.QueryObject.find_k_nearest_neighbors query_object q 10 in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int_exn result.{i}) done

