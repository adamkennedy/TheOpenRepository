use inc::Module::Install::DSL 0.90;

all_from      lib/ORDB/AU/Census2006.pm
requires_from lib/ORDB/AU/Census2006.pm
requires       Module::Install::ORLite2Pod    0.1
test_requires Test::More  0.42
test_requires LWP::Online 1.07

#sadly, i didn't find a way to get it to coeectly have a space in the name...
orlite2pod	ORDB::AU::Census2006 lib AdamKennedy	adamk@cpan.org 2009
