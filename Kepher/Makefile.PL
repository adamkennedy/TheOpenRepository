use inc::Module::Install;

name           'Kepher';
all_from       'lib/Kepher.pm';   
requires       'File::Spec'            => '0.80';
requires       'Wx'                    => '0.50';
requires       'Wx::STC'               => 0;
requires       'Wx::DND'               => 0;
requires       'Wx::Grid'              => 0;
requires       'Config::General'       => 0;
requires       'YAML'                  => 0;
requires       'File::Copy'            => 0;
requires       'File::Copy::Recursive' => 0;
requires       'Hash::Merge'           => 0;
requires       'File::UserConfig'      => 0;
build_requires 'Test::More'            => '0.47';
install_share;

WriteAll;

