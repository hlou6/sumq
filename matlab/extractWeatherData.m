function [ structdata ] = extractWeatherData( nbatches, rawdata, time, dataset )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    if strcmpi(dataset, 'fmi::observations::weather::multipointcoverage') == 1
        
        % cell columns in fmi::observations::weather::multipointcoverage:
        % t2m,ws_10min,wg_10min,wd_10min,rh,td,r_1h,ri_10min,snow_aws,p_sea,vis,n_man,wawa
        % meanings and units can be queried by:
        % http://data.fmi.fi/meta?observableProperty=observation&param=INSERT_PARAM_NAME&fmi-apikey=INSERT_YOUR_APIKEY

        structdata = struct('Time',[],'AirTemperature',[],'WindSpeed',[],'GustSpeed',[],'WindDir',[],...
            'RelativeHumidity',[],'DewTemperature',[],'PrecipAmount',[],...
            'PrecipIntensity',[],'SnowDepth',[],'Pressure',[],'Visibility',[],...
            'CloudAmount',[],'PresentWeather',[]);

        t2m = [];       % air temperature (C)
        ws_10min = [];  % wind speed (m/s)
        wg_10min = [];  % gust speed (m/s)
        wd_10min = [];  % wind direction (degree)
        rh = [];        % relative humidity (%)
        td = [];        % dew-point temperature (C)
        r_1h = [];      % precipitation amount (mm) 
        ri_10min = [];  % precipitation intensity (mm/h)
        snow_aws = [];  % snow depth (cm)
        p_sea = [];    % pressure (hPa)
        vis = [];      % horizontal visibility (m)
        n_man = [];    % cloud amount (1/8)
        wawa = [];     % present weather ??

        for k=1:nbatches

            t2m = [t2m; rawdata{k}{1}(:)];
            ws_10min = [ws_10min; rawdata{k}{2}(:)];
            wg_10min = [wg_10min; rawdata{k}{3}(:)];
            wd_10min = [wd_10min; rawdata{k}{4}(:)];
            rh = [rh; rawdata{k}{5}(:)];
            td = [td; rawdata{k}{6}(:)];
            r_1h = [r_1h; rawdata{k}{7}(:)];
            ri_10min = [ri_10min; rawdata{k}{8}(:)];
            snow_aws = [snow_aws; rawdata{k}{9}(:)];
            p_sea = [p_sea; rawdata{k}{10}(:)];
            vis = [vis; rawdata{k}{11}(:)];
            n_man = [n_man; rawdata{k}{12}(:)];
            wawa = [wawa; rawdata{k}{13}(:)];

        end

        structdata.Time = time;
        structdata.AirTemperature = t2m;
        structdata.WindSpeed = ws_10min;
        structdata.GustSpeed = wg_10min;
        structdata.WindDir = wd_10min;
        structdata.RelativeHumidity = rh;
        structdata.DewTemperature = td;
        structdata.PrecipAmount = r_1h;
        structdata.PrecipIntensity = ri_10min;
        structdata.SnowDepth = snow_aws;
        structdata.Pressure = p_sea;
        structdata.Visibility = vis;
        structdata.CloudAmount = n_man;
        structdata.PresentWeather = wawa;
        
    end
            
            

end

