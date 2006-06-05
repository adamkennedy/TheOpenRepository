use inc::Module::Install;

name           'File-UserConfig';
all_from       'lib/File/UserConfig.pm';
requires       'Carp'                  => 0;
requires       'File::Spec'            => '0.80';
requires       'File::HomeDir'         => '0.51';
requires       'File::ShareDir'        => '0.03';
requires       'File::Copy::Recursive' => '0.18';
build_requires 'Test::More'            => '0.47';
build_requires 'File::Remove'          => 0;
install_share;

WriteAll;
