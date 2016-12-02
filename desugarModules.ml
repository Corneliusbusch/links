(* New implementation of desugarModules making use of the scope graph. *)
(*
 * Desugars modules into plain binders.
 * Bindingnode -> [Bindingnode]
 *
 * module Foo {
 *    val bobsleigh = ...;
 *    fun x() {
 *    }
 *
 *    module Bar {
 *      fun y() {
 *      }
 *    }
 * }
 * val x = ...;
 *
 *  --->
 *
 * val Foo.bobsleigh = ...;
 * fun Foo.x() { ...}
 * fun Foo.Bar.y() { ... }
 * val x = ...;
 *
*)
open Utility
open Sugartypes
open Printf
open ModuleUtils
open ScopeGraph

let get_fq_resolved_decl decl_name sg u_ast =
  ScopeGraph.make_resolved_plain_name decl_name sg u_ast

(* Wrapper function taking a unique reference, scope graph, and
 * unique AST, and providing a single output reference name.
 *
 * If the resolution is unsuccessful, will simply return the plain name,
 * which will be picked up as an error later.
 *
 * If the resolution is ambiguous, then the function will raise an error.
 * *)
let resolve name resolver scope_graph u_ast =
  match resolver#resolve_reference name with
    | `UnsuccessfulResolution ->
        (* failwith ("Resolution of " ^ name ^ " was unsuccessful"); *)
        Uniquify.lookup_var name u_ast
    | `SuccessfulResolution decl_name ->
        (* printf "Successful resolution of name %s: %s\n" name decl_name; *)
        get_fq_resolved_decl decl_name scope_graph u_ast
    | `AmbiguousResolution decl_names ->
        let plain_names = List.map (fun n -> get_fq_resolved_decl n scope_graph u_ast) decl_names in
        failwith ("Error: ambiguous resolution for " ^ name ^ ":" ^ (print_list decl_names))


let rec get_last_list_value = function
  | [] -> failwith "INTERNAL ERROR: Empty list in get_last_list_value. This can only be caused by an" ^
            "empty qualified name and so should be outlawed by the grammar"
  | [x] -> x
  | x::xs -> get_last_list_value xs


(* After renaming, we can simply discard modules and imports. *)
let rec flatten_simple = fun () ->
object(self)
  inherit SugarTraversals.map as super

  method phrasenode : phrasenode -> phrasenode = function
    | `Block (bs, phr) ->
        let flattened_bindings =
          List.concat (
            List.map (fun b -> ((flatten_bindings ())#binding b)#get_bindings) bs
          ) in
        let flattened_phrase = self#phrase phr in
        `Block (flattened_bindings, flattened_phrase)
    | x -> super#phrasenode x
end

(* Flatten modules out. By this point the renaming will already have
 * happened.
 * Also, remove import statements (as they will have been used by the renaming
 * pass already, and we won't need them any more)
 *)
and flatten_bindings = fun () ->
object(self)
  inherit SugarTraversals.fold as super

  val bindings = []
  method add_binding x = {< bindings = x :: bindings >}
  method get_bindings = List.rev bindings

  method binding = function
    | (`Module (_, bindings), _) ->
        self#list (fun o -> o#binding) bindings
    | (`QualifiedImport _, _) -> self
    | b -> self#add_binding ((flatten_simple ())#binding b)

  method program = function
    | (bindings, _body) -> self#list (fun o -> o#binding) bindings
end


let perform_type_renaming resolver type_scope_graph unique_ast =
  object(self)
    inherit SugarTraversals.map as super
    method bindingnode = function
      | `Type (n, tvs, dt) ->
        let plain_name =
          ScopeGraph.make_resolved_plain_name n type_scope_graph unique_ast in
        let dt = self#datatype' dt in
        `Type (plain_name, tvs, dt)
      | bn -> super#bindingnode bn

    method datatype = function
      | `TypeApplication (name, args) ->
            `TypeApplication (resolve name resolver type_scope_graph unique_ast, args)
      | `QualifiedTypeApplication (names, args) ->
          let name = get_last_list_value names in
          `TypeApplication (resolve name resolver type_scope_graph unique_ast, args)
      | dt -> super#datatype dt
  end

let perform_renaming resolver scope_graph unique_ast =
object(self)
  inherit SugarTraversals.map as super

  method binder = function
    | (unique_name, dt, pos) ->
        (* Binders should just be resolved to their unique FQ name *)
        let plain_name =
          ScopeGraph.make_resolved_plain_name unique_name scope_graph unique_ast in
        (plain_name, dt, pos)

  method phrasenode = function
    | `Var name ->
        (* Resolve name. If it's ambiguous, throw an error.
         * If it's not found, just put the plain one back in and the error will
         * be picked up later.*)
        (* printf "Attempting to resolve Var %s\n" name; *)
        `Var (resolve name resolver scope_graph unique_ast)
    | `QualifiedVar names ->
        (* Only need to look at the final name here *)
        let name = get_last_list_value names in
        (* printf "Attempting to resolve (qualified) Var %s\n" name; *)
        `Var (resolve name resolver scope_graph unique_ast)
    | pn -> super#phrasenode pn

  method datatype dt = dt
end


let desugarModules scope_graph ty_scope_graph unique_ast =
  (*
  printf "Starting module desugar\n";
  printf "%!";
  *)
  let unique_prog = Uniquify.get_ast unique_ast in
  printf "Type Scope graph: %s\n" (ScopeGraph.show_scope_graph ty_scope_graph);
  printf "Scope graph: %s\n" (ScopeGraph.show_scope_graph scope_graph);
  (*
  printf "Before module desugar: %s\n" (Sugartypes.Show_program.show unique_prog);
  printf "\n=============================================================\n";
  *)
  let term_resolver = ScopeGraph.make_resolver scope_graph unique_ast in
  let desugared_terms_prog =
    (perform_renaming term_resolver scope_graph unique_ast)#program unique_prog in
  (*
  printf "After term desugar: %s\n" (Sugartypes.Show_program.show desugared_terms_prog);
  printf "\n=============================================================\n";
  *)
  printf "starting type renaming\n%!";
  let type_resolver = ScopeGraph.make_resolver ty_scope_graph unique_ast in
  let plain_prog =
    (perform_type_renaming type_resolver ty_scope_graph unique_ast)#program desugared_terms_prog in
  printf "got past type renaming\n%!";
  let o = (flatten_bindings ())#program plain_prog in
  let flattened_bindings = o#get_bindings in
  let flattened_prog = (flattened_bindings, snd plain_prog) in
  (* Debug *)
  (*
  printf "After module desugar: %s\n" (Sugartypes.Show_program.show flattened_prog);
  *)
  flattened_prog
