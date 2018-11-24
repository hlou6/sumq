library(shiny)
library(shinythemes)
library(shinyWidgets)
library(shinyBS)
library(ggplot2)
library(dplyr)
library(DT)

ui <- fluidPage(theme = shinytheme("paper"),
  
  title = "Summer quality",
  chooseSliderSkin("Flat"),
  fluidRow(
    tabsetPanel(
      tabPanel("Plot", fluidRow(column(10,offset=1,plotOutput("myplot")))), 
      tabPanel("Table", fluidRow(column(10,offset=1,DTOutput("mytable")))),
      tabPanel("Background", fluidRow(column(10,offset=1,br(),br(),uiOutput("background"))))
    ),
    br(),br()),
  fluidRow(
    column(12,
           br()
    )
  ),
  fluidRow(
    
    # title column, dataset selection
    column(3,
           h3("Summer quality"),
           hr(),
           selectInput("dataset", label = "Select dataset", 
                       choices = list("Helsinki Kumpula" = 101004,
                                      "Enontekiö Kilpisjärvi kyläkeskus" = 102016,
                                      "Kuhmo Kalliojoki" = 101773,
                                      "Parainen Utö" = 100908),
                       selected = 101004),
           radioButtons("param", "Which parameter to analyze?",
                        c("Temperature"="temp",
                          "Rain"="rain"),
                          #"Cloud coverage"="cloud"), # not working yet
                        selected="rain")
    ),
    
    # slider column
    column(4, offset = 1,
           sliderInput("years","Which years?",min=2010,max=2017,value=c(2010,2017),sep=""),
           uiOutput("monthSliderInputUI"),
           uiOutput("dateRangeInputUI"),
           uiOutput("hoursOfDayInputUI"),
           uiOutput("rainAllowanceInputUI"),
           uiOutput("cloudAllowanceInputUI"),
           uiOutput("thermalSummerThresholdInputUI")
    ),
    
    #other settings column
    column(4,
           uiOutput("plotTypeInputUI"),
           hr(),
           uiOutput("dateSelectionInputUI")
           
           
    )
  )
  
)


