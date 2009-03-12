(* 
 * ExtMap - Additional map operations
 * Copyright (C) 1996 Xavier Leroy
 *               2009 David Rajchenbach-Teller, LIFO, Universite d'Orleans
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version,
 * with the special exception on linking described in file LICENSE.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

open Sexplib
TYPE_CONV_PATH "" (*For Sexplib, Bin-prot...*)


module Map =
struct
  module type OrderedType = Interfaces.OrderedType

  module type S =
  sig
    type key
      (** The type of the map keys. *)
      
    type (+'a) t
      (** The type of maps from type [key] to type ['a]. *)
      
    val empty: 'a t
      (** The empty map. *)
      
    val is_empty: 'a t -> bool
      (** Test whether a map is empty or not. *)
      
    val add: key -> 'a -> 'a t -> 'a t
      (** [add x y m] returns a map containing the same bindings as
	  [m], plus a binding of [x] to [y]. If [x] was already bound
	  in [m], its previous binding disappears. *)
      
    val find: key -> 'a t -> 'a
      (** [find x m] returns the current binding of [x] in [m],
	  or raises [Not_found] if no such binding exists. *)
      
    val remove: key -> 'a t -> 'a t
      (** [remove x m] returns a map containing the same bindings as
	  [m], except for [x] which is unbound in the returned map. *)
      
    val mem: key -> 'a t -> bool
      (** [mem x m] returns [true] if [m] contains a binding for [x],
	  and [false] otherwise. *)
      
    val iter: (key -> 'a -> unit) -> 'a t -> unit
      (** [iter f m] applies [f] to all bindings in map [m].
	  [f] receives the key as first argument, and the associated value
	  as second argument.  The bindings are passed to [f] in increasing
	  order with respect to the ordering over the type of the keys.
	  Only current bindings are presented to [f]:
	  bindings hidden by more recent bindings are not passed to [f]. *)
      
    val map: ('a -> 'b) -> 'a t -> 'b t
      (** [map f m] returns a map with same domain as [m], where the
	  associated value [a] of all bindings of [m] has been
	  replaced by the result of the application of [f] to [a].
	  The bindings are passed to [f] in increasing order
	  with respect to the ordering over the type of the keys. *)
      
    val mapi: (key -> 'a -> 'b) -> 'a t -> 'b t
      (** Same as {!Map.S.map}, but the function receives as arguments both the
	  key and the associated value for each binding of the map. *)

    val fold: (key -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
      (** [fold f m a] computes [(f kN dN ... (f k1 d1 a)...)],
	  where [k1 ... kN] are the keys of all bindings in [m]
	  (in increasing order), and [d1 ... dN] are the associated data. *)

   val filter: ('a -> bool) -> 'a t -> 'a t
      (**[filter f m] returns a map where only the values [a] of [m]
	 such that [f a = true] remain. The bindings are passed to [f]
	 in increasing order with respect to the ordering over the
	 type of the keys. *)

    val filteri: (key -> 'a -> bool) -> 'a t -> 'a t
      (**[filter f m] returns a map where only the key, values pairs
	 [key], [a] of [m] such that [f key a = true] remain. The
	 bindings are passed to [f] in increasing order with respect
	 to the ordering over the type of the keys. *)
            
    val filter_map: (key -> 'a -> 'b option) -> 'a t -> 'b t
      (** [filter_map f m] combines the features of [filteri] and
	  [map].  It calls calls [f key0 a0], [f key1 a1], [f keyn an]
	  where [a0..an] are the elements of [m] and [key0..keyn] the
	  respective corresponding keys. It returns the map of
	  pairs [keyi],[bi] such as [f keyi ai = Some bi] (when [f] returns
	  [None], the corresponding element of [m] is discarded). *)

    val compare: ('a -> 'a -> int) -> 'a t -> 'a t -> int
      (** Total ordering between maps.  The first argument is a total ordering
          used to compare data associated with equal keys in the two maps. *)
      
    val equal: ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
      (** [equal cmp m1 m2] tests whether the maps [m1] and [m2] are
	  equal, that is, contain equal keys and associate them with
	  equal data.  [cmp] is the equality predicate used to compare
	  the data associated with the keys. *)
      
    val keys : _ t -> key Enum.t
      (** Return an enumeration of all the keys of a map.*)
      
    val values: 'a t -> 'a Enum.t
      (** Return an enumeration of al the values of a map.*)
(*
    val min_key : 'a t -> (key * 'a)
      (** return the ([key,value]) pair with the smallest key *)

    val max_key : 'a t -> (key * 'a)
      (** return the [(key,value)] pair with the largest key *)

    val choose : 'a t -> (key * 'a)
      (** return an implementation defined [(key,value)] pair.  As [Set.choose] *)
*)
(*
    val split : key -> 'a t -> ('a t * 'a option * 'a t)
      (** as [Set.split] *)
*)
    val enum  : 'a t -> (key * 'a) Enum.t
      (** Return an enumeration of (key, value) pairs of a map.*)

    val of_enum: (key * 'a) Enum.t -> 'a t
      (** Create a map from a (key, value) enumeration. *)

    (** {6 Boilerplate code}*)
    (** {7 S-Expressions}*)
      
    val t_of_sexp : (Sexplib.Sexp.t -> key) -> (Sexplib.Sexp.t -> 'b) -> Sexplib.Sexp.t -> 'b t
    val sexp_of_t : (key -> Sexplib.Sexp.t) -> ('b -> Sexplib.Sexp.t) -> 'b t -> Sexplib.Sexp.t

    (** {7 Printing}*)

    val print :  ?first:string -> ?last:string -> ?sep:string -> 
      (('a #InnerIO.output as 'out) -> key -> unit) -> 
      ('out -> 'c -> unit) -> 'out -> 'c t -> unit

    module ExceptionLess : sig
      val find: key -> 'a t -> 'a option
    end

    module Labels : sig
      val add : key:key -> data:'a -> 'a t -> 'a t
      val iter : f:(key:key -> data:'a -> unit) -> 'a t -> unit
      val map : f:('a -> 'b) -> 'a t -> 'b t
      val mapi : f:(key:key -> data:'a -> 'b) -> 'a t -> 'b t
      val filter: f:('a -> bool) -> 'a t -> 'a t
      val filteri:f:(key -> 'a -> bool) -> 'a t -> 'a t
      val fold :
	f:(key:key -> data:'a -> 'b -> 'b) ->
	'a t -> init:'b -> 'b
      val compare: cmp:('a -> 'a -> int) -> 'a t -> 'a t -> int
      val equal: cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool

    end
  end

  module Make(Ord : OrderedType) =
    struct
      include Map.Make(Ord)

	(*We break the abstraction so as to be able to create enumerations
	  lazily*)
      type 'a implementation = 
	  Empty
	| Node of 'a implementation * key * 'a * 'a implementation * int


      external t_of_impl: 'a implementation -> 'a t = "%identity"
      external impl_of_t: 'a t -> 'a implementation = "%identity"

      let enum t =
	let queue = Queue.create () in
	let rec next () = 
	  match 
	    try  Some (Queue.pop queue) 
	    with Queue.Empty -> None
	  with None       -> raise Enum.No_more_elements
	    |  Some Empty -> next ()
	    | Some Node (l, key, data, r, _) -> 
		Queue.push l queue;
		Queue.push r queue;
		(key, data)
	in Queue.add (impl_of_t t) queue;
	  Enum.from next

      let keys    t = Enum.map fst (enum t)
      let values  t = Enum.map snd (enum t)
      let of_enum e =
	Enum.fold (fun (key, data) acc -> add key data acc) empty e


      let print ?(first="{\n") ?(last="\n}") ?(sep=",\n") print_k print_v out t =
	Enum.print ~first ~last ~sep (fun out (k,v) -> ExtPrintf.Printf.fprintf out "%a: %a" print_k k print_v v) out (enum t)

      (*We rely on [fold] rather than on ['a implementation] to
	make future changes of implementation in the base
	library's version of [Map] easier to track, even if the
	result is a tad slower.*)
      let filter  f t = fold (fun k a acc -> if f a then add k a acc else acc) t empty
      let filteri f t = fold (fun k a acc -> if f k a then add k a acc else acc) t empty
      let filter_map f t = fold (fun k a acc -> match f k a with
				   | None   -> acc
				   | Some v -> add k v acc)  t empty

      let rec min_key = function
	  Empty -> raise Not_found
	| Node(Empty, x, d, r, _) -> (x, d)
	| Node(l, x, d, r, _) -> min_key l
      let min_key s = min_key (impl_of_t s) (* define properly for t *)

      let rec max_key = function
	  Empty -> raise Not_found
	| Node(l, x, d, Empty, _) -> (x, d)
	| Node(l, x, d, r, _) -> max_key r
      let max_key s = max_key (impl_of_t s) (* define properly for t *)

      let choose = function
	  Empty -> raise Not_found
	| Node(_, x, d, _, _) -> (x, d)
      let choose s = choose (impl_of_t s) (* define properly for t *)

(*	NEEDS BAL FROM MAP IMPLEMENTATION
      (* needed by split, not exposed atm *)
      let rec join (l : 'a implementation) (x : key) (d : 'a) (r : 'a implementation) =
	match (l, r) with
            (Empty, _) -> add x d (t_of_impl r)
	  | (_, Empty) -> add x d (t_of_impl l)
	  | (Node(ll, lx, ld, lr, lh), Node(rl, rx, rd, rr, rh)) ->
              if lh > rh + 2 then bal ll lx ld (join lr x d r) else
		if rh > lh + 2 then bal (join l x d rl) rx rd rr else
		  create l x d r

      let rec split key = function
          Empty ->
            (Empty, None, Empty)
	| Node(l, x, d, r, _) ->
            let c = Ord.compare key x in
            if c = 0 then (l, Some d, r)
            else if c < 0 then
              let (ll, pres, rl) = split key l in (ll, pres, join rl x d r)
            else
              let (lr, pres, rr) = split key r in (join l x d lr, pres, rr)
      let split k s = split k (impl_of_t s) (* define properly for t *)
*)

      (*The following is a hack to make sure that we're letting sexplib
	do the conversion automatically, hence that we're following sexplib protocol.*)

      let t_of_sexp key_of_sexp = 
	let module Local =
	  struct
	    let sexp_of_key _ = assert false

	    type 'a t = 'a implementation = 
			| Empty
			| Node of 'a t * key * 'a * 'a t * int
	    with sexp
		
	     t_of_sexp
	  end in fun key_of_a sexp -> t_of_impl (Local.t_of_sexp key_of_a sexp)

      let sexp_of_t sexp_of_key = 
	let module Local =
	  struct
	    let key_of_sexp _ = assert false

	    type 'a t = 'a implementation = 
			| Empty
			| Node of 'a t * key * 'a * 'a t * int
	    with sexp
		
	     t_of_sexp
	  end in fun a_of_key (t:'a t) -> Local.sexp_of_t a_of_key (impl_of_t t)


      module ExceptionLess =
      struct
	let find k t = try Some (find k t) with Not_found -> None
      end
	
      module Labels =
      struct
	let add ~key ~data t = add key data t
	let iter ~f t = iter (fun key data -> f ~key ~data) t
	let map ~f t = map f t
	let mapi ~f t = mapi (fun key data -> f ~key ~data) t
	let fold ~f t ~init = fold (fun key data acc -> f ~key ~data acc) t init
	let compare ~cmp a b = compare cmp a b
	let equal ~cmp a b = equal cmp a b
	let filter ~f = filter f
	let filteri ~f = filteri f
      end  

    end

  module StringMap  = Make(ExtString.String)
  module IStringMap = Make(ExtString.String.IString)
  module NumStringMap = Make(ExtString.String.NumString)
  module RopeMap    = Make(Rope)
  module IRopeMap   = Make(Rope.IRope)
  module IntMap     = Make(ExtInt.Int)

end
