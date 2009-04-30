use inc::Module::Install::DSL 0.83;

all_from      lib/Aspect.pm
requires      Benchmark::Timer 0.7100
requires      Devel::Symdump   2.07
requires      Test::Class      0.28
test_requires Test::More       0.70

extra_tests
