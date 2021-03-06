(*
 * ExtArray - additional and modified functions for arrays.
 * Copyright (C) 2005 Richard W.M. Jones (rich @ annexia.org)
 *               2008 David Teller
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


TYPE_CONV_PATH "Batteries.Data.Mutable" (*For Sexplib, Bin-prot...*)

module Array = struct



type 'a t = 'a array with sexp
type 'a enumerable = 'a t
type 'a mappable = 'a t

open Array
  let init         = init
  external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
  external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"
  external length : 'a t -> int = "%array_length"
  external get : 'a t -> int -> 'a = "%array_safe_get"
  external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
  external make : int -> 'a -> 'a t = "caml_make_vect"
  external create : int -> 'a -> 'a t = "caml_make_vect"
  let make_matrix  = make_matrix
  let create_matrix= create_matrix
  let iter         = iter
  let map          = map
  let iteri        = iteri
  let mapi         = mapi
  let fold_left    = fold_left
  let fold_right   = fold_right
  let append       = append
  let concat       = concat
  let sub          = sub
  let copy         = copy
  let fill         = fill
  let blit         = blit
  let to_list      = to_list
  let of_list      = of_list
  let sort         = sort
  let stable_sort  = stable_sort
  let fast_sort    = fast_sort



let rev_in_place xs =
  let n = length xs in
  let j = ref (n-1) in
  for i = 0 to n/2-1 do
    let c = xs.(i) in
    xs.(i) <- xs.(!j);
    xs.(!j) <- c;
    decr j
  done

let rev xs =
  let ys = Array.copy xs in
  rev_in_place ys;
  ys

let for_all p xs =
  let n = length xs in
  let rec loop i =
    if i = n then true
    else if p xs.(i) then loop (succ i)
    else false
  in
  loop 0

let exists p xs =
  let n = length xs in
  let rec loop i =
    if i = n then false
    else if p xs.(i) then true
    else loop (succ i)
  in
  loop 0

let mem a xs =
  let n = length xs in
  let rec loop i =
    if i = n then false
    else if a = xs.(i) then true
    else loop (succ i)
  in
  loop 0

let memq a xs =
  let n = length xs in
  let rec loop i =
    if i = n then false
    else if a == xs.(i) then true
    else loop (succ i)
  in
  loop 0

let findi p xs =
  let n = length xs in
  let rec loop i =
    if i = n then raise Not_found
    else if p xs.(i) then i
    else loop (succ i)
  in
  loop 0

let find p xs = xs.(findi p xs)

(* Use of BitSet suggested by Brian Hurt. *)
let filter p xs =
  let n = length xs in
  (* Use a bitset to store which elements will be in the final array. *)
  let bs = BitSet.create n in
  for i = 0 to n-1 do
    if p xs.(i) then BitSet.set bs i
  done;
  (* Allocate the final array and copy elements into it. *)
  let n' = BitSet.count bs in
  let j = ref 0 in
  let xs' = init n'
    (fun _ ->
       (* Find the next set bit in the BitSet. *)
       while not (BitSet.is_set bs !j) do incr j done;
       let r = xs.(!j) in
       incr j;
       r) in
  xs'




let find_all = filter

let partition p xs =
  let n = length xs in
  (* Use a bitset to store which elements will be in which final array. *)
  let bs = BitSet.create n in
  for i = 0 to n-1 do
    if p xs.(i) then BitSet.set bs i
  done;
  (* Allocate the final arrays and copy elements into them. *)
  let n1 = BitSet.count bs in
  let n2 = n - n1 in
  let j = ref 0 in
  let xs1 = init n1
    (fun _ ->
       (* Find the next set bit in the BitSet. *)
       while not (BitSet.is_set bs !j) do incr j done;
       let r = xs.(!j) in
       incr j;
       r) in
  let j = ref 0 in
  let xs2 = init n2
    (fun _ ->
       (* Find the next clear bit in the BitSet. *)
       while BitSet.is_set bs !j do incr j done;
       let r = xs.(!j) in
       incr j;
       r) in
  xs1, xs2

let enum xs =
  let rec make start xs =
    let n = length xs in(*Inside the loop, as [make] may later be called with another array*)
    Enum.make
      ~next:(fun () ->
	       if !start < n then
		 xs.(Ref.post_incr start)
	       else
		 raise Enum.No_more_elements)
      ~count:(fun () ->
		n - !start)
      ~clone:(fun () ->
		let xs' = Array.sub xs !start (n - !start) in
		make (ref 0) xs')
  in
  make (ref 0) xs

let backwards xs =
  let rec make start xs =
    Enum.make
      ~next:(fun () ->
	       if !start > 0 then 
		 xs.(Ref.pre_decr start)
	       else
		 raise Enum.No_more_elements)
      ~count:(fun () ->
		!start)
      ~clone:(fun () ->
		let xs' = Array.sub xs 0 !start in
		make (Ref.copy start) xs')
  in
  make (ref (length xs)) xs

let of_enum e =
  let n = Enum.count e in
  (* This assumes, reasonably, that init traverses the array in order. *)
  Array.init n
    (fun i ->
       match Enum.get e with
       | Some x -> x
       | None -> assert false)

let of_backwards e =
  of_list (ExtList.List.of_backwards e)

let filter_map p xs =
  of_enum (Enum.filter_map p (enum xs))

let iter2 f a1 a2 =
  if Array.length a1 <> Array.length a2
  then raise (Invalid_argument "Array.iter2");
  for i = 0 to Array.length a1 - 1 do
    f a1.(i) a2.(i);
  done;;

let iter2i f a1 a2 =
  if Array.length a1 <> Array.length a2
  then raise (Invalid_argument "Array.iter2");
  for i = 0 to Array.length a1 - 1 do
    f i a1.(i) a2.(i);
  done;;

let make_compare cmp a b =
  let length_a = Array.length a
  and length_b = Array.length b in
  let length   = min length_a length_b
  in
  let rec aux i = 
    if i < length then
      let result = compare (unsafe_get a i) (unsafe_get b i) in
	if result = 0 then aux (i + 1)
	else               result
    else
      if length_a < length_b then -1
      else                         1
  in aux 0

let print ?(first="[|") ?(last="|]") ?(sep="; ") print_a  out t =
  match length t with
    | 0 ->
	InnerIO.nwrite out first;
	InnerIO.nwrite out last
    | 1 ->
	InnerIO.Printf.fprintf out "%s%a%s" first print_a (unsafe_get t 0) last
    | n -> 
	InnerIO.nwrite out first;
	print_a out (unsafe_get t 0);
	for i = 1 to n - 1 do
	  InnerIO.Printf.fprintf out "%s%a" sep print_a (unsafe_get t i) 
	done;
	InnerIO.nwrite out last

module Cap =
struct
  (** Implementation note: in [('a, 'b) t], ['b] serves only as
      a phantom type, to mark which operations are only legitimate on
      readable arrays or writeable arrays.*)
  type ('a, 'b) t = 'a array constraint 'b = [< `Read | `Write]

  external of_array   : 'a array -> ('a, _ ) t                  = "%identity"
  external to_array   : ('a, [`Read | `Write]) t -> 'a array    = "%identity"
  external read_only  : ('a, [>`Read])  t -> ('a, [`Read])  t   = "%identity"
  external write_only : ('a, [>`Write]) t -> ('a, [`Write]) t   = "%identity"
  external length     : ('a, [> ]) t -> int                     = "%array_length"
  external get        : ('a, [> `Read]) t -> int -> 'a          = "%array_safe_get"
  external set        : ('a, [> `Write]) t -> int -> 'a -> unit = "%array_safe_set"
  external make       : int -> 'a -> ('a, _) t                  = "caml_make_vect"
  external create     : int -> 'a -> ('a, _) t                  = "caml_make_vect"

  let init         = init
  let make_matrix  = make_matrix
  let create_matrix= create_matrix
  let iter         = iter
  let map          = map
  let filter       = filter
  let filter_map   = filter_map
  let iteri        = iteri
  let mapi         = mapi
  let fold_left    = fold_left
  let fold_right   = fold_right
  let iter2        = iter2
  let iter2i       = iter2i
  let for_all      = for_all
  let exists       = exists
  let find         = find
  let mem          = mem
  let memq         = memq
  let findi        = findi
  let find_all     = find_all
  let partition    = partition
  let rev          = rev
  let rev_in_place = rev_in_place
  let append       = append
  let concat       = concat
  let sub          = sub
  let copy         = copy
  let fill         = fill
  let blit         = blit
  let enum         = enum
  let of_enum      = of_enum
  let backwards    = backwards
  let of_backwards = of_backwards
  let to_list      = to_list
  let of_list      = of_list
  let sort         = sort
  let stable_sort  = stable_sort
  let fast_sort    = fast_sort
  let make_compare = make_compare
  let print        = print
  let sexp_of_t    = sexp_of_t
  let t_of_sexp    = t_of_sexp
  external unsafe_get : ('a, [> `Read]) t -> int -> 'a = "%array_unsafe_get"
  external unsafe_set : ('a, [> `Write])t -> int -> 'a -> unit = "%array_unsafe_set"

  module Labels =
  struct
      let init i ~f = init i f
      let create len ~init = create len init
      let make             = create
      let make_matrix ~dimx ~dimy x = make_matrix dimx dimy x
      let create_matrix = make_matrix
      let sub a ~pos ~len = sub a pos len
      let fill a ~pos ~len x = fill a pos len x
      let blit ~src ~src_pos ~dst ~dst_pos ~len = blit src src_pos dst dst_pos len
      let iter ~f a = iter f a
      let map  ~f a = map  f a
      let iteri ~f a = iteri f a
      let mapi  ~f a = mapi f a
      let fold_left ~f ~init a = fold_left f init a
      let fold_right ~f a ~init= fold_right f a init
      let sort ~cmp a = sort cmp a
      let stable_sort ~cmp a = stable_sort cmp a
      let fast_sort ~cmp a = fast_sort cmp a
      let iter2 ~f a b = iter2 f a b
      let exists ~f a  = exists f a
      let for_all ~f a = for_all f a
      let iter2i  ~f a b = iter2i f a b
      let find ~f a = find f a
      let map ~f a = map f a
      let mapi ~f a = mapi f a
      let filter ~f a = filter f a
      let filter_map ~f a = filter_map f a
  end

  module ExceptionLess =
  struct
    let find f e =
      try  Some (find f e)
      with Not_found -> None
	
    let findi f e =
      try  Some (findi f e)
      with Not_found -> None
  end
end

module ExceptionLess =
struct
  let find f e =
    try  Some (find f e)
    with Not_found -> None

  let findi f e =
    try  Some (findi f e)
    with Not_found -> None
end

module Labels =
struct
  let init i ~f = init i f
  let create len ~init = create len init
  let make             = create
  let make_matrix ~dimx ~dimy x = make_matrix dimx dimy x
  let create_matrix = make_matrix
  let sub a ~pos ~len = sub a pos len
  let fill a ~pos ~len x = fill a pos len x
  let blit ~src ~src_pos ~dst ~dst_pos ~len = blit src src_pos dst dst_pos len
  let iter ~f a = iter f a
  let map  ~f a = map  f a
  let iteri ~f a = iteri f a
  let mapi  ~f a = mapi f a
  let fold_left ~f ~init a = fold_left f init a
  let fold_right ~f a ~init= fold_right f a init
  let sort ~cmp a = sort cmp a
  let stable_sort ~cmp a = stable_sort cmp a
  let fast_sort ~cmp a = fast_sort cmp a
  let iter2 ~f a b = iter2 f a b
  let exists ~f a  = exists f a
  let for_all ~f a = for_all f a
  let iter2i  ~f a b = iter2i f a b
  let find ~f a = find f a
  let map ~f a = map f a
  let mapi ~f a = mapi f a
  let filter ~f a = filter f a
  let filter_map ~f a = filter_map f a
end
end


