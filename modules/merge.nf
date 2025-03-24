process MERGE_WILDTYPE {
    tag "Merging wildtype VCF files"

    publishDir "${params.outdir}/merged", mode: 'copy'

    input:
    path vcfs_and_indices

    output:
    path "merged_wildtype.vcf.gz", emit: merged_vcf
    path "merged_wildtype.vcf.gz.tbi", emit: merged_vcf_index

    script:
    // Extract VCF files (every other file is an index)
    """
    # Create list of VCF files (excluding .tbi files)
    find . -name "*.vcf.gz" ! -name "*.tbi" > vcf_list.txt

    # Merge all wildtype VCFs into a single file
    bcftools merge --file-list vcf_list.txt -Oz -o merged_wildtype.vcf.gz

    # Index the merged VCF file
    bcftools index --tbi merged_wildtype.vcf.gz
    """
}