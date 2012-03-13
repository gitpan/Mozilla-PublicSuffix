package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use parent "Exporter";
use Carp;
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

our $VERSION = 'v0.1.2'; # VERSION
# ABSTRACT: Get a domain name's "public suffix" via Mozilla's Public Suffix List

sub public_suffix {
	my $domain = lc $_[0];
	index($domain, "xn--") != -1
		and $domain = eval { URI::_idna::decode($_[0]) };

	return _find_rule($domain, substr($domain, index($domain, ".") + 1 ) ) }

my %rules = qw();
sub _find_rule {
	my ($domain, $rhs) = @_;
	my $drule = $rules{$domain};
	return defined $drule       # Test for rule with full domain
		? $drule eq "w"
			? undef             # Wildcard rules need an extra level.
			: $domain
		: $domain eq $rhs
			? undef
			: do {
				my $rrule = $rules{$rhs};
				defined $rrule  # Test for rule with right-hand side
					? $rrule eq "w"
						? $domain
						: $rhs
					: _find_rule($rhs, substr($rhs, index($rhs, ".") + 1 ) ) } }

1;


1;
=encoding utf8

=head1 NAME

Mozilla::PublicSuffix - Get a domain name's public suffix via Mozilla's Public Suffix List

=head1 SYNOPSIS

	use feature "say";
	use Mozilla::PublicSuffix "public_suffix";

	say public_suffix("org");       # "org"
	say public_suffix("perl.org");  # "org"
	say public_suffix("perl.orc");  # undef
	say public_suffix("ga.gov.au"); # "gov.au"
	say public_suffix("ga.goo.au"); # undef

=head1 DESCRIPTION

This module provides a single function that returns the I<public suffix> of a
domain name by referencing a parsed copy of Mozilla's Public Suffix List
(official website at L<http://publicsuffix.org>).

A copy of the official list is bundled with the distribution. As the official
list continues to be updated, the bundled copy will inevitably fall out of date.
Therefore, if the bundled copy of found to be over thirty days old, this
distribution's installer provides the option to check for a new version of the
list and download/use it if one is found.

=head1 FUNCTIONS

=over

=item public_suffix($domain)

Exported on request. Simply returns the public suffix of the passed domain, or
C<undef> if a public suffix is not found.

=back

=head1 SEE ALSO

=over

=item L<Domain::PublicSuffix>

Similar to this module, with an object-oriented interface and somewhat
alternative interpretation of the rules Mozilla stipulates for determining a
public suffix.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT & LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License v. 3.0|http://gnu.org/licenses/lgpl.html>
and may be modified and/or redistributed under the same or any compatible
license.
