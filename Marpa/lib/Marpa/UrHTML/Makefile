
dummy:

test.storable:
	perl -I../.. ./rewrite.pl < t/test.html > $@

test.html: test.storable
	perl -I../.. ./rewrite2.pl < test.storable > $@

wenyan.storable:
	perl -I../.. ./rewrite.pl < ../../../wenyan/glossary.body.html > $@

wenyan.html:
	perl -I../.. ./rewrite2.pl < wenyan.storable > $@

