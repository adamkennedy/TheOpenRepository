
dummy:

test: test.storable
	cmp test.storable test.storable.save
	cmp glossary.storable glossary.storable.save

test.storable:
	perl -I../lib ./rewrite.pl <test.html > $@

test_out.html: test.storable
	perl -I../lib ./rewrite2.pl <test.storable > $@

glossary.storable:
	perl -I../lib ./rewrite.pl < glossary.body.html > $@

glossary.body.out.html: glossary.storable
	perl -I../lib ./rewrite2.pl < glossary.storable > $@

