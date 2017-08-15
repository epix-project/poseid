#' Computing Incidence From Line Listing
#'
#' \code{ll2incidence} takes individual dates of infections and returns incidences
#' by a specified time step.
#'
#' The \code{time} variable of the output is defined at regular time step as
#' defined by the \code{unit} argument. In absence of cases between two steps,
#' a zero incidence is explicitly displayed.
#'
#' @param \code{x} either a vector or a 1-column data frame of dates of \code{"Date"}
#' or \code{"POSIXct"} class.
#'
#' @param \code{unit} a character string (one of \code{"day"}, \code{"week"}
#' \code{"month"}, \code{"quarter"} or \code{year}) specifying the temporal
#' aggregation wished for the incidence calculation. Value set to "day" by default.
#'
#' @return \code{ll2incidence} returns a 2-variable data frame of incidences
#' values with \code{time} and \code{incidence} variables.
#'
#' @examples
#' # Four different data sets of infections dates:
#' infection_date_v <- infections_dates
#' infection_posixct_v <- as.POSIXct(infection_date_v)
#' infection_date_df <- as.data.frame(infection_date_v)
#' infection_posixct_df <- as.data.frame(infection_posixct_v)
#' data_sets <- list(infection_date_v,      # vector of Date class
#'                   infection_date_df,     # data frame of Date class
#'                   infection_posixct_v,   # vector of POSIXct class
#'                   infection_posixct_df)  # data frame of POSIXct class
#' lapply(data_sets, head)
#'
#' # Five time resolutions we want to consider for incidence calculations:
#' steps <- c("day", "week", "month", "quarter", "year")
#'
#' # Calculating of the 4 x 5 = 20 incidence data sets:
#' incidences <- lapply(steps,
#'                      function(y) lapply(data_sets, function(x) ll2incidence(x, y)))
#'
#' # Comparing the results:
#' n <- length(incidences[[1]])
#' any(!unlist(lapply(1:n,
#'                    function(x) sapply(1:(n - 1),
#'                                       function(y) sapply((y + 1):n,
#'                                                          function(z)
#'                                                            identical(incidences[[c(x, y)]],
#'                                                                      incidences[[c(x, z)]]))))))
#'
#' # Showing the results:
#' for(i in 1:5) print(head(incidences[[c(i, 1)]]))
#'
#' @importFrom magrittr %>%
#' @importFrom magrittr %<>%
#' @importFrom lubridate floor_date
#' @importFrom lubridate as_date
#' @export
#'
#' @author Marc Choisy
#'
ll2incidence <- function(x, unit = c("day", "week", "month", "quarter", "year")) {

  clnames <- c("Date", "POSIXct")
  mess_class <- "Dates in x should be of class Date or POSIXct"

  unit <- match.arg(unit)

# checking the format and class of data x:
  d <- dim(x)
  if(is.null(d)) {  # if x is a vector:
    if(!(class(x)[1] %in% clnames)) stop(mess_class)  # checking the class of the dates
  } else {          # if x is not a vector:
    if(d[2] > 1 | !any(class(x) %in% "data.frame")) { # make sure it is a 1-column data frame
      stop("x should be a vector or a 1-column data frame")
    } else {        # vectorize the data:
      cl <- as.vector(sapply(x, class))[1]
      if(!(cl %in% clnames)) stop(mess_class)         # checking the class of the dates
      fct <- setNames(c(as.Date, as.POSIXct), clnames)[[cl]]
      x %<>% mutate_all(as.character) %>% unlist %>% fct
    }
  }

# doing the transformations:
  x %>%
    floor_date(unit) %>%
    table %>%
    data.frame %>%
    setNames(c("date", "incidence")) %>%
    mutate(date = as_date(date)) %>%
    right_join(data.frame(date = seq(min(.$date), max(.$date), unit)), by = "date") %>%
    mutate(incidence = ifelse(is.na(incidence), 0, incidence))
}
