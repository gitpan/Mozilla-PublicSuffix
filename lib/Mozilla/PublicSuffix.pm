package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use parent "Exporter";
use Carp ();
use Net::LibIDN qw(idn_prep_name idn_to_ascii idn_to_unicode);
our @EXPORT_OK = qw(public_suffix);

our $VERSION = 'v0.1.0'; # VERSION
# ABSTRACT: Get a domain name's "public suffix" via Mozilla's Public Suffix List

my %rules = qw();
sub public_suffix {
	my ($domain) = @_;

	# Test domain well-formedness:
	eval { $domain = idn_to_unicode idn_to_ascii idn_prep_name $domain }
		or Carp::croak("Argument passed is not a well-formed domain name");

	my @labels = split /\./, $domain;
	return exists $rules{$labels[-1]}
		? do {
			# Gather matching rules:
			my @matches = sort {
				$b->{label} =~ tr/.// <=> $a->{label} =~ tr/.// }
				map {
					my $label = !$_ ? $domain : join ".", @labels[$_..$#labels];
					exists $rules{$label}
						? { type => $rules{$label}, label => $label }
						: () } 0 .. $#labels;

			# Choose prevailing rule and return suffix:
			my ($exc_rule) = grep { $_->{type} eq "e" } @matches;
			$exc_rule
				? $exc_rule->{label}
				: do {
					my ($type, $label) = @{$matches[0]}{qw(type label)};
					$type eq "w"
						and ($label) = $domain =~ /((?:[^.]+\.)$label)$/;
					$label ||= undef } }
		: undef }

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

Exported on request. Simply returns the public suffix of the passed argument,
or C<undef> if the public suffix is not found. Croaks if the passed argument
is not a well-formed domain name.

=back

=head1 SEE ALSO

=over

=item L<Domain::PublicSuffix>

An alternative to this module, with an object-oriented interface and slightly
difference interpretation of the rules Mozilla stipulates for determining a
public suffix.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License v. 3.0|http://gnu.org/licenses/lgpl.html>
and may be modified and/or redistributed under the same or any compatible
license.
