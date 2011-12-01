package t::lib::MyHtmlWindow;

use strict;
use Wx;
use Wx::Html;

our $VERSION = '0.68';
our @ISA     = 'Wx::Html';

sub new {
	shift->SUPER::new(@_);
}

1;
