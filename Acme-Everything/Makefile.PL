use inc::Module::Install;

name           'Acme-BadExample';
all_from       'lib/Acme/BadExample.pm';
requires       'CPANPLUS'       => 0;
requires       'Class::AutoUse' => '1.03';
build_requires 'File::Spec'     => '0.80';
build_requires 'Test::More'     => '0.47';

WriteAll;

require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Acme::Everything',
	'VERSION_FROM' => 'lib/Acme/Everything.pm',
	'PREREQ_PM'    => {
		Test::More     => 0,
		CPANPLUS       => 0,
		File::Spec     => 0.83,
		Class::Autouse => 1.03,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Effectively loads every class in CPAN',
	) : (),
);
