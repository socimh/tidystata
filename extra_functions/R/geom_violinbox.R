geom_violinbox <- function() {
  list(
    geom_violin(
      trim = TRUE,
      width = 0.8
    ),
    geom_boxplot(
      outlier.shape = NA,
      notch = TRUE,
      width = .15
    )
  ) %>%
    invisible()
}

geom_box <- function() {
  geom_boxplot(
    notch = TRUE,
    outlier.shape = 21,
    outlier.size = 5,
    outlier.stroke = 1,
    outlier.alpha = .75,
    width = .3
  ) %>%
    invisible()
}