package # Hide from PAUSE.
	XML::WiX3::Classes::Types;

use 5.008001;
use Regexp::Common 2.105;
use MooseX::Types -declare => [qw( Host Tracelevel IsTag)];
use MooseX::Types::Moose qw(Str Int Bool);

use version; our $VERSION = version->new('0.003')->numify;

subtype Host,
    as Str, 
    where { $_ =~ /\A$RE{net}{IPv4}\z/ or $_ =~ /\A$RE{net}{domain}{-nospace}\z/ },
    message { "$_ is not a valid hostname" };

subtype Tracelevel, 
	as Int,
	where { ($_ >= 0) && ($_ <= 5) },
	message { "The tracelevel you provided, $_, was not valid." };

subtype IsTag,
	as role_type 'XML::WiX3::Classes::Role::Tag';
	
subtype _YesNoType,
    as Str, 
    where { $_ =~ m{\A(?:yes|no)\z}i; },
    message { "$_ is not yes or no" };

subtype YesNoType,
    as _YesNoType,
    where { $_ =~ m{\A(?:yes|no)\z}; },
    message { "$_ is not yes or no" };
	
coerce YesNoType,
	from _YesNoType,
	via { lc $_ };
	
coerce YesNoType,
	from Bool|Int,
	via { $_ ? 'yes' ? 'no' };

#coerce YesNoType,
#	from Int,
#	via { $_ ? 'yes' ? 'no' };

subtype ComponentGuidType,
    as Str, 
    where { $_ =~ m{\A[{(]?[0-9A-F]{8}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{12}[})]?\z}; },
    message { "$_ is not a GUID" };

subtype PositiveInt, 
    as Int, 
    where { $_ > 0 },
    message { "Number is not larger than 0" };
  
subtype NonNegativeInt,
    as Int,
    where { $_ >= 0 },
    message { "Number is smaller than 0" };

# type coercion
coerce PositiveInt,
    from Int,
    via { 1 };

# type coercion
coerce NonNegativeInt,
    from Int,
    via { 1 };

1; # Magic true value required at end of module
