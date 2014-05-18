package Validate::Plugin::_list;
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
$DB::single=1;   
  my @glob = glob("$Bin/lib/Validate/*/*.pm");
  my @plugins;
  foreach (@glob) {
    if (m#/([^/]+).pm$#) {
       push(@plugins,$1);
    }
  }
  @plugins = grep(/^[a-z]/,@plugins);  # Hide _* and anything starting with uppercase
   return { status=>"ok", plugins => \@plugins, expect=>"test plugins", found => "test plugins" };
}

1;
