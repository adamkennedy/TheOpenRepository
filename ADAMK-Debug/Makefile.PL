use inc::Module::Install;

name           'ADAMK-Debug';
all_from       'bin/apld';
build_requires 'Test::More'   => '0.47';
build_requires 'Test::Script' => '0.01';
install_script 'bin/apld';

WriteAll;
