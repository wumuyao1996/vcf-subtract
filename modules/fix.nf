process FIX_VCF_SEQIDS {
    tag "Fixing sequence IDs: ${sample_id}"

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)

    output:
    tuple val(sample_id), path("${sample_id}.fixed.vcf.gz"), path("${sample_id}.fixed.vcf.gz.tbi"), emit: fixed_vcf

    container 'quay.io/biocontainers/bcftools:1.15--h0ea216a_2'

    script:
    """
    # Decompress VCF
    bcftools view -h ${vcf} > header.txt
    bcftools view -H ${vcf} > body.txt

    # Remove decimals from sequence IDs in the header
    sed -E 's/contig=<ID=([^.]*)\\.([^,]*),/contig=<ID=\\1,/g' header.txt > fixed_header.txt

    # Remove decimals from sequence IDs in the body (first column)
    awk '{split(\$1,a,"."); \$1=a[1]; print}' OFS="\\t" body.txt > fixed_body.txt

    # Combine and compress
    cat fixed_header.txt fixed_body.txt | bcftools view -Oz -o ${sample_id}.fixed.vcf.gz

    # Index the fixed VCF
    bcftools index --tbi ${sample_id}.fixed.vcf.gz
    """
}

process FIX_WILDTYPE_VCF_SEQIDS {
    tag "Fixing sequence IDs in wildtype: ${vcf.fileName}"

    input:
    path vcf

    output:
    tuple path("fixed.${vcf.fileName}"), path("fixed.${vcf.fileName}.tbi"), emit: fixed_vcf_with_index

    container 'quay.io/biocontainers/bcftools:1.15--h0ea216a_2'

    script:
    """
    # Decompress VCF
    bcftools view -h ${vcf} > header.txt
    bcftools view -H ${vcf} > body.txt

    # Remove decimals from sequence IDs in the header
    sed -E 's/contig=<ID=([^.]*)\\.([^,]*),/contig=<ID=\\1,/g' header.txt > fixed_header.txt

    # Remove decimals from sequence IDs in the body (first column)
    awk '{split(\$1,a,"."); \$1=a[1]; print}' OFS="\\t" body.txt > fixed_body.txt

    # Combine and compress
    cat fixed_header.txt fixed_body.txt | bcftools view -Oz -o fixed.${vcf.fileName}

    # Index the fixed VCF
    bcftools index --tbi fixed.${vcf.fileName}
    """
}