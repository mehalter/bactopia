// Import generic module functions
include { get_resources; initOptions; saveFiles } from '../../../lib/nf/functions'
RESOURCES   = get_resources(workflow.profile, params.max_memory, params.max_cpus)
options     = initOptions(params.options ? params.options : [:], 'scoary')
publish_dir = params.is_subworkflow ? "${params.outdir}/bactopia-tools/${params.wf}/${params.run_name}" : params.outdir
conda_tools = "bioconda::scoary=1.6.16"
conda_name  = conda_tools.replace("=", "-").replace(":", "-").replace(" ", "-")
conda_env   = file("${params.condadir}/${conda_name}").exists() ? "${params.condadir}/${conda_name}" : conda_tools

process SCOARY {
    tag "$meta.id"
    label 'process_low'
    publishDir "${publish_dir}", mode: params.publish_dir_mode, overwrite: params.force,
        saveAs: { filename -> saveFiles(filename:filename, opts:options) }

    conda (params.enable_conda ? conda_env : null)
    container "${ workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/scoary:1.6.16--py_2' :
        'quay.io/biocontainers/scoary:1.6.16--py_2' }"

    input:
    tuple val(meta), path(genes)
    path(traits)

    output:
    tuple val(meta), path("*.csv"), emit: csv
    path "*.{log,err}", emit: logs, optional: true
    path ".command.*", emit: nf_logs
    path "versions.yml", emit: versions

    script:
    def prefix = options.suffix ? "${options.suffix}" : "scoary"
    """
    scoary \\
        $options.args \\
        --no-time \\
        --threads $task.cpus \\
        --traits $traits \\
        --genes $genes

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scoary: \$( scoary --version 2>&1 )
    END_VERSIONS
    """
}
