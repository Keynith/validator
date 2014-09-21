package Validate::Plugin::dns_ds_v6ns;

use strict;
use Validate::Plugin::DNS;

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate} = shift;
    return $self;
}

sub run {
    my $self     = shift;
    my $validate = $self->{validate};
    my $config   = $validate->{config};

    my %config = %{$config};
    my $site   = $config{"site"}{"name"};
    my $domain = $config{"load"}{"domain"};

    my $dns = Validate::Plugin::DNS->new($validate);
    my $check = "ds.v6ns.$domain";

    my %return = $dns->check( "$check", "66.220.4.227", "A", "AAAA" );
    return \%return;
} ## end sub run

1;
