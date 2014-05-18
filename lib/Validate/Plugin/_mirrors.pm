package Validate::Plugin::_mirrors;
use strict;
use FindBin qw($Bin);

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

    my $buffer = $validate->load_file("/home/jfesler/falling-sky/source/js/mirrors.js");
    $buffer =~ s#/[*].*?[*]/##sg;
    my $ref = $validate->parse_config( $buffer, "GIGO.mirrors" );

    my %return;
    $return{"mirrors"} = [];
    $return{"status"}  = "ok";

    foreach my $href (@$ref) {
        if ( !$href->{hide} ) {
            push( @{ $return{"mirrors"} }, $href->{site} );
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
