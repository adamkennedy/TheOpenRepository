#!perl

print "1..1\n";

eval {
	require CPAN::Test::Dummy::Perl5::Developer;
};

if ( length($@) ) {
	print "not ok 1 - CPAN::Test::Dummy::Perl5::Developer loads ok\n";
} else {
	print "ok 1 - CPAN::Test::Dummy::Perl5::Developer loads ok\n";
}

exit(0);
