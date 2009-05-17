use inc::Module::Install::DSL 0.88;

all_from      lib/CPANDB/Generator.pm
requires_from lib/CPANDB/Generator.pm
requires_from script/cpandb-generate
requires      Probe::Perl 0.01
test_requires Test::More  0.42
