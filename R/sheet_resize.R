#' Change the size of a (work)sheet
#'
#' Changes the number of rows and/or columns in a (work)sheet.
#'
#' @eval param_ss()
#' @eval param_sheet(action = "resize")
#' @param nrow,ncol Desired number of rows or columns, respectively. The default
#'   of `NULL` means to leave unchanged.
#' @param exact Logical, indicating whether to impose `nrow` and `ncol` exactly
#'   or to treat them as lower bounds. If `exact = FALSE`,
#'   `sheet_resize()` can only add cells. If `exact = TRUE`, cells can be
#'   deleted and their contents are lost.
#'
#' @template ss-return
#' @export
#' @family worksheet functions
#' @seealso Makes an `UpdateSheetPropertiesRequest`:
#'   * <https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/request#UpdateSheetPropertiesRequest>
#'
#' @examplesIf gs4_has_token()
#' # create a Sheet with the default initial worksheet
#' (ss <- gs4_create("sheet-resize-demo"))
#'
#' # see (work)sheet dims
#' sheet_properties(ss)
#'
#' # no resize occurs
#' sheet_resize(ss, nrow = 2, ncol = 6)
#'
#' # reduce sheet size
#' sheet_resize(ss, nrow = 5, ncol = 7, exact = TRUE)
#'
#' # add rows
#' sheet_resize(ss, nrow = 7)
#'
#' # add columns
#' sheet_resize(ss, ncol = 10)
#'
#' # add rows and columns
#' sheet_resize(ss, nrow = 9, ncol = 12)
#'
#' # re-inspect (work)sheet dims
#' sheet_properties(ss)
#'
#' # clean up
#' gs4_find("sheet-resize-demo") %>%
#'   googledrive::drive_trash()
sheet_resize <- function(ss,
                         sheet = NULL,
                         nrow = NULL, ncol = NULL,
                         exact = FALSE) {
  ssid <- as_sheets_id(ss)
  maybe_sheet(sheet)
  maybe_non_negative_integer(nrow)
  maybe_non_negative_integer(ncol)
  check_bool(exact)

  x <- gs4_get(ssid)
  s <- lookup_sheet(sheet, sheets_df = x$sheets)
  gs4_bullets(c(v = "Resizing sheet {.w_sheet {s$name}} in {.s_sheet {x$name}}."))

  bureq <- prepare_resize_request(s, nrow_needed = nrow, ncol_needed = ncol, exact = exact)

  if (is.null(bureq)) {
    gs4_bullets(c(
      i = "No need to change existing dims ({s$grid_rows} x {s$grid_columns})."
    ))
    return(invisible(ssid))
  }

  new_grid_properties <- pluck(bureq, "updateSheetProperties", "properties", "gridProperties")
  new_nrow <- pluck(new_grid_properties, "rowCount") %||% s$grid_rows
  new_ncol <- pluck(new_grid_properties, "columnCount") %||% s$grid_columns

  gs4_bullets(c(
    v = "Changing dims: ({s$grid_rows} x {s$grid_columns}) --> \\
         ({new_nrow} x {new_ncol})."
  ))

  req <- request_generate(
    "sheets.spreadsheets.batchUpdate",
    params = list(
      spreadsheetId = ssid,
      requests = list(bureq)
    )
  )
  resp_raw <- request_make(req)
  gargle::response_process(resp_raw)

  invisible(ssid)
}

prepare_resize_request <- function(sheet_info,
                                   nrow_needed,
                                   ncol_needed,
                                   exact = FALSE) {
  nrow_sheet <- sheet_info$grid_rows
  ncol_sheet <- sheet_info$grid_columns

  new_dims <- c(
    make_dim_patch(nrow_sheet, nrow_needed, "nrow", exact),
    make_dim_patch(ncol_sheet, ncol_needed, "ncol", exact)
  )

  if (length(new_dims) == 0) {
    NULL
  } else {
    bureq_set_grid_properties(
      sheetId = sheet_info$id,
      nrow = new_dims$nrow, ncol = new_dims$ncol,
      frozenRowCount = NULL
    )
  }
}

make_dim_patch <- function(current, target, nm, exact = FALSE) {
  out <- list()
  if (is.null(target)) {
    return(out)
  }
  patch_needed <- (isTRUE(exact) && current != target) || current < target
  if (patch_needed) {
    out[[nm]] <- target
  }
  out
}
