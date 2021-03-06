package Validate::Plugin::modip_mtu1280;

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
   my %return = $modip->check("mtu1280.$domain");
   
   unless ($return{"status"} eq "ok") {
     $return{"notes"} = <<"EOF";

Please see https://github.com/falling-sky/source/wiki/InstallPMTUD

EOF
   }
   
   return \%return;
}

1;
