use inc::Module::Install::DSL;

all_from      lib/Top100/Mojo.pm
requires      GraphViz
requires      CPANDB           0.14
requires      Mojo             0.9003
test_requires Test::More       0.80
test_requires Test::NoWarnings 1.02
test_requires Test::Script     1.07
