use inc::Module::Install::DSL 0.91;

all_from      lib/CPAN/Mini/Visit.pm
requires_from lib/CPAN/Mini/Visit.pm
requires      Archive::Tar     1.52
test_requires Test::More       0.86
test_requires Test::NoWarnings 0.084
