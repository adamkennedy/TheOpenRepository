use inc::Module::Install::DSL 1.00;

all_from       lib/SDL/Tutorial/3DWorld.pm
requires_from  lib/SDL/Tutorial/3DWorld.pm
test_requires  Test::More 0.80
test_requires  Test::Script
install_script 3dworld
