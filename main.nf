
// Pipeline version
version = '0.1'

params.irods_username = 'vk6'
params.irods_keytab = '~/irods.keytab'

log.info "========================================="
log.info "         10X cellranger v${version}"
log.info "========================================="
def summary = [:]
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

sample_list = Channel.fromPath('samples.txt')

process irods {
    tag "${sample}"
    
    beforeScript "kinit ${params.irods_username} -k -t ${params.irods_keytab}"
    input: 
        val sample from sample_list.flatMap{ it.readLines() }
    output: 
        set val(sample), file('*.cram') into cram_files
    script:
    """
    imeta qu -z seq \\
        -d sample = ${sample} \\
        and target = 1 and manual_qc = 1 \\
    | sed ':a;N;\$!ba;s/----\\ncollection:/iget -K/g' \\
    | sed ':a;N;\$!ba;s/\\ndataObj: /\\//g' \\
    | bash
    """
}

/*
 * STEP 2 - cram to fastq conversion
 */

process cram2fastq10x {
    
    input:
        set val(sample), file(cram) from cram_files
    output:
        set val(sample), file('*.fastq.gz') into fastq_files

    script:
    """
    samtools fastq \\
        -N \\
        -@ ${task.cpus} \\
        -1 ${cram}_R1_001.fastq.gz \\
        -2 ${cram}_R2_001.fastq.gz \\
        --i1 ${cram}_I1_001.fastq.gz \\
        -n -i --index-format i8 \\
        -
    """
}

/*
 * STEP 3 - rename for cellranger
 */

process fastq10xRename {
    tag "${fastq.baseName}"

    input:
        set val(sample), file(fastq) from fastq_files
    output:
        set val(sample), file('*.fastq.gz') into fastq_files_10x

    script:
    """
    #rename the resulting FASTQ files to be cellranger input friendly
	#we're starting off with a file named like this: 22288_1#1.cram_I1_001.fastq.gz
	#and we want to turn it into SAMPLENAME_S##_L001_I1_001.fastq.gz
	#the ## in the S doesn't matter, we just want however many unique values for however many unique files
	#while staying consistent across the same block of I1/R1/R2

	#so let's just pick up the I1's as the block reps, and swap everything up to the .cram
	#to samplename_S*COUNT*_L001. that'll do. but we have to keep a count going manually

	count=1
	for file in *I1_001.fastq.gz
	do
		mv "\${file}" "\${file/*.cram/${sample}_S\$count_L001}"
		file=\$(sed 's/I1/R1/g' <<< \$file)
		mv "\${file}" "\${file/*.cram/${sample}_S\$count_L001}"
		file=\$(sed 's/R1/R2/g' <<< \$file)
		mv "\${file}" "\${file/*.cram/${sample}_S\$count_L001}"
		(( count++ ))
	done
    """
}
