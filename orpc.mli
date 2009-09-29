(** This is the simplest RPC library I could come up with for ocaml programs.

    The idea is to have a straightforward way to call "distant" functions in a
    non-blocking fashion (using Lwt), where "distant" means another program
    running either on the same host or another one. In this later case, you must
    take care to use an architecture agnostic marshalling module (an helper for
    S-Expressions is provided).

    Like traditional RPCs, This is client-server where the client ask for the
    server to execute some function and wait for its return value. The server
    exports only one function, which accepts a single parameter which type (a
    constructed type probably) is defined by both the server (when he creates
    it's orpc_service) and the client (when he connects).

    If they happen to disagree on this type, the compiler won't catch it and a
    flying dragon might show up.
 
    @author rixed@free.fr *)

(** Type marshallers.
    You must provide an (un)marshaller when creating the server or connecting
    to it. Again, better use the same ones on both !  *)

(** Returns a thread that writes a value into an Lwt stream *)
type 'a marshaller = Lwt_unix.file_descr -> 'a -> unit Lwt.t

(** Returns a thread that reads a value from a Lwt stream *)
type 'a unmarshaller = Lwt_unix.file_descr -> 'a Lwt.t

(** These simple strings (un)marshallers might be useful.  Strings need
    marshalling because we must be able to read/write several ones in a single
    stream. These ones merely prepend the string by its length (in ASCII) so
    that we know where to stop.  *)

val string_marshaller : string marshaller
val string_unmarshaller : string unmarshaller

(** For more complex types, you can wrap S-expressions into strings.
    Of course, if you know that both clients and server will run on the same
    host you can choose a faster marshaller (like the one of the Marshal
    module).  *)

val sexp_marshaller : Sexplib.Sexp.t marshaller
val sexp_unmarshaller : Sexplib.Sexp.t unmarshaller

(** Client side.

    Before anything the client must call Lwt_preemptive.init (because the asynchronous
    domainname resolver requires it).
    Then one can connect to a server, and when done start to use rcall.  *)

(** The type of connections to a server that takes argument of type 'a and return
    values of type 'b.  *)
type ('a, 'b) connection

(** Returns a thread that connects to the specified hostname and port, using
    the given marshalling functions, and which final value is a handle to the connection
    suitable for rcall.  *)
val connect : string -> int -> 'a marshaller -> 'b unmarshaller -> ('a, 'b) connection Lwt.t

(** Returns a thread that calls the remote server with given argument and waits
    for the answer. *)
val rcall : ('a, 'b) connection -> 'a -> 'b Lwt.t

(** Server side.

    The server is only required to call the serve function with the appropriate
    (un)marshallers and, of course, the function that will handle clients
    queries. *)
val serve : int -> ('a -> 'b) -> 'a unmarshaller -> 'b marshaller -> unit Lwt.t

