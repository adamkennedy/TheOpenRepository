use inc::Module::Install::DSL 0.90;

all_from              lib/ADAMK/Repository.pm
requires_from         lib/ADAMK/Repository.pm
requires              Module::Install   0.90
requires              ORDB::CPANUploads 0.01
requires              ORDB::CPANTesters 0.08
test_requires         Test::More        0.86
test_requires         Test::Script      1.03
test_requires         Test::NoWarnings  0.84
requires_external_bin svn
install_script        adamk
install_share
