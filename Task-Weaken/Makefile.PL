use inc::Module::Install;

name           'Task-Weaken';
all_from       'lib/Task/Weaken.pm';
requires       'Scalar::Util' => '1.14'; # Last significant bug-fix to weaken
build_requires 'Test::More'   => '0.42';
build_requires 'File::Spec'   => '0.80';

WriteAll;
