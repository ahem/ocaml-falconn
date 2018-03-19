val libfalconn : Dl.library

module LSHConstructionParameters :
  sig
    type lsh_family_t = Unknown | CrossPolytope | Hyperplane

    type distance_function_t =
      | Unknown
      | EuclideanSquared
      | NegativeInnerProduct

    type storage_hash_table_t =
      | Unknown
      | BitPackedFlatHashTable
      | FlatHashTable
      | LinearProbingHashTable
      | STLHashTable

    type t = {
      dimension : int;
      lsh_family : lsh_family_t;
      distance_function : distance_function_t;
      k : int;
      l : int;
      storage_hash_table : storage_hash_table_t;
      num_setup_threads : int;
      seed : int;
      last_cp_dimension : int;
      num_rotations : int;
      feature_hashing_dimension : int;
    }

    val empty : t
    val get_default_parameters : int -> int -> distance_function_t -> bool -> t
    val compute_number_of_hash_functions : t -> int -> t
  end

module LSHNearestNeighborTable :
  sig
    type t

    val create : LSHConstructionParameters.t -> (float, 'a, 'b) Bigarray.Array2.t -> t

    val free : t -> unit
  end

module QueryStatistics :
  sig
    type t = {
      average_total_query_time : float;  
      average_lsh_time : float;
      average_hash_table_time : float;
      average_distance_time : float;
      average_num_candidates : float;
      average_num_unique_candidates : float;
      num_queries : int;
    }
  end


module LSHNearestNeighborQuery :
  sig
    type t

    val create :
      ?num_probes:int ->
      ?max_num_candidates:int -> LSHNearestNeighborTable.t -> t

    val free : t -> unit

    val find_k_nearest_neighbors :
      t ->
      (float, 'a, 'b) Bigarray.Array1.t ->
      int -> (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t

    val get_num_probes : t -> int
    val set_num_probes : t -> int -> unit

    val get_max_num_candidates : t -> int
    val set_max_num_candidates : t -> int -> unit

    val get_query_statistics : t -> QueryStatistics.t
  end

module LSHNearestNeighborQueryPool :
  sig
    type t

    val create :
      ?num_probes:int ->
      ?max_num_candidates:int ->
      ?num_query_objects:int -> LSHNearestNeighborTable.t -> t

    val free : t -> unit

    val find_k_nearest_neighbors :
      t ->
      (float, 'a, 'b) Bigarray.Array1.t ->
      int -> (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t

    val get_num_probes : t -> int
    val set_num_probes : t -> int -> unit

    val get_max_num_candidates : t -> int
    val set_max_num_candidates : t -> int -> unit

    val get_query_statistics : t -> QueryStatistics.t
  end

