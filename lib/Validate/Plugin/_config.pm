package Validate::Plugin::_config;
use strict;
use FindBin qw($Bin);

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
   return { status=>"ok", expect=>"site config", found => "site config", config=>$config };
}

1;
