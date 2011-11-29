use inc::Module::Install::DSL 1.04;

all_from      lib/Parse/CSV.pm
requires_from lib/Parse/CSV.pm
test_requires File::Spec   0.80
test_requires Test::More   0.47
