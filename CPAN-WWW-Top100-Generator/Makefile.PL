use inc::Module::Install::DSL 0.88;

all_from       lib/CPAN/WWW/Top100/Generator.pm
requires_from  lib/CPAN/WWW/Top100/Generator.pm
test_requires  Test::More   0.42
test_requires  File::Remove 1.42
install_script cpantop100
