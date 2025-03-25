process VCF_TO_GENOMEDIFF {
    tag "Converting VCF to genomediff: ${sample_id}"

    publishDir "${params.outdir}/genomediff", mode: 'copy', pattern: "*.gd"
    publishDir "${params.outdir}/status", mode: 'copy', pattern: "*.txt"

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)
    path(reference)

    output:
    tuple val(sample_id), path("${sample_id}.gd"), emit: genomediff
    path "${sample_id}_annotation_status.txt", emit: status

    container 'jysgro/breseq:ub2304_py3114_R422_br0381_bt245_HTC'

    script:
    def reference_arg = reference.name != 'NO_FILE' ? "REFERENCE_PROVIDED" : "NO_REFERENCE"

    if (reference_arg == "REFERENCE_PROVIDED")
        """
        # Decompress the VCF file using gzip
        gzip -dc ${vcf} > ${sample_id}.vcf

        # Use gdtools from breseq package to convert VCF to genomediff format
        gdtools VCF2GD -o ${sample_id}.gd ${sample_id}.vcf

        # Try to annotate with reference, but fallback if there's a sequence ID mismatch
        if gdtools ANNOTATE -r ${reference} ${sample_id}.gd -o ${sample_id}.annotated.gd -f GD 2> annotation_errors.log; then
            # Annotation successful
            mv ${sample_id}.annotated.gd ${sample_id}.gd
            echo "INFO: Successfully annotated variants with reference" > ${sample_id}_annotation_status.txt
        else
            # Annotation failed, use unannotated files
            echo "WARNING: Failed to annotate some or all variants with reference" > ${sample_id}_annotation_status.txt
            echo "Reason:" >> ${sample_id}_annotation_status.txt
            cat annotation_errors.log >> ${sample_id}_annotation_status.txt
        fi

        # Clean up temporary files
        rm ${sample_id}.vcf annotation_errors.log
        """
    else
        """
        # Decompress the VCF file using gzip
        gzip -dc ${vcf} > ${sample_id}.vcf

        # Use gdtools from breseq package to convert VCF to genomediff format
        gdtools VCF2GD -o ${sample_id}.gd ${sample_id}.vcf

        # Create status file
        echo "INFO: Converted VCF to genomediff format without annotation (no reference provided)" > ${sample_id}_annotation_status.txt

        # Clean up the temporary uncompressed VCF
        rm ${sample_id}.vcf
        """
}