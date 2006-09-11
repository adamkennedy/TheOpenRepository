use inc::Module::Install;

name           'PITA-Scheme';
all_from       'lib/PITA/Scheme.pm';
build_requires 'Module::Build'    => '0.28';
requires       'Carp'             => 0;
requires       'File::Temp'       => 0;
requires       'File::Spec'       => '0.80';
requires       'File::pushd'      => 0;
requires       'File::Which'      => 0;
requires       'IPC::Run3'        => '0.034';
requires       'Params::Util'     => '0.10';
requires       'Archive::Extract' => '0.07';
requires       'Process'          => '0.16';
requires       'PITA::XML'        => '0.30';
build_requires 'Cwd'              => 0;
build_requires 'Test::More'       => '0.47';
build_requires 'File::Remove'     => '0.22';

WriteAll;
