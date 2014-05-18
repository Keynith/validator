package Validate::Plugin::modip_literal_ipv6;

use strict;
use Validate::Plugin::MODIP;


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
   my $ipv6 = $config{"load"}{"ipv6"};
   
   my $modip =  Validate::Plugin::MODIP->new($validate);
   my %return = $modip->check($ipv6);
   
   unless ($return{"status"} eq "ok") {
   }
   
   return \%return;
}

1;
