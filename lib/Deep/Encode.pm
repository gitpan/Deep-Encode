package Deep::Encode;

use 5.008008;
use strict;
use warnings;

require Exporter;
require Encode;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Deep::Encode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
	all => [ qw( 
		deep_utf8_decode
	   	deep_utf8_encode
	   	deep_from_to
	   	deep_from_to_
		deep_encode
		deep_decode
		) ], 
	expr=> [ qw( deep_str_process) ] );

our @EXPORT_OK = ( map @$_, map  $EXPORT_TAGS{$_} , 'all', 'expr' );

our @EXPORT =  ( map @$_, map  $EXPORT_TAGS{$_} , 'all');

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Deep::Encode', $VERSION);

1;
__END__

=head1 NAME

Deep::Encode - Perl extension for  coding and decoding strings in arrays and hashes ( reqursive )

=head1 SYNOPSIS

  use Deep::Encode;
  use Encode; # optional

  my $s = [ 1, 2, "string in cp1251 encoding" ];

  deep_from_to( $s, "cp1251", "utf8" ); # convert $s to [ [ 1, 2, "string in utf8 encoding" ];
  # Using Encode::from_to( $str,  , ,)

  deep_utf8_encode( $s ) ; # call utf8::encode on every string in $s

  deep_utf8_decode( $s ) ; # call utf8::decode on every string in $s

=head1 DESCRIPTION

	This module allow apply Encode::from_to, utf8::decode, utf8::encode function on every scalar in array or hash recursively

=head2 EXPORT

  deep_from_to( $s, $from, $to )
  deep_utf8_decode( $s )
  deep_utf8_encode( $s )


=head1 SEE ALSO

Encode, utf8

=head1 AUTHOR

A.G. Grishaev, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A.G. Grishaev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
