 #!/bin/bash
 
	# Author: Catherine Dawson
	# Date: 15/01/2023
	# Version: 1.0.0

	# Dependencies: 
	 # entrez direct ncbi https://www.ncbi.nlm.nih.gov/books/NBK179288/
	 # written with entrez-direct version 16.2
	 
	# Input: an ncbi blastn HitTable in txt format 

	## Usage : $ ./entrez_ncbi_gene_slice.sh ncbi-HitTable.txt <INT> <INT> email@domain.com output_dir_name

	# positional arguments
	 # $1 : text file containing hit info from ncbi-blast, assumes accession is the 2nd column and sequence start and stop are the 9th and 10th columns
	 # $2 : integer value ; number of bp upstream of target to download - if no additional sequence is required enter 0
	 # $3 : integer value ; number of bp downstream of target to download - if no additional sequence is required enter 0
	 # $4 : a valid email address on which you can be contacted in case the script interferes with ncbi databases
	 # $5 : output directory name
	 
	#NOTE: ncbi entrez requests that large queries (>200) be split up into chunks so as not to overwhelm the system. I tried to code this in but haven't yet managed to get it to work, therefore, use this script with caution and make sure to supply a valid email address so ncbi can get in contact if it's causing as issue. Otherwise, try to aim for downloading during non-peak times in the US (e.g. night time and weekends)


# Script start

# Renaming positional variables for ease of reading later code, also makes it easy to change positional variables

in_file="$1"
up="$2"
down="$3"
email="$4"
outfile="$5"

# make output directory 

 mkdir "$outfile"

# get the columns from the NCBI hit-table.txt file that have the accession, query_start and query_end, then remove the #info at the top of the file
# awk expressions subtract INT supplied at command line from the start position and add to the stop position of the target sequence, bash arguments need to be supplied to awk with the -v flag (once passed to awk drop the $ in front of variables), things in curly brackets are telling awk what to do (the action to take), the {FS=OFS="\t"} part is telling it that the input field separator (FS) and output field separator (OFS) are tabs, things outside curly brackets can be filtering arguments so that the following action in curly brackets is only applied to those values - this whole line is messy, need to get a better handle on usage of awk. 
# 2nd awk expression finds any negative values in the start position and converts them to 1


 cut -f 2,9,10 "$in_file" | grep -v "#" | awk -v up="$up" -v down="$down" ' BEGIN {FS=OFS="\t"} {$1 ; $2 = $2 - up ; $3 = $3 + down ; print} ' | awk '{FS=OFS="\t"} $2<0 {$2=1} 1' > seq_file.txt
 
# read in seq_file.txt, asign each column variable names as listed in order, perform entrez efetch request, save to output directory
 
 cat seq_file.txt | while IFS=$'\t' read accession qstart qstop
 do
	efetch -email "$email" -db nucleotide -id "$accession" -seq_start "$qstart" -seq_stop "$qstop" -format gb > ./"$outfile"/"$accession".gb
 done
 
# Test all files were downloaded
 # first part creates two files (in and out.txt) that only contain accession numbers and can be compared using the comm and sort commands
 # the -23 suppresses lines unique to the 2nd file and lines common to both files, only lines unique to the 1st file should be displayed 

 cut -f 1 seq_file.txt > in.txt
 ls "$outfile" | sed 's/.gb//g' > out.txt
 comm -23 <(sort in.txt) <(sort out.txt) > compare_in_out.txt
 
 #This if statement prints a message to the terminal if the compare_in_out.txt file is non-zero in size, otherwise deletes the file. 
 
 if [ -s compare_in_out.txt ] ; then
	printf "\n"
	printf "Not all files appear to have downloaded. Check compare_in_out.txt file.\n"
	printf "\n"
# can unhash this if you want, will try to download the missing files but good to investigate them first - can be duplicates.
#	printf "Will re-try downloading the missing files. \n"
	
#	grep -F -f compare_in_out.txt seq_file.txt > re-run.txt
#		cat re-run.txt | while IFS=$'\t' read accession qstart qstop
#		do
#			efetch -email "$email" -db nucleotide -id "$accession" -seq_start "$qstart" -seq_stop "$qstop" -format gb > ./"$outfile"/"$accession".gb
#		done
 
 else
	printf "\n"
	printf "All files appear to have been downloaded. :) \n"
	printf "\n"
	rm "compare_in_out.txt"
	rm "in.txt"
	rm "out.txt"
 fi
 
 