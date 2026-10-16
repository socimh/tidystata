#' Quick plot
#' 
#' @param data A data frame or tibble.
#' @param x A column name.
#' @param y A column name (optional).
#' @param ... Other arguments to be passed to the `qplot()` function.
#' @inheritParams ggplot2::qplot
#' 
#' @export
s_plot <- function(data, x, y, ..., geom = "auto",
                   main, xlab, ylab, asp) {
  with_x <- !missing(x)
  with_y <- !missing(y)

  if (with_x) {
    if (data %>%
      s_select({{ x }}) %>%
      ncol() != 1) {
      stop("x must be a single column.", call. = FALSE)
    }
  }
  if (with_y) {
    if (data %>%
      s_select({{ y }}) %>%
      ncol() != 1) {
      stop("y must be a single column.", call. = FALSE)
    }
  }
  if (!with_x && !with_y) {
    stop("At least one of x and y must be specified.", call. = FALSE)
  }

  if (with_x) {
    x_vec <- data %>%
      s_select({{ x }}) %>%
      dplyr::pull(1)
    x_type <- s_type(x_vec)

    if (stringr::str_detect(x_type, "label")) {
      data <- data %>%
        dplyr::mutate({{ x }} := haven::as_factor({{ x }}))
      x_type <- "factor"
    }

    x_is_numeric <- stringr::str_detect(x_type, "integer|double")

    if (x_is_numeric) {
      x_is_integer <- mean(as.integer(x_vec) == x_vec, na.rm = TRUE) == 1
    } else {
      x_is_integer <- FALSE
    }

    if (x_is_integer) {
      range <- data %>%
        dplyr::summarise(
          range = max({{ x }}, na.rm = TRUE) - min({{ x }}, na.rm = TRUE)
        ) %>%
        dplyr::pull(range)
      if (range > 30) {
        x_is_integer <- FALSE
      }
    }
  }

  if (with_y) {
    y_type <- data %>%
      s_select({{ y }}) %>%
      dplyr::pull(tidyselect::last_col()) %>%
      s_type()

    if (stringr::str_detect(y_type, "label")) {
      data <- data %>%
        dplyr::mutate({{ y }} := haven::as_factor({{ y }}))
      y_type <- "factor"
    }

    y_is_numeric <- stringr::str_detect(y_type, "integer|double")
  }

  change_ggplot_style()

  # change default ggplot2 settings
  if (geom[1] == "auto") {
    if (!with_y) {
      if (x_is_integer) {
        gg <- ggplot2::ggplot(data) +
          ggplot2::geom_histogram(
            mapping = ggplot2::aes(x = {{ x }}),
            binwidth = .5,
            center = 0,
            ...
          ) +
          ggplot2::labs(
            y = "count"
          )

        if (range <= 30) {
          gg <- gg +
            ggplot2::scale_x_continuous(
              breaks = data %>%
                dplyr::count({{ x }}) %>%
                dplyr::pull({{ x }})
            )
        }
      } else if (x_is_numeric) {
        gg <- ggplot2::qplot(
          data = data, x = {{ x }},
          geom = "histogram", ylab = "count",
          ...
        )
      } else {
        gg <- ggplot2::ggplot(data) +
          ggplot2::geom_bar(
            mapping = ggplot2::aes(x = {{ x }}),
            width = .4,
            ...
          ) +
          ggplot2::labs(
            y = "count"
          )
      }
    } else if (!with_x) {
      gg <- ggplot2::qplot(
        data = data, x = seq_along({{ y }}), y = {{ y }},
        geom = "point", xlab = "observation", ...
      )
    } else if (!x_is_numeric && y_is_numeric) {
      data2 <- data %>%
        s_select({{ x }}, {{ y }}) %>%
        dplyr::rename_with(
          ~ c("x", "y")
        ) %>%
        dplyr::summarise(
          y = mean(y, na.rm = TRUE),
          .by = x
        )
      gg <- ggplot2::ggplot(data) +
        ggplot2::aes(x = {{ x }}, y = {{ y }}) +
        ggplot2::geom_violin(
          scale = "width",
          trim = TRUE,
          width = .9
        ) +
        ggplot2::geom_boxplot(
          outlier.shape = NA,
          width = .15
        ) +
        ggplot2::geom_point(
          data = data2,
          mapping = ggplot2::aes(x, y),
          size = 3,
          fill = "firebrick",
          alpha = .9,
          shape = 23
        )
    } else if (x_is_numeric + y_is_numeric == 0) {
      data2 <- data %>%
        dplyr::add_count({{ x }}, {{ y }}, name = "...count")
      gg <- data2 %>%
        ggplot2::ggplot() +
        ggplot2::geom_tile(
          mapping = ggplot2::aes(x = {{ x }}, y = {{ y }}, fill = ...count),
          ...
        ) +
        ggplot2::scale_fill_distiller(
          "count",
          palette = "YlOrRd",
          direction = 1
        )
    } else {
      gg <- ggplot2::ggplot(data) +
        ggplot2::aes(x = {{ x }}, y = {{ y }}) +
        ggplot2::geom_point() +
        ggplot2::geom_smooth(
          method = "loess", formula = y ~ x
        )
    }
  } else {
    if (!with_y) {
      gg <- ggplot2::qplot(
        data = data, x = {{ x }},
        geom = geom, ...
      )
    } else if (!with_x) {
      gg <- ggplot2::qplot(
        data = data, y = {{ y }},
        geom = geom, ...
      )
    } else {
      gg <- ggplot2::qplot(
        data = data, x = {{ x }}, y = {{ y }},
        geom = geom, ...
      )
    }
  }

  return(gg)
}

# Author: Leonard Blechman
# copy from https://copyprogramming.com/howto/change-geom-default-aesthetics-as-part-of-theme-component-only#theme-overrides-geompointrange
geom_aes_defaults <- function() {
  geom_names <- apropos("^Geom", ignore.case = FALSE)
  geoms <- mget(geom_names, envir = asNamespace("ggplot2"))
  purrr::map(geoms, ~ .$default_aes)
}

# Author: Leonard Blechman
# copy from https://copyprogramming.com/howto/change-geom-default-aesthetics-as-part-of-theme-component-only#theme-overrides-geompointrange
replace_geom_aes_defaults <- function(name, old_aes, new_aes) {
  matching_geoms <-
    purrr::map(geom_aes_defaults(), name) %>%
    purrr::compact() %>%
    purrr::keep(~ !is.na(.) & . == old_aes)
  geoms <- gsub("^Geom(.*)", "\\1", names(matching_geoms))
  purrr::walk(geoms, update_geom_defaults, setNames(list(new_aes), name))
}

aes_to_single_tbl <- function(aes) {
  tb <- purrr::map(geom_aes_defaults(), aes) %>%
    purrr::compact() %>%
    tibble::as_tibble() %>%
    tidyr::pivot_longer(
      tidyselect::everything(),
      names_to = "geom",
      values_to = aes
    )
  return(tb)
}

aes_to_tbl <- function() {
  possible_aes <- c(
    "linetype", "linewidth", "colour", "fill", "weight", "size", "stroke",
    "shape", "alpha", "hjust", "vjust", "angle", "family", "fontface"
  )
  replace_geom_aes_defaults("linetype", "solid", 1)

  purrr::map(possible_aes, aes_to_single_tbl) %>%
    purrr::reduce(~ dplyr::full_join(.x, .y, by = dplyr::join_by(geom))) %>%
    dplyr::arrange(geom) %>%
    dplyr::mutate(
      Geometry = geom,
      geom = stringr::str_extract(geom, "(?<=Geom)\\w+$") %>%
        stringr::str_to_lower(),
      .before = 1
    )
}


theme_statart <- function(base_size = 18, base_family = "",
                          base_line_size = base_size / 22,
                          base_rect_size = base_size / 22) {
  # Starts with theme_bw() and then modify some parts
  ggplot2::theme_bw(
    base_size = base_size,
    base_family = base_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size
  ) %+replace%
    ggplot2::theme(
      legend.key.height = grid::unit(1, "cm")
    )
}

#' @importFrom ggplot2 update_geom_defaults aes
change_ggplot_style <- function() {
  ggplot2::theme_set(theme_statart())

  replace_geom_aes_defaults("linetype", "solid", 1)
  replace_geom_aes_defaults("colour", "#3366FF", "firebrick")
  replace_geom_aes_defaults("fill", "grey60", "firebrick")
  replace_geom_aes_defaults("fill", "grey20", "lightgray")
  replace_geom_aes_defaults("fill", "grey35", "lightgray")
  replace_geom_aes_defaults("fill", "grey50", "lightgray")

  lines <- c(
    "abline", "function", "hline", "vline", "line",
    "path", "segment", "step"
  )
  lines %>%
    purrr::map(~ update_geom_defaults(.x, ggplot2::aes(linewidth = 1)))
  update_geom_defaults("area", ggplot2::aes(alpha = .5))
  update_geom_defaults("bar", ggplot2::aes(color = "black"))
  update_geom_defaults("boxplot", ggplot2::aes(alpha = .5))
  update_geom_defaults("col", ggplot2::aes(color = "black"))
  update_geom_defaults("label", ggplot2::aes(size = 5))
  update_geom_defaults(
    "point", 
    ggplot2::aes(fill = "lightgray", shape = 21, size = 5, alpha = 0.75)
  )
  update_geom_defaults(
    "sf",
    ggplot2::aes(
      color = "black", fill = "lightgray")
  )
  update_geom_defaults("text", ggplot2::aes(size = 5))
  update_geom_defaults("violin", ggplot2::aes(fill = "lightgray"))
}
