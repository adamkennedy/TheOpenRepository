use inc::Module::Install::DSL 0.91;

all_from      lib/Aspect.pm
requires      Devel::Symdump   2.04
requires      Sub::Uplevel     0.2002
test_requires Test::More       0.70
test_requires Test::Class      0.33
test_requires Test::NoWarnings 0.084
test_requires Test::Exception  0.27
