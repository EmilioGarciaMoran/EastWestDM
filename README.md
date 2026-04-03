# East-West Diabetes Story
## Divergent Allometric Adaptations in Glucose Homeostasis: From Atapuerca to the Americas

**Status:** Work in progress — Acto 1 complete, Acto 2 pilot complete  
**Author:** egarmo  
**Last updated:** April 2026

---

## La hipótesis central

La diabetes tipo 2 no es una enfermedad uniforme. Es el resultado de **dos soluciones evolutivas distintas** al mismo problema biológico: suministrar glucosa a un cerebro metabólicamente muy costoso bajo condiciones ambientales opuestas.

- **Western lineage** (Sima de los Huesos → Vindija → europeos modernos): optimización del umbral renal de glucosa. El riñón aprendió a retener azúcar eficientemente en un ambiente de escasez calórica y frío moderado. Gen clave: *SLC5A2* (SGLT2).

- **Eastern lineage** (Denisova → Ust'-Ishim → amerindios): resistencia periférica masiva a la insulina como estrategia anticongelante ártico. El músculo se cierra al azúcar para que el cerebro y los tejidos vitales mantengan perfusión caliente en temperaturas de -50°C. Gen clave: *SLC16A11*.

**La implicación clínica es directa:** tratamos una Eastern Diabetes con fármacos diseñados para el modelo Western. Esto explica la crisis metabólica desproporcionada en poblaciones nativas americanas expuestas a dieta occidental.

---

## Estructura del estudio

```
Acto 1 — ¿Es Homo sapiens un outlier alométrico único?
Acto 2 — ¿Qué genes están bajo selección positiva en nuestra rama?
Acto 3 — ¿Cómo se polariza esa señal entre linajes arcaicos y modernos?
         (Sima vs Vindija vs Denisova vs Ust'-Ishim → gnomAD v4)
```

---

## ACTO 1 — Análisis alométrico ✅ COMPLETADO

### Pregunta
¿Es *Homo sapiens* el único mamífero outlier simultáneo en **encefalización extrema** (EQ residual) y **adaptación al frío** (temperatura de hábitat)?

### Método
- 52 mamíferos, 4 variables: EQ residual (Jerison), BMR_z, longevidad_z, temperatura_hábitat
- Fuentes: Stephan et al. 1981, Isler & van Schaik 2006, Burger et al. 2019, PanTHERIA
- Distancia de Mahalanobis + FDR en dos modelos:
  - **Modelo 1** (EQ puro, N=28): incluye cetáceos
  - **Modelo 2** (terrestres, N=22): *Homo sapiens* asignado a -5°C (nicho glacial LGM)

### Resultados clave
| Métrica | Valor |
|---------|-------|
| Ranking *H. sapiens* M1 | **2/28** |
| Distancia Mahalanobis | D = 28.81 |
| p-valor (FDR corregido) | **p = 3.4 × 10⁻⁵** |
| Especies en cuadrante EQ>0 + T<5°C (M2) | *Vulpes lagopus*, *Canis lupus*, *Ursus americanus*, *Marmota marmota* |

**Conclusión Acto 1:** *Homo sapiens* es un outlier estadísticamente incontestable en encefalización. El cuadrante de alto EQ + temperatura fría está ocupado exclusivamente por mamíferos boreales — y nuestra especie. Esto justifica la búsqueda de señales de selección positiva en genes de metabolismo de glucosa y termogénesis.

### Figura principal
`act1/act1_figure1_combined_v7.pdf` — tres paneles: PCA, Mahalanobis M1, Mahalanobis M2

---

## ACTO 2 — Selección positiva y tasas evolutivas ⚠️ PILOTO COMPLETADO

### Pregunta
¿Qué genes candidatos muestran evidencia de selección positiva (ω > 1) en la rama humana comparada con 13 especies de mamíferos?

### Método A — PAML branch-site (piloto, N=39 genes)
- 14 taxa, árbol TimeTree, *homo_sapiens* como foreground (#1)
- Modelo alternativo (M2a) vs nulo (ω=1 fijado), LRT con χ² df=1
- **Limitación:** genes con CDS > 3000 bp causan no-convergencia. Solo 39 genes completaron con calidad suficiente.
- **Resultado:** 0 genes FDR < 0.05 (N insuficiente para potencia estadística)
- Candidatos destacados: CYP11B2 (LRT=2.28), IRS2 (LRT=1.37)

### Método B — yn00 pairwise dN/dS (N=79 genes, 13 especies) ✅
- yn00 (PAML 4.9j), alineamiento MAFFT, 890 pares válidos de 1027
- **Sin árbol filogenético** — comparación directa *homo_sapiens* vs cada especie
- Ventaja: robusto, sin problemas de convergencia, completa en ~13 minutos en local

### Resultados yn00 destacados

**Genes bajo selección positiva (ω_mean > 1.0):**

| Gen | ω medio | Eje biológico | Nota |
|-----|---------|---------------|------|
| PKM | 2.44 | Glucólisis | Piruvato kinasa M — isoforma muscular |
| SLC2A3 | 2.41 | Western/glucosa | GLUT3 — transporte cerebral |
| LDHA | 2.23 | Glucólisis | Lactato deshidrogenasa A |
| PFKM | 1.77 | Glucólisis | Fosfofructokinasa muscular |
| UGP2 | 1.81 | Glucosa/glucógeno | UDP-glucosa pirofosforilasa |
| ADIPOQ | 1.45 | Señalización | Adiponectina |
| PGM1 | 1.32 | Glucógeno | Fosfoglucomutasa |
| PPARGC1A | 1.24 | Frío/termogénesis | Coactivador maestro termogénesis |
| TRPA1 | 1.05 | Frío | Receptor canal de frío |
| ACACA | 1.29 | Lípidos | Acetil-CoA carboxilasa |

**Señales del eje frío:**
- TRPA1 vs *Ursus americanus*: ω = **3.63** — receptor de frío más divergente en oso
- PPARGC1A vs *Loxodonta africana*: ω = **5.09** — regulador maestro de termogénesis
- UCP1 ω_mean = 0.86 — casi en umbral positivo

**Señales del eje Western (glucosa/riñón):**
- SLC5A2 ω_mean = **0.39** — conservado bajo purificación (esencial, no negociable)
- LDHA vs *Tursiops truncatus*: ω = **4.18** — LDHA del delfín muy divergente (metabolismo anaeróbico de buceo)

---

## ACTO 2 — Mejoras pendientes (roadmap)

Basado en revisión crítica externa (DeepSeek, Abril 2026):

1. **RELAX (HyPhy)** sobre top-20 genes de yn00 — detecta si la intensidad de selección ha cambiado específicamente en la rama humana (K>1 = intensificación, K<1 = relajación). Más robusto que PAML branch-site para este propósito. Complementario a aBSREL para selección positiva directa.
2. **phyloP de Zoonomia** (UCSC Table Browser) como validación externa de aceleración — independiente de nuestros alineamientos.
3. **GWAS Catalog / T2D Knowledge Portal** — cruzar top genes con variantes asociadas a diabetes tipo 2 en poblaciones AMR y EAS.
4. **Nota sobre circularidad:** Los 79 genes fueron seleccionados de rutas KEGG (hsa00010 glucólisis, hsa04910 insulina, hsa04714 termogénesis) — criterio agnóstico respecto al fenotipo de diabetes. Documentar explícitamente en Métodos.
5. **yn00 no es branch-specific** — un ω elevado en *H. sapiens* vs *Ursus* refleja divergencia acumulada en cualquiera de las dos ramas. RELAX o aBSREL son necesarios para atribuir la aceleración específicamente a la rama humana.

---

## ACTO 3 — Polarización Este-Oeste (en diseño)

### Pregunta
¿Las firmas de selección del Acto 2 se polarizan entre linajes arcaicos y se proyectan en las poblaciones humanas actuales de forma consistente con la hipótesis East-West?

### 3A — simaFive: pileup de los 5 individuos de Sima de los Huesos

Los 5 genomas disponibles tienen cobertura individual ~0.5-1x — insuficiente para genotipado individual fiable. Sin embargo, para inferencia de **presencia/ausencia alélica a nivel poblacional**, el pileup agregado es metodológicamente válido.

**Justificación:** Los 5 individuos son contemporáneos (~430 kyr), pertenecen a la misma población, y lo que se busca no es el genotipo de un individuo sino si el alelo estaba presente en ese linaje. Con 5×1x = ~5x efectivo en zonas solapantes, es posible llamar alelos presentes con frecuencia >30% con confianza razonable.

Protocolo simaFive:
```bash
# 1. Merge de los 5 BAMs (ENA PRJEB9021)
samtools merge sima_merged.bam sima_ind1.bam sima_ind2.bam \
    sima_ind3.bam sima_ind4.bam sima_ind5.bam
samtools index sima_merged.bam

# 2. Pileup sobre regiones de genes top-10
samtools mpileup \
    -f hg38.fa \
    -l top10_genes_hg38.bed \
    -q 30 -Q 20 \
    --rf PROPER_PAIR \
    sima_merged.bam > sima_merged.pileup

# 3. Filtro: incluir solo genes con cobertura media >= 3x
awk '$4 >= 3' sima_merged.pileup > sima_filtered.pileup
```

Criterios de inclusión/exclusión:
- **Incluir:** cobertura media ≥ 3x → análisis de presencia alélica válido
- **Excluir:** cobertura media < 3x → documentar en suplemento
- Filtro de deaminación: excluir C→T en primeros/últimos 5bp de cada read
- Llamar solo variantes presentes en ≥ 2 reads independientes

Texto para Métodos del paper:
> *"Given the low individual coverage of Sima de los Huesos specimens (~0.5-1x per individual), we merged all five available BAM files to obtain a composite pileup with effective coverage of 3-5x per locus. Genes with mean coverage < 3x in the merged pileup were excluded from downstream analysis (n=X). This approach is appropriate for population-level allele presence/absence inference but precludes individual genotyping."*

### 3B — Arcaicos comparados

| Espécimen | Cobertura | Linaje | Fuente ENA |
|-----------|-----------|--------|------------|
| Sima de los Huesos (×5, merged) | ~3-5x efectivo | Pre-Neandertal Western | PRJEB9021 |
| Vindija 33.19 | ~30x | Neandertal europeo | ENA |
| Altai Denisova | ~30x | Denisovano | ENA |
| Ust'-Ishim | ~42x | Sapiens Siberiano (~45 kyr) | ENA |

### 3C — Proyección en gnomAD v4

Objetivo: demostrar que las firmas evolutivas del Acto 2 tienen correlatos medibles en la distribución actual de variantes humanas.

Poblaciones clave:
- **NFE** (Non-Finnish European) → proxy Western
- **EAS** (East Asian) → proxy Eastern
- **AMR** (Latino/Admixed American) → proxy Eastern con mezcla reciente
- **AFR** (African) → outgroup basal

Análisis:
1. Extraer frecuencias alélicas de variantes no sinónimas en top-10 genes para NFE, EAS, AMR, AFR
2. Calcular odds ratio (OR) EAS/AMR vs NFE para cada variante
3. Definir "alelo Oriental" si OR > 2, presente en AMR/EAS, raro en NFE
4. Cruzar con GWAS Catalog y T2D Knowledge Portal — ¿asociados a T2D en AMR/EAS?
5. Visualización: scatter frecuencia AMR vs EUR — buscar alelos "diagnósticos" en las esquinas

**Predicción principal:** Los alelos de alta ω en PKM, PFKM y PPARGC1A serán más frecuentes en EAS/AMR que en NFE. SLC5A2 mostrará distribución uniforme (gen bajo purificación, sin polarización).

### 3D — Test D-statistic (ABBA-BABA)

Para confirmar estructura poblacional en los loci candidatos:
- Topología: (Pan, Sima; Vindija, Denisova)
- Genes top-10 Acto 2 como ventanas de análisis
- Z-score > 3 como umbral de significancia
- Herramienta: ANGSD -doAbbababa2

---

## Stack técnico

```
Alometría:      R (ape, MASS, ggplot2, ggrepel, patchwork)
Alineamiento:   MAFFT 7
dN/dS:          yn00 (PAML 4.9j, apt install paml)
PAML branch:    codeml (PAML 4.9j)
Infraestructura: AWS EC2 r6i.2xlarge (Acto 2 PAML), local Dell (yn00)
Orquestación:   Python 3.12, bash, nohup
Datos:          Ensembl REST API, PanTHERIA, UCSC
Versión:        git (este repositorio)
```

---

## Archivos clave

```
scripts/
├── act1_allometric_pca_v7.R         # Acto 1 completo
├── yn00_eastwest_final.py           # Acto 2 dN/dS pipeline (el que funciona)
├── fetch_dnds_eastwest.py           # Intento Ensembl API (dn_ds=null, no usar)
└── run_yn00_eastwest.py             # Versiones previas (deprecadas)

act1/
├── act1_figure1_combined_v7.pdf     # FIGURA PUBLICABLE
├── act1_model1_mahalanobis_v7.csv
├── act1_model2_mahalanobis_v7.csv
└── act1_results_v7.txt

act2/
├── paml_lrt_raw.csv                 # PAML branch-site (39 genes, piloto)
├── yn00_results/dnds_final.csv      # yn00 pairwise (79 genes, 890 pares) ✅
├── act2_final_genes.csv             # Análisis estadístico PAML
└── act2_volcano_v1.pdf              # Volcano plot PAML

data/
├── combined_mammal_pes.csv          # Dataset alométrico
└── species_tree_14taxa.nwk          # Árbol filogenético
```

---

## Reflexión sobre el Acto 2

El análisis yn00 no es equivalente al branch-site de PAML — no detecta selección específica de rama sino divergencia pairwise acumulada. Esto significa que un ω elevado en la comparación *homo_sapiens* vs *Ursus americanus* para TRPA1 puede reflejar divergencia en cualquiera de las dos ramas, no necesariamente aceleración humana.

**Para el paper, el Acto 2 necesita:**
1. PAML branch-site completo sobre los top-15 genes de yn00 (factible con timeout generoso)
2. O bien análisis de sitios específicos (BEB posterior probability) en los genes candidatos
3. Integración con datos de aceleración phyloP de Zoonomia como validación externa

**El Acto 2 actual es exploratorio y sirve para priorizar candidatos para el Acto 3.**

---

## Títulos candidatos para el paper

1. *"The East-West Diabetes Story: Divergent Allometric Adaptations in Glucose Homeostasis from the Middle Pleistocene to Modern Clinical Practice"*

2. *"Positive Selection in Human Glucose and Thermogenic Genes: Allometric Evidence for Two Distinct Metabolic Architectures"*

3. *"HotSaltySoup: Thermal Homeostasis as the Evolutionary Driver of Western Hypertension and Eastern Insulin Resistance"* (para el paper de hipertensión, spin-off)

---

## Revistas target

| Paper | Target | Justificación |
|-------|--------|---------------|
| Flagship (metodología completa) | *Genome Biology* / *Nature Communications* | Elegancia del pipeline, novedad Atapuerca |
| East-West Diabetes | *Diabetes* / *Cell Metabolism* | Impacto clínico directo |
| HotSaltySoup (HTA) | *Hypertension* / *JASN* | Farmacogenómica de poblaciones |

---

*"No estamos describiendo fósiles. Estamos diagnosticando a sus descendientes."*
