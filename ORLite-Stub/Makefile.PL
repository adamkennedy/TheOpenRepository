use inc::Module::Install::DSL 0.90;

all_from       lib/ORLite/Stub.pm
requires_from  lib/ORLite/Stub.pm
test_requires  Test::More 0.42
install_script orlite2stub
