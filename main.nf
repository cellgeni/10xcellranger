
// Pipeline version
version = '0.1'

params.sample = false

log.info "========================================="
log.info "         10X cellranger v${version}"
log.info "========================================="
def summary = [:]
summary['Sample']        = params.sample
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

if( params.sample ){
    process imeta {
        output: 
            stdout imeta_data
        script:
        """
        kinit vk6 -k -t /nfs/users/nfs_v/vk6/irods.keytab
        imeta qu -z seq \\
            -d sample = ${params.sample} \\
            and target = 1 and manual_qc = 1 \\
        | grep cram \\
        | cut -d' ' -f 2
        """
    }
}

process iget {
    input: 
        file cram_file from imeta_data.flatMap{ it.readLines() }
    script:
    """
    kinit vk6 -k -t /nfs/users/nfs_v/vk6/irods.keytab
    local id_run="\$(echo ${cram_file} | cut -d'_' -f 1)"
    iget \\seq\\${id_run}\\${cram_file}
    """
}
