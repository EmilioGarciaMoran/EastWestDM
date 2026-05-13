import requests, csv, time

GTEX = "https://gtexportal.org/api/v2"

tissues = [
    "Muscle_Skeletal",
    "Adipose_Subcutaneous",
    "Adipose_Visceral_Omentum", 
    "Pancreas",
    "Liver",
    "Brain_Cortex",
    "Whole_Blood"
]

# Leer todas las variantes Eastern
variants = []
with open("act3/vep_eastern_all.csv") as f:
    for row in csv.DictReader(f):
        v = row['variant']  # formato: chrom-pos-ref-alt
        parts = v.split('-')
        if len(parts) == 4:
            chrom, pos, ref, alt = parts
            # GTEx formato: chr_pos_ref_alt_b38
            gtex_id = f"chr{chrom}_{pos}_{ref}_{alt}_b38"
            variants.append((gtex_id, row['gene'], row['consequence']))

print(f"Consultando {len(variants)} variantes en {len(tissues)} tejidos...")

results = []
for i, (vid, gene, csq) in enumerate(variants):
    for tissue in tissues:
        try:
            r = requests.get(
                f"{GTEX}/association/singleTissueEqtl",
                params={"variantId": vid, 
                        "tissueSiteDetailId": tissue,
                        "datasetId": "gtex_v8"},
                timeout=10
            )
            data = r.json()
            if data.get("data"):
                for hit in data["data"]:
                    pval = hit.get("pValue", 1)
                    if pval < 0.01:
                        results.append({
                            "variant": vid,
                            "our_gene": gene,
                            "consequence": csq,
                            "tissue": tissue,
                            "eqtl_gene": hit.get("geneSymbol",""),
                            "pval": pval,
                            "nes": hit.get("nes", 0)
                        })
                        print(f"[{i+1}/{len(variants)}] ✓ {vid} | "
                              f"{tissue} | {hit.get('geneSymbol','')} | "
                              f"p={pval:.2e} | NES={hit.get('nes',0):.3f}")
        except:
            pass
        time.sleep(0.15)

with open("act3/gtex_eqtls_all.csv","w",newline="") as f:
    if results:
        w = csv.DictWriter(f, fieldnames=results[0].keys())
        w.writeheader()
        w.writerows(results)

print(f"\nTotal eQTLs p<0.01: {len(results)}")
print("Guardado: act3/gtex_eqtls_all.csv")
