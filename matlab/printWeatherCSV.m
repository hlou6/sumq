% assume weather, fmisid from the loading script
filename = sprintf('%s_data.csv',fmisid);

fid = fopen(filename,'w');

fprintf(fid,'time, Tair, vWind, vGust, dirWind, relHum, Tdew,mmPrec,intPrec,depthSnow,press,vis,cloud,weather\n');
ndt = length(weather.Time(:));
for k=1:ndt
    thedate = datestr(weather.Time(1,k),'dd-mm-yyyy HH:SS:MM');
    fprintf(fid,'%s, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %d, %d\n',...
        thedate,weather.AirTemperature(k),weather.WindSpeed(k),weather.GustSpeed(k),weather.WindDir(k),...
        weather.RelativeHumidity(k),weather.DewTemperature(k),weather.PrecipAmount(k),weather.PrecipIntensity(k),...
        weather.SnowDepth(k),weather.Pressure(k),weather.Visibility(k),weather.CloudAmount(k),weather.PresentWeather(k));    
end
fclose(fid);



