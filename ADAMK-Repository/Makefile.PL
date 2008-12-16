use inc::Module::Install 0.77;

author         'Adam Kennedy <adamk@cpan.org>';
license        'perl';
all_from       'lib/ADAMK/Repository.pm';
requires       'File::Spec'            => '3.29';
requires       'File::pushd'           => '1.00';
requires       'File::Find::Rule'      => '0.30';
requires       'File::Find::Rule::VCS' => '1.05';
requires       'File::Remove'          => '1.42';
requires       'IPC::Run3'             => '0.034';
requires       'Object::Tiny'          => '1.06';
requires       'Params::Util'          => '0.35';
requires       'CPAN::Version'         => '5.5';
build_requires 'Test::More'            => '0.86';
requires_external_bin 'svn';

WriteAll;
