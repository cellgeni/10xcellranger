
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
    beforeScript "set +u; source activate rnaseq1.5"
    afterScript "set +u; source deactivate"
    input: 
        val sample from sample_list.flatMap{ it.readLines() }
    output: 
        file "${sample}.cram" into read_files_cram
    script:
    """
    kinit ${params.irods_username} -k -t ${params.irods_keytab}
    imeta qu -z seq \\
        -d sample = $sample \\
        and target = 1 and manual_qc = 1 \\
    | sed ':a;N;\$!ba;s/----\ncollection:/iget -K/g' \\
    | sed ':a;N;\$!ba;s/\ndataObj: /\\//g' \\
    | bash
    samtools merge -f - *.cram > ${sample}.cram
    """
}
