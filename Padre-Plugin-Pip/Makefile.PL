use inc::Module::Install 0.77;

all_from       'lib/Padre/Plugin/Pip.pm';
requires       'pip'                => '0.13';
requires       'Padre'              => '0.13';
build_requires 'Test::More'         => '0.42';
build_requires 'Test::NeedsDisplay' => '1.05';

WriteAll;
