library(lubridate)
library(plyr)
library(dplyr)

fmisid = 100908

wd <- read.csv(paste(fmisid,"_data.csv",sep=""))
wdconv <- wd

wdconv$intPrec[is.na(wdconv$intPrec)] <- 0
wdconv$mmPrec[is.na(wdconv$mmPrec)] <- 0

wdconv$time <- as.POSIXct(as.numeric(dmy_hms(wdconv$time)), origin="1970-01-01", tz="UTC")
wdconv$hour <- cut(wdconv$time,breaks = "1 hour")
ns <- data.frame(time=wdconv$hour,prec=wdconv$intPrec,temp=wdconv$Tair,cloud=wdconv$cloud)


hourly <- ns %>% 
	group_by(time) %>% 
	summarize(meanprec = mean(prec), 
			meanT = mean(temp),
			meancloud = trunc(mean(cloud)))

save(hourly, file=paste(fmisid,".RData",sep=""))


