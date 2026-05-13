import requests, json, time

# GTEx v8 API
GTEX = "https://gtexportal.org/api/v2"

# Variantes Eastern con coordenadas hg38
variants = [
    ("chr15", 72410596, "A", "C", "PKM"),
    ("chr15", 72414359, "C", "T", "PKM"),
    ("chr6",  16278159, "A", "G", "PGM1"),
    ("chr1",  35542512, "T", "C", "UGP2"),
    ("chr1",  35546895, "A", "G", "UGP2"),
    ("chr1",  35552461, "C", "T", "UGP2"),
    ("chr1",  35561736, "A", "G", "UGP2"),
    ("chr1",  35549492, "G", "A", "UGP2"),
]

# Tejidos relevantes
tissues = [
    "Muscle_Skeletal",
    "Adipose_Subcutaneous", 
    "Adipose_Visceral_Omentum",
    "Pancreas",
    "Liver",
    "Brain_Cortex"
]

print("=== GTEx eQTL query ===\n")

results = []
for chrom, pos, ref, alt, gene in variants:
    # Formato GTEx: chr_pos_ref_alt_b38
    variant_id = f"{chrom}_{pos}_{ref}_{alt}_b38"
    
    for tissue in tissues:
        url = f"{GTEX}/association/singleTissueEqtl"
        params = {
            "variantId": variant_id,
            "tissueSiteDetailId": tissue,
            "datasetId": "gtex_v8"
        }
        try:
            r = requests.get(url, params=params, timeout=10)
            data = r.json()
            if data.get("data"):
                for hit in data["data"]:
                    pval = hit.get("pValue", 1)
                    if pval < 0.05:
                        results.append({
                            "variant": variant_id,
                            "gene_symbol": gene,
                            "tissue": tissue,
                            "eqtl_gene": hit.get("gencodeId",""),
                            "pval": pval,
                            "effect": hit.get("nes", 0)
                        })
                        print(f"✓ eQTL: {variant_id} | {tissue} | p={pval:.4f}")
        except Exception as e:
            pass
        time.sleep(0.2)

print(f"\nTotal eQTLs encontrados: {len(results)}")
if results:
    import csv
    with open("act3/gtex_eqtls.csv","w",newline="") as f:
        w = csv.DictWriter(f, fieldnames=results[0].keys())
        w.writeheader()
        w.writerows(results)
    print("Guardado: act3/gtex_eqtls.csv")
