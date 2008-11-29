use inc::Module::Install 0.77;

all_from       'lib/Text/FindIndent.pm';
build_requires 'Test::More' => '0.80';
license        'perl';

WriteAll;
