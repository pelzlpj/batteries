(* 
 * LazyListLabels - lazily-computed lists
 * Copyright (C) 2008 David Teller
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

(** {6 Exceptions} *)

exception No_more_elements
exception Empty_list
exception Invalid_index of int
exception Different_list_size of string

  
(** {6  Types} *)
type 'a node_t =
  | Nil 
  | Cons of 'a * 'a t
and 'a t =
  ('a node_t) Lazy.t


(** {6 Access} *)

let nil    = lazy Nil

let next l = Lazy.force l

let cons h t = lazy (Cons(h, t))

let get l = match next l with
  | Nil            -> None
  | Cons (x, rest) -> Some (x, rest)

let peek l = match next l with
  | Nil         -> None
  | Cons (x, _) -> Some x
(**
   {6 Constructors}
*)
let from_while f =
  let rec aux () = lazy (
    match f () with
      | None   -> Nil
      | Some x -> Cons (x, aux ()) ) in aux ()

let from f = 
  let f' () =
    try  Some (f ())
    with No_more_elements -> None
  in from_while f'

let seq data next cond =
  let rec aux data = 
    if cond data then lazy (Cons (data, aux (next data)))
    else              nil
  in aux data


let unfold (data:'b) (next: 'b -> ('a * 'b) option) =
  let rec aux data =
    match next data with
      | Some(a,b) -> lazy (Cons(a, aux b))
      | None      -> nil
  in aux data


let from_loop (data:'b) (next:'b -> ('a * 'b)) : 'a t=
  let f' data =
    try  Some (next data)
    with No_more_elements -> None
  in unfold data f'

let init n f = 
  let rec aux i = 
    if i < n then lazy (Cons (f i, aux ( i + 1 ) ) )  
    else          nil
  in if n < 0 then raise (Invalid_argument "LazyList.init")
     else          aux 0

let make n x =
  let rec aux i =
    if i < n then lazy (Cons (x, aux ( i + 1 ) ) )
    else          nil
  in if n < 0 then raise (Invalid_argument "LazyList.make")
     else          aux 0

(**
   {6  Iterators}
*)
let iter f l =
  let rec aux l =
    match next l with | Cons (x, t) -> (f x; aux t) | _ -> ()
  in aux l
  
let iteri f l =
  let rec aux i l =
    match next l with | Cons (x, t) -> (f i x; aux (i + 1) t) | _ -> ()
  in aux 0 l
  
let map f l =
  let rec (aux : 'a t -> 'b t) =
    fun rest ->
      match next rest with
      | Cons (x, (t : 'a t)) -> lazy (Cons (f x, aux t))
      | Nil -> lazy Nil
  in aux l
  
let mapi f l =
  let rec aux rest i =
    match next rest with
      | Cons (x, (t : 'a t)) -> lazy (Cons (f i x, aux t ( i + 1 ) ))
      | Nil -> lazy Nil
  in aux l 0

let fold_left f init l =
  let rec aux acc rest =
    match next rest with 
      | Cons (x, t) -> aux (f acc x) t 
      | _           -> acc
  in aux init l
  
let fold_right f init l =
  let rec aux rest =
    match next rest with | Cons (x, t) -> f x (aux t) | _ -> init
  in aux l

(** {6 Finding}*)

let may_find p l =
  let rec aux l =
    match next l with
      | Nil         -> None
      | Cons (x, t) -> if p x then Some x else aux t
  in aux l 

let may_rfind p l =
  let rec aux l acc =
    match next l with
      | Nil         -> acc
      | Cons (x, t) -> aux t (if p x then Some x else acc)
  in aux l None

let may_findi p l =
  let rec aux l i =
    match next l with
      | Nil                    -> None
      | Cons (x, _) when p i x -> Some (i, x)
      | Cons (_, t)            -> aux t (i+1)
  in aux l 0

let may_rfindi p l =
  let rec aux l acc i =
    match next l with
      | Nil         -> acc
      | Cons (x, t) -> aux t (if p i x then Some (i, x) else acc) (i+1)
  in aux l None 0

let find_exn p e l =
  Option.get_exn (may_find p l) e

let rfind_exn p e l =
  Option.get_exn (may_rfind p l) e

let find  p l = find_exn p Not_found l

let rfind p l = rfind_exn p Not_found l

let findi p l =
  Option.get_exn (may_findi p l) Not_found

let rfindi p l =
  Option.get_exn (may_rfindi p l) Not_found

let index_of e l =
  match may_findi (fun _ x -> e = x) l with
    | None        -> None
    | Some (i, _) -> Some i

let rindex_of e l =
  match may_rfindi (fun _ x -> e = x) l with
    | None        -> None
    | Some (i, _) -> Some i

let index_ofq e l =
  match may_findi (fun _ x -> e == x) l with
    | None        -> None
    | Some (i, _) -> Some i

let rindex_ofq e l =
  match may_rfindi (fun _ x -> e == x) l with
    | None        -> None
    | Some (i, _) -> Some i

  
(** {6  Common functions}*)
let length l = fold_left (fun n _ -> n + 1) 0 l
  
let is_empty l = match next l with
  | Nil -> true
  | _   -> false

let would_at_fail n =
  let rec aux l i = match next l with
    | Nil                    -> true
    | Cons (_, _) when i = 0 -> false
    | Cons (_, t)            -> aux t (i - 1)
  in aux n

let hd list =
  match next list with
  | Cons (x, _) -> x
  | _ -> raise Empty_list
  
let first = hd


let last l =
  let rec aux acc l = match next l with
    | Nil        -> acc
    | Cons(x, t) -> aux (Some x) t
  in match aux None l with
    | None   -> raise Empty_list
    | Some x -> x

let tl list =
  match next list with
  | Cons (_, t) -> t
  | _ -> raise Empty_list
  
  
let at list n =
  let rec aux list i =
    match ((next list), i) with
    | (Cons (x, _), 0) -> x
    | (Cons (_, t), _) -> aux t (i - 1)
    | _ -> raise (Invalid_index n)
  in if n < 0 then raise (Invalid_index n) else aux list n

let nth = at

let rev list = fold_left (fun acc x -> lazy (Cons (x, acc))) nil list
  
(**Revert a list, convert it to a lazy list.
   Used as an optimisation.*)
let rev_of_list (list:'a list) = List.fold_left (fun acc x -> lazy (Cons (x, acc))) nil list

let eager_append (l1 : 'a t) (l2 : 'a t) =
  let rec aux list =
    match next list with
    | Cons (x, t) -> lazy (Cons (x, aux t))
    | _ -> l2
  in aux l1
  
let rev_append (l1 : 'a t) (l2 : 'a t) =
  let rec aux list acc =
    match next list with
    | Cons (x, t) -> aux t (lazy (Cons (x, acc)))
    | _ -> acc
  in aux l1 l2

(**Revert a list, convert it to a lazy list and append it.
   Used as an optimisation.*)
let rev_append_of_list (l1 : 'a list) (l2 : 'a t) : 'a t =
  let rec aux list acc = match list with
    | []   -> acc
    | h::t -> aux t (lazy (Cons (h, acc)))
  in aux l1 l2

let append (l1 : 'a t) (l2 : 'a t) =
  let rec (aux : 'a t -> 'a t) =
    fun rest_of_l1 ->
      match next rest_of_l1 with
      | Cons (x, (t : 'a t)) -> lazy (Cons (x, aux t))
      | _ -> l2
  in aux l1
  
let ( ^@^ ) = append
  
let flatten (lol : ('a t) list) =
  ListLabels.fold_left ~init: nil ~f: append lol
  
let concat  (lol : ('a t) t) = fold_left append nil lol
  
(**
   {6  Conversions}
*)
(**
   Eager conversion to string.
*)
let to_list l = fold_right (fun x acc -> x :: acc) [] l
  
(**
   Lazy conversion to stream.
*)
let to_stream l =
  let rec aux rest =
    match next rest with
    | Cons (x, t) -> Stream.icons x (Stream.slazy (fun _ -> aux t))
    | _ -> Stream.sempty
  in aux l
  
(**
   Eager conversion to array.
*)
let to_array l = Array.of_list (to_list l)

let enum l =
  let rec aux l = 
    let reference = ref l in
      Enum.make ~next:(fun () -> match next !reference with
			 | Cons(x,t) -> reference := t; x
			 | _         -> raise Enum.No_more_elements )
        ~count:(fun () -> length !reference)
        ~clone:(fun () -> aux !reference)
  in aux l
  
(**
   Lazy conversion from lists

   Albeit slower than eager conversion, this is the default mechanism for converting from regular 
   lists to lazy lists.  This for two reasons :
   * if you're using lazy lists, total speed probably isn't as much an issue as start-up speed
   * this will let you convert regular infinite lists to lazy lists.
*)
let of_list l =
  let rec aux rest =
    match rest with | [] -> nil | h :: t -> lazy (Cons (h, aux t))
  in aux l
  
(**
   Lazy conversion from stream.
*)
let of_stream s =
  let rec aux s =
    let (__strm : _ Stream.t) = s
    in
      match Stream.peek __strm with
      | Some h -> (Stream.junk __strm; lazy (Cons (h, aux s)))
      | _ -> nil
  in aux s
  
(**
   Eager conversion from lists
*)
let eager_of_list l =
  ListLabels.fold_right ~init: nil ~f: (fun x acc -> lazy (Cons (x, acc))) l
  
(**
   Lazy conversion from array
*)
let of_array l =
  ArrayLabels.fold_right ~init: nil ~f: (fun x acc -> lazy (Cons (x, acc))) l

(**
   Lazy conversion from enum
*)
let of_enum e =
  let rec aux () =
    lazy (match Enum.get e with
      |	Some x -> Cons (x, aux () ) 
      | _      -> Nil )
  in
    aux ()
  
(**
   {6  Predicates}
*)
let filter f l =
  let rec aux rest =
    match next rest with
    | Cons (x, t) when f x -> lazy (Cons (x, aux t))
    | Cons (_, t)          -> aux t
    | Nil                  -> nil
  in aux l
  
let exists f l =
  let rec aux rest =
    match next rest with
    | Cons (x, t) when f x -> true
    | Cons (_, t)          -> aux t
    | Nil                  -> false
  in aux l
  
let for_all f l =
  let rec aux rest =
    match next rest with
    | Cons (x, t) when f x -> aux t
    | Cons (_, t)          -> false
    | Nil                  -> true
  in aux l
  
let range a b =
  let rec increasing lo hi =
    if lo > hi then nil else lazy (Cons (lo, increasing (lo + 1) hi))
  in
    (*      and     decreasing lo hi = if lo > hi then 
	nil
      else 
	lazy (Cons hi (decreasing lo (hi - 1)))*)
    if b >= a then increasing a b else (*decreasing b a*) nil

let split_at n l =
  let rec aux acc l i =
    if i = 0 then (rev_of_list acc, l)
    else match next l with
      | Nil        -> raise (Invalid_index n)
      | Cons(h, t) -> aux (h::acc) t (i - 1)
  in aux [] l n

let split_nth = split_at

let mem   e = exists (( = ) e)
 
let memq  e = exists (( == ) e )

let assoc e l = snd (find (fun (a,_) -> a = e) l)

let assq  e l = snd (find (fun (a,_) -> a == e) l)

let mem_assoc e l = Option.is_some (may_find (fun (a, _) -> a = e) l)

let mem_assq e l = Option.is_some (may_find (fun (a, _) -> a == e) l)

let filter_map f l =
  let rec aux rest =
    match next rest with
    | Cons (h, t) ->
        (match f h with | None -> aux t | Some x -> lazy (Cons (x, aux t)))
    | Nil -> nil
  in aux l

let unique ?(cmp = compare) l =
  let set      = ref (PMap.create cmp) in
  let filter x = if PMap.mem x !set then None
                 else                  ( set := PMap.add x true !set; Some x )
  in
    filter_map filter l

let remove_if p l =
  let rec aux acc l = match next l with
    | Nil                -> rev_of_list acc
    | Cons(h,t) when p h -> rev_append_of_list acc t
    | Cons(h,t)          -> aux (h::acc) t
  in aux [] l

let remove_all_such p l =
  filter_map (fun y -> if p y then None else Some y) l

let remove x l =
  remove_if ( ( = ) x ) l

let remove_all x l =
  remove_all_such ( ( = ) x ) l



(** An infinite list of nothing *)
let rec eternity = lazy (Cons ((), eternity))
  
let take n l = fst (split_at n l)

let drop n l = 
  let rec aux l i =
    if i = 0 then l
    else match next l with
      | Nil        -> raise (Invalid_index n)
      | Cons(_, t) -> aux t (i - 1)
  in aux l n

let drop_while p =
  let rec aux l = match next l with
    | Nil                -> nil
    | Cons(h,t) when p h -> aux t
    | Cons(_,_)          -> l
  in aux

let take_while p =
  let rec aux acc l = match next l with
    | Cons(h,t) when p h -> aux (h::acc) t
    | _                  -> rev_of_list acc
  in aux []

let sort ?cmp l = of_list (ExtList.List.sort ?cmp (to_list l))

let stable_sort cmp l = of_list (ExtList.List.stable_sort cmp (to_list l))

let map2 f l1 l2 =
  let rec aux l1 l2 =
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> lazy (Cons (f h1 h2, aux t1 t2))
	| (Nil, Nil)                    -> nil
	| _                             -> raise (Different_list_size "LazyList.map2")
  in aux l1 l2

let iter2 f l1 l2 =
  let rec aux l1 l2 =
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> f h1 h2; aux t1 t2
	| (Nil, Nil)                    -> ()
	| _                             -> raise (Different_list_size "LazyList.iter2")
  in aux l1 l2

let fold_left2 f acc l1 l2 = 
  let rec aux acc l1 l2 = 
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> aux (f acc h1 h2) t1 t2
	| (Nil, Nil)                    -> acc
	| _                             -> raise (Different_list_size "LazyList.fold_left2")
  in aux acc l1 l2

let fold_right2 f l1 l2 acc =
  let rec aux l1 l2 =
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> f h1 h2 (aux t1 t2)
	| (Nil, Nil)                    -> acc
	| _                             -> raise (Different_list_size "LazyList.fold_right2")
  in aux l1 l2

let for_all2 p l1 l2 =
  let rec aux l1 l2 =
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> p h1 h2 && (aux t1 t2)
	| (Nil, Nil)                    -> true
	| _                             -> raise (Different_list_size "LazyList.for_all2")
  in aux l1 l2

let exists2 p l1 l2 =
  let rec aux l1 l2 =
      match (next l1, next l2) with
	| (Cons (h1, t1), Cons(h2, t2)) -> p h1 h2 || (aux t1 t2)
	| (Nil, Nil)                    -> false
	| _                             -> raise (Different_list_size "LazyList.exists2")
  in aux l1 l2

let combine l1 l2 =
  let rec aux l1 l2 = match (next l1, next l2) with
    | (Cons(h1, t1), Cons(h2, t2)) -> lazy (Cons ((h1, h2), ( aux t1 t2 )))
    | (Nil,          Nil         ) -> nil
    | _                            -> raise (Different_list_size "LazyList.combine")
  in aux l1 l2

module Exceptionless = struct
  (** Exceptionless counterparts for error-raising operations*)

  let find   = may_find
  let rfind  = may_rfind
  let findi  = may_findi
  let rfindi = may_rfindi
    
  let at list n =
    let rec aux list i =
      match (next list, i) with
	| (Cons (x, _), 0) -> `Ok x
	| (Cons (_, t), _) -> aux t (i - 1)
	| _ -> `Invalid_index n
    in if n < 0 then `Invalid_index n else aux list n

  let assoc a (l:'a t) =
    try  Some (assoc a l)
    with Not_found -> None

  let assq a l =
    try  Some (assq a l)
    with Not_found -> None

  let split_at n l =
    try  `Ok (split_at n l)
    with Not_found -> `Invalid_index n
end