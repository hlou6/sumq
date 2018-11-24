library(shiny)
library(shinyBS)
library(ggplot2)
library(dplyr)
library(DT)


server <- function(input,output,session) {
  
  # load the data
  hourly <- reactive({
    filename<-paste(input$dataset,".RData",sep="")
    load(filename)
    hourly$year <- lubridate::year(hourly$time)
    hourly$day <- paste(createNumberString(lubridate::month(hourly$time)),
                        createNumberString(lubridate::day(hourly$time)),
                        sep = "-")
    
    return(hourly)
  })
  
  # do the calculation of each day class
  ndays <- reactive({
    
    # all kinds of requirements
    req(input$months)
    if((input$dateinput == "thermsum") | (input$plottype == "thsum")) {
      req(input$thsumthresh)
    }
    req(input$param)
    if(input$param == "cloud") {
      req(input$cloudAllow)
    }
    if(input$param == "rain") {
      req(input$rainAllow)
    }
    
    ndays <-calcNumRainyCloudyDaysForYears(input,hourly())
    return(ndays)
  })
  

  
  # format the ndays column names for the table output
  ndaystab <- reactive({
    ndaystab <- ndays()
    if(input$param == "cloud") {
      colnames(ndaystab) <- ndaycolnames_cloud
    } else if (input$param == "rain") {
      colnames(ndaystab) <- ndaycolnames_rain
    }
    return(ndaystab)
  })

  # output the table with DT
  output$mytable <- DT::renderDataTable(
    ndaystab(), options = list(lengthChange = FALSE)
  )

  # plot the barplot
  output$myplot <- renderPlot({
    
    req(input$plottype)
    if((input$dateinput == "thermsum") | (input$plottype == "thsum")) {
      req(input$thsumthresh)
    }
    
    fontsize = 15
    boxsize = 0.25
    
    shinygrey = "#666666"
    
    yearlabels <- seq(from=input$years[1],to=input$years[2],by=1)
    
    if(input$param == "temp") {
      if(input$plottype == "thsum") {
        
        thesuml <- calcThermalSummerLengthForYears(input,hourly())
        
        p <- ggplot(data=thesuml,aes(x=Year,y=Length)) + 
          geom_line(color=flatpink,size=2) +
          labs(x = "Year", y="Number of thermal summer days") 
        
      }
    } else if ((input$param == "cloud") | (input$param == "rain")) {
    
      ndays_this <- ndays()
      
      if(input$plottype == "dayabs") {
        
        ndaysl <- reshape2::melt(ndays_this,id.vars="year")
        
        p <- ggplot(data=ndaysl,aes(x=year,y=value,fill=variable)) + 
             geom_bar(stat="identity", position=position_dodge()) +
             labs(x = "Year", y="Number of days")
             
        if(input$param == "cloud") {
          p <- p + scale_fill_manual(labels=ndaycolnames_cloud[2:5],
                                     values=ndaycolors)
        } else if (input$param == "rain") {
          p <- p + scale_fill_manual(labels=ndaycolnames_rain[2:5],
                                     values=ndaycolors)
        }
      
      } else if(input$plottype == "dayrel") {
        
        ndaysl <- reshape2::melt(ndays_this,id.vars="year")
        
        p <- ggplot(data=ndaysl,aes(x=year,y=value,fill=factor(variable,levels=c("wc","rcday","rcnight","dc")))) + 
          geom_bar(stat="identity", position=position_fill()) +
          labs(x = "Year", y="Fraction of days")
        
        if(input$param == "cloud") {
          p <- p + scale_fill_manual(labels=c(ndaycolnames_cloud[[2]],
                                              ndaycolnames_cloud[[4]],
                                              ndaycolnames_cloud[[5]],
                                              ndaycolnames_cloud[[3]]),
                                     values=ndaycolors)
        } else if (input$param == "rain") {
          p <- p + scale_fill_manual(labels=c(ndaycolnames_rain[[2]],
                                              ndaycolnames_rain[[4]],
                                              ndaycolnames_rain[[5]],
                                              ndaycolnames_rain[[3]]),
                                     values=ndaycolors)
        }
      }
    }
    
    p <- p + theme_classic() +
      scale_x_continuous(breaks=yearlabels) +
      theme(text=element_text(color=shinygrey,size=fontsize),
            axis.text.x = element_text(size = fontsize,color=shinygrey),
            axis.text.y = element_text(size = fontsize,color=shinygrey),
            axis.line = element_blank(),
            legend.title = element_blank()) +
      theme(panel.background = element_rect(fill="white",color="white",size=boxsize))
    
    if(!is.null(p)) {
      print(p)
    }
  })

  # render the month slider if thermal summer selection is not selected
  output$monthSliderInputUI <- renderUI({
    req(input$dateinput)
    req(input$plottype)
    
    if(input$dateinput == "months" & input$plottype != "thsum") {
      sliderInput("months","Which months?",min=1,max=12,value=c(5,8))
    }
  })
  
  # render the date range input if thermal summer selection is not selected
  output$dateRangeInputUI <- renderUI({
    req(input$dateinput)
    if(input$dateinput == "dates") {
      dateRangeInput("daterange",
               label = "Which dates?",
               start = as.Date("2015-05-01"), 
               end = as.Date("2015-08-31"))
    }
  })
  
  output$thermalSummerThresholdInputUI <- renderUI({
    req(input$dateinput)
    req(input$plottype)
    
    if((input$plottype == "thsum") | (input$dateinput == "thermsum")) {
      tipify(numericInput("thsumthresh", "Thermal summer change threshold:", 10, min = 1, max = 100),
             placement="top",trigger="hover",
             title="The number of days which must have a mean daily temperature over or under 10 C before the first day is counted as the beginning of thermal summer.")
    }
  })
  
  output$rainAllowanceInputUI <- renderUI({
    req(input$plottype)
    if((input$plottype != "thsum") & (input$param == "rain")) {
      tipify(numericInput("rainAllow", "Allow for rain in hour:", value=0.0, min = 0.0, max = 100, step = 0.1),
             placement="top",trigger="hover",
             title="The amount of rain allowed for the day to be counted dry.")
    }
  })
  
  output$cloudAllowanceInputUI <- renderUI({
    req(input$plottype)
    
    if((input$plottype != "thsum") & (input$param == "cloud")) {
      numericInput("cloudAllow", "Allow for cloud coverage:", value=4, min = 0, max = 8, step = 1)
    }
  })
  
  output$hoursOfDayInputUI <- renderUI({
    req(input$plottype)
    
    if(input$plottype != "thsum") {
      sliderInput("hours","Define the hours of day (the rest is night):",min=0,max=24,value=c(7,23))
    }
  })
  
  output$plotTypeInputUI <- renderUI ({
    if(input$param == "temp") {
      selectInput("plottype", "Type of plot:",
                  c("Length of thermal summer"="thsum"),
                  selected="thsum")
    }else if ((input$param == "rain") | (input$param == "cloud")) {
      selectInput("plottype", "Type of plot:",
                  c("Day comparison (absolute)"="dayabs",
                    "Day comparison (fraction)"="dayrel"),
                  selected="dayrel")
    }
  })
  
  output$dateSelectionInputUI <- renderUI ({
    if(input$param != "temp"){
      radioButtons("dateinput", "How to select time of year?",
                 c("Months"="months","Dates"="dates",
                   "Thermal summer"="thermsum"),
                 selected="months")
      }
  })
    
  output$background <- renderUI({
    div(
      tags$head(
        tags$style("#background{overflow-y:scroll; max-height: 400px;}")
      ),
      "In the tabloid press and common parlance, the quality of a summer season is usually measured by the number of days with rain. For an engineer, this is an unreasonably simple statistic. ",
      "To obtain more accurate measure of the quality of a summer, I thought about what makes a summer day feel best. No rain is of course a good measure, but what if the rain happens at night? ",
      "At night you are often asleep, and wouldn't notice the rain after all. Another would be the temperature: for each person, there is an ideal temperature you would like to hang around in. ",
      "A third measure might be cloud cover. A overcast day could be counted as a worse summer day than one with a clear sky, if you are so inclined to feel.",
      br(),br(),
      "Let us start with a single statistic: the amount of rain. Is it possible for the amount of rain to vary between day and night? ",
      "The occurrence of a natural phenomenon at different times of day is called the diurnal cycle, and with rain whether the diurnal cycle is strong depends on the geography of the location.",
      br(),br(),
      "Another thing we have to define is the summer itself. When does it start, and when does it end? You can think that May to August are the summer months, and select them. However, there is also a more objective way to define summer: the thermal summer. ",
      "Thermal summer is defined in Finland to begin as the daily mean temperature is above 10 C for a sufficient time. Similarly, it ends when the daily mean falls below 10 C permanently. ",
      "When you select thermal summer as an option, either to calculate the summer length or just to see how long the thermal summer has been each year, you can also select the threshold for how long ",
      "the daily mean temperature must be over and under 10 C for thermal summer to begin and end.",
      br(),br(),
      "The app currently only processes temperature data to thermal summer lengths, and calculates the numbers of days in each day class with the user-given parameters for ",
      "time of year, time of day and amount of rain allowed to still count the day as a dry one.",
      br(),br(),
      "The weather data is from the ",
      a(href="https://en.ilmatieteenlaitos.fi/open-data", "Finnish Meteorological Institute Open Data service. "),
      "Weather data with a  sufficient time resolution, hourly, is available only after 1st January 2010, so years before that could not be analyzed.",
      "Weather data with 10-minute intervals in the dataset 'fmi::observations::weather::multipointcoverage' were obtained with a MATLAB script and processed to CSV for use in R.",
      br(),br(),
      "R version 3.5.1, RStudio version 1.1.456, shiny version 1.1.0, MATLAB R2016b and R libraries shinythemes, shinyWidgets, ggplot2, dplyr, DT and lubridate were used."
    )
  })
  

}