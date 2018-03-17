val libfalconn : Dl.library
module LSHConstructionParameters :
  sig
    type t

    val create :
      l:int ->
      dimension:int ->
      lsh_family:[< `CrossPolytope | `Hyperplane | `Unknown ] ->
      distance_function:[< `EuclideanSquared
                         | `NegativeInnerProduct
                         | `Unknown ] ->
      num_rotations:int ->
      storage_hash_table:[< `BitPackedFlatHashTable
                          | `FlatHashTable
                          | `LinearProbingHashTable
                          | `STLHashTable
                          | `Unknown ] ->
      num_setup_threads:int -> ?k:int -> unit -> t

    val compute_number_of_hash_functions : t -> int -> t
  end
module LSHNearestNeighborTable :
  sig
    type t

    val create :
      LSHConstructionParameters.t -> (float, 'a, 'b) Bigarray.Array2.t -> t
  end

module LSHNearestNeighborQuery :
  sig
    type t

    val create :
      ?num_probes:int ->
      ?max_num_candidates:int -> LSHNearestNeighborTable.t -> t

    val find_k_nearest_neighbors :
      t ->
      (float, 'a, 'b) Bigarray.Array1.t ->
      int -> (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t

    val set_num_probes : t -> int -> unit
  end

module LSHNearestNeighborQueryPool :
  sig
    type t

    val create :
      ?num_probes:int ->
      ?max_num_candidates:int ->
      ?num_query_objects:int -> LSHNearestNeighborTable.t -> t

    val find_k_nearest_neighbors :
      t ->
      (float, 'a, 'b) Bigarray.Array1.t ->
      int -> (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t

    val set_num_probes : t -> int -> unit
  end
