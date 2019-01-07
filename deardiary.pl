use strict;
use warnings;

my $repo_url = 'http://github.com/geraintanderson/deardiary';
my %paths = (
  'config_file' => '.config',
  'simple_help' => 'help/simple-help.txt',
  'diaries'     => 'diaries'
);

if (!scalar @ARGV) {
  open (my $fh, '<', $paths{'simple_help'}) or die "Can't open simple-help.txt. Please raise a bug on $repo_url\n$!";
  print readline($fh);
  
} elsif ($ARGV[0] eq 'init') {
  # SET UP. Use OO to create a new diary?
  print "Creating a new diary...\n";
  print "What is your diary called?\n";
  my $name = <STDIN>;
  chomp($name);

  if (-e 'diaries/'.$name) {
    print "This diary already exists!\n";
    exit;
  } else {
    create_diary_entry($name, 'New diary created.');
  }

  print "Do you want to make this the active diary?\n";
  my $resp = <STDIN>;
  chomp($resp);
  while ($resp ne 'y' and $resp ne 'n') {
    print "Please type 'y' or 'n'\n";
    $resp = <STDIN>;
    chomp($resp);
  }
  if ($resp eq 'y') {
    update_config('active_diary', $name);
    print "$name is now the active diary\n";
  }

} elsif ($ARGV[0] eq 'use') {
  # Make the currently active diary equal to $ARGV[1]
  # XXX Check this diary actually exists before switching!
  update_config('active_diary', $ARGV[1]);

} elsif ($ARGV[0] eq 'list') {
  my $pm = "$paths{'diaries'}/*.psv";
  my @files = glob($pm);
  foreach my $file (@files) {
    my @fragments = split(/[\/\.]/, $file);
    print "$fragments[1]\n";
  }

} elsif ($ARGV[0] eq 'getconfig') {
  my @configs = get_config($ARGV[1]);
  if (scalar @configs) {
    foreach my $config (@configs) {
      print "$config\n";
    }
  } else {
    print "No matching configuration found.\n";
  }

} elsif ($ARGV[0] eq 'e' or $ARGV[0] eq 'entry') {
  # Write the diary to a file e.g. "deardiary e 'hello this is my frst entry'" or even just "deardiary e" then prompt user entry in a while looop for multi lines.
  print "Diary Entry\n";

} else {
  # Read a simple help file.
  print "Invalid command\n";
  open (my $fh, '<', $paths{'simple_help'}) or die "Can't open simple-help.txt. Please raise a bug on $repo_url\n$!";
  print readline($fh);
}

sub generate_timestamp {
  # Creates a timestamp in the format used by the diary.
  return localtime;
}

sub create_diary_entry {
  # Creates a new diary entry in the diary file.
  my $diary_name = shift;
  my $entry_text = shift;
  my $timestamp = generate_timestamp();

  open (my $fh, '>', './diaries/'.$diary_name.'.psv') or die "Can't open $diary_name.'psv' for writing: $!";
  my $message = $timestamp.'|'.$entry_text;
  print $fh $message;
  close($fh) or "Could not close the diary file: $!";
}

sub update_config {
  # Changes the value for the given key in the configuration file.
  my $config_key = shift;
  my $value = shift;
  my $updated = 0;

  # XXX Throw an error if $value is empty or if the key is empty or not a recognised key.

  # If the configuration file does not exist, it must be created.
  unless (-e $paths{'config_file'}) {
    open (my $fh_original, '>', $paths{'config_file'}) or die "Configuration file does not exist and cannot be created. $!";
  }

  # A temporary file is used for writing to. If this file already exists we must not update the config file as a write is in progress.
  if (-e $paths{'config_file'}.'.tmp') {
    print "The config file is already being edited. If you believe this is a mistake you should repair the .config file and delete .config.tmp from the Dear Diary's directory.\n";
    exit;
  }

  open (my $fh_original, '<', $paths{'config_file'}) or die "Cannot read config file.";
  open (my $fh_temp, '>', $paths{'config_file'}.'.tmp') or die "Cannot write to temporary config file.";

  # Substitute the line with the key for the new value.
  while (<$fh_original>) {
    if ($_ =~ /$config_key/) {
      print $fh_temp "$config_key $value\n";
      $updated = 1;
    } else {
      print $fh_temp $_;
    }
  }

  # If the configuration file did not contain the key, it would not have been added, so it should be appended to the file here.
  if (!$updated) {
    print "The key does not exist. Creating $config_key in the configuration file.\n";
    print $fh_temp "$config_key $value\n";
  }

  close $fh_temp;

  rename($paths{'config_file'}.'.tmp', $paths{'config_file'});
}

sub get_config {
  # Gets a value from the configuration file
  my $config_key = shift;
  my @configs = ();
  open (my $fh, '<', $paths{'config_file'}) or die "Cannot read config file.";
  while (my $line = <$fh>) {
    if ($config_key) {
      if ($line =~ /^$config_key /) {
        push(@configs, $line);
      }
    } else {
      push(@configs, $line);
    }
  }
  return @configs;
}

1;
