use inc::Module::Install::DSL 0.85;

all_from      lib/ORDB/CPANTSWeight.pm
requires      ORLite::Mirror 1.11
test_requires Test::More     0.42
test_requires LWP::Online    1.07
