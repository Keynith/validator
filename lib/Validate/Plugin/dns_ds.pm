package Validate::Plugin::dns_ds;

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
   my %return = $dns->check("ds.$domain","66.220.4.227","A","AAAA");
   
   return \%return;
}

1;
