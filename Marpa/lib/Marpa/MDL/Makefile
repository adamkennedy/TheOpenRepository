
all: try2.marpa.raw

try1.marpa.raw:
	perl -I../../ bootstrap.pl self.marpa > $@

try2.marpa.raw: try1.marpa.raw
	../MDLex/bin/mdlex_dump -I../.. -OMarpa::MDL::Internal::New_Actions \
		try1.marpa.raw \
		self.marpa > $@

try3.marpa.raw: try2.marpa.raw
	../MDLex/bin/mdlex_dump -I../.. -OMarpa::MDL::Internal::New_Actions \
		try2.marpa.raw \
		self.marpa > $@

test:  try2.marpa.raw try3.marpa.raw
	diff try2.marpa.raw try3.marpa.raw
