package Validate::Plugin::_all;

use strict;
use Validate::Plugin::_list;


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
   
   my $_list = new Validate::Plugin::_list;
   my $_list_ref = $_list->run;
   my @plugins = @{$_list_ref->{plugins}};
   
   @plugins = grep(!/^_/,@plugins);
   push(@plugins,"_config");
   
   my %return;
   foreach my $plugin (@plugins) {
     my ($o,$r);
     my $perl = <<"EOF";
     use Validate::Plugin::$plugin;
     \$o = Validate::Plugin::$plugin\->new(\$validate);
     \$r = \$o->run; 
EOF
     print $perl if (-t STDOUT);
     eval $perl;
     if ($@) {
        warn $@ if (-t STDERR);
       $return{$plugin}={error=>"failed to eval plugin"};
     }
     else {
       $return{$plugin}=$r;
     }
   }

   return { all => \%return };
}

1;
