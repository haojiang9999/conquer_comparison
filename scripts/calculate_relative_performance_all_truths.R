args <- (commandArgs(trailingOnly = TRUE))
for (i in 1:length(args)) {
  eval(parse(text = args[[i]]))
}

suppressPackageStartupMessages(library(iCOBRA))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(reshape2))

print(dataset)
print(filt)

if (filt == "") {
  exts <- filt
} else {
  exts <- paste0("_", filt)
}

get_method <- function(x) sapply(strsplit(x, "\\."), .subset, 1)
get_nsamples <- function(x) sapply(strsplit(x, "\\."), .subset, 2)
get_repl <- function(x) sapply(strsplit(x, "\\."), .subset, 3)

cobratmp <- readRDS(paste0("figures/cobra_data/", dataset, exts, "_cobra.rds"))
pval(cobratmp)[is.na(pval(cobratmp))] <- 1
padj(cobratmp)[is.na(padj(cobratmp))] <- 1

summary_data <- list()

fdr_all <- list()
fpr_all <- list()
tpr_all <- list()
f1_all <- list()

for (m in gsub("\\.truth", "", grep("\\.truth", colnames(truth(cobratmp)), value = TRUE))) {
  message(m)
  cobrares <- calculate_performance(cobratmp, onlyshared = FALSE, 
                                    aspects = c("tpr", "fpr", "fdrtpr"), 
                                    binary_truth = paste0(m, ".truth"), 
                                    thrs = 0.05)
  fdr_all[[m]] <- data.frame(fdrtpr(cobrares)[, c("method", "FDR")], 
                             truth = paste0(m, " (", sum(truth(cobratmp)[, paste0(m, ".truth")], 
                                                         na.rm = TRUE), ")"),
                             stringsAsFactors = FALSE)
  fpr_all[[m]] <- data.frame(fpr(cobrares)[, c("method", "FPR")], 
                             truth = paste0(m, " (", sum(truth(cobratmp)[, paste0(m, ".truth")], 
                                                         na.rm = TRUE), ")"),
                             stringsAsFactors = FALSE)
  tpr_all[[m]] <- data.frame(tpr(cobrares)[, c("method", "TPR")], 
                             truth = paste0(m, " (", sum(truth(cobratmp)[, paste0(m, ".truth")], 
                                                         na.rm = TRUE), ")"),
                             stringsAsFactors = FALSE)
  tmp <- fdrtpr(cobrares) %>% dplyr::mutate(F1 = 2*TP/(2*TP + FN + FP))
  f1_all[[m]] <- data.frame(tmp[, c("method", "F1")],
                            truth = paste0(m, " (", sum(truth(cobratmp)[, paste0(m, ".truth")],
                                                        na.rm = TRUE), ")"),
                            stringsAsFactors = FALSE)
}
RES <- list(fdr = do.call(rbind, fdr_all) %>% dcast(truth ~ method, value.var = "FDR") %>% as.data.frame(),
            fpr = do.call(rbind, fpr_all) %>% dcast(truth ~ method, value.var = "FPR") %>% as.data.frame(),
            tpr = do.call(rbind, tpr_all) %>% dcast(truth ~ method, value.var = "TPR") %>% as.data.frame(),
            f1 = do.call(rbind, f1_all) %>% dcast(truth ~ method, value.var = "F1") %>% as.data.frame())
RES <- lapply(RES, function(tb) {
  rownames(tb) <- tb$truth
  tb$truth <- NULL
  tb[order(rownames(tb)), ]
})

saveRDS(RES, file = paste0("figures/results_relativetruth_all/", dataset, exts, "_relative_performance.rds"))

sessionInfo()