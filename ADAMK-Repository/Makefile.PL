use inc::Module::Install::DSL 0.83;

all_from              lib/ADAMK/Repository.pm
requires_from         lib/ADAMK/Repository.pm
requires              ORDB::CPANTesters 
test_requires         Test::More        0.86
test_requires         Test::Script      1.03
test_requires         Test::NoWarnings  0.84
install_share
install_script        adamk
requires_external_bin svn
