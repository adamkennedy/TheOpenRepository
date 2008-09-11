use inc::Module::Install 0.77;

all_from       'lib/File/IgnoreReadonly.pm';
requires       'constant';
requires       'File::chmod'         => '0.32';
build_requires 'Test::More'          => '0.42';
build_requires 'File::Spec'          => '0.80';
build_requires 'File::Remove'        => '1.42';

WriteAll;
