package # Hide from PAUSE.
	XML::WiX3::Classes::Types;

use 5.008001;
use Regexp::Common 2.105;
use MooseX::Types -declare => [qw( Host Tracelevel IsTag)];
use MooseX::Types::Moose qw(Str Int);

use version; our $VERSION = version->new('0.003')->numify;

subtype Host,
    as Str, 
    where { $_ =~ /\A$RE{net}{IPv4}\z/ or $_ =~ /\A$RE{net}{domain}{-nospace}\z/ },
    message { "$_ is not a valid hostname" };

subtype Tracelevel, 
	as Int,
	where { ($_ >= 0) && ($_ <= 5) },
	message { "The tracelevel you provided, $_, was not valid." };

#subtype IsTag,
#	as Object,
#	where { $_->meta->does_role('XML::WiX3::Classes::Role::Tag') },
#	message { "Something not a Tag was passed in." };

subtype IsTag,
	as role_type 'XML::WiX3::Classes::Role::Tag';

	
# subtype ArrayOfTags,
#	as ArrayRef[IsTag];
	
1; # Magic true value required at end of module
