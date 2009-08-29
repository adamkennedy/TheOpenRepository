#! perl

use warnings;
use strict;
use IO::Handle;
require Perl::Dist::WiX;

STDOUT->autoflush(1);
STDERR->autoflush(1);

my $sb = Perl::Dist::WiX->new(
    image_dir => 'C:\WiXTest',
	temp_dir => 'C:\tmp',
	trace => 2,
	force => 1,
	app_id => 'WiXTest',
	app_name => 'Perl-Dist-WiX Test Perl',
	app_publisher => 'Curtis Jewell',
	app_publisher_url => 'http://csjewell.comyr.com/perl/',
	build_number => 10,
#	checkpoint_before => 5,
#	checkpoint_after => 10,
# After this run, uncomment this line, and comment the two above.
	checkpoint_before => 9,
	msi => 1,
	zip => 1,
	perl_version => 5100,
);

$sb->run();

require Data::Dumper;
require File::Slurp;
File::Slurp::write_file('makewix.data.txt', Data::Dumper->new([$sb], ['*sb'])->Indent(1)->Dump());
