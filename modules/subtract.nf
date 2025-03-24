process SUBTRACT_VARIANTS {
    tag "Subtracting wildtype variants from ${sample_id}"

    publishDir "${params.outdir}/subtracted", mode: 'copy'

    input:
    tuple val(sample_id), path(exp_vcf), path(exp_vcf_index)
    path wildtype_vcf
    path wildtype_vcf_index

    output:
    tuple val(sample_id), path("${sample_id}.subtracted.vcf.gz"), path("${sample_id}.subtracted.vcf.gz.tbi"), emit: subtracted_vcf

    script:
    """
    # Use bcftools isec to find variants unique to experimental sample (set difference)
    # -C means complement: output positions present only in the first file but not in the second
    bcftools isec -C -c none -p temp_dir ${exp_vcf} ${wildtype_vcf}

    # Compress and rename the output
    bcftools view -Oz -o ${sample_id}.subtracted.vcf.gz temp_dir/0000.vcf

    # Index the output VCF
    bcftools index --tbi ${sample_id}.subtracted.vcf.gz
    """
}