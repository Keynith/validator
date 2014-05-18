#! /usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use FindBin qw($Bin);
use lib "$Bin/lib";
use Validate;

my $v = new Validate();
