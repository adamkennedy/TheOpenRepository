
all: test

try1.marpa.raw: self.marpa bootstrap.pl
	perl -I../../ bootstrap.pl self.marpa > $@

try2.marpa.raw: try1.marpa.raw self.marpa
	../MDLex/bin/mdlex_dump -I../.. -OMarpa::MDL::Internal::Actions \
		try1.marpa.raw \
		self.marpa > $@

try3.marpa.raw: try2.marpa.raw self.marpa
	../MDLex/bin/mdlex_dump -I../.. -OMarpa::MDL::Internal::Actions \
		try2.marpa.raw \
		self.marpa > $@

test:  try2.marpa.raw try3.marpa.raw
	diff try2.marpa.raw try3.marpa.raw
