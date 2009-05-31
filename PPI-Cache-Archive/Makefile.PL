use inc::Module::Install::DSL 0.90;

all_from       lib/PPI/Cache/Archive.pm
requires_from  lib/PPI/Cache/Archive.pm
test_requires  Test::More 0.42
install_script ppicache
