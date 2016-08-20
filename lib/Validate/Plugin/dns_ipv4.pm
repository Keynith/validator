package Validate::Plugin::dns_ipv4;

use strict;
use Validate::Plugin::DNS;

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate}=shift;
    return $self;
}

sub run {
   my $self = shift;
   my $validate = $self->{validate};
   my $config = $validate->{config};
   
   my %config = %{ $config};
   my $site   = $config{"site"}{"name"};
   my $domain = $config{"load"}{"domain"};
   
   my $dns =  Validate::Plugin::DNS->new($validate);
   my %return = $dns->check("ipv4.$domain","2001:470:1:18:1000::46","A");
   
   return \%return;
}

1;
