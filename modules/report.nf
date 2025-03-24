process GENERATE_REPORT {
    tag "Generating report for ${sample_id}"

    publishDir "${params.outdir}/reports", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)

    output:
    path "${sample_id}_report.txt", emit: report

    script:
    """
    # Count the number of variants
    total_variants=\$(bcftools view -H ${vcf} | wc -l)

    # Extract variant types
    snps=\$(bcftools view -v snps -H ${vcf} | wc -l)
    indels=\$(bcftools view -v indels -H ${vcf} | wc -l)

    # Generate a summary report
    echo "Sample ID: ${sample_id}" > ${sample_id}_report.txt
    echo "Total unique variants: \$total_variants" >> ${sample_id}_report.txt
    echo "SNPs: \$snps" >> ${sample_id}_report.txt
    echo "Indels: \$indels" >> ${sample_id}_report.txt
    echo "VCF File: ${vcf}" >> ${sample_id}_report.txt
    echo "Genomediff File: ${params.outdir}/genomediff/${sample_id}.gd" >> ${sample_id}_report.txt
    echo "" >> ${sample_id}_report.txt

    # Add variant statistics by chromosome
    echo "Variant distribution by chromosome:" >> ${sample_id}_report.txt
    bcftools view -H ${vcf} | cut -f1 | sort | uniq -c | sort -rn >> ${sample_id}_report.txt
    """
}