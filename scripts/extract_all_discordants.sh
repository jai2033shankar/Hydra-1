if [ -z $2 ]
then
	echo "usage:$0 <<hydra config file> <number of threads>"
	exit
fi

CONFIG=$1
PROCS=$2
COUNTER=0
INDEX=0


function add_next_bam {
    # if still jobs to do then add one
    if [[ $COUNTER -lt PROCS ]]
    then
	COUNTER=$(($COUNTER+1))
		extract_discordants ${bams_todo[$INDEX]} & 
		INDEX=$(($INDEX+1))
	else
		wait
		COUNTER=$(($COUNTER-$PROCS))
    fi
}

function add_final_bam {
    extract_discordants ${bams_todo[$INDEX]} ${dataset_names[$INDEX]}
    wait
}


function extract_discordants {
	samtools view -bF 0x040E -f 0x001 $1 > $1.disc.tmp.bam
	samtools sort -m 1000000000 -n $1.disc.tmp.bam $1.disc.tmp.bam.qrysort
	rm $1.disc.tmp.bam
	extract_discordants.py -i $1.disc.tmp.bam.qrysort.bam $2
}


dataset_names=($(cut -f 1 $CONFIG))
bams_todo=($(cut -f 2 $CONFIG)) # places output into an array

max_index=${#bams_todo[*]}-1
while [[ $INDEX -lt $max_index ]]
do
    add_next_bam
done
if [[ $INDEX -eq $max_index ]]
    then
    add_final_bam
fi

