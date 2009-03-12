(* 
 * ExtBool - Extended booleans
 * Copyright (C) 2007 Bluestorm <bluestorm dot dylc on-the-server gmail dot com>
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

(**Operations on booleans
   
   @author Gabriel Scherer
   @author David Teller
*)
module Bool :
sig

  type t = bool
      (**The type of booleans. Formally, this is defined as [type t = true | false] *)

  external not : bool -> bool = "%boolnot"
      (** The boolean negation. *)

  external ( && ) : bool -> bool -> bool = "%sequand"
      (** The boolean ``and''. Evaluation is sequential, left-to-right:
	  in [e1 && e2], [e1] is evaluated first, and if it returns [false],
	  [e2] is not evaluated at all. *)

  external ( || ) : bool -> bool -> bool = "%sequor"
      (** The boolean ``or''. Evaluation is sequential, left-to-right:
	  in [e1 || e2], [e1] is evaluated first, and if it returns [true],
	  [e2] is not evaluated at all. *)


  val zero : bool
  val one : bool
  val neg : bool -> bool
  val succ : 'a -> bool
  val pred : 'a -> bool
  val abs : 'a -> 'a
  val add : bool -> bool -> bool
  val mul : bool -> bool -> bool
  val sub : 'a -> bool -> bool
  val div : 'a -> 'b -> 'c
  val modulo : 'a -> 'b -> 'c
  val pow : 'a -> 'b -> 'c
  val min_num : bool
  val max_num : bool
  val compare : 'a -> 'a -> int
  val of_int : int -> bool
  val to_int : bool -> int
  val of_string : string -> bool
    (** Convert the given string to a boolean.
	Raise [Invalid_argument "Bool.of_string"] if the string is not
	["true"], ["false"], ["0"], ["1"], ["tt"] or ["ff"]. *)

  val to_string : bool -> string
  val of_float  : float -> bool
  val to_float  : bool  -> float

  val ( + ) : t -> t -> t
  val ( - ) : t -> t -> t
  val ( * ) : t -> t -> t
  val ( / ) : t -> t -> t
  val ( ** ) : t -> t -> t
  val ( <> ) : t -> t -> bool
  val ( >= ) : t -> t -> bool
  val ( <= ) : t -> t -> bool
  val ( > ) : t -> t -> bool
  val ( < ) : t -> t -> bool
  val ( = ) : t -> t -> bool
  val operations : t Number.numeric

(** {6 Boilerplate code}*)
(** {7 S-Expressions}*)

val t_of_sexp : Sexplib.Sexp.t -> t
val sexp_of_t : t -> Sexplib.Sexp.t

(** {7 Printing}*)
val print: 'a #InnerIO.output -> t -> unit
end
