use inc::Module::Install::DSL 0.99;

all_from      lib/FBP.pm
requires_from lib/FBP.pm
test_requires File::Spec       0.80
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
