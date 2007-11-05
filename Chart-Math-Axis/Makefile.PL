require 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'Chart::Math::Axis',
	'VERSION_FROM' => 'lib/Chart/Math/Axis.pm',
	'PREREQ_PM'    => {
		'Clone'          => '0.25',
		'Math::BigInt'   => '1.70',
		'Math::BigFloat' => '1.44', # Needs bdiv()
		'Storable'       => '2.12',
		'Test::More'     => '0.42',
		'Params::Util'   => '0.15',
	},
	($] >= 5.005) ? (
		'AUTHOR'     => 'Adam Kennedy <cpan@ali.as>',
		'ABSTRACT'   => 'An algorithm to find good values for chart axis',
	) : (),
);
