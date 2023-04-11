rule get_genome:
    output:
        genome=expand(
            "resources/{species}.{build}.{release}.fasta",
            species=config["reference"]["species"],
            build=config["reference"]["build"],
            release=config["reference"]["release"],
        ),
    log:
        "logs/get-genome.log",
    params:
        species=config["reference"]["species"],
        datatype="dna",
        build=config["reference"]["build"],
        release=config["reference"]["release"],
    cache: "omit-software"  # save space and time with between workflow caching (see docs)
    wrapper:
        "v1.25.0/bio/reference/ensembl-sequence"


rule genome_faidx:
    input:
        rules.get_genome.output.genome,
    output:
        index=expand(
            "{genome}.fai",
            genome=rules.get_genome.output.genome,
        ),
    log:
        "logs/genome-faidx.log",
    cache: True
    wrapper:
        "v1.25.0/bio/samtools/faidx"


rule minimap2_index:
    input:
        target=rules.get_genome.output.genome,
    output:
        index=expand(
            "resources/{species}.{build}.{release}.mmi",
            species=config["reference"]["species"],
            build=config["reference"]["build"],
            release=config["reference"]["release"],
        ),
    log:
        "logs/minimap2_index/genome.log",
    benchmark:
        "benchmarks/minimap2_index/genome.txt"
    params:
        extra="",  # optional additional args
    cache: True
    # Minimap2 uses at most three threads when indexing target sequences:
    # https://lh3.github.io/minimap2/minimap2.html
    threads: 3
    wrapper:
        "v1.25.0/bio/minimap2/index"


# TODO: create new ENSEMBL-REGULATORY-ANNOTATION snakemake wrapper
rule download_regulatory_annotation:
    output:
        "resources/regulatory_annotation.gff3.gz",
    log:
        "logs/download_regulatory_annotation.log",
    params:
        release=get_annotation_release,
    benchmark:
        "benchmarks/download_regulatory_annotation.txt"
    cache: "omit-software"  # save space and time with between workflow caching (see docs)
    conda:
        "../envs/wget.yaml"
    shell:
        """wget https://ftp.ensembl.org/pub/release-{params.release}/regulation/homo_sapiens/homo_sapiens.GRCh38.Regulatory_Build.regulatory_features.20220201.gff.gz --no-check-certificate -O {output} 2> {log}"""


# TODO: if possible, make this rule / repeat mask retrieval more general (as in more genome builds and species possible)
# ideas: create repeat masks ourselves, using:
# * repeatmasker: https://repeatmasker.org/RepeatMasker/ (pin version in envs/repeatmasker.yaml)
# * dfam: https://www.dfam.org/home (pin version in config.yaml)
# * ensembl reference specified in config.yaml
rule download_repeatmasker_annotation:
    output:
        "resources/repeat_masker.hg38.fa.out.gz",
    log:
        "logs/download_repeatmasker_annotation.log",
    params:
        release=get_annotation_release,
    benchmark:
        "benchmarks/download_repeatmasker_annotation.txt"
    cache: "omit-software"  # save space and time with between workflow caching (see docs)
    conda:
        "../envs/wget.yaml"
    shell:
        """wget http://www.repeatmasker.org/genomes/hg38/RepeatMasker-rm406-dfam2.0/hg38.fa.out.gz --no-check-certificate -O {output} 2> {log}"""


rule download_gene_annotation:
    output:
        "resources/gene_annotation.gff3.gz",
    params:
        species=config["reference"]["species"],
        build=config["reference"]["build"],
        release=config["reference"]["release"],
        flavor="",  # optional, e.g. chr_patch_hapl_scaff, see Ensembl FTP.
        # branch="plants",  # optional: specify branch
    log:
        "logs/download_gene_annotation.log",
    cache: "omit-software"  # save space and time with between workflow caching (see docs)
    wrapper:
        "v1.25.0/bio/reference/ensembl-annotation"
