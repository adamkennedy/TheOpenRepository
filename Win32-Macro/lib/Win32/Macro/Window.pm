package Win32::Macro::Window;

=pod

=head1 NAME

Win32::Macro::Window - An abstraction for a Window in the Win32 Macro System

=head1 SYNOPSIS

  # Locate all windows
  my @windows = Win32::Macro::Window->find_by_title('My Program');
  my $window  = Win32::Macro::Window->find_by_title('My Program');
  
  # Save a screenshot of the Window to a file
  $window->save_as('image.bmp');
  
  # Add more later...

=head1 DESCRIPTION

=cut

use 5.006;
use strict;

our $VERSION = '0.01';





#####################################################################
# Static Methods

sub find_all {

}






#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless {
		hwnd => shift,
		}, $class;
	return $self;
}

sub hwnd {
	$_[0]->{hwnd};
}

1;
	