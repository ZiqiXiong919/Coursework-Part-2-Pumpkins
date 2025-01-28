library(ggplot2)
library(dplyr)
library(pheatmap)
library(readr)
library(ggrepel)
file1 <- "A_vs_B.deseq2.results.tsv"
file2 <- "A_vs_F.deseq2.results.tsv"
data1 <- read_tsv("C:/Users/Xiong/Desktop/LIFE4138/A_vs_B.deseq2.results.tsv")
data2 <- read_tsv("C:/Users/Xiong/Desktop/LIFE4138/A_vs_F.deseq2.results.tsv")
data1 <- data1 %>% filter(!is.na(padj) & !is.na(log2FoldChange))
data2 <- data2 %>% filter(!is.na(padj) & !is.na(log2FoldChange))

pval_threshold <- 0.05
logfc_threshold <- 1
analyze_dge <- function(data, comparison_name) {
  data <- data %>%
    mutate(Significance = case_when(
      padj < pval_threshold & log2FoldChange > logfc_threshold ~ "Upregulated",
      padj < pval_threshold & log2FoldChange < -logfc_threshold ~ "Downregulated",
      TRUE ~ "Not Significant"
    ))
  upregulated <- nrow(data %>% filter(Significance == "Upregulated"))
  downregulated <- nrow(data %>% filter(Significance == "Downregulated"))
  
  summary_stats <- data.frame(
    Comparison = comparison_name,
    Total_Genes = nrow(data),
    Upregulated = upregulated,
    Downregulated = downregulated
  )
  
# Valcano
  volcano_plot <- ggplot(data, aes(x = log2FoldChange, y = -log10(padj), color = Significance)) +
    geom_point(alpha = 0.6) +
    scale_color_manual(values = c("Upregulated" = "red", "Downregulated" = "blue", "Not Significant" = "grey")) +
    theme_minimal() +
    labs(title = paste("Volcano Plot -", comparison_name), x = "Log2 Fold Change", y = "-log10(padj)")
  
# MA
  ma_plot <- ggplot(data, aes(x = baseMean, y = log2FoldChange, color = Significance)) +
    geom_point(alpha = 0.6) +
    scale_color_manual(values = c("Upregulated" = "red", "Downregulated" = "blue", "Not Significant" = "grey")) +
    scale_x_log10() +
    theme_minimal() +
    labs(title = paste("MA Plot -", comparison_name), x = "Mean Expression (log scale)", y = "Log2 Fold Change")
# Pval
  pval_histogram <- ggplot(data, aes(x = padj)) +
    geom_histogram(bins = 50, fill = "blue") +
    theme_minimal() +
    labs(title = paste("P-value Distribution -", comparison_name), x = "Adjusted P-value", y = "Frequency")
  
# Heatmap
  top_genes <- data %>%
    filter(Significance %in% c("Upregulated", "Downregulated")) %>%
    arrange(padj) %>%
    head(50)
  
  if (nrow(top_genes) > 0) {
    heatmap_data <- as.matrix(top_genes$log2FoldChange)
    rownames(heatmap_data) <- top_genes$gene_id
    heatmap <- pheatmap(heatmap_data, cluster_rows = TRUE, cluster_cols = FALSE,
                        show_rownames = TRUE, main = paste("Top Genes Heatmap -", comparison_name))
  } else {
    heatmap <- NULL
  }
  
  list(
    summary_stats = summary_stats,
    volcano_plot = volcano_plot,
    ma_plot = ma_plot,
    pval_histogram = pval_histogram,
    heatmap = heatmap,
    significant_genes = top_genes
  )
}

result1 <- analyze_dge(data1, "A_vs_B")
result2 <- analyze_dge(data2, "A_vs_F")

write.csv(result1$summary_stats, "C:/Users/Xiong/Desktop/LIFE4138/summary_stats_A_vs_B.csv", row.names = FALSE)
write.csv(result2$summary_stats, "C:/Users/Xiong/Desktop/LIFE4138/summary_stats_A_vs_F.csv", row.names = FALSE)

ggsave("C:/Users/Xiong/Desktop/LIFE4138/volcano_A_vs_B.png", result1$volcano_plot)
ggsave("C:/Users/Xiong/Desktop/LIFE4138/volcano_A_vs_F.png", result2$volcano_plot)

ggsave("C:/Users/Xiong/Desktop/LIFE4138/ma_plot_A_vs_B.png", result1$ma_plot)
ggsave("C:/Users/Xiong/Desktop/LIFE4138/ma_plot_A_vs_F.png", result2$ma_plot)

ggsave("C:/Users/Xiong/Desktop/LIFE4138/pval_histogram_A_vs_B.png", result1$pval_histogram)
ggsave("C:/Users/Xiong/Desktop/LIFE4138/pval_histogram_A_vs_F.png", result2$pval_histogram)

write.csv(result1$significant_genes, "C:/Users/Xiong/Desktop/LIFE4138/significant_genes_A_vs_B.csv", row.names = FALSE)
write.csv(result2$significant_genes, "C:/Users/Xiong/Desktop/LIFE4138/significant_genes_A_vs_F.csv", row.names = FALSE)

