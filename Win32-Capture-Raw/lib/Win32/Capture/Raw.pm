package Win32::Capture::Raw;

use 5.008;
use strict;
use Exporter   ();
use Win32::API ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Exporter';
}

my $Win32_GetDC = Win32::API->new('user32','GetDC',['N'],'N');





#####################################################################
# Exportable Functions

sub capture {
	my $dc = $Win32_GetDC->Call(0);
	return \$dc;
}

1;
