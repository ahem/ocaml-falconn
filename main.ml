open Ctypes
open Foreign

type falconn_table = unit ptr
let falconn_table : falconn_table typ = ptr void

type falconn_query_object = unit ptr
let falconn_query_object : falconn_query_object typ = ptr void

let libfalconn = Dl.dlopen ~flags:[Dl.RTLD_LAZY] ~filename:"./libfalconn-wrapper.so";;

let create_table =
	foreign ~from:libfalconn "create_table"
		(int @-> int @-> int @-> int @-> int @-> ptr float @-> returning falconn_table)

let create_query_object =
	foreign ~from:libfalconn "create_query_object"
		(falconn_table @-> int @-> returning falconn_query_object)

let find_k_nearest_neighbors =
	foreign ~from:libfalconn "find_k_nearest_neighbors"
    (falconn_query_object @-> ptr float @-> int @-> int @-> returning (ptr int32_t))

let read_lda_list filename =
  let Npy.P2 arr = Npy.read_mmap2 filename ~shared:false in
  match (Bigarray.Array2.layout arr), (Bigarray.Array2.kind arr) with
  | Bigarray.C_layout, Bigarray.Float32 -> Some (arr: (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array2.t)
  | _ -> None

let () =
  let dataset = (Core.Option.value_exn (read_lda_list "./lda_list.npy")) in
  let table = create_table 10 20 1 (Bigarray.Array2.dim1 dataset) (Bigarray.Array2.dim2 dataset) (bigarray_start array2 dataset) in
  let query_object = create_query_object table 0 in

  let q = Bigarray.Array2.slice_left dataset 3 in
  let result_ptr = find_k_nearest_neighbors query_object (bigarray_start array1 q) 10 (Bigarray.Array2.dim2 dataset) in
  let result = bigarray_of_ptr array1 10 Bigarray.int32 result_ptr in
  for i = 0 to 9 do Printf.printf "%d\n" (Int32.to_int result.{i}) done

