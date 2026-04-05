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

### 3A — Dataset de especímenes arcaicos

Dataset completo ordenado cronológicamente:

| Espécimen | Abrev. | Edad | Linaje | Cobertura | Estrategia análisis |
|-----------|--------|------|--------|-----------|---------------------|
| Altai Neandertal (D5) | D5 | ~118 ka | Neandertal Altai | 52x | SNPs targeted + full |
| Chagyrskaya 8 | Chag8 | ~77 ka | Neandertal Altai | 27x | SNPs targeted + full |
| Denisova 3 | D3 | ~205 ka | Denisovano | ~30x | SNPs targeted + full |
| Denisova 17 | D17 | ~110 ka | Denisovano | 37x | SNPs targeted + full |
| Denisova 25 | D25 | — | Denisovano | 31x | SNPs targeted |
| Vindija 33.19 | Vi33.19 | ~49 ka | Neandertal europeo | 30x | SNPs targeted + full |
| Goyet 1 | GN1 | ~40 ka | Neandertal occidental | 22x | SNPs targeted |
| Ust'-Ishim | N/A | ~65 ka | Sapiens siberiano | 42x | **CORE — smoking gun** |
| Loschbour | N/A | ~10 ka | Sapiens europeo temprano | 24x | SNPs targeted |
| Stuttgart LBK | N/A | ~7 ka | Sapiens agrícola europeo | 19x | SNPs targeted |
| **Sima de los Huesos (×5)** | simaFive | ~430 ka | Pre-Neandertal Western | ~3-5x merged | Targeted SNPs only |
| **El Sidrón (×13)** | sidronMerge | ~49 ka | Neandertal ibérico | ~3-5x merged | Targeted SNPs only |

Fuente: Prüfer et al. 2014, 2017; Mafessoni et al. 2020; Meyer et al. 2016; Fu et al. 2014; Lazaridis et al. 2016; ENA PRJEB9021

### 3B — Estrategia de SNPs informativos targeted

**Insight clave:** La baja cobertura de Sima (~430 ka, 5 individuos) y El Sidrón (~49 ka, 13 individuos) no impide el análisis si se focaliza en posiciones específicas altamente informativas en lugar de explorar todo el gen.

**Protocolo targeted SNP:**

Paso 1 — Seleccionar SNPs informativos desde gnomAD (Fst AMR/EAS vs NFE > 0.3):
```bash
# Ejemplo: PKM rs3024994 → AFR=0.02, NFE=0.05, AMR=0.45, EAS=0.38
# Estos SNPs discriminan perfectamente Eastern vs Western
# Crear BED con solo esas posiciones exactas
echo -e "chr15	72044768	72044769	PKM_rs3024994" > snps_informative.bed
```

Paso 2 — Pileup targeted en Sima/Sidrón merged:
```bash
# simaFive
samtools merge sima_merged.bam sima_ind*.L35MQ30.bam
samtools index sima_merged.bam

# sidronMerge
samtools merge sidron_merged.bam sidron_ind*.L35MQ30.bam
samtools index sidron_merged.bam

# Pileup SOLO en SNPs informativos
for BAM in sima_merged.bam sidron_merged.bam vindija.bam ust_ishim.bam; do
    samtools mpileup         -f hg38.fa         -l snps_informative.bed         -q 25 -Q 20         --rf PROPER_PAIR         $BAM > ${BAM%.bam}_targeted.pileup
done
```

Paso 3 — Interpretación:
- ≥1 read con alelo ancestral → consistente con Western
- ≥1 read con alelo derivado Eastern → señal Eastern presente
- 0 reads → "insufficient coverage at this locus" (documentar, no inferir)

**Texto para Métodos:**
> *"For low-coverage specimens (Sima de los Huesos, n=5, ~0.5-1x per individual; El Sidrón, n=13, ~0.3-0.5x per individual), we merged all available BAM files and performed targeted pileup analysis restricted to 12 highly informative SNPs (gnomAD AMR/EAS vs NFE Fst > 0.3) in top candidate genes. This approach is appropriate for allele presence/absence inference at pre-selected informative positions but precludes genome-wide variant calling."*

**Predicción y narrativa temporal:**

```
430 ka  Sima de los Huesos  → ancestral/Western (pre-adaptación Eastern)
 49 ka  El Sidrón           → Western (neandertal ibérico)
 49 ka  Vindija 33.19       → Western (neandertal europeo, alta cobertura)
 77 ka  Chagyrskaya         → Western? (neandertal Altai, a confirmar)
205 ka  Denisova 3          → ??? (clave: ¿tiene ya alelos Eastern?)
 65 ka  Ust'-Ishim          → EASTERN (sapiens siberiano — smoking gun)
 10 ka  Loschbour           → Western (sapiens europeo post-glacial)
  7 ka  Stuttgart LBK       → Western (sapiens agrícola europeo)
```

Si Denisova 3 → ancestral Y Ust'-Ishim → derivado Eastern:
**La adaptación Eastern ocurrió en sapiens modernos entre ~200 ka y ~65 ka, probablemente como selección positiva rápida bajo presión de frío extremo siberiano. Convergente con zorro ártico y oso polar pero sin millones de años de refinamiento — una solución chapucera que hoy causa diabetes en Jalisco.**

### 3C — Gradiente temporal Este-Oeste: la narrativa central

Esta es la **Figura 3 del paper** — el argumento visual completo:

| Población | Región | Edad (ka) | Linaje | Estado metabólico predicho |
|-----------|--------|-----------|--------|---------------------------|
| Sima de los Huesos | Burgos, España | ~430 | Pre-Neandertal Western | **Ancestral neutro** — sin alelos Eastern ni Western establecidos |
| Altai Neandertal D5/D17 | Siberia | ~118-110 | Neandertal Oriental | **Oriental primitivo** — aislamiento, Ne pequeño, mezcla denisovana |
| Chagyrskaya 8 | Siberia | ~77 | Neandertal Occidental derivado | Reemplazó a orientales — ¿transición? |
| El Sidrón | Asturias, España | ~49 | Neandertal Occidental | **Pre-adaptación Western** — SLC5A2 ancestral, sin Eastern |
| Vindija 33.19 | Croacia | ~49 | Neandertal Occidental | **Western establecido** — referencia de alta cobertura |
| Denisova 3 | Siberia | ~205 | Denisovano | **??? clave** — ¿ya tiene alelos Eastern? |
| Ust'-Ishim | Siberia | ~65 | Sapiens siberiano | **SMOKING GUN Eastern** — adaptación rápida chapucera |
| Loschbour | Luxemburgo | ~10 | Sapiens europeo | Western moderno temprano |
| Stuttgart LBK | Alemania | ~7 | Sapiens agrícola | Western moderno |
| gnomAD NFE | Europa actual | 0 | Sapiens moderno | Western fijado |
| gnomAD EAS/AMR | Asia/América | 0 | Sapiens moderno | **Eastern fijado → T2D en Jalisco** |

**La predicción testable:**
- Alelos Eastern (PKM derivado, PPARGC1A termogénico, SLC16A11) → presentes en Ust'-Ishim, frecuentes en EAS/AMR, ausentes en Vindija/El Sidrón/Sima
- Alelos Western (SLC5A2 conservado, umbral renal) → presentes en Vindija, consistentes en El Sidrón/Sima, raros en EAS/AMR

**El argumento narrativo para el paper:**
> *"Los alelos que hoy causan diabetes en Jalisco no son un error moderno — son una adaptación de emergencia fijada en sapiens siberianos entre ~200 ka y ~65 ka, convergente con la evolución del zorro ártico y el oso polar, pero sin los millones de años de refinamiento de esos linajes. Esta 'solución chapucera' funcionó perfectamente en el Pleistoceno siberiano. Hoy, expuesta a dieta occidental y calor en México, colapsa el sistema metabólico."*

### 3D — Convergencia ártica: mamíferos boreales como validación

Objetivo: demostrar que los mismos genes bajo selección en humanos (Acto 2) también están acelerados en linajes árticos independientes → convergencia evolutiva.

Comparaciones clave:
| Gen | Ártico | Templado (control) | Predicción |
|-----|--------|---------------------|------------|
| PPARGC1A | Oso polar (*U. maritimus*) | Oso pardo (*U. arctos*) | ω polar > ω pardo |
| TRPA1 | Zorro ártico (*V. lagopus*) | Zorro rojo (*V. vulpes*) | ω ártico > ω rojo |
| UCP1 | Reno (*Rangifer tarandus*) | Ciervo (*Cervus elaphus*) | ω reno > ω ciervo |
| PKM | Oso polar | Oso pardo | ω polar > ω pardo |

Método: yn00 pairwise (ya funciona en local) sobre CDS descargados de NCBI/Ensembl.
Script: `scripts/yn00_eastwest_final.py` — añadir estas especies al config.

**Si PPARGC1A muestra ω > 1 en oso polar y ω < 0.5 en oso pardo → convergencia demostrada.**
Eso cierra el círculo: la misma presión ambiental (frío extremo) seleccionó los mismos genes en linajes independientes — humanos siberianos, zorros árticos, osos polares.

### 3E — Arcaicos de alta cobertura: pipeline completo

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

## Preprint

García-Morán E. Paleogenomic Evidence for Two Independent Metabolic Architectures 
Underlying Ethnic Disparities in Type 2 Diabetes: An East-West Axis Traced Through 
430,000 Years of Hominin Evolution. Zenodo. 2026. 
DOI: 10.5281/zenodo.19431147
