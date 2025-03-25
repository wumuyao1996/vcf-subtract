process GD_TO_HTML {
    tag "Creating HTML visualization: ${sample_id}"

    publishDir "${params.outdir}/html", mode: 'copy'

    input:
    tuple val(sample_id), path(gd_file)
    path(reference)

    output:
    tuple val(sample_id), path("${sample_id}.html"), emit: html_report

    container 'jysgro/breseq:ub2304_py3114_R422_br0381_bt245_HTC'

    script:
    def reference_arg = reference.name != 'NO_FILE' ? "REFERENCE_PROVIDED" : "NO_REFERENCE"

    if (reference_arg == "REFERENCE_PROVIDED")
        """
        # Generate HTML report with annotation
        gdtools ANNOTATE -r ${reference} ${gd_file} -o ${sample_id}.html -f HTML
        """
    else
        """
        # Create a simple HTML visualization without reference
        echo "<html><head><title>${sample_id} Variants</title></head><body>" > ${sample_id}.html
        echo "<h1>${sample_id} Variants</h1>" >> ${sample_id}.html
        echo "<p>No reference provided for annotation. Showing raw genomediff content.</p>" >> ${sample_id}.html
        echo "<pre>" >> ${sample_id}.html
        cat ${gd_file} >> ${sample_id}.html
        echo "</pre></body></html>" >> ${sample_id}.html
        """
}