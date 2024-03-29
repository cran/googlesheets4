% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sheet_delete.R
\name{sheet_delete}
\alias{sheet_delete}
\title{Delete one or more (work)sheets}
\usage{
sheet_delete(ss, sheet)
}
\arguments{
\item{ss}{Something that identifies a Google Sheet:
\itemize{
\item its file id as a string or \code{\link[googledrive:drive_id]{drive_id}}
\item a URL from which we can recover the id
\item a one-row \code{\link[googledrive:dribble]{dribble}}, which is how googledrive
represents Drive files
\item an instance of \code{googlesheets4_spreadsheet}, which is what \code{\link[=gs4_get]{gs4_get()}}
returns
}

Processed through \code{\link[=as_sheets_id]{as_sheets_id()}}.}

\item{sheet}{Sheet to delete, in the sense of "worksheet" or "tab". You can identify a sheet by name, with a string, or by position, with a number. You can pass a vector to delete multiple sheets at once or even a list, if you need to mix names and positions.}
}
\value{
The input \code{ss}, as an instance of \code{\link{sheets_id}}
}
\description{
Deletes one or more (work)sheets from a (spread)Sheet.
}
\examples{
\dontshow{if (gs4_has_token()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
ss <- gs4_create("delete-sheets-from-me")
sheet_add(ss, c("alpha", "beta", "gamma", "delta"))

# get an overview of the sheets
sheet_properties(ss)

# delete sheets
sheet_delete(ss, 1)
sheet_delete(ss, "gamma")
sheet_delete(ss, list("alpha", 2))

# get an overview of the sheets
sheet_properties(ss)

# clean up
gs4_find("delete-sheets-from-me") \%>\%
  googledrive::drive_trash()
\dontshow{\}) # examplesIf}
}
\seealso{
Makes an \code{DeleteSheetsRequest}:
\itemize{
\item \url{https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/request#DeleteSheetRequest}
}

Other worksheet functions: 
\code{\link{sheet_add}()},
\code{\link{sheet_append}()},
\code{\link{sheet_copy}()},
\code{\link{sheet_properties}()},
\code{\link{sheet_relocate}()},
\code{\link{sheet_rename}()},
\code{\link{sheet_resize}()},
\code{\link{sheet_write}()}
}
\concept{worksheet functions}
