use inc::Module::Install::DSL 0.83;

name          prefork
all_from      lib/prefork.pm
requires      Scalar::Util 1.10
test_requires Test::More   0.47
test_requires File::Spec   0.80
