#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Benchmark "cmpthese";
use Mozilla::PublicSuffix "public_suffix";
use Domain::PublicSuffix;

my $dp = Domain::PublicSuffix->new;

cmpthese undef, {
	mps => sub { my $s = public_suffix("foo.gov.au") },
	dps => sub { $dp->get_root_domain("foo.gov.au"); my $s = $dp->suffix; } };
