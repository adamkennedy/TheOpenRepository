package PPI::Exception;

use strict;
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.204_02';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	return bless { @_ }, $class if @_ > 1;
	return bless { message => $_[0] }, $class if @_;
	return bless { message => 'Unknown Reason' }, $class;
}

sub message {
	$_[0]->{message};
}

sub callers {
	@{ $_[0]->{callers} || [] };
}





#####################################################################
# Main Methods

sub throw {
	my $it = shift;
	if ( _INSTANCE($it, 'PPI::Exception') ) {
		if ( $it->{callers} ) {
			push @{ $it->{callers} }, [ caller(0) ];
		} else {
			$it->{callers} ||= [];
		}
	} else {
		my $message = $_[0] || 'Unknown Reason';
		$it = $it->new(
			message => $message,
			callers => [
				[ caller(0) ],
			],
		);
	}
	die $it;
}

1;
