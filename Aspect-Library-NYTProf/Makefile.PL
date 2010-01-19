use inc::Module::Install::DSL 0.91;

all_from      lib/Aspect/Library/NYTProf.pm
requires      Aspect         0.40
requires      Devel::NYTProf 3.01
test_requires Test::More     0.42
