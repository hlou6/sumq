
function [ nbatches ] = downloadFMIdata( apikey, dataset, fmisid, datapath, date_begin, date_end )
%downloadFMIdata() downloads data for dataset from the FMI open data server
%in batches. The data is saved in datapath in xml format.

    %length of maximum downloadable dataset in hours
    if strcmpi(dataset, 'fmi::observations::weather::multipointcoverage') == 1
        % data interval 10 minutes and one week maximum per download
        max_download_size = 168; 
    end

    % calculate the amount of batches
    format shortg;
    str = date_begin; % beginning of the FMI dataset
    tbegin = datevec(str,'mmmm dd, yyyy HH:MM:SS');
    tbegin_dt = datetime(tbegin(1),tbegin(2),tbegin(3),tbegin(4),tbegin(5),tbegin(6));
    str = date_end; % some endpoint
    tend = datevec(str,'mmmm dd, yyyy HH:MM:SS');
    tend_dt = datetime(tend(1),tend(2),tend(3),tend(4),tend(5),tend(6));
    interval = etime(tend,tbegin);
    interval = interval/(60*60); %convert to hours
    interval = interval/max_download_size;
    nbatches = ceil(interval);


    t_batchbegin = tbegin_dt;
    for k=1:nbatches
        t_batchend = dateshift(t_batchbegin,'start','second',168*60*60-1);
        if (isbetween(t_batchend,tbegin_dt,tend_dt)== 0) 
            t_batchend = tend_dt;
        end

        % date format in url: 2010-01-01T00:00:00Z
        starttime = sprintf('%d-%02d-%02dT%02d:%02d:%02dZ',year(t_batchbegin),month(t_batchbegin),day(t_batchbegin),hour(t_batchbegin),minute(t_batchbegin),second(t_batchbegin));
        endtime = sprintf('%d-%02d-%02dT%02d:%02d:%02dZ',year(t_batchend),month(t_batchend),day(t_batchend),hour(t_batchend),minute(t_batchend),second(t_batchend));

        url = sprintf('http://data.fmi.fi/fmi-apikey/%s/wfs?request=getFeature&storedquery_id=%s&fmisid=%s&starttime=%s&endtime=%s',apikey,dataset,fmisid,starttime,endtime);

        filename = sprintf(datapath,fmisid,k);
        urlwrite(url,filename);

        t_batchbegin = dateshift(t_batchend,'start','second',1);
    end

end