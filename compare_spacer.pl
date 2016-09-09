#!/usr/bin/perl

#########################################################################################################
# Compare fasta files with spacers sequences and find out which spacers are the same
# You may distribute this script under the same terms as perl itself
# Francislon Silva <francislon at cpqrr dot fiocruz dot br>
# Biosystems Informatics and Genomics Fiocruz-MG - September 9th, 2016
#########################################################################################################
use strict;
use Getopt::Long;


#########################################################################################################
# Declaring variables
#########################################################################################################
my @array_files = (); # array with fasta files to compare provided by the user
my $dir; # when the user provides a directory as an input to the script we store the value in this variable
my $is_directory = 0; # a flag indicating if the file passed by the user is a regular file or is a directory

my %hash_spacers = 0; # Hash to structure in memory all sequences for all files.
					  # The key of the hash will be the name of the file and the value will be an array with the
					  # spacers.

my $help; # a flag indicating if the user wants the help of the script

#########################################################################################################
# Receiving input parameters by the user
#########################################################################################################
GetOptions(
	'f=s'    => \@array_files,
	'help|?' => \$help
);
$| = 1; # forces a flush right away and after every write or print on the currently selected output channel

#########################################################################################################
# Calling the main function
#########################################################################################################
main();

#########################################################################################################
# The main function of the script
#########################################################################################################
sub main {
	validate_parameters(); # This function validates if the parameters provided by the user are correct
	read_spacers(); # This function reads all files and stores the sequences in the hash %hash_spacers
	compare_spacers(); # This function compares the spacers and prints out in the standard output the spacers which are the same

}

#########################################################################################################
# The function to read the spacers from fasta files and store the sequences in the hash %hash_spacers
#########################################################################################################
sub read_spacers{
	if($is_directory){
		opendir my $dh, $array_files[0] or die "Could not open the directory for reading: $!\n";
		@array_files = grep {$_ ne '.' and $_ ne '..'} readdir $dh;
	}

	foreach my $file (@array_files) {
		my @spacers = ();
		$hash_spacers{$file} = \@spacers;
		open(IN, $dir."/".$file);
		while(<IN>){
			chomp;
			unless(/^>/){
				push(@spacers, $_);
			}
		}
		close(IN);
	}
}

#########################################################################################################
# The function to compare the spacers and print in the standard output the spacers which are the same
#########################################################################################################
sub compare_spacers{
	for(my $i = 0; $i < scalar @array_files; $i++){
		my $file_i = $array_files[$i];
		my $spacers_file_i = $hash_spacers{$file_i};
		for(my $j = $i+1; $j < scalar @array_files; $j++){
			my $file_j = $array_files[$j];
			my $spacers_file_j = $hash_spacers{$file_j};
			print "$file_i vs $file_j\n";
			for(my $x = 0; $x < scalar @$spacers_file_i; $x++){
				my $spacer_i = $spacers_file_i->[$x];
				for(my $y = 0; $y < scalar @$spacers_file_j; $y++){
					my $spacer_j = $spacers_file_j->[$y];
					if($spacer_i eq $spacer_j){
						print sprintf("[%d][%d]\t", $x+1, $y+1);
						print $spacer_i."\n";
					}else{
						my $revcomp1 = reverse($spacer_i);
						$revcomp1 =~ tr/ACGTacgt/TGCAtgca/;
						if($revcomp1 eq $spacer_j){
							print sprintf("rev[%d][%d]\t", $x+1, $y+1);
							print $revcomp1."\n";
						}else{
							my $revcomp2 = reverse($spacer_j);
							$revcomp2 =~ tr/ACGTacgt/TGCAtgca/;
							if($spacer_i eq $revcomp2){
								print sprintf("[%d]rev[%d]\t", $x+1, $y+1);
								print $revcomp2."\n";
							}
						}
					}
				}
			}
		}

	}

}

#########################################################################################################
# The function to validate the parameters provided by the user
#########################################################################################################
sub validate_parameters {
	my $allExists  = 1;
	my $fileExists = 1;

	if ( defined $help ) {
		print usage();
		exit 0;
	}
	my $num_files = scalar @array_files;
	unless ( $num_files > 0 ) {
		$allExists = 0;
	}

	if ($allExists) {
		if($num_files == 1){
			unless(-e $array_files[0]){
				print STDERR $array_files[0]." doesn't exists.\n";
				$fileExists = 0;
			}else{
				if(-d $array_files[0]){
					$dir = $array_files[0];
					$is_directory = 1;
				}
			}
		}else{
			for(my $i = 0; $i < $num_files; $i++){
				unless(-f $array_files[$i]){
					print STDERR $array_files[$i]." doesn't exists.\n";
					$fileExists = 0;
				}
			}
		}
		
	}
	else {
		print usage();
		exit 0;
	}

	unless ($fileExists) {
		print STDERR "Program execution aborted.\n";
		exit 0;
	}

}

#########################################################################################################
# The function to show the usage of the script
#########################################################################################################
sub usage {
	my $usage = <<FOO;
	
Usage:
	perl $0 (-f file1 -f file2 ... -f fileN | -f directory_with_files)
FOO
	return $usage;

}
