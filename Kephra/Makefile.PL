use inc::Module::Install;

name           'Kepher';
all_from       'lib/Kephra.pm';   
requires       'File::Spec'            => '0.80';
requires       'File::Copy'            => 0;
requires       'File::Copy::Recursive' => 0;
requires       'File::HomeDir'         => '0.54';
requires       'File::UserConfig'      => '0.04';
requires       'Config::General'       => 0;
requires       'Hash::Merge'           => 0;
requires       'Wx'                    => '0.50';
requires       'Wx::STC'               => 0;
requires       'Wx::DND'               => 0;
requires       'Wx::Grid'              => 0;
requires       'Config::General'       => 0;
requires       'YAML'                  => 0;
build_requires 'Test::More'            => '0.47';
build_requires 'Test::Script'          => '0.01';
install_script 'bin/kephra';
install_share;

WriteAll;
