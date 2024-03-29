#  input: a named list, usually an instance of googlesheets4_schema_Spreadsheet
# output: instance of googlesheets4_spreadsheet, which is actually useful
new_googlesheets4_spreadsheet <- function(x = list()) {
  ours_theirs <- list(
    spreadsheet_id  = "spreadsheetId",
    spreadsheet_url = "spreadsheetUrl",
    name            = list("properties", "title"),
    locale          = list("properties", "locale"),
    time_zone       = list("properties", "timeZone")
  )
  out <- map(ours_theirs, ~ pluck(x, !!!.x, .default = "<unknown>"))

  if (!is.null(x$sheets)) {
    sheets <- map(x$sheets, ~ new("Sheet", !!!.x))
    sheet_properties <- map(sheets, as_tibble)
    out$sheets <- do.call(rbind, sheet_properties)

    protected_ranges <- map(sheets, "protectedRanges")
    protected_ranges <- purrr::flatten(protected_ranges)
    protected_ranges <- map(protected_ranges, ~ new("ProtectedRange", !!!.x))
    protected_ranges <- map(protected_ranges, as_tibble)
    out$protected_ranges <- do.call(rbind, protected_ranges)
  }

  if (!is.null(x$namedRanges)) {
    named_ranges <- map(x$namedRanges, ~ new("NamedRange", !!!.x))
    named_ranges <- map(named_ranges, as_tibble)
    named_ranges <- do.call(rbind, named_ranges)

    # if there is only 1 sheet, sheetId might not be sent!
    # https://github.com/tidyverse/googlesheets4/issues/29
    needs_sheet_id <- is.na(named_ranges$sheet_id)
    if (any(needs_sheet_id)) {
      # if sheetId is missing, I assume it's the "first" (visible?) sheet
      named_ranges$sheet_id[needs_sheet_id] <- first_visible_id(out$sheets)
    }
    named_ranges$sheet_name <- vlookup(
      named_ranges$sheet_id,
      data = out$sheets,
      key = "id",
      value = "name"
    )

    # https://github.com/tidyverse/googlesheets4/issues/175
    # dysfunctional named ranges are possible and should not prevent us from
    # dealing with a Sheet
    possibly_make_cell_range <- purrr::possibly(
      make_cell_range,
      otherwise = NA_character_
    )
    named_ranges$cell_range <- pmap_chr(named_ranges, possibly_make_cell_range)
    named_ranges$A1_range <- qualified_A1(
      named_ranges$sheet_name,
      named_ranges$cell_range
    )
    named_ranges$A1_range[is.na(named_ranges$cell_range)] <- NA_character_

    out$named_ranges <- named_ranges
  }

  structure(out, class = c("googlesheets4_spreadsheet", "list"))
}

#' @export
format.googlesheets4_spreadsheet <- function(x, ...) {
  cli::cli_div(theme = gs4_theme())
  meta <- list(
  `Spreadsheet name` = cli::format_inline("{.s_sheet {x$name}}"),
                  ID = as.character(x$spreadsheet_id),
              Locale = x$locale,
         `Time zone` = x$time_zone,
       `# of sheets` = if (rlang::has_name(x, "sheets")) {
         as.character(nrow(x$sheets))
       } else {
         "<unknown>"
       }
  )
  if (!is.null(x$named_ranges)) {
    meta <- c(meta, `# of named ranges` = as.character(nrow(x$named_ranges)))
  }
  if (!is.null(x$protected_ranges)) {
    meta <- c(meta, `# of protected ranges` = as.character(nrow(x$protected_ranges)))
  }
  out <- c(
    cli::cli_format_method(
      cli::cli_h1("<googlesheets4_spreadsheet>")
    ),
    glue("{fr(names(meta))}: {fl(meta)}")
  )

  if (!is.null(x$sheets)) {
    col1 <- fr(c(
      "(Sheet name)",
      sapply(
        gargle::gargle_map_cli(x$sheets$name, template = "{.w_sheet <<x>>}"),
        cli::format_inline
      )
    ))
    col2 <- c(
      "(Nominal extent in rows x columns)",
      glue_data(x$sheets, "{grid_rows} x {grid_columns}")
    )
    out <- c(
      out,
      cli::cli_format_method(
        cli::cli_h1("<sheets>")
      ),
      glue_data(list(col1 = col1, col2 = col2), "{col1}: {col2}")
    )
  }

  if (!is.null(x$named_ranges)) {
    col1 <- fr(c(
      "(Named range)",
      sapply(
        gargle::gargle_map_cli(x$named_ranges$name, template = "{.range <<x>>}"),
        cli::format_inline
      )
    ))
    col2 <- fl(c("(A1 range)", x$named_ranges$A1_range))
    out <- c(
      out,
      cli::cli_format_method(
        cli::cli_h1("<named ranges>")
      ),
      glue_data(list(col1 = col1, col2 = col2), "{col1}: {col2}")
    )
  }

  out
}

#' @export
print.googlesheets4_spreadsheet <- function(x, ...) {
  cat(format(x), sep = "\n")
  invisible(x)
}
