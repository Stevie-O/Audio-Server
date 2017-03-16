#!/usr/bin/perl -s
use strict;
use warnings;
use File::ChangeNotify;
use File::Find;

our $test;
our $cycles; $cycles //= 1_000_000;

# returns an arrayref containing every directory we'll ever want to play
sub get_disc_list;

# get_song_list($path) gets the list of song files in $path
sub get_song_list;

# I use cvlc for audio streaming.
# The root path we will be following is /music
# since that is where the drive will be mounted.
my $vlc = "/usr/bin/cvlc";
my $root = "/music";

# Default regex patterns I use in this script
my $sng_pattern = qr/\.(mp3|m4a|wav|flac)$/;

sub play_selection;

# read the system to find out what files are there
my $disc_list = get_disc_list();

# set up a filesystem watcher so we find out if someone adds/removes files
my $watcher =
        File::ChangeNotify->instantiate_watcher(
                directories => [$root],
        );

# Main body to repeat forever until the process is killed
while(1){
	if ($watcher->new_events) {
		print "Filesystem change detected. Re-scanning...\n";
		$disc_list = get_disc_list();
	}
	
	my $path = $disc_list->[int rand @$disc_list];

	if($path ne $last_played && (@songs = get_song_list($path)) {
		# Print out which Artist and which Album are queued up.
		print "\nPlaying $path\n";

		my $count = 1;
		foreach(@songs){
			# Make a pretty output to tell which song
			# is currently playing.
			my $basename = $_; $basename =~ s/$sng_pattern//;
			my $cur_status = " - Playing $basename  (" . 
			sprintf("%03d", $count) . "/" . 
			sprintf("%03d", scalar(@songs)) . ")\n";
			print $cur_status;
			
			play_selection("$path/$_");
		
			$count++;
		}
	}
    # Save the last path so we dont play it again and reset
    # the current path.
    $last_played = $path;
}

sub play_selection {
	my $selection = shift;
	if ($test) {
		open(my $tmp, '>>', 'audio_server_selections.log');
		print $tmp $selection, "\n";
		exit unless --$cycles;
	} else {
			system($vlc, "--no-video", "--play-and-exit", "-q", $selection);
	}
}

sub get_song_list {
	my $path = shift;
	my @songs;
	find(sub {
		if (-d $_) { $File::Find::prune = 1; return; }
		if (-f $_ && $_ =~ $sng_pattern) { 
			push @songs, $_;
		}
	}, $path);
	return sort @songs;
}

sub get_disc_list {
	my @discs;
	my %discs;
	
	# find all directories with playable files
	find(sub {
		if (-f $_ && $_ =~ $sng_pattern) {
			my $dir = $File::Find::dir;
			unless ($discs{$dir}) {
				push @discs, $dir;
				$discs{$dir} = 1;
			}
		}
	}, $root);
	
	@discs = sort @discs;
	
	print "Completed filesystem scan. Found ", 0+@discs, " folders.\n";
	
	return \@discs;
}