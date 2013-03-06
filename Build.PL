#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use utf8;
use open ":encoding(UTF-8)";
use HTTP::Tiny;
use Module::Build;
use Tie::File;

my $builder = Module::Build->new(
    dist_name => "Mozilla-PublicSuffix",
    license => "MIT",
    dist_abstract => q(Get a domain name's public suffix via Mozilla's Public Suffix List),
    dist_author => q"Richard Simões <rsimoes AT cpan DOT org>",
    dist_version_from => "lib/Mozilla/PublicSuffix.pm",
    # Prerequisites inserted by DistZilla:
      'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'HTTP::Tiny' => '0',
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'URI::_idna' => '0',
    'perl' => '5.008'
  },
);

my $dat_file = "effective_tld_names.dat";
my $get_new_list = $builder->y_n(
    "Check for a new version of the Public Suffix List?", "N"
);
if ($get_new_list) {
    my $http = HTTP::Tiny->new( timeout => 6 );
    my $list_uri = "http://mxr.mozilla.org"
                 . "/mozilla-central/source/netwerk/dns/$dat_file?raw=1";
    my %options = (
        headers => {
            "If-Modified-Since" => "Mon, 18 Feb 2013 20:02:07 GMT"
        }
    );
    my $response = $http->get( $list_uri, \%options );
    if ( $response->{status} == 200 ) {
        IO::File->new($dat_file, "w")->print( $response->{content} );
    }
}

# Divide rules from list into sets:
my $rules = join " ", map {
    s/\s//g;
    if    ( s/^!// )        { $_ => "e" }  # exception rule
    elsif ( s/^\*\.// )     { $_ => "w" }  # wildcard rule
    elsif ( /^[[:word:]]/ ) { $_ => "i" }  # identity rule
    else { () }
} IO::File->new($dat_file)->getlines;

tie my @pm, "Tie::File", "lib/Mozilla/PublicSuffix.pm";
for (@pm) { s/(my %rules = qw\()\)/$1$rules)/ and last }
untie @pm;

$builder->create_build_script;
