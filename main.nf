#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Parameters
params.wildtype_vcfs = "wildtype/*.vcf.gz"
params.experimental_vcfs = "experimental/*.vcf.gz"
params.outdir = "results"
params.help = false

// Show help message
if (params.help) {
    log.info """
    ==================================================================
    VCF Subtraction Pipeline
    ==================================================================

    This pipeline subtracts wildtype variants from experimental VCF files
    and converts the resulting unique variants to genomediff format.

    Usage:
    nextflow run main.nf --wildtype_vcfs "wildtype/*.vcf.gz" --experimental_vcfs "experimental/*.vcf.gz"

    Parameters:
      --wildtype_vcfs      Pattern to match wildtype VCF files (default: ${params.wildtype_vcfs})
      --experimental_vcfs  Pattern to match experimental VCF files (default: ${params.experimental_vcfs})
      --outdir             Output directory (default: ${params.outdir})
      --help               Show this help message

    Outputs:
      - Subtracted VCF files (variants unique to experimental samples)
      - Genomediff format files for compatibility with tools like breseq
      - Summary reports for each sample
    ==================================================================
    """
    exit 0
}

// Log pipeline info
log.info """
==================================================================
VCF Subtraction Pipeline
==================================================================
wildtype VCFs     : ${params.wildtype_vcfs}
experimental VCFs : ${params.experimental_vcfs}
output directory  : ${params.outdir}
==================================================================
"""

// Include modules
include { PREPARE_WILDTYPE; PREPARE_EXPERIMENTAL } from './modules/prepare'
include { MERGE_WILDTYPE } from './modules/merge'
include { SUBTRACT_VARIANTS } from './modules/subtract'
include { VCF_TO_GENOMEDIFF } from './modules/convert'
include { GENERATE_REPORT } from './modules/report'

// Define input channels
Channel
    .fromPath(params.wildtype_vcfs)
    .ifEmpty { error "No wildtype VCF files found with pattern: ${params.wildtype_vcfs}" }
    .set { wildtype_vcf_ch }

Channel
    .fromPath(params.experimental_vcfs)
    .ifEmpty { error "No experimental VCF files found with pattern: ${params.experimental_vcfs}" }
    .map { file -> tuple(file.baseName, file) }
    .set { experimental_vcf_ch }

// Main workflow
workflow {
    // Prepare wildtype VCFs (index and validate)
    PREPARE_WILDTYPE(wildtype_vcf_ch)

    // Merge all wildtype VCFs into a single file
    // We collect() all tuples of (vcf, index) files
    MERGE_WILDTYPE(PREPARE_WILDTYPE.out.vcf_with_index.collect())

    // Prepare experimental VCFs
    PREPARE_EXPERIMENTAL(experimental_vcf_ch)

    // Subtract wildtype variants from each experimental VCF
    SUBTRACT_VARIANTS(
        PREPARE_EXPERIMENTAL.out.vcf,
        MERGE_WILDTYPE.out.merged_vcf,
        MERGE_WILDTYPE.out.merged_vcf_index
    )

    // Convert subtracted VCF files to genomediff format
    VCF_TO_GENOMEDIFF(SUBTRACT_VARIANTS.out.subtracted_vcf)

    // Generate reports
    GENERATE_REPORT(SUBTRACT_VARIANTS.out.subtracted_vcf)
}