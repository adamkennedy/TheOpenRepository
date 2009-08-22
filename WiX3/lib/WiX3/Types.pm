package                                # Hide from PAUSE.
  WiX3::Types;

use 5.008001;
use MooseX::Types -declare => [ qw(
	  Host Tracelevel IsTag _YesNoType YesNoType ComponentGuidType PositiveInt
	  NonNegativeInt TraceConfig TraceObject
	  ) ];
use Regexp::Common 2.105;
use MooseX::Types::Moose qw( Str Int Bool HashRef );
use WiX3::Trace::Config ();

use version; our $VERSION = version->new('0.006')->numify;

subtype Host, as Str, where {
	$_ =~ /\A$RE{net}{IPv4}\z/msx
	  or $_ =~ /\A$RE{net}{domain}{-nospace}\z/msx;
}, message {
	"$_ is not a valid hostname";
};

subtype IsTag, as role_type 'WiX3::XML::Role::Tag';

subtype TraceConfig, as class_type 'WiX3::Trace::Config';

coerce TraceConfig, from HashRef,
  via { return WiX3::Trace::Config->new($_) };

subtype TraceObject, as class_type 'WiX3::Trace::Object';

subtype Tracelevel,
  as Int,
  where { ( $_ >= 0 ) && ( $_ <= 5 ) },
  message {"The tracelevel you provided, $_, was not valid."};

subtype _YesNoType,
  as Str,
  where { ( lc $_ eq 'yes' ) or ( lc $_ eq 'no' ); },
  message {"$_ is not yes or no"};

subtype YesNoType,
  as _YesNoType,
  where { ( $_ eq 'yes' ) or ( $_ eq 'no' ); },
  message {"$_ is not yes or no"};

coerce YesNoType, from _YesNoType, via { lc $_ };

coerce YesNoType, from Bool | Int, via { $_ ? 'yes' : 'no' };

subtype ComponentGuidType, as Str, where {
	$_ =~
m{\A[{(]?[0-9A-F]{8}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{12}[})]?\z}msx;
}, message {
	"$_ is not a GUID";
};

subtype PositiveInt,
  as Int,
  where { $_ > 0 },
  message {'Number is not larger than 0'};

subtype NonNegativeInt,
  as Int,
  where { $_ >= 0 },
  message {'Number is smaller than 0'};

# type coercion
coerce PositiveInt, from Int, via {1};

# type coercion
coerce NonNegativeInt, from Int, via {1};

1;                                     # Magic true value required at end of module
