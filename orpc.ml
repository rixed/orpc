let (>>=) = Lwt.(>>=)

(** (Un)Marshallers *)

type 'a marshaller = Lwt_unix.file_descr -> 'a -> unit Lwt.t
type 'a unmarshaller = Lwt_unix.file_descr -> 'a Lwt.t

(** Write or read a predetermined amount of char into a Lwt stream.
	@return a thread that wait until everything was read/write from/to the supplied buffer.
	@raise Failure when reading a closed stream. *)
let complete_io io_func fd buffer =
	let length = String.length buffer in
	let rec do_more offset =
		let to_io = length - offset in
		io_func fd buffer offset to_io >>= function
			| 0 -> Lwt.fail (Failure "Client closed")
			| rlen when rlen = to_io -> Lwt.return ()
			| rlen -> do_more (offset + rlen) in
	do_more 0

let write_length fd str = complete_io Lwt_unix.write fd str

let read_length fd length =
	let buffer = String.create length in
	complete_io Lwt_unix.read fd buffer >>= fun () ->
		Lwt.return buffer

(** When we write an ASCII length, use that number of digits (justified with zeros). *)
let mashall_int_buffer_len = 5

(** (Un)Marshallers for strings and S-Expressions. *)

let string_marshaller fd str =
	let len = String.length str in
	let header = Printf.sprintf "%0*d" mashall_int_buffer_len len in
	write_length fd (header^str)

let string_unmarshaller fd =
	read_length fd mashall_int_buffer_len >>= fun buffer ->
		read_length fd (int_of_string buffer)

let sexp_marshaller fd sexp = string_marshaller fd (Sexplib.Sexp.to_string sexp)
let sexp_unmarshaller fd = string_unmarshaller fd >>= fun str ->
	Lwt.return (Sexplib.Sexp.of_string str)

(* Client *)

type ('a, 'b) connection = {
	fd : Lwt_unix.file_descr ;	(** The socket file descriptor as a Lwt stream. *)
	marshaller : 'a marshaller ;	(** The marshalling function. *)
	unmarshaller : 'b unmarshaller	(** The unmarshalling function. *)
}

let connect hostname port marshaller unmarshaller =
	let sock_fd = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
	Lwt_lib.gethostbyname hostname >>= fun host_entry ->
		if Array.length host_entry.Unix.h_addr_list < 1 then (
			Lwt.fail (Failure ("No useable address when resolving '"^hostname^"'"))
		) else (
			let addr = host_entry.Unix.h_addr_list.(0) in
			Lwt_unix.connect sock_fd (Unix.ADDR_INET (addr, port)) >>= fun () ->
				Lwt.return { fd = sock_fd ; marshaller = marshaller ; unmarshaller = unmarshaller }
		)

let rcall cnx arg =
	cnx.marshaller cnx.fd arg >>= fun () ->
		cnx.unmarshaller cnx.fd

(* Server *)

(** Accept on SYN from fd, and execute the service_func function on each connection. *)
let rec accept_all fd service_func =
	Lwt_unix.accept fd >>= fun (peer_fd, peer_addr) ->
		Lwt.ignore_result (
			Lwt.catch (fun () ->
				Lwt.finalize
					(fun () -> service_func peer_fd peer_addr)
					(fun () -> Lwt.return (Lwt_unix.close peer_fd))
			) (function
				| Failure str -> Lwt.return (prerr_endline str (* FIXME: log *))
				| e -> Lwt.fail e)
		) ;
		accept_all fd service_func

let local_addr num = Unix.ADDR_INET (Unix.inet_addr_any, num)

let string_of_sockaddr = function
	| Unix.ADDR_UNIX s -> s
	| Unix.ADDR_INET (inet, port) -> (Unix.string_of_inet_addr inet)^":"^(string_of_int port)

(** Listen on this port and run service_func on all sockets. *)
let listen port service_func =
	let serv_fd = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
	Lwt_unix.setsockopt serv_fd Unix.SO_REUSEADDR true ;
	Lwt_unix.bind serv_fd (local_addr port) ;
	Lwt_unix.listen serv_fd 10 ;
	accept_all serv_fd service_func

let serve port rfunc unmarshaller marshaller =
	listen port (fun fd addr ->
		let rec forever f = f () >>= fun () -> forever f in
		print_endline ("Connected from "^(string_of_sockaddr addr))	(* FIXME: log *) ;
		forever (fun () ->
			unmarshaller fd >>= fun arg ->
				marshaller fd (rfunc arg)
		)
	)

