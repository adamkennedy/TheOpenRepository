use inc::Module::Install::DSL 1.00;

all_from      lib/FBP/Perl.pm
requires_from lib/FBP/Perl.pm
test_requires File::Spec       0.80
test_requires Test::More       0.47
test_requires Test::LongString 0.13
test_requires Test::NoWarnings 0.084
