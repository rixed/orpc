NAME = orpc

OCAMLC   = ocamlfind ocamlc   -thread
OCAMLOPT = ocamlfind ocamlopt -thread
OCAMLDEP = ocamlfind ocamldep
OCAMLDOC = ocamlfind ocamldoc
OCAMLOPTFLAGS = -S -w Ae -g
OCAMLFLAGS    = -w Ae -g

OBJECTS  = orpc.cmo
XOBJECTS = orpc.cmx

ARCHIVE  = $(NAME).cma
XARCHIVE = $(NAME).cmxa

REQUIRES = lwt.extra sexplib.syntax camlp4

.PHONY: all clean install uninstall doc

all: $(ARCHIVE)
opt: $(XARCHIVE)

$(ARCHIVE): $(OBJECTS)
	$(OCAMLC)   -a -o $(ARCHIVE)  -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $(OBJECTS)

$(XARCHIVE): $(XOBJECTS)
	$(OCAMLOPT) -a -o $(XARCHIVE) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) $(XOBJECTS)

orpc_test: orpc.cmx orpc_test.cmx
	$(OCAMLOPT) -package "$(REQUIRES)" -syntax camlp4o -thread -linkpkg $(OCAMLOPTFLAGS) -o $@ $^

install: all
	if test -f $(XARCHIVE) ; then extra="$(XARCHIVE) "`basename $(XARCHIVE) .cmxa`.a ; fi ; \
	ocamlfind install $(NAME) *.mli *.cmi $(ARCHIVE) META $$extra

uninstall:
	ocamlfind remove $(NAME)

html:
	mkdir -p $@

doc: all html
	$(OCAMLDOC) -package "$(REQUIRES)" -html -d html orpc.ml* 

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) -package "$(REQUIRES)" -thread -syntax camlp4o $(OCAMLOPTFLAGS) -c $<

# Clean up
clean:
	rm -f *.cm[ioxa] *.cmxa *.a
	rm -rf html

# Dependencies
.depend: *.ml *.mli
	$(OCAMLDEP) -package "$(REQUIRES)" -syntax camlp4o *.mli *.ml > .depend

include .depend
