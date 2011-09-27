package t::lib::MyHtmlWindow;

use strict;
use Wx;
use Wx::Html;

our $VERSION = '0.64';
our @ISA     = 'Wx::Html';

sub new {
	shift->SUPER::new(@_);
}

1;
