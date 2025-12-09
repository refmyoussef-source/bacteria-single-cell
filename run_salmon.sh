#!/bin/bash

# ==========================================
# SALMON PIPELINE V2: Robust & Clean
# ==========================================

mkdir -p processed_data/salmon_quant
mkdir -p references/indices

# --- Function to Build Index ---
build_index() {
    species=$1
    fasta=$2
    index_path="references/indices/${species}_index"

    echo "🏗️  Building Index for $species..."
    
    # Salmon command
    salmon index -t $fasta -i $index_path -k 31
    
    # Verification: Check if it worked
    if [ -f "$index_path/versionInfo.json" ]; then
        echo "✅ Index for $species built successfully."
    else
        echo "❌ CRITICAL ERROR: Index for $species FAILED to build."
        exit 1
    fi
}

# --- STEP 1: FORCE BUILD INDICES ---
# We build them sequentially to save RAM
echo "=== STEP 1: Building Indices ==="

# P. aeruginosa
build_index "PAO1" "references/PAO1_cds.fna"

# S. aureus
build_index "USA300" "references/USA300_cds.fna"

# E. coli
build_index "MG1655" "references/MG1655_cds.fna"


# --- STEP 2: QUANTIFICATION ---
echo "=== STEP 2: Starting Quantification ==="

for file in raw_data/*_1.fastq.gz; do
    filename=$(basename "$file")
    sample="${filename%_1.fastq.gz}"
    
    # Define files
    read1="raw_data/${sample}_1.fastq.gz"
    read2="raw_data/${sample}_2.fastq.gz"
    output="processed_data/salmon_quant/${sample}"

    # Select Index based on Sample ID
    if [[ "$sample" == "SRR25445867" || "$sample" == "SRR25445868" || "$sample" == "SRR25445869" || "$sample" == "SRR25445870" ]]; then
        INDEX="references/indices/PAO1_index"
    elif [[ "$sample" == "SRR25445871" || "$sample" == "SRR25445872" || "$sample" == "SRR25445873" || "$sample" == "SRR25445874" ]]; then
        INDEX="references/indices/USA300_index"
    else
        INDEX="references/indices/MG1655_index"
    fi

    echo "------------------------------------------------"
    echo "🚀 Processing $sample using $(basename $INDEX)"
    
    # Run Salmon
    salmon quant -i $INDEX -l A \
        -1 $read1 -2 $read2 \
        -p 4 --validateMappings -o $output -q

    if [ $? -eq 0 ]; then
        echo "✅ Success: $sample"
    else
        echo "❌ Error processing $sample"
    fi
done

echo "=== PIPELINE FINISHED ==="
