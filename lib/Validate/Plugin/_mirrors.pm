package Validate::Plugin::_mirrors;
use strict;
use FindBin qw($Bin);
use YAML::Syck;

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
    $DB::single = 1;
    my $yref = LoadFile("/home/jfesler/falling-sky/source/sites/sites.yaml");

    my %return;
    $return{"mirrors"} = [];
    $return{"status"}  = "ok";
    
    foreach my $key ( keys %$yref ) {
        if ( $yref->{$key}->{mirror} ) {
            if ( !$yref->{$key}->{hide} ) {
                push( @{ $return{"mirrors"} }, $key );
            }
        }
    }


  @{ $return{"mirrors"} } = sort bydomain @{ $return{"mirrors"} } ;
  
    return \%return;
}

sub bydomain {
  my($aa) = join(".",reverse split(/\./,$a));
  my($bb) = join(".",reverse split(/\./,$b));
  return $aa cmp $bb;
}
    1;
