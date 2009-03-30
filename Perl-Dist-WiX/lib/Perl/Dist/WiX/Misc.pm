package Perl::Dist::WiX::Misc;

####################################################################
# Perl::Dist::WiX::Misc - Miscellaneous routines for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# NOTE: This is a base class with miscellaneous routines.  It is
# meant to be subclassed, as opposed to creating objects of this
# class directly.

#<<<
use     5.006;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                    );
use     Object::InsideOut     qw( Storable                    );
use     Params::Util          qw( _STRING  _POSINT _NONNEGINT );
use     File::Spec::Functions qw( splitpath splitdir          );
use     List::MoreUtils       qw( any                         );
use     Data::UUID            qw( NameSpace_DNS               );
require Devel::StackTrace;

use version; $VERSION = version->new('0.163')->numify;

#>>>

#####################################################################
# Error Handling

use Exception::Class (
	'PDWiX'            => { 'description' => 'Perl::Dist::WiX error', },
	'PDWiX::Parameter' => {
		'description' =>
		  'Perl::Dist::WiX error: Parameter missing or invalid',
		'isa'    => 'PDWiX',
		'fields' => [ 'parameter', 'where' ],
	},
	'PDWiX::Caught'    => { 
		'description' => 
		  'Error caught by Perl::Dist::WiX from other module', 
		'isa'    => 'PDWiX',
		'fields' => [ 'message', 'info' ],
	},
);

sub PDWiX::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string     = $self->description() . ': ' . $self->message() . "\n" .  'Time error caught: ' . localtime() . "\n";
	my $misc       = Perl::Dist::WiX::Misc->new();
	my $tracelevel = $misc->get_trace() % 100;

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $misc->_trace_line( 0, $string, 0, $tracelevel,
		$self->trace->frame(0) );
} ## end sub PDWiX::full_message

sub PDWiX::Parameter::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->parameter()
	  . ' in Perl::Dist::WiX'
	  . $self->where() . "\n" . 'Time error caught: ' . localtime() . "\n";
	my $misc       = Perl::Dist::WiX::Misc->new();
	my $tracelevel = $misc->get_trace() % 100;

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	return $misc->_trace_line( 0, $string, 0, $tracelevel,
		$self->trace->frame(0) );
} ## end sub PDWiX::Parameter::full_message

sub PDWiX::Caught::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message()
	  . "\n"
	  . $self->info() . "\n" . 'Time error caught: ' . localtime() . "\n";
	my $misc       = Perl::Dist::WiX::Misc->new();
	my $tracelevel = $misc->get_trace() % 100;

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $misc->_trace_line( 0, $string, 0, $tracelevel,
		$self->trace->frame(0) );
} ## end sub PDWiX::Parameter::full_message

#####################################################################
# Attributes

# Tracestate, sitename, and sitename_guid are singletons.
my $tracestate    = -1;
my $sitename      = q{};
my $sitename_guid = undef;
my $guidgen       = undef;

my %init_args : InitArgs = (
	'TRACE' => {
		'Regex'   => qr/\Atrace(?:level)?\z/imsx,
		'Type'    => 'numeric',
		'Default' => -1,
	},
	'SITENAME' => {
		'Regex'   => qr/\Asite(?:name)?\z/imsx,
		'Type'    => 'scalar',
		'Default' => q{},
	},
);

#####################################################################
# Accessors

sub sitename { return $sitename; }

sub get_trace { return $tracestate; }


#####################################################################
# Constructor for Misc
#
# Parameters: (pairs)
#   sitename: Name of site that distribution is for.
#     (default: www.perl.invalid)
#   trace: Trace level. : (default: 0)

sub _init : Init {
	my ( $self, $args ) = @_;

	# Set the trace state from the parameter IF it's
	# non-negative. Otherwise, set it to 0.

	$tracestate =
	    defined _NONNEGINT( $args->{'TRACE'} ) ? $args->{'TRACE'}
	  : defined _NONNEGINT($tracestate)        ? $tracestate
	  :                                          0;

	# Set the sitename from the parameter IF it hasn't been set yet.
	# Set it to www.perl.invalid if the parameter is invalid.
	if ( ( $sitename eq q{} ) or ( $sitename eq 'www.perl.invalid' ) ) {
		$sitename =
		  _STRING( $args->{'SITENAME'} )
		  ? $args->{'SITENAME'}
		  : 'www.perl.invalid';
	}

	return $self;
} ## end sub _init :

sub _dump : Dumper {
	my $obj = shift;

	my %field_data;
	$field_data{'trace'}    = $tracestate;
	$field_data{'sitename'} = $sitename;
	$field_data{'siteguid'} = $sitename_guid;

	return ( \%field_data );
}

sub _pump : Pumper {
	my ( $obj, $field_data ) = @_;

	$tracestate    = $field_data->{'trace'};
	$sitename      = $field_data->{'sitename'};
	$sitename_guid = $field_data->{'siteguid'};

	return;
}

#####################################################################
# Main Methods

########################################
# set_trace($tracelevel)
# Parameters:
#   $tracelevel: Number to set tracelevel to.
# Returns:
#   The object used.

sub set_trace {
	my ( $self, $tracelevel ) = @_;

	unless ( defined _NONNEGINT($tracelevel) ) {
		PDWiX::Parameter->throw(
			parameter => 'tracelevel',
			where     => '::Misc->set_trace'
		);
	}

	$tracestate = $tracelevel;

	return $self;
} ## end sub set_trace

########################################
# indent($spaces, $string)
# Parameters:
#   $spaces: Number of spaces to indent $string.
#   $string: String to indent.
# Returns:
#   Indented $string.

sub indent {
	my ( $self, $num, $string ) = @_;

	# Check parameters.
	unless ( _STRING($string) ) {
		PDWiX::Parameter->throw(
			parameter => 'string',
			where     => '::Misc->indent'
		);
	}
	unless ( defined _NONNEGINT($num) ) {
		PDWiX::Parameter->throw(
			parameter => 'num',
			where     => '::Misc->indent'
		);
	}

	# Indent string.
	my $spaces = q{ } x $num;
	my $answer = $spaces . $string;
	chomp $answer;
#<<<
		$answer =~ s{\n}                   # match a newline 
					{\n$spaces}gxms;       # and add spaces after it.
										   # (i.e. the beginning of the line.)
#>>>
	return $answer;
} ## end sub indent

########################################
# trace_line($tracelevel, $text, $no_display)
# Parameters:
#   $tracelevel: Level of trace to print at.
#   $text: Text to print if trace flag is >= $tracelevel.
#   $no_display: Don't add anything in [] (because this will go
#     through trace_line again.)
# Returns:
#   Object called upon (chainable).

sub trace_line {
	my ( $self, $tracelevel, $text, $no_display ) = @_;
	my $tracestate_status = $tracestate;

	# Check parameters and object state.
	unless ( defined _NONNEGINT($tracelevel) ) {
		PDWiX::Parameter->throw(
			parameter => 'tracelevel',
			where     => '::Misc->trace_line'
		);
	}
	unless ( defined _NONNEGINT($tracestate) ) {
		$tracestate_status = 0;
	}
	unless ( defined _STRING($text) ) {
		PDWiX::Parameter->throw(
			parameter => 'text',
			where     => '::Misc->trace_line'
		);
	}

	my $tracestate_test = 0;
	if ( $tracestate_status >= 100 ) {
		$tracestate_status -= 100;
		$tracestate_test = 1;
		require Test::More;
	}

	# Short-circuit.
	return $self if ( $tracestate_status < $tracelevel );

	$no_display = 0 unless defined $no_display;

	my $stack = Devel::StackTrace->new();

	my $string =
	  $self->_trace_line( $tracelevel, $text, $no_display,
		$tracestate_status, $stack->frame(1) );

	if ($tracestate_test) {
		Test::More::diag("$string");
	} elsif ( $tracelevel == 0 ) {
		## no critic 'RequireBracedFileHandleWithPrint'
		print STDERR "$string";
	} else {
		print "$string";
	}

	return $self;
} ## end sub trace_line

sub _trace_line : Private { ## no critic 'ProhibitManyArgs'
	my ( $self, $tracelevel, $text, $no_display, $tracestate_status,
		$frame ) = @_;

	if ( $tracestate_status >= $tracelevel ) {
		my $start = q{};

		if ( not $no_display ) {
			if ( $tracestate_status > 1 ) {
				$start = "[$tracelevel] ";
			}
			if ( ( $tracelevel > 2 ) or ( $tracestate_status > 4 ) ) {
				my $filespec = $frame->filename();
				my $line     = $frame->line();
				my ( undef, $path, $file ) = splitpath($filespec);
				my @dirs = splitdir($path);
				pop @dirs
				  if ( ( not defined $dirs[-1] )
					or ( $dirs[-1] eq q{} ) );
				$file = $dirs[-1] . q{\\} . $file
				  if (  ( defined $dirs[-2] )
					and ( $dirs[-2] eq 'WiX' ) );
				$start .= "[$file $line] ";
			} ## end if ( ( $tracelevel > 2...
#<<<
			$text =~ s{\n}              # Replace a newline
					  {\n$start}gxms;   ## with a newline and the start string.
			$text =~ s{\n\Q$start\E\z}  # Replace the newline and start
										# string at the end
					  {\n}gxms;         # with just the newline.
#>>>
		} ## end if ( not $no_display )

		return "$start$text";
	} ## end if ( $tracestate_status...

	return q{};
} ## end sub _trace_line :

########################################
# check_options($check, $options)
# Parameters:
#   $check: Option to check.
#   $options: List of options to check against.
# Returns:
#   1 if option is in list.

sub check_options : Restricted {
	my ( $self, $check, @options ) = @_;

	return ( any { $check eq $_ } @options ) ? 1 : 0;
}

########################################
# generate_guid($id)
# Parameters:
#   $check: Option to check.
#   $options: List of options to check against.
# Returns:
#   1 if $check is in $options, 0 otherwise.

sub generate_guid {
	my ( $self, $id ) = @_;

	$guidgen ||= Data::UUID->new();

	# Make our own namespace if needed...
	unless ( defined $sitename_guid ) {
		$sitename_guid =
		  $guidgen->create_from_name( Data::UUID::NameSpace_DNS,
			$sitename );
	}

	$self->trace_line( 5,
		    'Generated site GUID: '
		  . $guidgen->to_string($sitename_guid)
		  . "\n" );

	#... then use it to create a GUID out of the filename.
	return uc $guidgen->create_from_name_str( $sitename_guid, $id );

} ## end sub generate_guid

########################################
# DDS_freeze()
# Parameters:
#   None.
# Returns:
#   String that Data::Dump::Streamer uses in its dump.

sub DDS_freeze { ## no critic 'Capitalization'
	my $self = shift;
	my $str  = $self->dump(1);
	return ( qq{Object::InsideOut->pump("$str")}, undef, undef );
}

1;
