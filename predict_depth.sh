#!/bin/sh

#written 2-14-13
#if [ $# -eq 0 || $# -gt 3 ] # usage for no or more than 3 arguments                                                                                 
if [ $# -eq 0 -o $# -gt 4 ]
then
    echo "DESCRIPTION: Shell wrapper for predict_depth.r"
    echo 
    echo "USAGE: >predict_depth.sh <file_in> <file_out_prefix> <produce_pdf> <show>"
    echo   
    echo "     <file_in>:         NO DEFAULT: string, name of the input file" 
    echo "                        (two column, tab delimited, annotations then abundances" 
    echo "                        first row, first column (annotation header) is blank, first" 
    echo "                        row, scecond column can have a text header)"
    echo
    echo "     <file_out_prefix>: Default = \"depth_prediction\"  :string, prefix for output file(s)" 
    echo "                        *.txt (& *.pdf if produce_fig = 1)"
    echo
    echo "     <produce_pdf>:     Default = TRUE:   TRUE|FALSE, produce a pdf visulization of the output"
    echo
    echo "     <show>:            Default = 10: Integer, number of taxa to show in pdf"
    echo
    echo "EXAMPLES: predict_depth.sh test_data.txt "
    echo "          predict_depth.sh test_data.txt \"depth_prediction\" TRUE 20"
    echo
    echo "Annoying: to change argument 2, you have to supply 1 and 2 etc."
    echo "There are additional arguments in the function file (predict_depth.r)"
    echo
    exit 1                                                                                          # exit the script
fi

time_stamp=`date +%m-%d-%y_%X:%N`;  # create the time stamp month-day-year_hour:min:sec:nanosec

# grab arguments from prompt
file_in=$1
file_out_prefix=$2
produce_pdf=$3
show=$4

# set default values
: ${file_out_prefix:="depth_prediction"}
: ${produce_pdf:=1}
: ${show:=10}

echo "# shell generated script to run predict_depth.r" > shell.predict_depth.r.$time_stamp.r

echo "source(\"~/bin/predict_depth.r\")" >> shell.predict_depth.r.$time_stamp.r       

echo "predict_depth(abundance_matrix=\"$file_in\", input_type=\"file\", file_out_prefix = \"$file_out_prefix\", create_figure=$produce_pdf, num_to_show=$show)" >>  shell.predict_depth.r.$time_stamp.r

R --vanilla --slave <  shell.predict_depth.r.$time_stamp.r
rm  shell.predict_depth.r.$time_stamp.r
