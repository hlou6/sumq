function [ alldata, time ] = parseXMLfiles( nbatches, dataset, datapath, fmisid )
%parseXMLfiles() parses FMI open data XML files where a time series
%is divided across multiple batches. Returned variable time is assumed to
%be monotonously increasing.

    alldata = cell(1,nbatches);
    time = [];
    
    if strcmpi(dataset, 'fmi::observations::weather::multipointcoverage') == 1
        location_time_tag = 'gmlcov:positions';
        data_tag = 'gml:doubleOrNilReasonTupleList';
        data_format = '%f %f %f %f %f %f %f %f %f %f %f %f %f';
    
        for k=1:nbatches
            thisDOM = xmlread(sprintf(datapath,fmisid,k));

            timeList = thisDOM.getElementsByTagName(location_time_tag);
            thisElement = timeList.item(0);
            datastr = char(thisElement.getFirstChild.getData);
            loc_time = textscan(datastr,'%f %f %d');
            for j=1:length(loc_time{1,3})
                time = [time datetime(loc_time{1,3}(j),'ConvertFrom','posixtime')];
            end

            dataList = thisDOM.getElementsByTagName(data_tag);
            thisElement = dataList.item(0);
            datastr = char(thisElement.getFirstChild.getData);
            data = textscan(datastr,data_format);

            alldata{k} = data;
            
            disp(k)
        end
    end
    
end