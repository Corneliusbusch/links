(*pp deriving *)
open Num
open Utility

type like_expr = [ `caret | `dollar | `underscore | `percent | `string of string | `variable of string | `seq of like_expr list]
    deriving (Eq, Typeable, Show, Pickle, Shelve)

(* Convert a like expression to a string. *)
let rec like_as_string : like_expr -> string =
  let quote = Str.global_replace (Str.regexp_string "%") "\\%" in
    function
      |	`caret -> ""
      |	`dollar -> ""
      |	`underscore -> "_"
      | `percent -> "%"
      | `string s -> quote s
      | `variable v -> "VARIABLE : " ^ v
      | `seq rs -> mapstrcat "" like_as_string rs

type table_spec = [ `TableName of string | `TableVariable of string ]
    deriving (Eq, Typeable, Show, Pickle, Shelve)

type table_instance = table_spec * string (* (real_name, alias) *)
    deriving (Eq, Typeable, Show, Pickle, Shelve)

(** A SQL expression to be used as the condition for a query. *)
type expression =
  | Field of (string (* table name (as) *) * string (* field name (real) *))
  | Variable of string
  | Null
  | Integer of num
  | Float of float
  | Boolean of bool
  | LikeExpr of like_expr
  | Text of string
  | Funcall of (string * expression list)
  | Binary_op of (string * expression * expression)
  | Unary_op of (string * expression)
  | Query of query
      
(** query:
    A query to a database. The elements in the record type are in order: {ol
      {li True if no duplicates should be returned, false otherwise.}
      {li A set of all columns to be returned formated as (table renaming, column name, renaming, SLinks kind).
        If this list is empty, the SQL 'NULL' value will be returned for every row.}
      {li A list of tables to query formated as (table name, table renaming).}
      {li The condition to be satisfied for a row to be returned.}
      {li A list of colums to be ordered formated as `Asc (table renaming, column name) for ascending ordering,
         `Desc (table renaming, column name) for descending ordering. If the list is empty, no ordering is done.}}
    @version 1.0 *)
and query = {distinct_only : bool;
             result_cols : col_or_expr list;
             tables : table_instance list;
             condition : expression;
             sortings : sorting list;
             max_rows : expression option; (* The maximum number of rows to be returned *)
             offset : expression; (* The row in the table to start from *)
            }

and sorting = [`Asc of (string * string) | `Desc of (string * string)]
and column = {table_alias : string;
              name : string;
              col_alias : string; (* TBD: call this `alias' *)
              col_type : Types.datatype}
and col_or_expr = (column, expression) either
    deriving (Eq, Typeable, Show, Pickle, Shelve)

(* Simple accessors *)

let add_sorting query col = 
  {query with
     sortings = col :: query.sortings}

let owning_table of_col qry =
  match (List.find (function
                              | Left c -> c.name = of_col
                              | Right _ -> false) qry.result_cols) with
    | Left col_rec -> col_rec.table_alias
    | Right _ -> assert false

let rec freevars {condition = condition;
                  offset = offset;
                  result_cols = result_cols;
                  max_rows = max_rows} =
  qexpr_freevars condition
@ qexpr_freevars offset
@ fromOption [] (opt_map qexpr_freevars max_rows)
@ concat_map colorexpr_freevars result_cols
and qexpr_freevars = function
    Variable name -> [name]
  | Funcall (_, exprs) -> concat_map qexpr_freevars exprs
  | Binary_op (_, lhs, rhs) -> qexpr_freevars lhs @ qexpr_freevars rhs
  | Unary_op (_, arg) -> qexpr_freevars arg
  | Query q -> freevars q
  | _ -> []
and colorexpr_freevars = function
  | Left _ -> []
  | Right e -> qexpr_freevars e

let rec replace_var name expr = function
  | Variable var when var = name -> expr
  | Funcall (op, args) -> Funcall(op, List.map (replace_var name expr) args)
  | Binary_op(op, lhs, rhs) -> Binary_op(op, replace_var name expr lhs,
                                         replace_var name expr rhs)
  | Unary_op(op, arg) -> Unary_op(op, replace_var name expr arg)
  | Query query -> Query (query_replace_var name expr query)
  | x -> x
and query_replace_var var expr query =
  {query with condition = replace_var var expr query.condition}

let occurs_free var q = List.mem var (freevars q)