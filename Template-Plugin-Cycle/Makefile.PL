require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Template::Plugin::Cycle',
	'VERSION_FROM' => 'lib/Template/Plugin/Cycle.pm',
	'PREREQ_PM'    => {
		# Test dependencies
		File::Spec => '0.82',
		Test::More => '0.47',
		Template   => '2.10',
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Cyclically insert into a Template from a sequence of values',
	) : (),
);
