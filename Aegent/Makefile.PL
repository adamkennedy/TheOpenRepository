use inc::Module::Install::DSL 0.95;

all_from      lib/Aegent.pm
requires      AE
requires      AnyEvent         5.261
test_requires Test::More       0.80
test_requires Test::NoWarnings 1.01
