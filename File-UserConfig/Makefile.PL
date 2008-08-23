use inc::Module::Install 0.77;

all_from      'lib/File/UserConfig.pm';
requires      'Carp'                  => 0;
requires      'File::Spec'            => '0.80';
requires      'File::HomeDir'         => '0.51';
requires      'File::ShareDir'        => '0.03';
requires      'File::Copy::Recursive' => '0.18';
test_requires 'Test::More'            => '0.47';
test_requires 'File::Remove'          => '1.42';
install_share;

WriteAll;
