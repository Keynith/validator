package Validate::Plugin::modip_literal_ipv4;

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
   my $ipv4 = $config{"load"}{"ipv4"};
   
   my $modip =  Validate::Plugin::MODIP->new($validate);
   my %return = $modip->check($ipv4);
   
   unless ($return{"status"} eq "ok") {
   }
   
   return \%return;
}

1;
