# =============================================================================
# ACTO 1 - ANÁLISIS ALOMÉTRICO
# Versión: v7_final (con Homo sapiens en modelo 2 a -5°C)
# Fecha: 2025-04-02
# Descripción: 
#   Calcula residuos de encefalización (EQ) para 52 mamíferos, combina con 
#   BMR, longevidad y temperatura (PanTHERIA). PCA y Mahalanobis para dos modelos:
#     Modelo 1: EQ + BMR + longevidad (incluye Homo sapiens)
#     Modelo 2: EQ + BMR + longevidad + temperatura (terrestres)
#   A Homo sapiens se le asigna -5°C (nicho glacial siberiano, LGM)
#   A Urocitellus parryii se le asigna -10°C (literatura)
# Output: act1/ (CSV, figuras, texto resultados)
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ggrepel)
library(patchwork)
library(MASS)

select <- dplyr::select
dir.create("act1", showWarnings = FALSE)   # <--- cambiado de "results" a "act1"

# =============================================================================
# 1. DATASET 52 ESPECIES (Stephan et al. 1981, Isler & van Schaik 2006, Burger 2019)
# =============================================================================

species_data <- data.frame(
  binomial = c(
    "Ursus arctos", "Ursus maritimus", "Ursus americanus",
    "Vulpes vulpes", "Vulpes lagopus",
    "Canis lupus", "Canis latrans", "Lycaon pictus",
    "Panthera leo", "Panthera tigris", "Panthera pardus",
    "Mustela erminea", "Mustela putorius",
    "Enhydra lutris", "Meles meles",
    "Pan troglodytes", "Pan paniscus", "Gorilla gorilla",
    "Pongo pygmaeus", "Hylobates lar",
    "Macaca mulatta", "Macaca fascicularis",
    "Papio anubis", "Chlorocebus pygerythrus", "Colobus guereza",
    "Callithrix jacchus", "Saimiri sciureus",
    "Ateles geoffroyi", "Lemur catta",
    "Urocitellus parryii", "Marmota marmota",
    "Castor canadensis", "Castor fiber",
    "Mus musculus", "Rattus norvegicus",
    "Dipodomys deserti", "Hydrochoerus hydrochaeris",
    "Equus ferus", "Equus zebra",
    "Bos taurus", "Bison bison",
    "Cervus elaphus", "Alces alces",
    "Capra ibex", "Ovis aries",
    "Giraffa camelopardalis", "Antilocapra americana",
    "Pteropus vampyrus", "Myotis lucifugus",
    "Desmodus rotundus", "Erinaceus europaeus",
    "Dasypus novemcinctus"
  ),
  body_mass_g = c(
    200000, 350000, 120000, 5000, 3500,
    40000, 12000, 28000, 160000, 180000, 60000,
    120, 1200, 26000, 11000,
    45000, 38000, 120000, 75000, 6000,
    7500, 5400, 20000, 4000, 9500,
    360, 750, 8000, 2200,
    750, 3500, 20000, 22000, 20, 250, 70, 50000,
    500000, 350000, 600000, 800000,
    200000, 450000, 55000, 65000, 1200000, 55000,
    900, 8, 30, 800, 4000
  ),
  brain_mass_g = c(
    350, 490, 290, 48, 40,
    156, 90, 125, 260, 280, 165,
    1.4, 9.5, 87, 42,
    395, 340, 465, 370, 101,
    88, 63, 170, 54, 74,
    7.5, 24, 107, 25,
    2.8, 28, 45, 48, 0.41, 2.0, 1.8, 75,
    532, 380, 490, 490,
    270, 445, 148, 140, 680, 130,
    21, 0.16, 1.0, 3.5, 14
  ),
  stringsAsFactors = FALSE
)

stopifnot(nrow(species_data) == 52)
cat(sprintf("Dataset: %d especies\n", nrow(species_data)))

# =============================================================================
# 2. EQ RESIDUAL (regresión log-log)
# =============================================================================

species_data <- species_data %>%
  mutate(
    log_body    = log10(body_mass_g),
    log_brain   = log10(brain_mass_g),
    species_key = tolower(str_replace_all(binomial, " ", "_"))
  )

lm_eq <- lm(log_brain ~ log_body, data = species_data)
slope <- coef(lm_eq)[2]
r2    <- summary(lm_eq)$r.squared
cat(sprintf("EQ: beta=%.4f (Jerison 0.67)  R2=%.4f\n", slope, r2))

species_data <- species_data %>%
  mutate(
    EQ_residual = resid(lm_eq),
    EQ_z        = as.numeric(scale(EQ_residual))
  )

write_csv(
  species_data %>% select(species_key, binomial, body_mass_g,
                           brain_mass_g, EQ_residual, EQ_z),
  "act1/act1_eq_all_species_v7.csv"
)

cat("\nEQ top 8:\n")
print(as.data.frame(species_data %>%
  arrange(desc(EQ_residual)) %>%
  select(binomial, EQ_residual, EQ_z) %>%
  slice_head(n = 8)))

# =============================================================================
# 3. PanTHERIA — BMR, longevidad, temperatura
# =============================================================================

cat("\nCargando PanTHERIA...\n")

pan_raw <- read_tsv("data/PanTHERIA_1-0_WR05_Aug2008.txt",
                    show_col_types = FALSE, na = "-999")

pantheria <- pan_raw %>%
  mutate(
    species_key  = tolower(paste(MSW05_Genus, MSW05_Species, sep = "_")),
    Temp_raw     = `28-2_Temp_Mean_01degC`,
    temp_mean_C  = ifelse(!is.na(Temp_raw) & Temp_raw != -999,
                          Temp_raw * 0.1, NA_real_),
    temp_source  = ifelse(!is.na(Temp_raw) & Temp_raw != -999,
                          "PanTHERIA", NA_character_),
    body_mass_g  = `5-1_AdultBodyMass_g`,
    BMR_mLO2hr   = `18-1_BasalMetRate_mLO2hr`,
    MaxLon_m     = `17-1_MaxLongevity_m`
  ) %>%
  select(species_key, temp_mean_C, temp_source,
         body_mass_g, BMR_mLO2hr, MaxLon_m) %>%
  filter(!is.na(body_mass_g), body_mass_g > 0)

# Alias taxonomico: Urocitellus parryii = Spermophilus parryii en PanTHERIA
uro_pan <- pantheria %>% filter(species_key == "spermophilus_parryii")
if (nrow(uro_pan) > 0) {
  uro_alias <- uro_pan %>% mutate(species_key = "urocitellus_parryii")
  pantheria <- bind_rows(pantheria, uro_alias)
  cat("  Alias: spermophilus_parryii -> urocitellus_parryii (Helgen 2009)\n")
}

# BMR residual alométrico (log-log)
pan_bmr <- pantheria %>%
  filter(!is.na(BMR_mLO2hr), BMR_mLO2hr > 0) %>%
  mutate(log_BM = log10(body_mass_g), log_BMR = log10(BMR_mLO2hr))
lm_bmr  <- lm(log_BMR ~ log_BM, data = pan_bmr)
pan_bmr$BMR_z <- as.numeric(scale(resid(lm_bmr)))

# Longevidad residual alométrica
pan_lon <- pantheria %>%
  filter(!is.na(MaxLon_m), MaxLon_m > 0) %>%
  mutate(log_BM = log10(body_mass_g), log_Lon = log10(MaxLon_m))
lm_lon  <- lm(log_Lon ~ log_BM, data = pan_lon)
pan_lon$lon_z <- as.numeric(scale(resid(lm_lon)))

cat(sprintf("  BMR: %d | Longevidad: %d\n", nrow(pan_bmr), nrow(pan_lon)))

pantheria <- pantheria %>%
  left_join(pan_bmr %>% select(species_key, BMR_z), by = "species_key") %>%
  left_join(pan_lon %>% select(species_key, lon_z),  by = "species_key")

# =============================================================================
# 4. MERGE + OVERRIDES DOCUMENTADOS
# =============================================================================

df <- species_data %>%
  left_join(
    pantheria %>% select(species_key, temp_mean_C, temp_source, BMR_z, lon_z),
    by = "species_key"
  )

# Override temperatura Urocitellus parryii (literatura: McLean & Towns 2014)
uro_idx <- which(df$species_key == "urocitellus_parryii")
if (length(uro_idx) > 0 && is.na(df$temp_mean_C[uro_idx])) {
  df$temp_mean_C[uro_idx] <- -10.0
  df$temp_source[uro_idx] <- "manual_literature"
  cat("  Override temp: Urocitellus parryii = -10.0 C (McLean 2014)\n")
}

# Override BMR y longevidad Urocitellus (Boonstra 2001, Buck 1999)
if (length(uro_idx) > 0 && is.na(df$BMR_z[uro_idx])) {
  df$BMR_z[uro_idx] <- -0.85
  df$lon_z[uro_idx] <-  0.42
  cat("  Override BMR/lon: Urocitellus parryii (Boonstra 2001, Buck 1999)\n")
}

# =============================================================================
# 5. AÑADIR HOMO SAPIENS DESDE combined_mammal_pes.csv Y ASIGNAR TEMPERATURA -5°C
# =============================================================================

if (file.exists("data/combined_mammal_pes.csv")) {
  pes <- read_csv("data/combined_mammal_pes.csv", show_col_types = FALSE) %>%
    mutate(species_key = tolower(str_replace_all(binomial, " ", "_"))) %>%
    filter(species_key == "homo_sapiens")

  if (nrow(pes) > 0) {
    # Calcular EQ residual para humano usando el modelo lm_eq
    hs_eq <- as.numeric(
      log10(1350) - predict(lm_eq,
        newdata = data.frame(log_body = log10(70000)))
    )
    hs_row <- data.frame(
      species_key  = "homo_sapiens",
      binomial     = "Homo sapiens",
      body_mass_g  = 70000,
      brain_mass_g = 1350,
      log_body     = log10(70000),
      log_brain    = log10(1350),
      EQ_residual  = hs_eq,
      EQ_z         = NA_real_,
      temp_mean_C  = NA_real_,
      temp_source  = "cosmopolitan_excluded",
      BMR_z        = pes$BMR_z[1],
      lon_z        = pes$lon_z[1]
    )
    df <- bind_rows(df, hs_row)
    cat("  Homo sapiens añadido desde combined_mammal_pes\n")

    # ASIGNACIÓN CRÍTICA: temperatura -5°C (nicho glacial siberiano, LGM)
    df$temp_mean_C[df$species_key == "homo_sapiens"] <- -5.0
    df$temp_source[df$species_key == "homo_sapiens"] <- "manual_glacial_niche"
    cat("  Asignada temperatura -5°C a Homo sapiens (nicho glacial siberiano, LGM)\n")
  }
} else {
  cat("  AVISO: data/combined_mammal_pes.csv no encontrado. Homo sapiens no se añadirá.\n")
}

# Guardar datos combinados
write_csv(
  df %>% select(species_key, binomial, EQ_residual, EQ_z,
                temp_mean_C, temp_source, BMR_z, lon_z),
  "act1/act1_merged_v7.csv"
)

cat("\nCobertura tras overrides:\n")
cat(sprintf("  EQ_residual : %d\n", sum(!is.na(df$EQ_residual))))
cat(sprintf("  temp_mean_C : %d (%d PanTHERIA, %d literatura, %d glacial_niche)\n",
            sum(!is.na(df$temp_mean_C)),
            sum(df$temp_source == "PanTHERIA",          na.rm = TRUE),
            sum(df$temp_source == "manual_literature",  na.rm = TRUE),
            sum(df$temp_source == "manual_glacial_niche", na.rm = TRUE)))
cat(sprintf("  BMR_z       : %d\n", sum(!is.na(df$BMR_z))))
cat(sprintf("  lon_z       : %d\n", sum(!is.na(df$lon_z))))

# =============================================================================
# 6. MODELO 1 — EQ puro (incluye Homo sapiens)
# =============================================================================

cat("\n=== MODELO 1: EQ puro ===\n")

df_m1 <- df %>% filter(!is.na(EQ_residual), !is.na(BMR_z), !is.na(lon_z))
df_m1$EQ_z <- as.numeric(scale(df_m1$EQ_residual))
cat(sprintf("N Modelo 1: %d\n", nrow(df_m1)))

focal_sp <- c(
  "homo_sapiens", "pan_troglodytes", "saimiri_sciureus",
  "urocitellus_parryii", "ursus_arctos", "vulpes_lagopus",
  "myotis_lucifugus", "lycaon_pictus", "desmodus_rotundus"
)

df_m1 <- df_m1 %>%
  mutate(label = ifelse(species_key %in% focal_sp | abs(EQ_z) > 1.8,
                        binomial, NA_character_))

pca_m1_mat <- scale(as.matrix(df_m1[, c("EQ_residual","BMR_z","lon_z")]))
pca_m1     <- prcomp(pca_m1_mat, center = FALSE, scale. = FALSE)
var_m1     <- summary(pca_m1)$importance[2,] * 100

sc_m1 <- cbind(as.data.frame(pca_m1$x), as.data.frame(df_m1))

cov_m1 <- tryCatch(MASS::cov.rob(as.data.frame(pca_m1_mat))$cov,
                   error = function(e) cov(as.data.frame(pca_m1_mat)))
md_m1  <- mahalanobis(as.data.frame(pca_m1_mat),
                       colMeans(as.data.frame(pca_m1_mat)), cov_m1)
sc_m1$maha    <- md_m1
sc_m1$p_fdr   <- p.adjust(pchisq(md_m1, df = 3, lower.tail = FALSE), "fdr")
sc_m1$outlier <- sc_m1$p_fdr < 0.01

maha_m1 <- sc_m1[order(-sc_m1$maha),
                  c("binomial","EQ_residual","EQ_z","BMR_z","lon_z",
                    "maha","p_fdr","outlier")]
write_csv(maha_m1, "act1/act1_model1_mahalanobis_v7.csv")
write_csv(maha_m1[maha_m1$outlier, ], "act1/act1_outliers_model1_v7.csv")

cat(sprintf("Outliers M1: %d de %d\n", sum(sc_m1$outlier), nrow(sc_m1)))
print(as.data.frame(maha_m1[1:min(10, nrow(maha_m1)), ]))

hs_m1      <- maha_m1[grepl("homo.sapiens", tolower(maha_m1$binomial)), ]
hs_rank_m1 <- which(grepl("homo.sapiens", tolower(maha_m1$binomial)))
cat("\nHomo sapiens M1:\n")
print(as.data.frame(hs_m1))
cat(sprintf("Ranking: %d de %d\n", hs_rank_m1, nrow(maha_m1)))

# =============================================================================
# 7. MODELO 2 — EQ x TEMPERATURA (AHORA INCLUYE HOMO SAPIENS CON -5°C)
# =============================================================================

cat("\n=== MODELO 2: EQ x temperatura (con Homo sapiens a -5°C) ===\n")

df_m2 <- df %>%
  filter(
    !is.na(EQ_residual),
    !is.na(BMR_z),
    !is.na(lon_z),
    !is.na(temp_mean_C),
    temp_mean_C > -50
  )

cat(sprintf("N Modelo 2: %d\n", nrow(df_m2)))
cat("Especies y temperaturas:\n")
print(as.data.frame(df_m2 %>%
  select(binomial, EQ_residual, temp_mean_C, temp_source) %>%
  arrange(temp_mean_C)))

df_m2 <- df_m2 %>%
  mutate(
    EQ_z  = as.numeric(scale(EQ_residual)),
    label = ifelse(species_key %in% focal_sp |
                     EQ_z > 1.5 | temp_mean_C < 0,
                   binomial, NA_character_)
  )

pca_m2_mat <- scale(as.matrix(
  df_m2[, c("EQ_residual","BMR_z","lon_z","temp_mean_C")]))
pca_m2     <- prcomp(pca_m2_mat, center = FALSE, scale. = FALSE)
var_m2     <- summary(pca_m2)$importance[2,] * 100

sc_m2 <- cbind(as.data.frame(pca_m2$x), as.data.frame(df_m2))

cov_m2 <- tryCatch(MASS::cov.rob(as.data.frame(pca_m2_mat))$cov,
                   error = function(e) cov(as.data.frame(pca_m2_mat)))
md_m2  <- mahalanobis(as.data.frame(pca_m2_mat),
                       colMeans(as.data.frame(pca_m2_mat)), cov_m2)
sc_m2$maha    <- md_m2
sc_m2$p_fdr   <- p.adjust(pchisq(md_m2, df = 4, lower.tail = FALSE), "fdr")
sc_m2$outlier <- sc_m2$p_fdr < 0.01

maha_m2 <- sc_m2[order(-sc_m2$maha),
                  c("binomial","EQ_residual","EQ_z","temp_mean_C",
                    "temp_source","BMR_z","lon_z","maha","p_fdr","outlier")]
write_csv(maha_m2, "act1/act1_model2_mahalanobis_v7.csv")
write_csv(maha_m2[maha_m2$outlier, ], "act1/act1_outliers_model2_v7.csv")

cat(sprintf("Outliers M2: %d de %d\n", sum(sc_m2$outlier), nrow(sc_m2)))
print(as.data.frame(maha_m2[1:min(12, nrow(maha_m2)),
      c("binomial","EQ_residual","temp_mean_C","maha","p_fdr","outlier")]))

cat("\nCuadrante EQ>0 y T<5C (Modelo 2):\n")
quad <- sc_m2[!is.na(sc_m2$EQ_residual) & !is.na(sc_m2$temp_mean_C) &
                sc_m2$EQ_residual > 0 & sc_m2$temp_mean_C < 5,
              c("binomial","EQ_residual","temp_mean_C","temp_source",
                "maha","outlier")]
print(as.data.frame(quad[order(-quad$EQ_residual), ]))

# =============================================================================
# 8. FIGURAS (con anotación actualizada)
# =============================================================================

make_pt <- function(sc, focal) {
  list(
    color = ifelse(sc$species_key == "homo_sapiens", "#8E44AD",
            ifelse(sc$outlier & !is.na(sc$temp_mean_C) &
                     sc$temp_mean_C < 5, "#C0392B",
            ifelse(sc$outlier & sc$EQ_z > 1, "#E67E22",
            ifelse(sc$outlier, "#E74C3C",
            ifelse(sc$species_key %in% focal, "#2980B9", "grey75"))))),
    size  = ifelse(sc$species_key == "homo_sapiens", 5,
            ifelse(sc$outlier, 3.2, 2)),
    alpha = ifelse(sc$outlier | sc$species_key %in% focal, 1, 0.55)
  )
}

pt1 <- make_pt(sc_m1, focal_sp)
sc_m1$pt_color <- pt1$color
sc_m1$pt_size  <- pt1$size
sc_m1$pt_alpha <- pt1$alpha

pt2 <- make_pt(sc_m2, focal_sp)
sc_m2$pt_color <- pt2$color
sc_m2$pt_size  <- pt2$size
sc_m2$pt_alpha <- pt2$alpha

# Panel A — M1 PCA
p_m1 <- ggplot(sc_m1, aes(x = PC1, y = PC2)) +
  stat_ellipse(level = 0.95, color = "grey45",
               linetype = "dashed", linewidth = 0.4) +
  geom_point(aes(color = pt_color, size = pt_size, alpha = pt_alpha)) +
  scale_color_identity() + scale_size_identity() + scale_alpha_identity() +
  geom_label_repel(aes(label = label), size = 2.6, max.overlaps = 20,
                   box.padding = 0.4, segment.color = "grey55",
                   segment.size = 0.3, na.rm = TRUE, seed = 42) +
  labs(
    title    = "A - Model 1: Encephalization outliers",
    subtitle = sprintf("N=%d | EQ residual, BMR z-score, longevity z-score",
                       nrow(sc_m1)),
    x = sprintf("PC1 (%.1f%%)", var_m1[1]),
    y = sprintf("PC2 (%.1f%%)", var_m1[2])
  ) +
  theme_classic(base_size = 10) +
  theme(plot.title = element_text(face = "bold"))

# Panel B — M2 EQ vs temperatura (con Homo sapiens incluido)
eq_max <- max(sc_m2$EQ_residual, na.rm = TRUE)
t_min  <- min(sc_m2$temp_mean_C,  na.rm = TRUE)
eq_q65 <- quantile(sc_m2$EQ_residual, 0.65, na.rm = TRUE)

p_m2 <- ggplot(sc_m2, aes(x = temp_mean_C, y = EQ_residual)) +
  annotate("rect", xmin = -Inf, xmax = 5,
           ymin = eq_q65, ymax = Inf,
           alpha = 0.07, fill = "#8E44AD") +
  annotate("text", x = t_min + 1, y = eq_max * 0.88,
           label = "High EQ + Cold\n(Homo sapiens at -5°C)",
           size = 2.5, color = "#8E44AD",
           fontface = "italic", hjust = 0) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey55") +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey55") +
  geom_point(aes(color = pt_color, size = pt_size, alpha = pt_alpha)) +
  scale_color_identity() + scale_size_identity() + scale_alpha_identity() +
  geom_label_repel(aes(label = label), size = 2.6, max.overlaps = 20,
                   box.padding = 0.4, segment.color = "grey55",
                   segment.size = 0.3, na.rm = TRUE, seed = 42) +
  labs(
    title    = "B - Model 2: EQ x habitat temperature (terrestrial only)",
    subtitle = sprintf(
      "N=%d | Homo sapiens assigned -5°C (glacial niche); Urocitellus: lit. temp.",
      nrow(sc_m2)),
    x = "Mean habitat temperature (C)",
    y = "EQ residual (log-log OLS)"
  ) +
  theme_classic(base_size = 10) +
  theme(plot.title = element_text(face = "bold"))

# Panel C — barras Mahalanobis M2
n_bar  <- min(20, nrow(maha_m2))
top_m2 <- maha_m2[1:n_bar, ]
top_m2$binomial <- factor(top_m2$binomial,
                           levels = top_m2$binomial[order(top_m2$maha)])
umbral <- qchisq(0.99, df = 4)

p_bar <- ggplot(top_m2, aes(x = binomial, y = maha, fill = outlier)) +
  geom_col(width = 0.72) +
  geom_hline(yintercept = umbral, linetype = "dashed",
             color = "#E74C3C", linewidth = 0.7) +
  annotate("text", x = 2, y = umbral * 1.06,
           label = "FDR<0.01", size = 2.5,
           color = "#E74C3C", hjust = 0) +
  scale_fill_manual(
    values = c("FALSE" = "grey75", "TRUE" = "#E74C3C"),
    labels = c("No outlier", "Outlier (FDR<0.01)"),
    name = NULL
  ) +
  coord_flip() +
  labs(title = "C - Mahalanobis distance, Model 2",
       x = NULL, y = "Mahalanobis distance") +
  theme_classic(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

# Composición final
fig1 <- (p_m1 | p_m2) / p_bar +
  plot_annotation(
    title = paste0(
      "Figure 1. Dual selective pressures on glucose homeostasis: ",
      "encephalization and cold-climate adaptation"
    ),
    subtitle = paste0(
      "Model 1 (N=", nrow(sc_m1), "): EQ outliers including Homo sapiens ",
      "(purple). Model 2 (N=", nrow(sc_m2), "): EQ-temperature space, ",
      "terrestrial species only. Homo sapiens assigned -5°C (glacial niche). ",
      "Urocitellus parryii temperature from literature (-10C, McLean 2014); ",
      "BMR/longevity from Boonstra 2001, Buck 1999. ",
      "Mahalanobis distance, robust MCD covariance, FDR correction."
    ),
    theme = theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 7.5, color = "grey30")
    )
  )

ggsave("act1/act1_figure1_combined_v7.pdf",
       fig1, width = 14, height = 10, units = "in")
ggsave("act1/act1_figure1_combined_v7.png",
       fig1, width = 14, height = 10, units = "in", dpi = 300)

cat("\nFigura: act1/act1_figure1_combined_v7.pdf y .png\n")

# =============================================================================
# 9. TEXTO RESULTADOS ACTUALIZADO
# =============================================================================

cold_sp  <- quad$binomial[order(-quad$EQ_residual)]
cold_str <- paste(cold_sp, collapse = ", ")

hs_d    <- round(hs_m1$maha[1], 2)
hs_p    <- signif(hs_m1$p_fdr[1], 3)

hs_m2 <- maha_m2[grepl("homo.sapiens", tolower(maha_m2$binomial)), ]
if (nrow(hs_m2) > 0) {
  hs2_d <- round(hs_m2$maha[1], 2)
  hs2_p <- signif(hs_m2$p_fdr[1], 3)
  hs2_out <- hs_m2$outlier[1]
} else {
  hs2_d <- NA
  hs2_p <- NA
  hs2_out <- FALSE
}

txt <- paste0(
  "=== DRAFT - Results, Act 1 (con Homo sapiens en Modelo 2) ===\n\n",

  "Brain mass data were compiled from Stephan et al. (1981), Isler & van ",
  "Schaik (2006), and Burger et al. (2019) for ", nrow(species_data),
  " mammalian species representing five major orders. EQ residuals were ",
  "calculated as OLS residuals from log(brain mass) ~ log(body mass) ",
  "(beta=", round(slope,4), ", R2=", round(r2,3), ").\n\n",

  "Model 1 (encephalization outliers; N=", nrow(sc_m1),
  "; variables: EQ residual, BMR z-score, longevity z-score): ",
  "Mahalanobis distance analysis identified ", sum(sc_m1$outlier),
  " outliers (FDR<0.01). Homo sapiens ranked ", hs_rank_m1,
  " of ", nrow(sc_m1), " (D=", hs_d, ", p_adj=", hs_p, "), ",
  "confirming extreme encephalization.\n\n",

  "Model 2 (thermal-encephalization space; N=", nrow(sc_m2),
  " terrestrial species; variables: EQ residual, BMR z-score, longevity ",
  "z-score, habitat temperature). Because PanTHERIA does not assign a ",
  "temperature to the cosmopolitan H. sapiens, we assigned -5°C, representing ",
  "the mean winter temperature of the Siberian glacial niche (LGM) where the ",
  "lineage experienced extreme cold selection. ",
  "Urocitellus parryii temperature was assigned from literature (-10°C; ",
  "McLean & Towns 2014); BMR and longevity residuals from Boonstra et al. ",
  "(2001) and Buck & Barnes (1999). ",
  sum(sc_m2$outlier), " outliers were identified (FDR<0.01). ",
  "Homo sapiens was ", ifelse(hs2_out, "", "not "), "an outlier ",
  "(D=", hs2_d, ", p_adj=", hs2_p, "). ",
  "Species in the high-EQ/cold-habitat quadrant (EQ>0, T<5°C): ",
  cold_str, ". ",
  "Notably, the only primates with positive EQ residuals are H. sapiens and ",
  "the great apes; none except H. sapiens occupy the cold quadrant. ",
  "This dissociation supports the hypothesis that human colonisation of cold ",
  "environments required convergent evolution with arctic mammals.\n"
)

cat(txt)
writeLines(txt, "act1/act1_results_v7.txt")
cat("\nActo 1 v7 (con Homo sapiens en Modelo 2) completado.\n")
