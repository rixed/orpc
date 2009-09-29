TYPE_CONV_PATH "Orpc_test"

(* An example with mere strings.
 * Give the server a string, and it will answer another string telling
 * if it found the letter 'O' in your string.
 *)

let (>>=) = Lwt.bind

type wc_in = GET_LENGTH of string | HAS_CHAR of (char * string) with sexp
type wc_out = GET_LENGTH_RES of int | HAS_CHAR_RES of bool with sexp

let server port =
	let service sexp =
		match wc_in_of_sexp sexp with
		| GET_LENGTH str -> Sexplib.Conv.sexp_of_int (String.length str)
		| HAS_CHAR (c, str) -> Sexplib.Conv.sexp_of_bool (String.contains str c) in
	Lwt_unix.run (
		Orpc.serve port service Orpc.sexp_unmarshaller Orpc.sexp_marshaller
	)

let client hostname port inp =
 	Lwt_unix.run (
		Lwt.ignore_result (Lwt_preemptive.init 1 10 (fun str -> prerr_endline str)) ;
		Orpc.connect hostname port Orpc.sexp_marshaller Orpc.sexp_unmarshaller >>= fun cnx ->
			Orpc.rcall cnx (sexp_of_wc_in inp) >>= fun out ->
				Lwt.return (print_endline ("Answer : "^(Sexplib.Sexp.to_string out)))
	)

let _ =
	match Array.length Sys.argv with
	| 2 -> server (int_of_string Sys.argv.(1))
	| 4 -> client Sys.argv.(1) (int_of_string Sys.argv.(2)) (GET_LENGTH Sys.argv.(3))
	| 5 -> client Sys.argv.(1) (int_of_string Sys.argv.(2)) (HAS_CHAR (Sys.argv.(3).[0], Sys.argv.(4)))
	| _ -> print_endline (Sys.argv.(0)^" port | hostname port string | hostname port string char")

