(** {0 IR variables} *)

open Utility

[@@@ocaml.warning "-39"] (** disable warnings about unused rec flags  in this module**)

type scope = [ `Local | `Global ]
  [@@deriving show]
(** Term variables *)
type var = int
  [@@deriving show,eq,yojson]
type var_info = Types.datatype * string * scope
  [@@deriving show]
type binder = var * var_info
  [@@deriving show]

let dummy_var = 0

(** {0 Generation of fresh variables} *)
let variable_counter = ref dummy_var

(** Generate just a fresh identifier *)
let fresh_raw_var : unit -> var =
  fun () ->
    incr variable_counter;
    !variable_counter

(** Given metadata, generate a full binder *)
let fresh_binder : var_info -> binder =
  fun info ->
    let var = fresh_raw_var () in
      (var, info)

(** Given metadata, generate a full binder and pair it with the new
    variable identifer; note this identifier is already the first
    component of the [binder] value *)
let fresh_var : var_info -> binder * var =
  fun info ->
    let (var, info) = fresh_binder info in
      (var, info), var

(** {0 Manipulate binder metadata} *)

let info_type (t, _, _) = t
let info_of_type t = (t, "", `Local)

let make_local_info (t, name) = (t, name, `Local)
let make_global_info (t, name) = (t, name, `Global)

let fresh_binder_of_type = info_of_type ->- fresh_binder
let fresh_var_of_type = info_of_type ->- fresh_var
let fresh_global_var_of_type = info_of_type ->- fresh_var

let var_of_binder (var, _ : binder) = var
let info_of_binder (_, info : binder) = info
let type_of_binder (_, (t, _, _) : binder) = t
let name_of_binder (_, (_, name, _) : binder) = name
let scope_of_binder (_, (_, _, scope) : binder) = scope

(** Create a copy of a type environment mapping vars (= ints) to types
    instead of strings to types
*)
let varify_env (nenv, tenv) : Types.datatype Env.Int.t =
  Env.String.fold
    (fun name t tenv ->
       Env.Int.bind tenv (Env.String.lookup nenv name, t))
    tenv
    Env.Int.empty
