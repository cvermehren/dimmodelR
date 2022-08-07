
# startdate <- as.Date(minmax$mindate, origin="1970-01-01")
# enddate <- as.Date(minmax$maxdate, origin="1970-01-01")

dm_period_start <- function(date,
                            unit = c("week", "month", "quarter", "year"),
                            start_on_monday = TRUE) {

  unit <- match.arg(unit)
  date <- as.Date(date)
  as.Date(cut(date, unit, start.on.monday = start_on_monday))[1]
}

dm_period_end <- function(date,
                          unit = c("week", "month", "quarter", "year"),
                          start_on_monday = TRUE) {
  unit <- match.arg(unit)
  date <- as.Date(date)

  start <- dm_period_start(date, unit, start_on_monday)
  seq.Date(from = start , by = unit, length.out = 2)[2]-1
}



# dm_calendar <- function(start, end) {
#
#
#   start <- lubridate::floor_date(start, unit = "year")
#   end <- lubridate::ceiling_date(end, unit = "year")-1
#
#   # ISO start date ----------------------------------------------------------
#
#   iso_seq_start <- lubridate::floor_date(startdate-1, unit = "month")
#   iso_seq_end <- lubridate::ceiling_date(startdate, unit = "month")-1
#   iso_seq <- seq.Date(iso_seq_start, iso_seq_end, by = "day")
#
#   iso_seq_dates <- iso_seq[isoyear(iso_seq) == year(startdate)]
#
#   iso_start <- min(iso_seq[isoyear(iso_seq) == year(startdate)])
#
#
#   # Calendar range ----------------------------------------------------------
#   date_range <-seq(iso_start, enddate, by = "day")
#
#   calendar <- data.table(date = date_range)
#
#
#   # Day of ------------------------------------------------------------------
#
#   calendar[, day_of_week_no := as.integer(wday(date, week_start = 1))]
#   calendar[, day_of_week := as.character(wday(date, label = TRUE))]
#   calendar[, day_of_month := day(date)]
#   calendar[, day_of_quarter := as.integer(qday(date))]
#   calendar[, day_of_year := as.integer(yday(date)) ]
#   calendar[, day_sequential := as.integer(date) ]
#
#   # ISO
#   calendar[, day_of_year_of_week := 1 ]
#   calendar[, day_of_year_of_week := cumsum(day_of_year_of_week), by = isoyear(date)]
#
#   # Month -------------------------------------------------------------------
#
#   calendar[, month_no := as.integer(month(date))]
#   calendar[, month := as.character(month(date, label = TRUE))]
#   calendar[, month_year := format(date, "%b-%Y")]
#   calendar[, month_start := lubridate::floor_date(date, unit = "month")]
#   calendar[, month_end := lubridate::ceiling_date(date, unit = "month")-1]
#   calendar[, month_days := days_in_month(date)]
#   calendar[, month_sequential := year(date)*12+month_no-1]
#
#
#   # Quarter -----------------------------------------------------------------
#
#   calendar[, quarter_no := quarter(date)]
#   calendar[, quarter := paste0("Q", quarter(date))]
#   calendar[, quarter_year := paste(quarter, year(date))]
#   calendar[, quarter_start := lubridate::floor_date(date, unit = "quarter")]
#   calendar[, quarter_end := lubridate::ceiling_date(date, unit = "quarter")-1]
#   calendar[, quarter_days := .N, by = quarter_year]
#   calendar[, quarter_sequential := year(date)*4 + quarter(date)-1]
#
#
#   # ISO week ----------------------------------------------------------------
#
#   calendar[, week_no := as.integer(isoweek(date))]
#   calendar[, week := paste0("W", formatC(as.integer(isoweek(date)), width=2, flag="0"))]
#   calendar[, week_year_no := isoyear(date) * 100 + isoweek(date)]
#   calendar[, week_sequential :=  as.integer( (date-lubridate::floor_date(startdate, unit = "week", week_start = 1) )/7+1)  ]
#
#
#   # Year --------------------------------------------------------------------
#
#   calendar[, year_no := as.integer(year(date))]
#   calendar[, year := as.character(year(date))]
#   calendar[, year_start := min(date), by = year]
#   calendar[, year_end := max(date), by = year]
#   calendar[, year_days := .N, by = year]
#   calendar[, year_of_week_no := as.integer(isoyear(date))]
#   calendar[, year_of_week := as.character(isoyear(date))]
#
#
#   # Relative ----------------------------------------------------------------
#
#   calendar[, relative_day_pos :=  as.integer(date)-as.integer(Sys.Date()) ]
#
#   currentweekpos <- calendar[date == Sys.Date()]$week_sequential
#   calendar[, relative_week_pos := week_sequential - currentweekpos]
#
#   calendar[, relative_month_pos := (year(date) - year(Sys.Date())) * 12 + month(date) - month(Sys.Date())]
#   calendar[, relative_quarter_pos := floor(  (year(date) - year(Sys.Date())) * 4  + (month(date) - month(Sys.Date()))/3 )]
#   calendar[, relative_year_pos := year_no - year(Sys.Date())]
#   calendar[, relative_year_of_week_pos := year_of_week_no - isoyear(Sys.Date())]
#
#   calendar[, date_previous_week := Sys.Date()-7]
#   calendar[, date_previous_month := Sys.Date() %m+% months(-1)]
#   calendar[, date_previous_quarter := Sys.Date() %m+% months(-3)]
#   calendar[, date_previous_year := Sys.Date() - years(1)]
#
#
#   }
#
#
#
