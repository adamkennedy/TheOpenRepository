require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Template::Plugin::StringTree',
	'VERSION_FROM' => 'lib/Template/Plugin/StringTree.pm',
	'PREREQ_PM'    => {
		# Application dependencies
		File::Spec    => '0.82',
		List::Util    => '1.11',

		# Test dependencies
		Test::More => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Access tree-like groups of strings naturally in both code and TT',
	) : (),
);
