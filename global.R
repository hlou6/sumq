library(lubridate)

calcNumRainyCloudyDays <- function(year1,beginDay,endDay,hour1,hour2,hourly,allowance,param) {
  
  # get this year as a subset
  selyr <- subset(hourly,year==year1)
  
  # select the desired range
  selms <- with(selyr, selyr[(as.Date(time) >= as.Date(beginDay) & as.Date(time) <= as.Date(endDay)), ]) 
  
  # get day and night time values separately
  dayvals <- with(selms, selms[(hour(time) >= hour1 & hour(time) < hour2), ])
  nightvals <- with(selms, selms[(hour(time) < hour1 | hour(time) >= hour2), ])

  
  # get the means
  if(param == "rain") {
    daymeans <- dayvals %>% 
      group_by(day) %>% 
      summarize(precday = mean(meanprec))
    nightmeans <- nightvals %>% 
      group_by(day) %>% 
      summarize(precnight = mean(meanprec))
  } else if (param == "cloud") {
    daymeans <- dayvals %>% 
      group_by(day) %>% 
      summarize(cloudday = trunc(mean(meancloud)))
    nightmeans <- nightvals %>% 
      group_by(day) %>% 
      summarize(cloudnight = trunc(mean(meancloud)))
  }
  
  means <- merge(daymeans,nightmeans,by = "day")
  
  # calculate the day class counts
  if(param == "rain") {
    if (abs(allowance) < 1.0e-10) {
      # no rain is allowed for day being dry
      means$dc <- as.integer(means$precday == 0 & means$precnight == 0)
      means$wc <- as.integer(means$precday > 0 & means$precnight > 0)
      means$rcday <- as.integer(means$precday > 0 & means$precnight == 0)
      means$rcnight <- as.integer(means$precday == 0 & means$precnight > 0)
    } else {
      # some rain is allowed to make the day dry
      allowance <- allowance/60.0
      means$dc <- as.integer(means$precday < allowance & means$precnight < allowance)
      means$wc <- as.integer(means$precday > allowance & means$precnight > allowance)
      means$rcday <- as.integer(means$precday > allowance & means$precnight < allowance)
      means$rcnight <- as.integer(means$precday < allowance & means$precnight > allowance)
    }
  } else if (param == "cloud") {
    if (abs(allowance) < 1.0e-10) {
      # no cloud is allowed for day/night being clear
      means$dc <- as.integer(means$cloudday == 0 & means$cloudnight == 0)
      means$wc <- as.integer(means$cloudday > 0 & means$cloudnight > 0)
      means$rcday <- as.integer(means$cloudday > 0 & means$cloudnight == 0)
      means$rcnight <- as.integer(means$cloudday == 0 & means$cloudnight > 0)
    } else {
      # some clouds are allowed to make the day/night clear
      means$dc <- as.integer(means$cloudday < allowance & means$cloudnight < allowance)
      means$wc <- as.integer(means$cloudday > allowance & means$cloudnight > allowance)
      means$rcday <- as.integer(means$cloudday > allowance & means$cloudnight < allowance)
      means$rcnight <- as.integer(means$cloudday < allowance & means$cloudnight > allowance)
    }
    
  }
  
  # form an empty data frame for the data 
  ndays <- data.frame(matrix(ncol=5, nrow= 1));
  x <- ndaycolnames_prog
  colnames(ndays) <- x
  
  # save data to ndays
  ndays$dc[1] <- sum(means$dc)
  ndays$wc[1] <- sum(means$wc)
  ndays$rcday[1] <- sum(means$rcday)
  ndays$rcnight[1] <- sum(means$rcnight)
  ndays$year[1] <- as.integer(year1)
  
  return (ndays)
  
}


calcThermalSummer <- function(input,year1,hourly) {
  
  numDaysChangeThreshold = input$thsumthresh
  
  # get this year as a subset
  selyr <- subset(hourly,year==year1)
  
  # get the daily means
  daymeans <- selyr %>% 
    group_by(day) %>% 
    summarize(Tday = mean(meanT))
  
  # set all NaNs to zero
  daymeans$Tday[is.na(daymeans$Tday)] <- 0
  
  isSummer = FALSE
  countChange = 0
  dayID = 0
  beginDay = 0
  endDay = 0
  for (Temp in daymeans$Tday) {
    if(!isSummer & endDay == 0) {
      if(Temp > 10.0) {
        countChange = countChange + 1
        beginDay = dayID
      }
      if((Temp < 10.0) & (countChange > 0)) {
        countChange = 0
      }
      if(countChange == numDaysChangeThreshold) {
        isSummer = TRUE
        countChange = 0
      }
    } else {
      if(Temp < 10.0) {
        countChange = countChange + 1
        endDay = dayID
      }
      if((Temp > 10.0) & (countChange > 0)) {
        countChange = 0
      }
      if(countChange == numDaysChangeThreshold) {
        isSummer = FALSE
        countChange = 0
        break
      }
    }
    dayID = dayID + 1
  }
  
  thermSumRange <- data.frame(matrix(ncol=3, nrow= 1));
  x <- c("begin","end","length")
  colnames(thermSumRange) <- x
  thermSumRange$begin[1] <- daymeans$day[beginDay]
  thermSumRange$end[1] <- daymeans$day[endDay]
  thermSumRange$length[1] <- endDay - beginDay
  
  return(thermSumRange)
}

calcThermalSummerLengthForYears<-function(input,hourly) {
  
  nyears <- as.integer(input$years[2]) - as.integer(input$years[1]) + 1
  lensumm <- data.frame(matrix(ncol=2, nrow= nyears));
  x <- c("Year","Length")
  colnames(lensumm) <- x
  
  iyear = 1
  for (year in seq(from=input$years[1],to=input$years[2],by=1)) {
    
    thermSumRange <- calcThermalSummer(input,year,hourly)
    lensumm$Year[iyear] = year
    lensumm$Length[iyear] = thermSumRange$length[1]
    
    iyear = iyear + 1
  }
  
  return(lensumm)
}


createNumberString <- function(num) {
  numString <- sprintf("%02d",num)
  return(numString)
}

calcNumRainyCloudyDaysForYears<-function(input,hourly) {
  
  ndays <- data.frame(matrix(ncol=5, nrow= 0));
  x <- ndaycolnames_prog
  colnames(ndays) <- x
  
  # the last days of each month
  monthEndString = c(31,28,31,30,31,30,31,31,30,31,30,31)
  
  for (year in seq(from=input$years[1],to=input$years[2],by=1)) {
    
    # check how to calculate the begin and end dates
    if(input$dateinput == "months") {
      beginMonth <- createNumberString(as.integer(input$months[1]))
      endMonth <- createNumberString(as.integer(input$months[2]))
      beginDay = as.Date(paste(year,beginMonth,"01",sep="-"))
      endDay = as.Date(paste(year,endMonth,monthEndString[as.integer(input$months[2])],sep="-"))
    } else if (input$dateinput == "dates") {
      mon = month(input$daterange[1])
      day = day(input$daterange[1])
      beginDay = as.Date(paste(year,mon,day,sep="-"))
      mon = month(input$daterange[2])
      day = day(input$daterange[2])
      endDay = as.Date(paste(year,mon,day,sep="-"))
    } else if (input$dateinput == "thermsum") {
      thermSumRange <- calcThermalSummer(input,year,hourly)
      beginDay <- paste(year,thermSumRange$begin[1],sep="-")
      endDay <- paste(year,thermSumRange$end,sep="-")
    }
    
    if(input$param == "rain") {
      allowance = input$rainAllow
    } else if(input$param == "cloud") {
      allowance = input$cloudAllow
    } else {
      allowance = 0.0
    }
    
    ndaysy <- calcNumRainyCloudyDays(year,
                               beginDay,
                               endDay,
                               input$hours[1],
                               input$hours[2],
                               hourly,
                               allowance,
                               input$param)
    ndays <- rbind(ndays,ndaysy)
  }
  
  return(ndays)
}


flatpink = "#ed5565"

ndaycolnames_prog <- c("year","wc","dc","rcday","rcnight")

ndaycolnames_rain <- c("Year",
                  "Rain all day", 
                  "No rain all day", 
                  "Rain only by day", 
                  "Rain only by night")
ndaycolnames_cloud <- c("Year",
                       "Cloudy all day", 
                       "Clear all day", 
                       "Cloudy only by day", 
                       "Cloudy only by night")
ndaycolors <- c("dc" = "yellow1",
                  "wc"="deepskyblue4",
                  "rcday"="lightskyblue",
                  "rcnight"=flatpink) # pink of flat slider