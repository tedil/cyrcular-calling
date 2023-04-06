rule get_genome:
    output:
        "resources/genome.fasta",
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
        "resources/genome.fasta",
    output:
        "resources/genome.fasta.fai",
    log:
        "logs/genome-faidx.log",
    cache: True
    wrapper:
        "v1.25.0/bio/samtools/faidx"


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
        """wget https://repeatmasker.org/genomes/hg38/RepeatMasker-rm405-db20140131/hg38.fa.out.gz --no-check-certificate -O {output} 2> {log}"""


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
