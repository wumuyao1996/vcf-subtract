process VCF_TO_GENOMEDIFF {
    tag "Converting VCF to genomediff: ${sample_id}"

    publishDir "${params.outdir}/genomediff", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)

    output:
    tuple val(sample_id), path("${sample_id}.gd"), emit: genomediff

    container 'jysgro/breseq:ub2304_py3114_R422_br0381_bt245_HTC'

    script:
    """
    # Decompress the VCF file using gzip (which should be available in most containers)
    gzip -dc ${vcf} > ${sample_id}.vcf

    # Use gdtools from breseq package to convert VCF to genomediff format
    gdtools VCF2GD -o ${sample_id}.gd ${sample_id}.vcf

    # Clean up the temporary uncompressed VCF
    rm ${sample_id}.vcf
    """
}