package EFWConfig;
use strict;

my $efwBasePath = '/var/efw/';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $path = shift;
    my $self  = {
        _realConfigFile => undef,
        _configFile => undef,
        _configuration => ()
    };
    $self->{_vendorConfigFile} = undef;
    $self->{_vendorConfig} = ();
    $self->{_defaultConfigFile} = undef;
    $self->{_defaultConfig} = ();
    $self->{_config} = ();
    bless ($self, $class);
    $self->{_configFile} = $self->_translatePath($path);
    
    # If the default file exists, it's used to create the config
    # and the real settings file is applied later
	
    if(-e $self->{_defaultConfigFile}) {
        %{ $self->{defaultConfig} } = $self->_parseConfig($self->{_defaultConfigFile});
        foreach my $key (keys %{ $self->{defaultConfig} }) {
            $self->{_configuration}{$key} = $self->{defaultConfig}{$key};
        }
    }
    if(-e $self->{_vendorConfigFile}) {
        %{ $self->{vendorConfig} } = $self->_parseConfig($self->{_vendorConfigFile});
        foreach my $key (keys %{ $self->{vendorConfig} }) {
            $self->{_configuration}{$key} = $self->{vendorConfig}{$key};
        }
    }
    if(-e $self->{_configFile}) {
        %{ $self->{config} } = $self->_parseConfig($self->{_configFile});
        foreach my $key (keys %{ $self->{config} }) {
            $self->{_configuration}{$key} = $self->{config}{$key};
        }
    }
    
    return $self;
}
sub _translatePath {
    my ($self, $path) = @_;
    my @path_parts = split(/\./, $path);
    my $real_path = $efwBasePath . join('/', @path_parts);
    my $settings_file = pop(@path_parts);
    my $real_path_default = $efwBasePath . join('/', @path_parts) . '/' . 'default/' . $settings_file;
    my $real_path_vendor = $efwBasePath . join('/', @path_parts) . '/' . 'vendor/' . $settings_file;

    
    $self->{'_realConfigFile'} = $real_path;
    if(-e "$real_path_default") {
        my $tmp_path = $real_path_default;
        $tmp_path =~ s/\/default//;
        $self->{'_realConfigFile'} = $tmp_path;
        $self->{_defaultConfigFile} = $real_path_default;
    }
    if(-e "$real_path_vendor") {
        my $tmp_path = $real_path_vendor;
        $tmp_path =~ s/\/vendor//;
        $self->{'_realConfigFile'} = $tmp_path;
        $self->{_vendorConfigFile} = $real_path_vendor;
    }
    return $real_path;
    return die("Config file $real_path_default or $real_path_vendor or $real_path not found!");
}    

sub _parseConfig {
    my ($self, $file) = @_;
    my $line;
    my %conf;
    my $var;
    my $val;
    open(IN, $file) or die();
    while ($line = <IN>) {
        next if ($line =~ /^\s*$/ or $line =~ /^\s*#/);
        chomp;
        ($var, $val) = split /=/, $line, 2;
        if ($var) {
            $val =~ s/^\'//g;
            $val =~ s/\'$//g;
            
            # Untaint variables read from hash
            $var =~ /([A-Za-z0-9_-]*)/;        $var = $1;
            $val =~ /([\w\W]*)/; $val = $1;
            chomp($val);
            $conf{$var} = $val;
        }
    }
    close(IN);
    return %conf;
}

sub get {
    my ($self, $key) = @_;
    if(!exists $self->{_configuration}{uc($key)}) { return undef; }
    return $self->{_configuration}{uc($key)};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{'_configuration'}{uc($key)} = $value;
}
sub dump {
    my $self = shift;
    my @lines = ();
    my %tmp_config = $self->{'_configuration'};
    foreach my $key (keys %{%$self->{_configuration}}) {
        push(@lines, $key . '=' . $self->{_configuration}{$key});
    }
    return join("\n", @lines);
}
sub settings {
    my $self = shift;
    return %{%$self->{_configuration}};
}
sub save {
    my $self = shift;
    my $filename = $self->{'_realConfigFile'};
    
    if (-e $filename) {
        system("cp -f $filename ${filename}.old &>/dev/null");
    }
    open(FILE, ">$filename") or die "Unable to write file $filename";
    flock FILE, 2;
    print FILE $self->dump() . "\n";
    close FILE;
}