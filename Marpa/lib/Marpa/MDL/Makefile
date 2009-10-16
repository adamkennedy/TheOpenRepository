
all: try2.marpa.raw

try1.marpa.raw:
	perl -I../../../lib bootstrap.pl self.marpa > $@

try2.marpa.raw: try1.marpa.raw
	perl -I../.. ./mdlex_dump try1.marpa.raw self.marpa > $@
