process PREPARE_WILDTYPE {
    tag "Preparing wildtype VCF: ${vcf.fileName}"

    publishDir "${params.outdir}/prepared", mode: 'copy'

    input:
    path vcf

    output:
    tuple path(vcf), path("${vcf}.tbi"), emit: vcf_with_index

    script:
    """
    # Index the VCF file
    bcftools index --tbi ${vcf}

    # Validate VCF
    bcftools view --header-only ${vcf} > /dev/null || { echo "Error: Invalid VCF file ${vcf}"; exit 1; }
    """
}

process PREPARE_EXPERIMENTAL {
    tag "Preparing experimental VCF: ${sample_id}"

    publishDir "${params.outdir}/prepared", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf)

    output:
    tuple val(sample_id), path(vcf), path("${vcf}.tbi"), emit: vcf

    script:
    """
    # Index the VCF file
    bcftools index --tbi ${vcf}

    # Validate VCF
    bcftools view --header-only ${vcf} > /dev/null || { echo "Error: Invalid VCF file ${vcf}"; exit 1; }
    """
}