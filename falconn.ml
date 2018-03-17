open Bigarray
open Ctypes
open Foreign

let libfalconn = Dl.dlopen ~flags:[Dl.RTLD_LAZY] ~filename:"./libfalconn-wrapper.so";;

module Table = struct
  type t = unit ptr
  let t : t typ = ptr void

  let create_table' =
    foreign ~from:libfalconn "create_table"
      (int @-> int @-> int @-> int @-> int @-> ptr float @-> returning t)

  let create num_hash_tables num_hash_bits num_rotations dataset =
    let num_points = Array2.dim1 dataset in
    let num_dimensions = Array2.dim2 dataset in
    let dataset_ptr = bigarray_start array2 dataset in
    create_table' num_hash_tables num_hash_bits num_rotations num_points num_dimensions dataset_ptr
end

module QueryObject = struct
  type t = unit ptr
  let t : t typ = ptr void

  type results
  let results : results structure typ = structure "results"
  let arr     = field results "arr" (ptr int32_t)
  let length  = field results "length" int32_t
  let ()      = seal results

  let create =
    foreign ~from:libfalconn "create_query_object"
      (Table.t @-> int @-> returning t)

  let find_k_nearest_neighbors' =
    foreign ~from:libfalconn "find_k_nearest_neighbors"
      (t @-> ptr float @-> int @-> int @-> returning results)

  let find_k_nearest_neighbors qobj query k =
    let r = find_k_nearest_neighbors' qobj (bigarray_start array1 query) 10 (Array1.dim query) in
    bigarray_of_ptr array1 (getf r length |> Int32.to_int) int32 (getf r arr)
end




