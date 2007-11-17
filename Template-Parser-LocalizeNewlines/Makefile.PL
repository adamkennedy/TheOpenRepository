use strict;
BEGIN {
	require 5.000;
}
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Template::Parser::LocalizeNewlines',
	'VERSION_FROM' => 'lib/Template/Parser/LocalizeNewlines.pm',
	'PREREQ_PM'    => {
		# Application dependencies
		Template    => '2.00',

		# Test dependencies
		Test::More  => '0.47',
		File::Spec  => '0.82',
	},
	($] >= 5.005) ? (
		'AUTHOR'    => 'Adam Kennedy<cpan@ali.as>',
		'ABSTRACT'  => 'Drop-in replacement Template::Parser that fixes bad newlines',
	) : (),
);
