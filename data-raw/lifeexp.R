# Opt-in build of `lifeexp` from World Bank World Development Indicators (WDI),
# licensed CC BY 4.0. Run from the package root.
#
# The first run downloads 1998 values (2000 for safe water, the earliest WDI
# year) for the 68 countries of the historical dataset and saves a dated
# snapshot to data-raw/lifeexp-wdi.csv. Later runs rebuild data/lifeexp.rda
# from that snapshot, so the shipped object is reproducible after WDI revisions.
# Delete the snapshot to refresh it from the API.
local({
  snapshot <- "data-raw/lifeexp-wdi.csv"

  # Region codes and country order follow the historical dataset.
  countries <- data.frame(
    region = rep(1:3, c(44L, 14L, 10L)),
    iso3c = c(
      "ALB",
      "ARM",
      "AUT",
      "AZE",
      "BLR",
      "BEL",
      "BIH",
      "BGR",
      "HRV",
      "CZE",
      "DNK",
      "EST",
      "FIN",
      "FRA",
      "GEO",
      "DEU",
      "GRC",
      "HUN",
      "IRL",
      "ITA",
      "KAZ",
      "KGZ",
      "LVA",
      "LTU",
      "MKD",
      "MDA",
      "NLD",
      "NOR",
      "POL",
      "PRT",
      "ROU",
      "RUS",
      "SVK",
      "SVN",
      "ESP",
      "SWE",
      "CHE",
      "TJK",
      "TUR",
      "TKM",
      "UKR",
      "GBR",
      "UZB",
      "SRB",
      "CAN",
      "CUB",
      "DOM",
      "SLV",
      "GTM",
      "HTI",
      "HND",
      "JAM",
      "MEX",
      "NIC",
      "PAN",
      "PRI",
      "TTO",
      "USA",
      "ARG",
      "BOL",
      "BRA",
      "CHL",
      "COL",
      "ECU",
      "PRY",
      "PER",
      "URY",
      "VEN"
    )
  )

  if (!file.exists(snapshot)) {
    fetch <- function(indicator, year) {
      url <- sprintf(
        "https://api.worldbank.org/v2/country/%s/indicator/%s?date=%d&format=json&per_page=100",
        paste(countries$iso3c, collapse = ";"),
        indicator,
        year
      )
      rows <- jsonlite::fromJSON(url)[[2]]
      stopifnot(setequal(rows$countryiso3code, countries$iso3c))
      list(
        value = rows$value[match(countries$iso3c, rows$countryiso3code)],
        country = rows$country$value[match(
          countries$iso3c,
          rows$countryiso3code
        )]
      )
    }
    life <- fetch("SP.DYN.LE00.IN", 1998)
    raw <- data.frame(
      countries,
      country = life$country,
      popgrowth = fetch("SP.POP.GROW", 1998)$value,
      lexp = life$value,
      gnppc = fetch("NY.GNP.PCAP.CD", 1998)$value,
      safewater = fetch("SH.H2O.SMDW.ZS", 2000)$value,
      retrieved = format(Sys.Date())
    )
    utils::write.csv(raw, snapshot, row.names = FALSE, fileEncoding = "UTF-8")
    message("lifeexp: saved WDI snapshot to ", snapshot, ".")
  }

  raw <- utils::read.csv(snapshot, encoding = "UTF-8", stringsAsFactors = FALSE)
  stopifnot(identical(raw$iso3c, countries$iso3c))
  retrieved <- unique(raw$retrieved)
  stopifnot(length(retrieved) == 1L)

  labelled <- function(x, label) {
    attr(x, "label") <- label
    x
  }
  lifeexp <- tibble::tibble(
    region = haven::labelled(
      as.double(raw$region),
      labels = c(
        "Europe & C. Asia" = 1,
        "North America" = 2,
        "South America" = 3
      ),
      label = "Region"
    ),
    country = labelled(raw$country, "Country"),
    popgrowth = labelled(round(raw$popgrowth, 1), "Avg. annual % growth"),
    lexp = labelled(round(raw$lexp), "Life expectancy at birth"),
    gnppc = labelled(round(raw$gnppc), "GNP per capita"),
    safewater = labelled(round(raw$safewater), "Safe water")
  )
  attr(lifeexp, "label") <- "Life expectancy, 1998"
  attr(lifeexp, "notes") <- c(
    paste0(
      "Source: World Bank, World Development Indicators (CC BY 4.0), retrieved ",
      retrieved,
      "."
    ),
    "Indicators: SP.POP.GROW, SP.DYN.LE00.IN, NY.GNP.PCAP.CD (1998) and SH.H2O.SMDW.ZS (2000).",
    "Values are rounded; safe water is the earliest available year, 2000."
  )
  save(lifeexp, file = "data/lifeexp.rda", compress = "bzip2", version = 2)
  message("lifeexp: wrote data/lifeexp.rda from the ", retrieved, " snapshot.")
})
