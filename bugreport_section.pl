#!/usr/bin/perl -w
# Copyright (C) 2012 Texas Instruments
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Nishanth Menon <nm@ti.com>
#
# Description: 
# Parse the output of adb bugreport>bugreport.txt file to pick up specific
# sections of the log - beats having to search sections in tons of logs ;)

sub usage {
	printf "$0: parses the bugreport and presents sections as needed\n";
	printf "Usage:\n";
	printf "$0 bugreport_file_name [section1 section2 .. sectionN]\n";
	printf "if no sections are given, script prints the name of sections in bugreport_file_name\n";
	printf "if sections are given, script prints only the contents of those sections\n";
	printf "Example usage:\n";
	printf "$0 bugreport.txt \n";
	printf "\t-prints all available section names in the bugreport\n";
	printf "$0 bugreport.txt dmesg\n";
	printf "\t-prints only the dmesg section of the bugreport\n";
	printf "$0 bugreport.txt dmesg last_kmsg\n";
	printf "\t-prints only the dmesg and last_kmsg sections of the bugreport\n";
	die "Error: $_[0]";
}

if ( $#ARGV < 0 ) {
	usage "not enough arguments $#ARGV";
}
$LOGFILE = $ARGV[0];
shift;
@PRINT_SECTIONS=@ARGV;

open(LOGFILE) or usage("Could not open -$LOGFILE- bugreport file.");

$dump=0;
sub section_head {
	$section_name=$_[0];
	$section_orig_name=$_[0];
	$section_name =~ s/^--*//g;
	$section_name =~ s/--*$//g;
	$section_name =~ s/^\s\s*//g;
	$section_name =~ s/\s\s*$//g;
	chomp($section_name);
	$dump=0;
	if ( $section_name ne '') {
		if (@PRINT_SECTIONS) {
			foreach (@PRINT_SECTIONS) {
				if ($section_name =~ m/$_/) {
					printf "$section_orig_name\n";
					$dump=1;
				}
			}
		} else {
			printf "$section_name\n";
		}
	}
}
if (!@PRINT_SECTIONS) {
	printf "SECTIONS in $LOGFILE:\n";
}
foreach $line (<LOGFILE>) {
	chomp($line);
	if ($line =~ m/^------/) {
		section_head "$line";
	} else {
		printf "$line\n" if $dump eq 1;
	}
}
close(LOGFILE);
