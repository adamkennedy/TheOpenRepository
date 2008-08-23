use inc::Module::Install 0.77;

all_from      'lib/Test/NeedsDisplay.pm';
requires      'File::Spec' => '0.80';
test_requires 'Test::More' => '0.47';

unless ( $^O eq 'MSWin32' or $ENV{DISPLAY} ) {
	requires_external_bin 'xvfb-run';
}

WriteAll;
