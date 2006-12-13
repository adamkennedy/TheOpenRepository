package Win32::Macro::Internals;

use 5.006;
use strict;
use warnings;
use Carp;
use Exporter ();

our $VERSION     = '0.01';
our @ISA         = 'Exporter';

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.
	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Win32::Screenshot::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ( $error ) {
		croak $error;
	}
	SCOPE: {
		no strict 'refs';
		*$AUTOLOAD = sub { $val };
	}
	goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Win32::Macro::Internals', $VERSION);

sub ListWindows () {
  ListChilds(GetDesktopWindow());
}

sub ListChilds ($) {
  my $parent = shift;
  my $hwnd = GetWindow($parent, GW_CHILD());
  my @list;

  while($hwnd) {
    my %win = (
      hwnd => $hwnd,
      title => GetWindowText($hwnd),
      rect  => [ GetWindowRect($hwnd) ],
      visible => IsVisible($hwnd),
    );
    push @list, \%win;
    $hwnd = GetWindow($hwnd, GW_HWNDNEXT());
  }

  return @list;
}

sub _getHwnd ($) {
  my $id = shift;
  if ( $id !~ /^\d+$/ ) {
    $id = FindWindow(undef, $id);
  }
  return $id;
}

sub _capture {
  CreateImage( CaptureHwndRect(@_) );
}

# This needs to be fully ported to Imager
# This was just done with s/Image::Magik/Imager/
sub CreateImage {
  my ($width, $height) = @_;
  my $image = Image->new(xsize => $width, ysize => $height);
  for my $y (0 .. $height-1) {
    my $scanline = substr($_[2], -$width * 4, $width * 4, '');
    $image->setscanline(y => $y, pixels => $data);
  }
  $image;
}

sub CaptureWindowRect ($$$$$) {
  _capture(_getHwnd(shift), @_);
}

sub CaptureWindow ($) {
  my $id   = _getHwnd(shift);
  my @rect = GetWindowRect($id);
  _capture(GetDesktopWindow(), $rect[0], $rect[1], $rect[2]-$rect[0], $rect[3]-$rect[1] );
}

sub CaptureScreen () {
  my $id = GetDesktopWindow();
  _capture($id, GetWindowRect($id));
}

sub CaptureRect ($$$$) {
  my $id = GetDesktopWindow();
  _capture($id, @_);
}

1;
