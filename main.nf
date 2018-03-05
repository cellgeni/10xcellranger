
params.sample = false

if( params.sample ){
    process imeta {
        output: imeta_data
        script:
        """
        kinit vk6 -k -t /nfs/users/nfs_v/vk6/irods.keytab
        imeta qu -z seq \\
            -d sample = ${sample} \\
            and target = 1 and manual_qc = 1 \\
        | grep cram \\
        | cut -d' ' -f 2
        """
    }
}

process iget {
    input: imeta_data
    script:
    """
    kinit vk6 -k -t /nfs/users/nfs_v/vk6/irods.keytab
    id_run="\$(echo ${imeta_data} | cut -d'_' -f 1)"
    iget \seq\\${id_run}\\${imeta_data}
    """
}
