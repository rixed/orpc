OCAMLC   = ocamlfind ocamlc   -thread
OCAMLOPT = ocamlfind ocamlopt -thread
OCAMLDEP = ocamlfind ocamldep
OCAMLOPTFLAGS = -S -w Ae -g
OCAMLFLAGS    = -w Ae -g

OBJECTS  = orpc_test.cmo
XOBJECTS = orpc_test.cmx

PROGRAM  = orpc_test
XPROGRAM = orpc_test.opt

REQUIRES = orpc sexplib.syntax camlp4

.PHONY: all clean

all: $(PROGRAM)
opt: $(XPROGRAM)

$(PROGRAM): $(OBJECTS)
	$(OCAMLC)   -o $@ -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $^

$(XPROGRAM): $(XOBJECTS)
	$(OCAMLOPT) -o $@ -package "$(REQUIRES)" -linkpkg $(OCAMLOPTFLAGS) $^

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) -package "$(REQUIRES)" -syntax camlp4o $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) -package "$(REQUIRES)" -thread -syntax camlp4o $(OCAMLOPTFLAGS) -c $<

# Clean up
clean:
	rm -f *.cm[ioxa] *.cmxa *.a

# Dependencies
.depend: *.ml
	$(OCAMLDEP) -package "$(REQUIRES)" -syntax camlp4o $^ > $@

include .depend
