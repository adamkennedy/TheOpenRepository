use inc::Module::Install 0.77;

author         'Adam Kennedy <adamk@cpan.org>';
license        'perl';
all_from       'lib/ADAMK/Repository.pm';
requires       'File::Spec' => '0.80';
build_requires 'Test::More' => '0.80';

WriteAll;
