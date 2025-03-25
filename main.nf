#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Parameters
params.wildtype_vcfs = "wildtype/*.vcf.gz"
params.experimental_vcfs = "experimental/*.vcf.gz"
params.reference = null  // Optional reference file (GenBank or GFF)
params.html = true  // Generate HTML reports (can be disabled)
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
      --reference          Optional reference file (GenBank or GFF) for annotating variants (default: none)
      --html               Generate HTML visualizations of variants (default: ${params.html})
      --outdir             Output directory (default: ${params.outdir})
      --help               Show this help message

    Outputs:
      - Subtracted VCF files (variants unique to experimental samples)
      - Genomediff format files for compatibility with tools like breseq
      - HTML visualizations of variants (if enabled)
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
reference file    : ${params.reference ?: 'Not provided'}
generate HTML     : ${params.html}
output directory  : ${params.outdir}
==================================================================
"""

// Include modules
include { PREPARE_WILDTYPE; PREPARE_EXPERIMENTAL } from './modules/prepare'
include { FIX_VCF_SEQIDS; FIX_WILDTYPE_VCF_SEQIDS } from './modules/fix'
include { MERGE_WILDTYPE } from './modules/merge'
include { SUBTRACT_VARIANTS } from './modules/subtract'
include { VCF_TO_GENOMEDIFF } from './modules/convert'
include { GD_TO_HTML } from './modules/html'
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

// Create a channel for the reference file (if provided)
reference_ch = params.reference ? Channel.fromPath(params.reference) : Channel.value("NO_FILE")

// Main workflow
workflow {
    // Prepare wildtype VCFs (index and validate)
    PREPARE_WILDTYPE(wildtype_vcf_ch)

    // Fix sequence IDs in wildtype VCFs (remove decimals)
    FIX_WILDTYPE_VCF_SEQIDS(PREPARE_WILDTYPE.out.vcf)

    // Merge all wildtype VCFs into a single file
    // We collect() all tuples of (vcf, index) files
    MERGE_WILDTYPE(FIX_WILDTYPE_VCF_SEQIDS.out.fixed_vcf_with_index.collect())

    // Prepare experimental VCFs
    PREPARE_EXPERIMENTAL(experimental_vcf_ch)

    // Fix sequence IDs in experimental VCFs (remove decimals)
    FIX_VCF_SEQIDS(PREPARE_EXPERIMENTAL.out.vcf)

    // Subtract wildtype variants from each experimental VCF
    SUBTRACT_VARIANTS(
        FIX_VCF_SEQIDS.out.fixed_vcf,
        MERGE_WILDTYPE.out.merged_vcf,
        MERGE_WILDTYPE.out.merged_vcf_index
    )

    // Convert subtracted VCF files to genomediff format
    // Process each sample with the same reference file (or placeholder)
    VCF_TO_GENOMEDIFF(
        SUBTRACT_VARIANTS.out.subtracted_vcf,
        reference_ch.collect()  // Use collect() to make sure all samples see the same reference
    )

    // Generate HTML visualizations if enabled
    if (params.html) {
        GD_TO_HTML(
            VCF_TO_GENOMEDIFF.out.genomediff,
            reference_ch.collect()
        )
    }

    // Generate reports
    GENERATE_REPORT(SUBTRACT_VARIANTS.out.subtracted_vcf)
}