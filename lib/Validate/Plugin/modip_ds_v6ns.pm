package Validate::Plugin::modip_ds_v6ns;

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
   
   my $modip =  Validate::Plugin::MODIP->new($validate);
   my %return = $modip->check("ds.v6ns.$domain");
   
   unless ($return{"status"} eq "ok") {
   }
   
   return \%return;
}

1;
