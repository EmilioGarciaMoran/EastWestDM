cat > README.md << 'EOF'
# East-West Diabetes Story

## Hipótesis central
La diabetes tipo 2 refleja dos soluciones evolutivas distintas al mismo problema: suministrar glucosa a un cerebro metabólicamente costoso bajo condiciones ambientales opuestas.  
**Western** (Europa): optimización del umbral renal de glucosa.  
**Eastern** (Asia/América): resistencia periférica masiva a la insulina como anticongelante.

## Estructura del estudio
- **Acto 1:** Demostrar que *Homo sapiens* es el único mamífero outlier simultáneo en **encefalización** (EQ residual) y **adaptación al frío** (temperatura de hábitat). Base alométrica objetiva.
- **Acto 2:** Identificar genes bajo selección positiva en los linajes outlier y enriquecimiento GO diferencial.
- **Acto 3:** Polarizar las firmas GO entre homínidos arcaicos (Sima, Vindija, Denisova, Ust’-Ishim) y poblaciones modernas (gnomAD v4).

## Acto 1 – Análisis alométrico (este repositorio)

### Datos
- `data/PanTHERIA_1-0_WR05_Aug2008.txt` – base de datos de rasgos de mamíferos (temperatura, BMR, longevidad).
- `data/combined_mammal_pes.csv` – valores de BMR y longevidad para *Homo sapiens* (no disponibles en PanTHERIA).
- Datos de masa corporal y cerebral de 52 especies compilados de Stephan et al. (1981), Isler & van Schaik (2006), Burger et al. (2019) – incluidos en el script.

### Script
`scripts/act1_allometric_pca_v7.R`  
Calcula el residuo de encefalización (EQ), combina con BMR, longevidad y temperatura, realiza PCA y distancia de Mahalanobis para dos modelos:
- **Modelo 1:** EQ + BMR + longevidad (incluye a *Homo sapiens*).
- **Modelo 2:** EQ + BMR + longevidad + temperatura (terrestres). A *Homo sapiens* se le asigna -5 °C (nicho glacial siberiano, LGM).

### Ejecución
```bash
Rscript scripts/act1_allometric_pca_v7.R
Resultados (generados en results/)
act1_eq_all_species_v7.csv – EQ residual por especie.

act1_merged_v7.csv – datos combinados con temperatura, BMR_z, lon_z.

act1_model1_mahalanobis_v7.csv / act1_model2_mahalanobis_v7.csv – distancias y p-valores.

act1_outliers_model1_v7.csv / act1_outliers_model2_v7.csv – outliers con FDR < 0.01.

act1_figure1_combined_v7.pdf / .png – figura principal (tres paneles).

act1_results_v7.txt – texto de resultados en formato draft.

Interpretación esperada
Modelo 1: Homo sapiens outlier por encefalización extrema.

Modelo 2: Homo sapiens en el cuadrante de EQ alto y temperatura baja, posible outlier o cerca del umbral. Otras especies en ese cuadrante: zorro ártico, lobo, oso, marmota.

Control de versiones
Este repositorio usa Git. El script está comentado línea por línea para documentar cada paso, fuentes de datos y overrides justificados (temperatura de Urocitellus parryii, valores de Homo sapiens).

Siguientes pasos
Tras confirmar el Acto 1, se procederá al Acto 2 (selección positiva y GO) en un entorno local o en la nube con recursos adecuados.

Referencias clave
McLean & Towns 2014 (J Mammal) – temperatura Urocitellus parryii.

Boonstra et al. 2001 (J Mammal) – longevidad y BMR.

Buck & Barnes 1999 (Physiol Biochem Zool) – BMR en hibernación.

Reich et al. 2010 (Nature) – poblamiento de Siberia.

Ponomarev et al. 2021 (Quat Sci Rev) – temperaturas LGM.

EOF

text

### 3. Añadir comentarios adicionales al script (opcional pero recomendado)

El script ya está bien comentado, pero puedes añadir una cabecera al principio con información de versión y propósito. Abre el script con un editor y añade estas líneas al inicio (después de los comentarios de cabecera existentes):

```r
# =============================================================================
# ACTO 1 - ANÁLISIS ALOMÉTRICO
# Versión: v7 (con Homo sapiens en modelo 2 a -5°C)
# Fecha: 2025-04-02
# Autor: egarmo
# Descripción: 
#   Calcula residuos de encefalización (EQ) para 52 mamíferos, combina con 
#   BMR, longevidad y temperatura (PanTHERIA). Realiza PCA y Mahalanobis para
#   identificar outliers en dos modelos: (1) EQ puro, (2) EQ + temperatura.
#   Asigna -5°C a Homo sapiens (nicho glacial siberiano) y -10°C a 
#   Urocitellus parryii (literatura).
# Output: results/act1_* (CSV, figuras, texto resultados)
# =============================================================================
